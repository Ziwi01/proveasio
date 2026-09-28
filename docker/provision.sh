#!/usr/bin/env bash
# Playbook step of a Proveasio image build.
#
# docker/Dockerfile runs it in the RUN step of the `build` stage (a new image)
# and, with --update, in the `update` stage (docker-bake.hcl target `update`,
# on top of an existing image). It is bind-mounted with the rest of docker/ at
# DOCKER_DIR, so it is not part of the image.
#
# New image: render ansible/vars/overrides.yml, stop when the tags or excludes
# leave out a task every image needs, write docker/build-info.env, upgrade the
# Ubuntu packages, run the playbook, install Mason tools and treesitter
# parsers, remove build leftovers, and start zsh once.
#
# Update: check that the base image and the settings allow an update (see
# update below), render the overrides with the base image's profile, run the
# playbook with ANSIBLE_TAGS without upgrading Ubuntu, install Mason tools
# only when the tags touch Neovim, remove leftovers, start zsh, and record the
# update in docker/build-info.env.
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

MODE=full
case "$#:${1:-}" in
  0:) ;;
  1:--update) MODE=update ;;
  *)
    echo "usage: provision.sh [--update]" >&2
    exit 2
    ;;
esac

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"
ANSIBLE_DIR="$PROVEASIO_HOME/ansible"
OVERRIDES="$ANSIBLE_DIR/vars/overrides.yml"
BUILD_INFO="$PROVEASIO_HOME/docker/build-info.env"
ANSIBLE_TAGS="${ANSIBLE_TAGS:-}"
ANSIBLE_SKIP_TAGS="${ANSIBLE_SKIP_TAGS:-}"
# update() compares the base image's profile with the one asked for, and an
# unset PROFILE asks for none.
REQUESTED_PROFILE="${PROFILE:-}"
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

# render [base overrides]: write ansible/vars/overrides.yml
# (docker/render-overrides.sh). An update passes the image's previous file.
render() {
  PROVEASIO_IMAGE_BUILD=1 PROVEASIO_HOME="$PROVEASIO_HOME" DOCKER_DIR="$DOCKER_DIR" \
    NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" PROFILE="$PROFILE" PROVEASIO_BASE_OVERRIDES="${1:-}" \
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

# excludes <overrides file> <role>: the effective <role>_tasks_exclude, sorted.
# A missing key means the role default, which is [] for both roles.
excludes() {
  KEY="${2}_tasks_exclude" yq -r '(.[strenv(KEY)] // [])[]' "$1" | sort -u
}

full() {
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
}

update() {
  local base role now base_ex added readded name selected requested passed image_wide tested item verb what
  local fresh=()
  [ -n "$ANSIBLE_TAGS" ] || die "an update needs ANSIBLE_TAGS, the tags of the tools to update. To update everything, run a full build."
  if [ ! -f "$BUILD_INFO" ] || [ ! -f "$OVERRIDES" ]; then
    die "the base image has no $BUILD_INFO or $OVERRIDES. BASE_IMAGE must be a Proveasio image built with docker-bake.hcl."
  fi
  if [ "$HOME" != "/home/${USERNAME:-}" ] || [ "$(id -u)" != "${USER_UID:-}" ] || [ "$(id -g)" != "${USER_GID:-}" ]; then
    die "USERNAME=${USERNAME:-} USER_UID=${USER_UID:-} USER_GID=${USER_GID:-} do not match the base image user $(id -un) ($(id -u):$(id -g), HOME=$HOME). Pass the values the base image was built with."
  fi
  # The base image's profile, not the build argument. Images built before
  # profiles existed have no PROFILE line and are full images.
  requested="$REQUESTED_PROFILE"
  # shellcheck source=/dev/null
  PROFILE="$(PROFILE=full; source "$BUILD_INFO"; printf '%s' "$PROFILE")"
  if [ -n "$requested" ] && [ "$requested" != "$PROFILE" ]; then
    die "the base image is a $PROFILE image, but PROFILE=$requested. Set PROFILE=$PROFILE (it also selects the default IMAGE and BASE_IMAGE) or set BASE_IMAGE to a $requested image."
  fi
  echo "provision: update of a $PROFILE image, REFRESH=${REFRESH:-} ANSIBLE_TAGS=$ANSIBLE_TAGS ANSIBLE_SKIP_TAGS=$ANSIBLE_SKIP_TAGS"

  base="$(mktemp)"
  cp "$OVERRIDES" "$base"
  render "$base"

  selected="$(selection "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS")" || die "docker/test.sh --list failed"
  [ -n "$selected" ] || die "ANSIBLE_TAGS='$ANSIBLE_TAGS' ANSIBLE_SKIP_TAGS='$ANSIBLE_SKIP_TAGS' select no task. The tags are listed in docs-web/docs/main/customization/50-partial-run.md."
  for role in software config; do
    now="$(excludes "$OVERRIDES" "$role")"
    base_ex="$(excludes "$base" "$role")"
    added="$(comm -13 <(printf '%s\n' "$base_ex") <(printf '%s\n' "$now") | sed '/^$/d' | paste -sd' ')"
    if [ -n "$added" ]; then
      die "${role}_tasks_exclude now also has: ${added}. An update cannot remove a tool from the image (it would stay installed and untested). If docker/overrides.yml changed since the base build (for example a removed *_tasks_include), restore it; to remove the tool, run a full build."
    fi
    readded="$(comm -23 <(printf '%s\n' "$base_ex") <(printf '%s\n' "$now") | sed '/^$/d')"
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      grep -qxF -- "$role/$name" <<<"$selected" \
        || die "$role/$name is no longer excluded, but ANSIBLE_TAGS does not select it. Add its tag to ANSIBLE_TAGS so the update installs it."
    done <<<"$readded"
  done
  if [ "$(yq -r '.neovim_config_source // ""' "$base")" = local ] \
    && [ -z "$(ls -A "$NVIM_CONFIG_DIR" 2>/dev/null)" ] \
    && grep -qxF config/neovim-config <<<"$selected"; then
    die "the base image was built with NVIM_CONFIG and these tags update config/neovim-config. Pass the same NVIM_CONFIG (and --allow fs.read=<dir>) to the update."
  fi
  # After the update, docker/test.sh checks every include the image's tags
  # select in the checked-out ansible/. An include added to the checkout after
  # the base build is not in the image, so its check fails unless these tags
  # install it. tests-passed lists the checks the base image passed.
  passed="$PROVEASIO_HOME/docker/tests-passed"
  if [ -f "$passed" ]; then
    image_wide="$(PROVEASIO_HOME="$PROVEASIO_HOME" bash "$DOCKER_DIR/test.sh" --list)" || die "docker/test.sh --list failed"
    tested="$(sed -nE 's#^ok ([^ ]+).*#\1#p' "$passed")"
    while IFS= read -r item; do
      [ -n "$item" ] || continue
      grep -qxF -- "$item" <<<"$tested" && continue
      grep -qxF -- "$item" <<<"$selected" && continue
      fresh+=("$item")
    done <<<"$image_wide"
    if [ ${#fresh[@]} -gt 0 ]; then
      verb="is new"; what="its tag"
      if [ ${#fresh[@]} -gt 1 ]; then verb="are new"; what="their tags"; fi
      die "${fresh[*]} $verb in the checked-out ansible/ since the base image was built and would be tested but not installed. Add $what to ANSIBLE_TAGS, or run a full build."
    fi
  else
    echo "WARNING: the base image has no $passed (built without its tests), so the check for includes added since the base build is skipped" >&2
  fi
  rm -f "$base"

  sudo apt-get update
  run_playbook
  if grep -qxE 'software/neovim|config/neovim-config' <<<"$selected"; then nvim_install; fi
  cleanup
  warm_zsh
  printf 'UPDATES+=(%q)\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)|$ANSIBLE_TAGS|$ANSIBLE_SKIP_TAGS" >> "$BUILD_INFO"
}

"$MODE"
