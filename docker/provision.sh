#!/usr/bin/env bash
# Playbook step of a Proveasio image build.
#
# docker/Dockerfile runs it in the RUN step of the `build` stage. It is
# bind-mounted with the rest of docker/ at DOCKER_DIR, so it is not part of
# the image. Steps: render ansible/vars/overrides.yml, stop when the tags or
# excludes leave out a task every image needs, write docker/build-info.env,
# upgrade the Ubuntu packages, run the playbook, install Mason tools and
# treesitter parsers, remove build leftovers, and start zsh once.
#
# It runs render-overrides.sh and cleanup.sh, so it refuses to run unless
# PROVEASIO_IMAGE_BUILD=1. docker/Dockerfile sets it for this one command.
# Never set it on a workstation.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "provision: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi
# The opt-in goes to render-overrides.sh and cleanup.sh only, not to the playbook.
unset PROVEASIO_IMAGE_BUILD

if [ $# -gt 0 ]; then
  echo "usage: provision.sh" >&2
  exit 2
fi

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"
ANSIBLE_DIR="$PROVEASIO_HOME/ansible"
OVERRIDES="$ANSIBLE_DIR/vars/overrides.yml"
BUILD_INFO="$PROVEASIO_HOME/docker/build-info.env"
ANSIBLE_TAGS="${ANSIBLE_TAGS:-}"
ANSIBLE_SKIP_TAGS="${ANSIBLE_SKIP_TAGS:-}"
PROFILE="${PROFILE:-full}"
# The includes every new image needs (docs-web/docs/main/docker/20-customize.md).
REQUIRED=(software/packages software/yq software/zsh config/zsh)

die() {
  echo "provision: $*" >&2
  exit 1
}

# selection <tags> <skip-tags>: the includes these tags run, minus the
# excludes of the rendered overrides, one "<role>/<name>" per line.
selection() {
  PROVEASIO_HOME="$PROVEASIO_HOME" bash "$DOCKER_DIR/test.sh" --list --tags "$1" --skip-tags "$2"
}

# render: write ansible/vars/overrides.yml (docker/render-overrides.sh).
render() {
  PROVEASIO_IMAGE_BUILD=1 PROVEASIO_HOME="$PROVEASIO_HOME" DOCKER_DIR="$DOCKER_DIR" \
    NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" PROFILE="$PROFILE" \
    bash "$DOCKER_DIR/render-overrides.sh"
}

# check_required: stop before the playbook when a new image would miss a
# required include. The playbook alone would fail much later, in the tests.
check_required() {
  local selected r missing=()
  selected="$(selection "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS")" || die "docker/test.sh --list failed"
  for r in "${REQUIRED[@]}"; do
    grep -qxF -- "$r" <<<"$selected" || missing+=("$r")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    die "a new image needs ${missing[*]}, but ANSIBLE_TAGS='$ANSIBLE_TAGS' ANSIBLE_SKIP_TAGS='$ANSIBLE_SKIP_TAGS' or the excludes in docker/overrides.yml leave them out. To leave tools out, exclude them in docker/overrides.yml."
  fi
}

# write_build_info: what docker/test.sh needs to select the checks of this image.
write_build_info() {
  mkdir -p "$(dirname "$BUILD_INFO")"
  {
    printf 'PROFILE=%q\n' "$PROFILE"
    printf 'ANSIBLE_TAGS=%q\n' "$ANSIBLE_TAGS"
    printf 'ANSIBLE_SKIP_TAGS=%q\n' "$ANSIBLE_SKIP_TAGS"
    printf 'REFRESH=%q\n' "${REFRESH:-}"
    printf 'BUILD_DATE=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'UPDATES=()\n'
  } > "$BUILD_INFO"
}

run_playbook() {
  local args=()
  if [ -n "$ANSIBLE_TAGS" ]; then args+=(--tags "$ANSIBLE_TAGS"); fi
  if [ -n "$ANSIBLE_SKIP_TAGS" ]; then args+=(--skip-tags "$ANSIBLE_SKIP_TAGS"); fi
  # Ansible ignores ansible.cfg in a world-writable current directory, which is
  # what COPY produces from a checkout under /mnt/c. ANSIBLE_CONFIG always loads it.
  (cd "$ANSIBLE_DIR" && ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" \
    ansible-playbook -i inventory.yml setup-ubuntu.yml "${args[@]}")
}

# zsh_path: the PATH of an interactive zsh, read the way docker/test.sh's
# use_zsh_path does. nvm, gvm and rvm add to PATH only there. Prints nothing
# when zsh is missing or the PATH looks wrong. GITHUB_TOKEN is only for the
# playbook's version lookups, so zsh runs without it.
zsh_path() {
  local p=""
  if [ -f "$HOME/.zshrc" ] && command -v zsh >/dev/null 2>&1; then
    p="$(env -u GITHUB_TOKEN TERM=xterm-256color timeout 60 script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)" || p=""
  fi
  case "$p" in */usr/bin*) printf '%s' "$p" ;; esac
}

# nvim_install: Mason and treesitter install in the background, so the role's
# headless `nvim +q` can exit before they finish. nvim-install.lua starts them
# and waits; it skips what the config does not use. It runs under pcall so
# that a missing or broken helper fails the build instead of exiting 0.
# Mason installs some packages with npm, go or gem, so nvim gets the zsh PATH.
# Mason sets GOBIN and GEM_HOME itself; PATH is the only variable it needs.
nvim_install() {
  local app nvim_path lua
  app="$(yq -r '.neovim_config_appname // ""' "$OVERRIDES")"
  if [ -z "$app" ]; then app="$(yq -r '.neovim_config_appname' "$ANSIBLE_DIR/roles/config/vars/main.yml")"; fi
  if ! command -v nvim >/dev/null 2>&1 || [ ! -d "$HOME/.config/$app" ]; then return 0; fi
  nvim_path="$(zsh_path)"
  if [ -z "$nvim_path" ]; then
    echo "WARNING: could not read PATH from zsh; nvim uses the build PATH, so Mason packages that need npm, go or gem fail" >&2
    nvim_path="$PATH"
  fi
  printf -v lua 'lua local ok, err = pcall(dofile, "%s/nvim-install.lua") if not ok then io.stderr:write("\\n" .. tostring(err) .. "\\n") vim.cmd("cquit 1") end' "$DOCKER_DIR"
  env -u GITHUB_TOKEN PATH="$nvim_path" NVIM_APPNAME="$app" timeout 1800 nvim --headless -c "$lua" -c 'qa'
}

cleanup() {
  PROVEASIO_IMAGE_BUILD=1 bash "$DOCKER_DIR/cleanup.sh"
}

# warm_zsh: the first interactive zsh start downloads gitstatusd for p10k and
# builds caches, so containers can start without network access. p10k fetches
# gitstatusd before the first prompt, so the shell has to draw one
# (`zsh -i -c exit` does not); `exit` on stdin then ends it.
warm_zsh() {
  if [ -f "$HOME/.zshrc" ]; then
    env -u GITHUB_TOKEN TERM=xterm-256color POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true \
      timeout 300 script -qec 'zsh -i' /dev/null <<<'exit'
  fi
}

echo "provision: PROFILE=$PROFILE REFRESH=${REFRESH:-} ANSIBLE_TAGS=$ANSIBLE_TAGS ANSIBLE_SKIP_TAGS=$ANSIBLE_SKIP_TAGS"
render
check_required
write_build_info
sudo apt-get update
sudo apt-get -y upgrade
run_playbook
nvim_install
cleanup
warm_zsh
