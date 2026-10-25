#!/usr/bin/env bash
# hunk-popup - hunk (https://github.com/modem-dev/hunk) in a hidden tmux session,
# shown in a popup over 90% of the screen. Every tmux session gets one hunk
# window, in a session named hunk-<session>. Hiding the popup keeps hunk (and
# its notes) alive; closing it quits hunk.
#
#   hunk-popup toggle <session> <dir> <client>  tmux.conf keys: start hunk if needed, show it
#   hunk-popup open [--force] [dir] [ref]       start hunk without showing it (for agents). With
#                                               <ref> it shows the changes since <ref>, committed
#                                               or not. In another dir or with another ref it
#                                               restarts hunk; it refuses while the user has notes
#                                               there unless --force is given.
#   hunk-popup notes [session]                  print the user's notes as JSON: from the running
#                                               hunk, else from the newest saved file
#   hunk-popup close [session]                  quit hunk
#   hunk-popup strip-resurrect <file>           tmux-resurrect hook: do not save hunk-* sessions
#
# Before close or a restart quits hunk, the user's notes are saved to
# ${XDG_STATE_HOME:-~/.local/state}/hunk-popup/<hunk session>-<time>.json.
# Quitting with q inside hunk saves nothing.
#
# open, notes and close default to the tmux session of the calling pane ($TMUX_PANE).
# The popup is never opened from an agent: display-popup blocks until it closes.
set -euo pipefail

prefix=hunk-
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hunk-popup"

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

# hunk_ref <name>: the ref <name> was started with, empty for the working tree.
hunk_ref() { tmux show-options -qv -t "=$1:" @hunk_ref 2>/dev/null || true; }

# hunk_id <name>: the id the hunk daemon gives the hunk running in <name>.
hunk_id() {
  local pane
  pane="$(tmux display-message -p -t "=$1:" '#{pane_id}')"
  hunk session list --json 2>/dev/null | jq -r --arg p "$pane" \
    '.sessions[] | select(any(.terminal.locations[]; .paneId == $p)) | .sessionId' | head -n 1
}

# user_notes <name>: the user's notes in the hunk running in <name>, as
# {"comments": [...]}; empty when hunk is not registered with the daemon.
user_notes() {
  local id
  id="$(hunk_id "$1")"
  [ -n "$id" ] || return 0
  hunk session comment list "$id" --type user --json
}

# save_notes <name>: save the user's notes before <name> is killed. Prints the file.
save_notes() {
  local notes file
  notes="$(user_notes "$1")"
  [ -n "$notes" ] && [ "$(jq '.comments | length' <<<"$notes")" -gt 0 ] || return 0
  mkdir -p "$state_dir"
  file="$state_dir/$1-$(date +%Y%m%dT%H%M%S).json"
  jq --arg dir "$(tmux display-message -p -t "=$1:" '#{pane_current_path}')" \
    --arg ref "$(hunk_ref "$1")" --arg saved "$(date -Iseconds)" \
    '{dir: $dir, ref: $ref, saved: $saved, comments: .comments}' <<<"$notes" >"$file"
  echo "Saved the user's notes to $file"
}

# start <name> <dir> [ref]: start `hunk diff [ref] --watch` in <dir> unless <name> runs.
# On failure (not a repository, ...) the message stays until Enter.
start() {
  running "$1" && return 0
  command -v hunk >/dev/null || { echo "hunk-popup: hunk is not installed" >&2; return 1; }
  local diff="hunk diff --watch"
  [ -n "${3:-}" ] && diff="hunk diff $(printf '%q' "$3") --watch"
  tmux new-session -d -s "$1" -c "$2" \
    "$diff || { echo; echo 'hunk exited. Press Enter to close.'; read -r _; }"
  tmux set-option -t "=$1:" status off
  tmux set-option -t "=$1:" @hunk_ref "${3:-}"
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
    [ $# -le 2 ] || die "usage: hunk-popup open [--force] [dir] [ref]"
    dir="$(cd "${1:-$PWD}" && pwd)" || die "no such directory: ${1:-}"
    ref="${2:-}"
    # A bad ref would only show up as an error inside the hidden window.
    if [ -n "$ref" ] && git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$dir" rev-parse --verify --quiet "$ref^{commit}" >/dev/null ||
        die "not a commit in $dir: $ref"
    fi
    name="$(hunk_name "$(pane_session)")"
    shows="$dir${ref:+ (changes since $ref)}"
    if running "$name"; then
      path="$(tmux display-message -p -t "=$name:" '#{pane_current_path}')"
      old_ref="$(hunk_ref "$name")"
      if [ "$path" = "$dir" ] && [ "$old_ref" = "$ref" ]; then
        echo "hunk is already running in $shows (session $name)."
        echo "The user shows it with Alt+h (or <prefix> H)."
        exit 0
      fi
      # hunk cannot reload a source outside the root it started in, so another
      # directory or ref means a restart, which quits hunk with the user's notes.
      if [ -z "$force" ]; then
        notes="$(user_notes "$name")"
        count=0
        [ -n "$notes" ] && count="$(jq '.comments | length' <<<"$notes")"
        if [ "$count" -gt 0 ]; then
          die "hunk in $path has $count user note(s) that a restart would discard. Read them first (hunk-popup notes), then run: hunk-popup open --force $(printf '%q' "$dir")${ref:+ $(printf '%q' "$ref")}"
        fi
      fi
      save_notes "$name"
      tmux kill-session -t "=$name"
      start "$name" "$dir" "$ref"
      echo "hunk restarted in $shows (was $path${old_ref:+ since $old_ref}, session $name)."
    else
      start "$name" "$dir" "$ref"
      echo "hunk started in $shows (session $name)."
    fi
    echo "The user shows it with Alt+h (or <prefix> H)."
    ;;
  notes)
    name="$(hunk_name "${1:-$(pane_session)}")"
    if running "$name"; then
      notes="$(user_notes "$name")"
      [ -n "$notes" ] || die "hunk runs in $name but is not registered with the hunk daemon"
      jq --arg dir "$(tmux display-message -p -t "=$name:" '#{pane_current_path}')" \
        --arg ref "$(hunk_ref "$name")" \
        '{source: "live", dir: $dir, ref: $ref, comments: .comments}' <<<"$notes"
    else
      file=""
      for f in "$state_dir/$name"-*.json; do
        [ -f "$f" ] && { [ -z "$file" ] || [ "$f" -nt "$file" ]; } && file="$f"
      done
      [ -n "$file" ] || die "no hunk running in $name and no saved notes in $state_dir"
      jq --arg file "$file" '{source: $file} + .' "$file"
    fi
    ;;
  close)
    name="$(hunk_name "${1:-$(pane_session)}")"
    if running "$name"; then
      save_notes "$name"
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
