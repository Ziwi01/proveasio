#!/usr/bin/env bash
# Smoke tests for a Proveasio Docker image.
#
# Runs in the `test` stage of docker/Dockerfile on every build (the `final`
# stage depends on it) and by hand in a container:
#   ~/proveasio/docker/test.sh                      run every selected check
#   ~/proveasio/docker/test.sh --list               print the selected checks
#   ~/proveasio/docker/test.sh --list --tags <t> --skip-tags <s>
#                                                   print what these tags select
#   ~/proveasio/docker/test.sh --only config/zsh    run one check (repeatable)
#   ~/proveasio/docker/test.sh --coverage           fail if an include has no check
#
# Selection comes from the real inputs: every include in
# roles/{software,config}/tasks/main.yml, minus the excludes in the effective
# ansible/vars/overrides.yml, filtered by the tags in docker/build-info.env:
# an include counts when the build's tags or the tags of any recorded update
# select it. --tags/--skip-tags replace all of those (docker/provision.sh
# uses them).
# Each selected include needs a check_<role>_<name> function below (dashes
# become underscores). A missing function counts as a failure.
set -uo pipefail

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
ANSIBLE_DIR="$PROVEASIO_HOME/ansible"
OVERRIDES="$ANSIBLE_DIR/vars/overrides.yml"
RECEIPT="$PROVEASIO_HOME/current-versions.yml"
BUILD_INFO="$PROVEASIO_HOME/docker/build-info.env"
ROLES=(software config)

if [ -z "${TERM:-}" ] || [ "$TERM" = dumb ]; then export TERM=xterm-256color; fi
export AZURE_CORE_COLLECT_TELEMETRY=no
# The PATH a container starts with, before use_zsh_path replaces it.
START_PATH="$PATH"

OUT=""
REASON=""
DETAIL=""
LIST=""

# ------------------------------------------------------------------ helpers

fail() { REASON="$*"; return 1; }

# effective <key> <role> [yq filter]: the value Ansible uses for a top-level
# variable. include_vars replaces whole variables, so the overrides file wins
# when it has the key. Do not use it for github_packages, pip_packages or
# docker_apt_packages (merged per key); read the receipt for those.
effective() {
  local key="$1" role="$2" filter="${3:-.}" file="$ANSIBLE_DIR/roles/$2/vars/main.yml"
  if [ -f "$OVERRIDES" ] && [ "$(yq "has(\"$key\")" "$OVERRIDES" 2>/dev/null)" = true ]; then
    file="$OVERRIDES"
  fi
  yq -r ".[\"$key\"] | $filter" "$file"
}

# effective_list <key> <role> <filter>: effective, for values a check loops
# over. Sets LIST instead of printing, because REASON set inside $(...) would
# be lost. Fails when yq fails or prints nothing, so a missing or empty list
# cannot make a check pass without checking anything.
effective_list() {
  if ! LIST="$(effective "$1" "$2" "$3")" || [ -z "$LIST" ]; then
    fail "no $1 values in overrides or roles/$2/vars/main.yml"
    return 1
  fi
}

# receipt <yq path>: a value from current-versions.yml, empty when absent.
receipt() {
  [ -f "$RECEIPT" ] || return 0
  local v
  v="$(yq -r "$1" "$RECEIPT" 2>/dev/null)"
  [ "$v" = null ] && v=""
  printf '%s' "$v"
}

# deb_upstream <apt version>: 1:2.55.0-0ppa1~ubuntu24.04.2 -> 2.55.0
deb_upstream() {
  local v="${1#*:}"
  printf '%s' "${v%%-*}"
}

# run_cmd <cmd...>: run with a timeout; combined output goes to OUT.
run_cmd() {
  local rc
  OUT="$(timeout 300 "$@" 2>&1)"
  rc=$?
  [ "$rc" -eq 0 ] || fail "'$*' exited $rc: $(head -c 300 <<<"$OUT")"
}

# run_sh <script>: run_cmd for commands that need `source` or pipes.
run_sh() { run_cmd bash -c "$1"; }

# expect_out <text>: OUT must contain text.
expect_out() {
  [ -n "$1" ] || fail "expected text is empty" || return 1
  grep -qF -- "$1" <<<"$OUT" || fail "expected '$1' in: $(head -c 200 <<<"$OUT")"
}

# expect_receipt <yq path> [deb]: the receipt version must appear in OUT.
expect_receipt() {
  local v
  v="$(receipt "$1")"
  [ -n "$v" ] || fail "no $1 in current-versions.yml" || return 1
  if [ "${2:-}" = deb ]; then v="$(deb_upstream "$v")"; fi
  DETAIL="$v"
  expect_out "$v"
}

expect_file() { [ -e "$1" ] || fail "missing $1"; }
expect_exec() { [ -x "$1" ] || fail "missing or not executable: $1"; }
expect_nonempty_dir() { [ -n "$(ls -A "$1" 2>/dev/null)" ] || fail "missing or empty directory: $1"; }

# ------------------------------------------------------------------ checks
check_software_packages() {
  local installed p missing=()
  # Names and virtual names (Provides) of installed packages, so renamed or
  # virtual entries such as libfuse2 (libfuse2t64) or ncurses-dev match.
  installed="$(dpkg-query -W -f '${db:Status-Abbrev} ${Package} ${Provides}\n' \
    | awk '$1 == "ii" { $1 = ""; print }' | sed -E 's/\([^)]*\)//g; s/,/ /g' \
    | tr ' ' '\n' | sed '/^$/d' | sort -u)"
  effective_list default_apt_packages software '.[]' || return 1
  while read -r p; do
    [ -n "$p" ] || continue
    grep -qxF -- "$p" <<<"$installed" || missing+=("$p")
  done <<<"$LIST"
  [ ${#missing[@]} -eq 0 ] || fail "not installed: ${missing[*]}" || return 1
  DETAIL="$(effective default_apt_packages software 'length') packages"
}

check_software_yq()        { run_cmd yq --version && expect_receipt .github_packages.yq; }
check_software_fx()        { run_cmd fx --version && expect_receipt .github_packages.fx; }
check_software_git()       { run_cmd git --version && expect_receipt .git_apt_version deb; }
check_software_ripgrep()   { run_cmd rg --version && expect_receipt .github_packages.ripgrep; }
check_software_fd()        { run_cmd fd --version && expect_receipt .github_packages.fd; }
check_software_eza()       { run_cmd eza --version && expect_receipt .github_packages.eza && expect_file "$HOME/.zfunc/_eza"; }
check_software_lsg()       { expect_exec "$HOME/.local/bin/lsg" && run_cmd bash -n "$HOME/.local/bin/lsg"; }
check_software_fzf()       { run_cmd fzf --version && expect_receipt .github_packages.fzf; }

check_software_diff_so_fancy() {
  local bin
  bin="$(command -v diff-so-fancy)" || fail "diff-so-fancy is not on PATH" || return 1
  run_sh 'printf "" | diff-so-fancy' || return 1
  # diff-so-fancy prints no version; the script defines `my $VERSION = "x";`.
  OUT="$(<"$bin")"
  expect_receipt .github_packages.diff_so_fancy
}

check_software_git_fuzzy() { expect_exec "$HOME/.local/opt/git-fuzzy/bin/git-fuzzy"; }
check_software_dry()       { run_cmd dry --version && expect_receipt .github_packages.dry; }
check_software_lazygit()   { run_cmd lazygit --version && expect_receipt .github_packages.lazygit; }
check_software_gita()      { run_cmd gita --version && expect_receipt .pip_packages.gita; }
check_software_bottom()    { run_cmd btm --version && expect_receipt .github_packages.bottom; }
check_software_pay_respects() { run_cmd pay-respects --version && expect_receipt .github_packages.pay_respects; }
check_software_kubeswitch() { run_cmd switcher --version && expect_receipt .github_packages.kubeswitch; }

check_software_az_account_switcher() {
  command -v az-account-switcher >/dev/null || fail "az-account-switcher is not on PATH" || return 1
  run_cmd "$HOME/.pyenv/shims/pip3" show az-account-switcher && expect_receipt .pip_packages.az_account_switcher
}

check_software_zoxide()    { run_cmd zoxide --version && expect_receipt .github_packages.zoxide; }
check_software_helm()      { run_cmd helm version --short && expect_receipt .github_packages.helm; }

check_software_zsh() {
  local p
  run_cmd zsh --version || return 1
  expect_nonempty_dir "$HOME/.oh-my-zsh" || return 1
  effective_list omz_plugins software 'keys | .[]' || return 1
  for p in $LIST; do
    expect_nonempty_dir "$HOME/.oh-my-zsh/custom/plugins/$p" || return 1
  done
  run_cmd git -C "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" describe --tags \
    && expect_receipt .github_packages.p10k
}

check_software_w32yank()   { expect_exec "$HOME/.local/bin/win32yank.exe"; }
check_software_wsl_notify_send() { expect_exec "$HOME/.local/bin/wsl-notify-send.exe"; }

check_software_tmux() {
  local sock="proveasio-test-$$"
  run_cmd tmux -V && expect_receipt .github_packages.tmux || return 1
  run_cmd tmuxp --version && expect_receipt .pip_packages.tmuxp || return 1
  expect_file "$HOME/.tmux/plugins/tpm/tpm" || return 1
  run_cmd tmux -L "$sock" new-session -d -s proveasio-test || return 1
  run_cmd tmux -L "$sock" kill-server
  DETAIL="$(receipt .github_packages.tmux)"
}

check_software_docker() {
  local detail
  run_cmd docker --version || return 1
  if [ -n "$(receipt '.docker_apt_packages["docker-ce-cli"]')" ]; then
    expect_receipt '.docker_apt_packages["docker-ce-cli"]' deb || return 1
  fi
  detail="$DETAIL"
  run_cmd docker compose version && expect_receipt '.docker_apt_packages["docker-compose-plugin"]' deb || return 1
  run_cmd docker buildx version || return 1
  if [ -n "$(receipt '.docker_apt_packages["docker-buildx-plugin"]')" ]; then
    expect_receipt '.docker_apt_packages["docker-buildx-plugin"]' deb || return 1
  fi
  DETAIL="cli ${detail:-?}"
  # Only when the host engine socket is mounted (never during the build).
  if [ -S /var/run/docker.sock ]; then
    run_cmd docker info --format '{{.ServerVersion}}' || return 1
    DETAIL+=", engine $(head -n 1 <<<"$OUT")"
  fi
}

check_software_kubectl()   { run_cmd kubectl version --client && expect_receipt .kubectl_version; }
check_software_kubecolor() { run_cmd kubecolor --kubecolor-version && expect_receipt .github_packages.kubecolor; }
check_software_kind()      { run_cmd kind version && expect_receipt .github_packages.kind; }
check_software_k9s()       { run_cmd k9s version -s && expect_receipt .github_packages.k9s; }

check_software_rvm() {
  local rvm='source "$HOME/.rvm/scripts/rvm"' ruby
  run_sh "$rvm && rvm --version" || return 1
  effective_list rvm1_rubies software '.[]' || return 1
  for ruby in $LIST; do
    run_sh "$rvm && rvm $ruby do ruby -v" && expect_out "${ruby#ruby-}" || return 1
  done
  DETAIL="$(effective rvm1_rubies software 'join(" ")')"
}

check_software_sdkman() {
  local init='source "$HOME/.sdkman/bin/sdkman-init.sh"' cand ver cmd
  run_sh "$init && sdk version" || return 1
  effective_list sdkman_defaults software 'keys | .[]' || return 1
  for cand in $LIST; do
    ver="$(effective sdkman_defaults software ".[\"$cand\"]")"
    case "$cand" in
      java) cmd="java -version" ;;
      maven) cmd="mvn --version" ;;
      *) cmd="$cand --version" ;;
    esac
    # SDKMAN candidate versions carry a vendor suffix: 25.0.2-open -> 25.0.2
    run_sh "$init && $cmd" && expect_out "${ver%%-*}" || return 1
    # The checks run with the PATH of an interactive zsh, so .zshrc has to load SDKMAN.
    case "$(command -v "${cmd%% *}")" in
      "$HOME/.sdkman/candidates/"*) ;;
      *) fail "${cmd%% *} from SDKMAN is not on the PATH of an interactive zsh"; return 1 ;;
    esac
  done
  DETAIL="$(effective sdkman_defaults software 'to_entries | map(.key + " " + .value) | join(", ")')"
}

check_software_nvm() {
  local init='source "$HOME/.local/opt/nvm/nvm.sh"' pkg
  run_sh "$init && nvm --version" && expect_receipt .github_packages.nvm || return 1
  run_cmd node --version || return 1
  DETAIL="nvm $(receipt .github_packages.nvm), node $(head -n 1 <<<"$OUT")"
  effective_list npm_default_packages software '.[]' || return 1
  for pkg in $LIST; do
    run_sh "$init && npm ls -g --depth=0 $pkg" && expect_out "$pkg@" || return 1
  done
}

check_software_rust()      { run_cmd rustc --version && run_cmd cargo --version; }

check_software_gvm() {
  local go
  go="$(effective go_default software)"
  [ -n "$go" ] && [ "$go" != null ] || fail "no go_default in overrides or roles/software/vars/main.yml" || return 1
  run_cmd go version && expect_out "$go " && DETAIL="$go"
}

check_software_ansible() {
  run_cmd "$HOME/.pyenv/shims/pip3" show ansible && expect_receipt .ansible_pip_version || return 1
  run_cmd ansible-playbook --version || return 1
  run_cmd ansible-lint --version && expect_receipt .ansible_lint_pip_version
}

check_software_neovim() {
  run_cmd nvim --version || return 1
  if [ "$(receipt .github_packages.neovim)" = nightly ]; then DETAIL=nightly; return 0; fi
  expect_receipt .github_packages.neovim
}

check_software_puppet() {
  local rvm='source "$HOME/.rvm/scripts/rvm"' pdk
  run_sh "$rvm && rvm all do gem list --exact puppet" \
    && expect_out "$(effective puppet_version software)" || return 1
  run_sh "$rvm && rvm all do gem list --exact puppet-lint" \
    && expect_out "$(effective puppet_lint_version software)" || return 1
  # apt 3.4.0.1-1focal is PDK 3.4.0 (the fourth number is the package build).
  pdk="$(deb_upstream "$(receipt .puppet_pdk_version)" | cut -d. -f1-3)"
  run_cmd pdk --version && expect_out "$pdk" || return 1
  expect_nonempty_dir "$HOME/.lsp/puppet-editor-services" || return 1
  DETAIL="puppet $(effective puppet_version software), pdk $pdk"
}

check_software_terraform()  { run_cmd terraform version && expect_receipt .github_packages.terraform; }
check_software_terragrunt() { run_cmd terragrunt --version && expect_receipt .github_packages.terragrunt; }
check_software_azurecli() {
  local az
  run_cmd az version && expect_receipt .azurecli_apt_version deb || return 1
  az="$DETAIL"
  # kubelogin --version prints "git hash: v0.2.20/<sha>"; the receipt has no "v".
  run_cmd kubelogin --version && expect_receipt .github_packages.kubelogin || return 1
  DETAIL="az $az, kubelogin $DETAIL"
}
check_software_awscli()     { run_cmd aws --version && expect_out "aws-cli/" && DETAIL="$(cut -d' ' -f1 <<<"$OUT")"; }
check_software_uv()         { run_cmd uv --version && expect_receipt .github_packages.uv; }
check_software_opencode()   { run_cmd opencode --version && expect_receipt .github_packages.opencode; }
check_software_hunk()       { run_cmd hunk --version && expect_receipt .github_packages.hunk; }
check_software_ccmux()      { run_cmd ccmux --version && expect_receipt .github_packages.ccmux; }

check_config_zsh() {
  local rc
  expect_file "$HOME/.zshrc" || return 1
  # Start zsh the way a container does. The zsh PATH the other checks use
  # has RVM's ruby but not GEM_HOME, and RVM prints a warning about that.
  # stdin is /dev/null for the reason given in use_zsh_path.
  OUT="$(PATH="$START_PATH" timeout 60 script -qec 'zsh -i -c exit' /dev/null </dev/null 2>&1)"
  rc=$?
  OUT="$(tr -d '\r' <<<"$OUT")"
  [ "$rc" -eq 0 ] || fail "interactive zsh exited $rc: $(head -c 300 <<<"$OUT")" || return 1
  [ -z "$(tr -d '[:space:]' <<<"$OUT")" ] || fail "interactive zsh printed: $(head -c 300 <<<"$OUT")"
}

check_config_p10k() {
  local gsd
  expect_file "$HOME/.p10k.zsh" || return 1
  # The image build's first zsh start downloads gitstatusd; without it p10k
  # downloads it on the first start in a container, which fails offline.
  # zsh loads p10k only when config/zsh wrote a .zshrc that selects it.
  if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] \
    && grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc" 2>/dev/null; then
    compgen -G "$HOME/.cache/gitstatus/gitstatusd-*" >/dev/null \
      || fail "gitstatusd missing in ~/.cache/gitstatus (p10k would download it on first start)" || return 1
    gsd="$(compgen -G "$HOME/.cache/gitstatus/gitstatusd-*" | head -n 1)"
    DETAIL="${gsd##*/}"
  fi
}

check_config_tmux() {
  local n
  expect_file "$HOME/.tmux.conf" || return 1
  expect_exec "$HOME/.local/bin/tmux-default-session-name" || return 1
  expect_file "$HOME/.tmuxp/default_session.yaml" || return 1
  n="$(find "$HOME/.tmux/plugins" -mindepth 1 -maxdepth 1 -type d ! -name tpm 2>/dev/null | wc -l)"
  [ "$n" -gt 0 ] || fail "no TPM plugins in ~/.tmux/plugins" || return 1
  DETAIL="$n TPM plugins"
}

check_config_ccmux()    { expect_file "$HOME/.config/ccmux/ccmux.json"; }

check_config_neovim_config() {
  local app lazy mason
  app="$(effective neovim_config_appname config)"
  expect_nonempty_dir "$HOME/.config/$app" || return 1
  expect_nonempty_dir "$HOME/.local/share/$app" || return 1
  run_cmd env NVIM_APPNAME="$app" nvim --headless +qa || return 1
  if grep -qE 'E[0-9]+: |Error' <<<"$OUT"; then
    fail "nvim reported errors: $(head -c 300 <<<"$OUT")"
    return 1
  fi
  lazy="$HOME/.local/share/$app/lazy"
  mason="$HOME/.local/share/$app/mason/packages"
  # blink.cmp loads only on InsertEnter, so the start above does not load it.
  # A checkout of the wrong major version fails here (see config/neovim-config).
  if [ -d "$lazy/blink.cmp" ]; then
    run_cmd env NVIM_APPNAME="$app" nvim --headless \
      -c 'lua local ok, err = pcall(function() require("lazy").load({ plugins = { "blink.cmp" } }); require("blink.cmp") end) if not ok then io.stderr:write(tostring(err), "\n") vim.cmd("cquit 1") end' \
      -c qa || return 1
  fi
  DETAIL="$app"
  if [ -d "$lazy" ]; then DETAIL+=", $(find "$lazy" -mindepth 1 -maxdepth 1 | wc -l) lazy plugins"; fi
  if [ -d "$mason" ]; then DETAIL+=", $(find "$mason" -mindepth 1 -maxdepth 1 | wc -l) mason packages"; fi
  return 0
}

check_config_sdkman()   { expect_file "$HOME/.sdkman/etc/config"; }
check_config_git()      { run_cmd git config --global user.name && expect_out "$(effective git config '.name')"; }
check_config_lazygit()  { expect_file "$HOME/.config/lazygit/config.yml"; }
check_config_ansible()  { expect_file "$HOME/.ansible-lint"; }
# ------------------------------------------------------------- end of checks

# includes <role>: "<name> <comma-separated outer tags>" for each include.
# docker/render-overrides.sh (role_includes) parses the same list; keep both in sync.
includes() {
  yq -r '.[] | select(has("ansible.builtin.include_tasks"))
    | (.["ansible.builtin.include_tasks"].file | sub("\.yml$"; "")) + " " + ((.tags // []) | join(","))' \
    "$ANSIBLE_DIR/roles/$1/tasks/main.yml"
}

# role_includes <role>: includes, but fails when yq fails or finds no include,
# so a broken yq or a moved main.yml cannot select zero checks and pass.
role_includes() {
  local out
  if ! out="$(includes "$1")" || [ -z "$out" ]; then
    echo "# error: could not read includes from roles/$1/tasks/main.yml" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

excluded() { effective "${1}_tasks_exclude" "$1" '.[]' | grep -qxF -- "$2"; }

# tags_select <outer tags> <--tags value> <--skip-tags value>: mirrors
# ansible-playbook --tags / --skip-tags on one include. Ansible's special tags
# in --tags: `all` selects every include, `tagged` every include with a tag
# (all of them here). --skip-tags matches literally. Empty means not passed.
tags_select() {
  local outer="$1" run="$2" skip="$3" t hit=0
  if [ -n "$run" ]; then
    for t in ${run//,/ }; do
      case "$t" in
        all) hit=1 ;;
        tagged) if [ -n "$outer" ]; then hit=1; fi ;;
        *) if [[ ",$outer," == *",$t,"* ]]; then hit=1; fi ;;
      esac
    done
    [ "$hit" -eq 1 ] || return 1
  fi
  if [ -n "$skip" ]; then
    for t in ${skip//,/ }; do
      if [[ ",$outer," == *",$t,"* ]]; then return 1; fi
    done
  fi
  return 0
}

# image_selects <outer tags>: whether this image ran the include, because the
# tags of the build (ANSIBLE_TAGS, ANSIBLE_SKIP_TAGS) or of any update select
# it. UPDATES entries are "<date>|<tags>|<skip-tags>" (provision.sh --update).
image_selects() {
  local u rest
  if tags_select "$1" "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS"; then return 0; fi
  for u in "${UPDATES[@]}"; do
    rest="${u#*|}"
    if tags_select "$1" "${rest%%|*}" "${rest#*|}"; then return 0; fi
  done
  return 1
}

check_fn() {
  local n="check_$1_$2"
  printf '%s' "${n//-/_}"
}

coverage() {
  local role name tags fn lines uncovered=0 total=0
  for role in "${ROLES[@]}"; do
    lines="$(role_includes "$role")" || exit 1
    while read -r name tags; do
      [ -n "$name" ] || continue
      total=$((total + 1))
      fn="$(check_fn "$role" "$name")"
      if ! declare -F "$fn" >/dev/null; then
        echo "missing $fn for $role/$name"
        uncovered=$((uncovered + 1))
      fi
    done <<<"$lines"
  done
  echo "# $total includes, $uncovered without a check"
  [ "$uncovered" -eq 0 ]
}

# Checks run in bash, with the PATH an interactive zsh would have, so they see
# what a user sees. zsh needs a terminal for a clean start; `script` gives it one.
# `timeout` runs script in its own process group. If script's stdin were the
# terminal of an interactive run, script would stop on its first terminal access
# and hang until the timeout, so stdin is /dev/null.
use_zsh_path() {
  if [ ! -f "$HOME/.zshrc" ] || ! command -v zsh >/dev/null || ! command -v script >/dev/null; then
    return 0
  fi
  local p
  p="$(timeout 60 script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)"
  case "$p" in
    */usr/bin*) export PATH="$p" ;;
    *) echo "# warning: could not read PATH from zsh, keeping the current PATH" ;;
  esac
}

usage() {
  cat <<'EOF'
Usage: docker/test.sh [--list [--tags <tags>] [--skip-tags <tags>]] [--coverage] [--only <role>/<name>]...
  --list        print the checks selected for this image and exit
  --tags        with --list: select as `ansible-playbook --tags` would, instead
                of using docker/build-info.env
  --skip-tags   with --list: the same for `--skip-tags`
  --coverage    exit non-zero if any include in the roles has no check function
  --only        run only the given check; repeatable
EOF
}

main() {
  local list_only=0 do_coverage=0 tags_given=0 opt_tags="" opt_skip=""
  local only=() selected=() role name tags item fn o lines
  while [ $# -gt 0 ]; do
    case "$1" in
      --list) list_only=1 ;;
      --coverage) do_coverage=1 ;;
      --only)
        [ $# -ge 2 ] || { echo "--only needs a value" >&2; exit 2; }
        only+=("$2"); shift ;;
      --tags)
        [ $# -ge 2 ] || { echo "--tags needs a value" >&2; exit 2; }
        tags_given=1; opt_tags="$2"; shift ;;
      --skip-tags)
        [ $# -ge 2 ] || { echo "--skip-tags needs a value" >&2; exit 2; }
        tags_given=1; opt_skip="$2"; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done

  if [ "$do_coverage" -eq 1 ]; then coverage; exit $?; fi
  if [ "$tags_given" -eq 1 ] && [ "$list_only" -eq 0 ]; then
    echo "--tags and --skip-tags only work with --list" >&2
    exit 2
  fi

  ANSIBLE_TAGS=""
  ANSIBLE_SKIP_TAGS=""
  UPDATES=()
  if [ "$tags_given" -eq 1 ]; then
    ANSIBLE_TAGS="$opt_tags"
    ANSIBLE_SKIP_TAGS="$opt_skip"
  elif [ -f "$BUILD_INFO" ]; then
    # shellcheck source=/dev/null
    source "$BUILD_INFO"
  fi

  for role in "${ROLES[@]}"; do
    lines="$(role_includes "$role")" || exit 1
    while read -r name tags; do
      [ -n "$name" ] || continue
      excluded "$role" "$name" && continue
      image_selects "$tags" || continue
      selected+=("$role/$name")
    done <<<"$lines"
  done
  # Explicit tags may select nothing (provision.sh reports that itself); an
  # image with nothing to check is an error.
  if [ ${#selected[@]} -eq 0 ] && [ "$tags_given" -eq 0 ]; then
    echo "# error: no checks selected" >&2
    exit 1
  fi

  if [ ${#only[@]} -gt 0 ]; then
    for o in "${only[@]}"; do
      printf '%s\n' "${selected[@]}" | grep -qxF -- "$o" || { echo "not selected in this image: $o" >&2; exit 2; }
    done
    selected=("${only[@]}")
  fi

  if [ "$list_only" -eq 1 ]; then
    if [ ${#selected[@]} -gt 0 ]; then printf '%s\n' "${selected[@]}"; fi
    exit 0
  fi

  use_zsh_path
  local pass=0 failed=0
  for item in "${selected[@]}"; do
    fn="$(check_fn "${item%%/*}" "${item#*/}")"
    OUT=""; REASON=""; DETAIL=""
    if ! declare -F "$fn" >/dev/null; then
      echo "not ok $item: no $fn in docker/test.sh"
      failed=$((failed + 1))
    elif "$fn"; then
      echo "ok $item${DETAIL:+ ($DETAIL)}"
      pass=$((pass + 1))
    else
      echo "not ok $item: ${REASON:-check failed}"
      failed=$((failed + 1))
    fi
  done
  echo "# ${#selected[@]} selected, $pass passed, $failed failed"
  [ "$failed" -eq 0 ]
}

main "$@"
