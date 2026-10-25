#!/usr/bin/env bash
# hunk-popup - hunk (https://github.com/modem-dev/hunk) in a hidden tmux session,
# shown in a popup over 90% of the screen. Every tmux session gets one hunk
# window, in a session named hunk-<session>. Hiding the popup keeps hunk (and
# its notes) alive; closing it quits hunk.
#
#   hunk-popup toggle <session> <dir> <client>  tmux.conf keys: start hunk if needed, show it
#   hunk-popup open [--force] [dir]             start hunk without showing it (for agents). In
#                                               another dir it restarts hunk, which discards the
#                                               notes; it refuses while the user has notes there
#                                               unless --force is given.
#   hunk-popup close [session]                  quit hunk
#   hunk-popup strip-resurrect <file>           tmux-resurrect hook: do not save hunk-* sessions
#
# open and close default to the tmux session of the calling pane ($TMUX_PANE).
# The popup is never opened from an agent: display-popup blocks until it closes.
set -euo pipefail

prefix=hunk-

die() { echo "hunk-popup: $*" >&2; exit 1; }

# The session of the pane this runs in, for open/close called from a shell.
pane_session() {
  [ -n "${TMUX:-}" ] || die "not inside tmux"
  tmux display-message -p ${TMUX_PANE:+-t "$TMUX_PANE"} '#{session_name}'
}

# hunk_name <session>: the hunk session of <session>; a hunk session maps to itself.
hunk_name() {
  case "$1" in
    "$prefix"*) printf '%s' "$1" ;;
    *) printf '%s%s' "$prefix" "$1" ;;
  esac
}

running() { tmux has-session -t "=$1" 2>/dev/null; }

# start <name> <dir>: start `hunk diff --watch` in <dir> unless <name> runs.
# On failure (not a repository, ...) the message stays until Enter.
start() {
  running "$1" && return 0
  command -v hunk >/dev/null || { echo "hunk-popup: hunk is not installed" >&2; return 1; }
  tmux new-session -d -s "$1" -c "$2" \
    "hunk diff --watch || { echo; echo 'hunk exited. Press Enter to close.'; read -r _; }"
  tmux set-option -t "=$1:" status off
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  toggle)
    [ $# -eq 3 ] || die "usage: hunk-popup toggle <session> <dir> <client>"
    name="$(hunk_name "$1")"
    if ! err="$(start "$name" "$2" 2>&1)"; then
      tmux display-message -c "$3" "${err:-hunk-popup: cannot start hunk}"
      exit 1
    fi
    socket="$(tmux display-message -p '#{socket_path}')"
    # The popup attaches a second client to the hunk session. Hiding detaches
    # that client (tmux.conf), which ends the attach and closes the popup.
    tmux display-popup -c "$3" -E -w 90% -h 90% -T " hunk: $2 " \
      "env -u TMUX tmux -S '$socket' attach-session -t '=$name'"
    ;;
  open)
    force=""
    if [ "${1:-}" = --force ]; then force=1; shift; fi
    dir="$(cd "${1:-$PWD}" && pwd)" || die "no such directory: ${1:-}"
    name="$(hunk_name "$(pane_session)")"
    if running "$name"; then
      path="$(tmux display-message -p -t "=$name:" '#{pane_current_path}')"
      if [ "$path" = "$dir" ]; then
        echo "hunk is already running in $dir (session $name)."
        echo "The user shows it with Alt+h (or <prefix> H)."
        exit 0
      fi
      # hunk cannot reload a source outside the root it started in, so a
      # different directory means a restart, which discards the user's notes.
      if [ -z "$force" ]; then
        pane="$(tmux display-message -p -t "=$name:" '#{pane_id}')"
        id="$(hunk session list --json 2>/dev/null | jq -r --arg p "$pane" \
          '.sessions[] | select(any(.terminal.locations[]; .paneId == $p)) | .sessionId' | head -n 1)"
        notes=0
        if [ -n "$id" ]; then
          notes="$(hunk session comment list "$id" --type user --json | jq '.comments | length')"
        fi
        if [ "$notes" -gt 0 ]; then
          die "hunk in $path has $notes user note(s) that a restart would discard. Read them first (hunk session comment list $id --type user), then run: hunk-popup open --force '$dir'"
        fi
      fi
      tmux kill-session -t "=$name"
      start "$name" "$dir"
      echo "hunk restarted in $dir (was $path, session $name)."
    else
      start "$name" "$dir"
      echo "hunk started in $dir (session $name)."
    fi
    echo "The user shows it with Alt+h (or <prefix> H)."
    ;;
  close)
    name="$(hunk_name "${1:-$(pane_session)}")"
    if running "$name"; then
      tmux kill-session -t "=$name"
      echo "hunk closed ($name)."
    else
      echo "No hunk window ($name)."
    fi
    ;;
  strip-resurrect)
    [ $# -eq 1 ] && [ -f "$1" ] || die "usage: hunk-popup strip-resurrect <file>"
    sed -i -E "/^(pane|window)\t${prefix}/d" "$1"
    ;;
  *)
    sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
