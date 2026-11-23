# ocs: per-project view, stricter search, tmux popup

## Intent

See the opencode sessions of one project, find sessions with search that does not match
scattered characters, and jump to a session that is already open in tmux instead of
starting a second TUI on it.

## Goals

- Stricter search: fzf `--exact`; space-separated terms are ANDed; `'term` falls back to
  fuzzy. The date column is not searchable.
- Project scope inside the list. `ocs` starts with all sessions. `CTRL+P` opens a project
  picker (session count, last used, an "all sessions" entry); picking reloads the list with
  that project's sessions and shows the project in the prompt. `CTRL+A` returns to all.
  `ocs -p` starts at the project picker, `ocs .` starts on the project of `$PWD`.
- Project = git repository: `project.worktree` for sessions with a real `project_id`,
  grouped by that path (merges duplicate project IDs with the same worktree). Sessions of
  the `global` project are grouped by their own `directory`.
- Open marker `● <session>:<window>` on sessions open in a tmux pane. Source: `ccmux show
  --json` (`nativeSessionId`, `tmuxPane`, `tmuxTarget`); fallback without ccmux: panes whose
  opencode process has `--session <id>` in its arguments.
- tmux binding Alt+Shift+O (`M-O`) and `Prefix O`: `ocs` in `display-popup -E -w 80% -h 75%`.

## Behaviour on pick

| Situation | Result |
|---|---|
| Session open in a tmux pane | Switch the client to that pane |
| Not open, other tmux windows run opencode in the same project | Second picker: "open in new window" first, then those windows, preview = `tmux capture-pane` |
| Not open, no such windows | Inside tmux: `new-window` in the session's directory, named after the project. Outside tmux: `exec opencode` in place, as today |

The popup always opens new sessions in a new window (a popup closes when its process exits).

`ocs --print` (Neovim `<Space>OS`): new session → print `<id>\t<dir>` as today; switch to an
existing pane → switch, print nothing (`polish.lua` ignores empty output). No Neovim change.

## Constraints

- Read-only on `opencode.db`; keep v1 (`session`/`message`/`part`) and v2 (`session_v2`/
  `session_message`) support. Both have `project_id`; join `project` for the worktree.
- zsh script, fzf 0.75, sqlite3, jq (ccmux path only; skip ccmux when jq or ccmux missing).
- Keys not used by tmux.conf, lazygit (`alt+a`, `alt+s`, `ctrl+a` are lazygit-only) or the
  Neovim config.

## Approaches considered

1. Switch project inside the list with fzf `reload` (chosen): one window, switching both
   ways, works in the Neovim float too.
2. Project picker first, then sessions: simpler, but switching means restarting.
3. Group the list by project: cheapest, but never shows only one project.

## Non-goals

- ccmux working/idle status in the list.
- Changes to the Neovim config.
- Deleting or archiving sessions.

## Files

- `ansible/roles/config/files/ocs`
- `ansible/roles/config/files/tmux.conf`
- `docker/test.sh` (existing exec check; extend only if a cheap flag test fits)
- `docs-web/docs/usage/20-terminal.md`, `docs-web/docs/usage/30-tmux.md`,
  `docs-web/docs/usage/80-ai.md`

## Left to the builder

- Exact fzf binding mechanics (`reload`, `transform-prompt`, state passing between the
  project picker and the session list).
- Window naming for new windows, column widths, colours of the marker.
