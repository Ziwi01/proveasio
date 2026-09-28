#!/usr/bin/env bash
# Build the effective ansible/vars/overrides.yml for a Docker image build.
#
# Runs in the playbook RUN step of docker/Dockerfile. Inputs are the committed
# docker/profile.yml and the optional, gitignored docker/overrides.yml (both
# bind-mounted at DOCKER_DIR), plus the nvim-config build context at
# NVIM_CONFIG_DIR. Maps merge recursively and lists are appended. The roles
# then merge github_packages, pip_packages and docker_apt_packages with their
# defaults per key; every other variable replaces the role default.
#
# It overwrites ansible/vars/overrides.yml, so it refuses to run unless
# PROVEASIO_IMAGE_BUILD=1. docker/Dockerfile sets it for this one command.
# Never set it on a workstation: there it would replace your own overrides.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "render-overrides: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"

profile="$DOCKER_DIR/profile.yml"
user_overrides="$DOCKER_DIR/overrides.yml"
target="$PROVEASIO_HOME/ansible/vars/overrides.yml"
build_info="$PROVEASIO_HOME/docker/build-info.env"

if [ ! -f "$profile" ]; then
  echo "render-overrides: missing $profile" >&2
  exit 1
fi

inputs=("$profile")
if [ -f "$user_overrides" ]; then
  inputs+=("$user_overrides")
  echo "render-overrides: merging docker/overrides.yml into the profile"
else
  echo "render-overrides: no docker/overrides.yml, using docker/profile.yml only"
fi

merged="$(yq eval-all '. as $i ireduce ({}; . *+ $i)' "${inputs[@]}")"

# The merged file stays in the image, so a token must never be written to it.
# The delete is unconditional so that a failing check cannot leave it in.
if [ "$(yq 'has("github_api_token")' <<<"$merged")" = true ]; then
  echo "render-overrides: WARNING: removed github_api_token. Pass the token as the GITHUB_TOKEN build secret instead." >&2
fi
merged="$(yq 'del(.github_api_token)' <<<"$merged")"

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

mkdir -p "$(dirname "$target")" "$(dirname "$build_info")"
printf '%s\n' "$merged" > "$target"

{
  printf 'ANSIBLE_TAGS=%q\n' "${ANSIBLE_TAGS:-}"
  printf 'ANSIBLE_SKIP_TAGS=%q\n' "${ANSIBLE_SKIP_TAGS:-}"
  printf 'REFRESH=%q\n' "${REFRESH:-}"
  printf 'BUILD_DATE=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$build_info"

echo "render-overrides: effective overrides ($target):"
sed 's/^/  /' "$target"
