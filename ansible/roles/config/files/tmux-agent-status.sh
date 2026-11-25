#!/usr/bin/env bash
# Colour a tmux window in the status line when an AI agent in it finished
# (green) or waits for input (yellow). The state is the window option
# @agent_state; the session-window-changed hook in ~/.tmux.conf unsets it when
# the window is selected.
#
#   tmux-agent-status format  Patch tmux2k's window-status-format to read
#                             @agent_state, and both window formats to show
#                             the [OC] prefix.
#                             Run after tpm; safe to run again.
#   tmux-agent-status mark    Set @agent_state from the ccmux notification
#                             (CCMUX_EVENT, CCMUX_PANE); see
#                             notifications.command in ~/.config/ccmux/ccmux.json.
set -e -o pipefail

tmux_cmd() {
  if [ -n "${CCMUX_TMUX_SOCKET:-}" ]; then
    tmux -S "$CCMUX_TMUX_SOCKET" "$@"
  else
    tmux "$@"
  fi
}

case "${1:-}" in
  format)
    # The colours tmux2k uses for windows that are not selected (onedark:
    # @agent-status-bg is its bg_alt, @agent-status-fg its white). Another
    # theme leaves the format unchanged.
    bg="$(tmux_cmd show -gv @agent-status-bg)"
    fg="$(tmux_cmd show -gv @agent-status-fg)"
    format="$(tmux_cmd show -gwv window-status-format)"
    case "$format" in
      *@agent-status-*) ;;
      *)
        bg_format='#{E:@agent-status-bg-format}'
        fg_format='#{E:@agent-status-fg-format}'
        format="${format//"$bg"/"$bg_format"}"
        format="${format//"$fg"/"$fg_format"}"
        ;;
    esac
    tmux_cmd set -gw window-status-format "$format"
    # The [OC] prefix (@oc-prefix in ~/.tmux.conf) goes in front of the window
    # name, in the selected window's format as well.
    for option in window-status-format window-status-current-format; do
      format="$(tmux_cmd show -gwv "$option")"
      case "$format" in
        *@oc-prefix*) continue ;;
      esac
      tmux_cmd set -gw "$option" "${format//'#I:#W'/'#I:#{E:@oc-prefix}#W'}"
    done
    ;;
  mark)
    case "${CCMUX_EVENT:-}" in
      waiting | finished) ;;
      *) exit 0 ;;
    esac
    [ -n "${CCMUX_PANE:-}" ] || exit 0
    read -r selected state < <(tmux_cmd display -p -t "$CCMUX_PANE" \
      '#{&&:#{window_active},#{session_attached}} #{@agent_state}')
    # The selected window of an attached session is already in view.
    [ "$selected" = 1 ] && exit 0
    # Waiting needs you more than finished: keep it when another pane in the
    # window finishes.
    [ "$CCMUX_EVENT" = finished ] && [ "$state" = waiting ] && exit 0
    tmux_cmd set -w -t "$CCMUX_PANE" @agent_state "$CCMUX_EVENT"
    ;;
  *)
    echo "Usage: ${0##*/} format|mark" >&2
    exit 2
    ;;
esac
