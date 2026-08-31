#!/bin/sh
# Rename auto-numbered tmux sessions to "Default", then "Default-1", "-2", ...
# Invoked from the `session-created` hook in tmux.conf with the new session's
# name as $1. tmux gives unnamed sessions a purely-numeric name (0, 1, 2, ...);
# we only touch those, leaving user-named sessions (e.g. via `tmux new -s foo`
# or tmuxp) untouched. tmux commands target the current server via $TMUX.
name="$1"

# Only act on tmux's auto-assigned numeric names.
case "$name" in
  '' | *[!0-9]*) exit 0 ;;
esac

if tmux has-session -t="Default" 2>/dev/null; then
  i=1
  while tmux has-session -t="Default-$i" 2>/dev/null; do
    i=$((i + 1))
  done
  tmux rename-session -t "$name" "Default-$i"
else
  tmux rename-session -t "$name" "Default"
fi
