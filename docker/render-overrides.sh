#!/usr/bin/env bash
# Build the effective ansible/vars/overrides.yml for a Docker image build.
#
# docker/provision.sh runs it in the playbook step. Inputs, bind-mounted at
# DOCKER_DIR, merged in this order: the committed docker/profile.yml,
# docker/profile-<PROFILE>.yml unless PROFILE is "full", and the optional,
# gitignored docker/overrides.yml. Maps merge recursively and lists are
# appended. Then software_tasks_include and config_tasks_include take names
# out of software_tasks_exclude and config_tasks_exclude. The nvim-config
# build context at NVIM_CONFIG_DIR switches the Neovim config to that
# directory. The roles then merge github_packages, pip_packages and
# docker_apt_packages with their defaults per key; every other variable
# replaces the role default.
#
# It overwrites ansible/vars/overrides.yml, so it refuses to run unless
# PROVEASIO_IMAGE_BUILD=1. docker/provision.sh sets it for this one command.
# Never set it on a workstation: there it would replace your own overrides.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "render-overrides: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"
PROFILE="${PROFILE:-full}"

profile="$DOCKER_DIR/profile.yml"
user_overrides="$DOCKER_DIR/overrides.yml"
target="$PROVEASIO_HOME/ansible/vars/overrides.yml"

if [ ! -f "$profile" ]; then
  echo "render-overrides: missing $profile" >&2
  exit 1
fi
if ! [[ "$PROFILE" =~ ^[a-z0-9-]+$ ]]; then
  echo "render-overrides: invalid PROFILE '$PROFILE' (use lowercase letters, digits and dashes)" >&2
  exit 1
fi

inputs=("$profile")
if [ "$PROFILE" != full ]; then
  if [ ! -f "$DOCKER_DIR/profile-$PROFILE.yml" ]; then
    available=full
    for f in "$DOCKER_DIR"/profile-*.yml; do
      [ -e "$f" ] || continue
      f="${f##*/profile-}"
      available+=" ${f%.yml}"
    done
    echo "render-overrides: no docker/profile-$PROFILE.yml. Profiles: $available" >&2
    exit 1
  fi
  inputs+=("$DOCKER_DIR/profile-$PROFILE.yml")
  echo "render-overrides: profile $PROFILE (docker/profile-$PROFILE.yml)"
fi
if [ -f "$user_overrides" ]; then
  inputs+=("$user_overrides")
  echo "render-overrides: merging docker/overrides.yml"
else
  echo "render-overrides: no docker/overrides.yml"
fi

merged="$(yq eval-all '. as $i ireduce ({}; . *+ $i)' "${inputs[@]}")"

# The merged file stays in the image, so a token must never be written to it.
# The delete is unconditional so that a failing check cannot leave it in.
if [ "$(yq 'has("github_api_token")' <<<"$merged")" = true ]; then
  echo "render-overrides: WARNING: removed github_api_token. Pass the token as the GITHUB_TOKEN build secret instead." >&2
fi
merged="$(yq 'del(.github_api_token)' <<<"$merged")"

# role_includes <role>: the include names of roles/<role>/tasks/main.yml,
# which are the names <role>_tasks_exclude uses.
# docker/test.sh (includes) parses the same list; keep both in sync.
role_includes() {
  yq -r '.[] | select(has("ansible.builtin.include_tasks")) | .["ansible.builtin.include_tasks"].file | sub("\.yml$"; "")' \
    "$PROVEASIO_HOME/ansible/roles/$1/tasks/main.yml"
}

# apply_includes <role>: take the names in <role>_tasks_include out of
# <role>_tasks_exclude, then drop <role>_tasks_include. An unknown name fails;
# a name that is not excluded is reported, so one docker/overrides.yml works
# with every profile.
apply_includes() {
  local inc="${1}_tasks_include" exc="${1}_tasks_exclude" kind valid names excluded name
  kind="$(KEY="$inc" yq '.[strenv(KEY)] | type' <<<"$merged")"
  case "$kind" in
    '!!null')
      merged="$(KEY="$inc" yq 'del(.[strenv(KEY)])' <<<"$merged")"
      return 0
      ;;
    '!!seq') ;;
    *) echo "render-overrides: $inc must be a list" >&2; exit 1 ;;
  esac
  if ! valid="$(role_includes "$1")" || [ -z "$valid" ]; then
    echo "render-overrides: cannot read the includes of roles/$1/tasks/main.yml" >&2
    exit 1
  fi
  names="$(KEY="$inc" yq -r '.[strenv(KEY)][]' <<<"$merged")"
  excluded="$(KEY="$exc" yq -r '(.[strenv(KEY)] // [])[]' <<<"$merged")"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if ! grep -qxF -- "$name" <<<"$valid"; then
      echo "render-overrides: $inc: unknown name '$name'. Valid names: $(tr '\n' ' ' <<<"$valid")" >&2
      exit 1
    fi
    if grep -qxF -- "$name" <<<"$excluded"; then
      echo "render-overrides: $inc: $name is no longer excluded"
    else
      echo "render-overrides: $inc: $name is not excluded, nothing to do"
    fi
  done <<<"$names"
  merged="$(INC="$inc" EXC="$exc" yq '.[strenv(EXC)] = ((.[strenv(EXC)] // []) - .[strenv(INC)]) | del(.[strenv(INC)])' <<<"$merged")"
}
apply_includes software
apply_includes config

# A directory that exists but cannot be listed is an error: falling back to
# the git config would build an image without the config the user asked for.
if [ -d "$NVIM_CONFIG_DIR" ]; then
  if ! nvim_entries="$(ls -A "$NVIM_CONFIG_DIR")"; then
    echo "render-overrides: cannot list $NVIM_CONFIG_DIR (the nvim-config build context)" >&2
    exit 1
  fi
  if [ -n "$nvim_entries" ]; then
    echo "render-overrides: using the local Neovim config from the nvim-config build context"
    merged="$(NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" yq '.neovim_config_source = "local" | .neovim_config_local_path = strenv(NVIM_CONFIG_DIR)' <<<"$merged")"
  fi
fi

mkdir -p "$(dirname "$target")"
printf '%s\n' "$merged" > "$target"

echo "render-overrides: effective overrides ($target):"
sed 's/^/  /' "$target"
