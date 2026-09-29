#!/bin/bash
# Entrypoint of the Proveasio image: warn when bind-mounted files belong to
# another UID than the image user, then run the command.
#
# The UID is fixed when the image is built (USER_UID/USER_GID). Changing it at
# start would need a chown of the whole home directory, which copies every file
# into the container layer, so this only points at the rebuild.
# Set PROVEASIO_NO_UID_CHECK=1 to turn the warning off.

check_owner() {
  local path="$1" owner group
  [ -e "$path" ] || return 0
  owner="$(stat -c %u "$path" 2>/dev/null)" || return 0
  group="$(stat -c %g "$path" 2>/dev/null)" || return 0
  # Root-owned paths (for example a directory Docker created) are not a UID mismatch.
  if [ "$owner" = "$(id -u)" ] || [ "$owner" = 0 ]; then return 0; fi
  {
    echo "proveasio: $path belongs to UID $owner (GID $group), but the user $(id -un) in this image is UID $(id -u) (GID $(id -g))."
    echo "proveasio: You may not be able to read or write files there. Build the image with your IDs:"
    echo "proveasio:   USER_UID=$owner USER_GID=$group docker buildx bake"
    echo "proveasio: See https://ziwi01.github.io/proveasio/next/main/docker/run#user-id (PROVEASIO_NO_UID_CHECK=1 hides this)."
  } >&2
}

if [ "${PROVEASIO_NO_UID_CHECK:-}" != 1 ]; then
  if [ "$PWD" != "$HOME" ] && [ "$PWD" != / ]; then check_owner "$PWD"; fi
  check_owner "$HOME/.ssh"
fi

exec "$@"
