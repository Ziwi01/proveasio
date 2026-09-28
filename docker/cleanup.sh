#!/usr/bin/env bash
# Remove build leftovers from a Proveasio image.
#
# docker/provision.sh runs it at the end of the playbook RUN step. It has to run
# in that same step: files deleted in a later layer still take space in the
# image. It never deletes a path the roles use to detect an existing install
# (for example ~/.local/opt/<tool>-<version>, ~/.gvm/environments/<version>,
# ~/.local/opt/nvm/nvm.sh), so the playbook can still be re-run in a container.
#
# It deletes package caches, apt lists and almost everything in /tmp, so it
# refuses to run unless PROVEASIO_IMAGE_BUILD=1. docker/provision.sh sets it.
# Never set it on a workstation.
#
# CLEANUP_SYSTEM=0 skips the parts that need sudo (apt lists, /tmp). It is used
# to test the script outside an image.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "cleanup.sh: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi

CLEANUP_SYSTEM="${CLEANUP_SYSTEM:-1}"
total_kib=0

log_size() {
  total_kib=$((total_kib + $1))
  printf 'cleanup: %8s KiB  %s\n' "$1" "$2"
}

# remove_paths [sudo] <path>...: delete each existing path, logging its size.
remove_paths() {
  local sudo=() path
  if [ "${1:-}" = sudo ]; then sudo=(sudo); shift; fi
  for path in "$@"; do
    [ -e "$path" ] || continue
    log_size "$("${sudo[@]}" du -sk "$path" | cut -f1)" "$path"
    "${sudo[@]}" rm -rf -- "$path"
  done
}

# remove_contents [sudo] <dir>...: empty directories that their tool expects to exist.
remove_contents() {
  local sudo=() dir
  if [ "${1:-}" = sudo ]; then sudo=(sudo); shift; fi
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    log_size "$("${sudo[@]}" du -sk "$dir" | cut -f1)" "$dir/*"
    "${sudo[@]}" find "$dir" -mindepth 1 -delete
  done
}

# Package manager caches and logs.
remove_paths "$HOME/.cache/pip" "$HOME/.cache/uv" "$HOME/.cache/go-build" \
  "$HOME/.npm/_cacache" "$HOME/.npm/_logs" "$HOME/.cache/gem" "$HOME/.cargo/registry/cache"

# Go module cache from Mason's `go install` in the build. GOPATH is not set
# there, so Go uses ~/go. Go makes the cache read-only, so rm needs write
# permission first. ~/go is removed only when nothing else is left in it.
if [ -d "$HOME/go/pkg/mod" ]; then chmod -R u+w "$HOME/go/pkg/mod"; fi
remove_paths "$HOME/go/pkg/mod" "$HOME/go/pkg/sumdb"
rmdir "$HOME/go/pkg" "$HOME/go" 2>/dev/null || true

# rvm: Ruby sources and build trees, downloaded archives.
remove_contents "$HOME/.rvm/src" "$HOME/.rvm/archives"

# Rust offline documentation (`rustup doc`). The toolchain stays.
if [ -x "$HOME/.cargo/bin/rustup" ]; then
  docs_kib="$(du -sck "$HOME"/.rustup/toolchains/*/share/doc 2>/dev/null | tail -n 1 | cut -f1 || true)"
  if "$HOME/.cargo/bin/rustup" component remove rust-docs >/dev/null 2>&1; then
    log_size "${docs_kib:-0}" "rust-docs component"
  fi
fi

# AWS CLI installer copy. awscli.yml downloads and unpacks it on every run and
# checks ~/.local/opt/aws-cli/v2/current instead.
remove_paths "$HOME/.local/opt/awscli-install" "$HOME/.local/opt/awscliv2.zip"

# gvm download archive. gvm.yml checks ~/.gvm and ~/.gvm/environments/<version>.
remove_contents "$HOME/.gvm/archive"

# SDKMAN download archives and temporary files.
remove_contents "$HOME/.sdkman/archives" "$HOME/.sdkman/tmp"

if [ "$CLEANUP_SYSTEM" = 1 ]; then
  sudo apt-get clean
  remove_contents sudo /var/lib/apt/lists
  # /tmp, except the bind mounts of the running build step.
  while IFS= read -r -d '' path; do
    remove_paths sudo "$path"
  done < <(find /tmp -mindepth 1 -maxdepth 1 ! -name proveasio-docker ! -name nvim-config -print0)
fi

printf 'cleanup: %d MiB removed in total\n' $((total_kib / 1024))
