# ocs projects, exact search and tmux popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ocs` gets exact search, a per-project view switchable inside the list, tmux awareness (marker, switch to an open session, pick among windows of the same project), and a tmux popup binding.

**Architecture:** Everything stays in the zsh script `ansible/roles/config/files/ocs`. It gains hidden subcommands that print fzf rows (`--_sessions`, `--_projects`, `--_preview`, `--_enter`) so fzf `reload`/`transform` can call the script itself. One fzf instance has two modes, told apart by the prompt. After the pick, a dispatcher switches, offers a window picker, or starts opencode. tmux.conf gets two bindings; docs get updated.

**Tech Stack:** zsh, fzf 0.75, sqlite3, jq, tmux 3.x, ccmux (optional), Docusaurus.

**Spec:** `docs/superpowers/specs/2026-11-23-ocs-projects-tmux-design.md`

## Global Constraints

- `opencode.db` is read-only. v2 tables (`session_v2`, `session_message`) when `session_v2` exists, else v1 (`session`, `message`, `part`). Both have `project_id`; `project.worktree` gives the repo path.
- Project key: `case when s.project_id = 'global' or p.worktree is null then s.directory else p.worktree end`. Archived sessions (`time_archived is not null`) stay hidden.
- fzf: `--exact`; date column not in the search scope.
- Keys in the list: `CTRL+P` project picker, `CTRL+A` all sessions, `CTRL+/` preview (kept), `ESC` abort (kept).
- CLI: `ocs`, `ocs -p`, `ocs .`, `ocs --print` (combinable with `-p` / `.`). Unknown args → usage on stderr, exit 2.
- Marker: `●` plus `<session>:<window>` of the first pane. Sessions not open get blank padding of the same width.
- Pane map source: `ccmux show --json` (`nativeSessionId`, `tmuxPane`); fallback without ccmux or jq: processes on each pane's tty whose args contain `opencode` and `--session <id>`. Entries whose pane does not exist in the current tmux server are dropped.
- Test hooks (env): `OCS_DB` (default `~/.local/share/opencode/opencode.db`), `OCS_CCMUX_JSON` (file read instead of running ccmux; `/dev/null` disables ccmux).
- tmux bindings: `bind-key -n M-O` and `bind-key O`, both `display-popup -E -w 80% -h 75% -d "#{pane_current_path}" ocs`.
- Keep `emulate -L zsh` and the existing style of the script (`print -u2 "ocs: ..."` errors, `local` declarations).
- Do not commit. The user commits.

## Test harness (all tasks)

No test runner exists in this repo. Checks run by hand against a fixture DB and a throwaway tmux server, never the user's DB or tmux server.

```bash
T=/tmp/opencode/ocs-test; mkdir -p $T/bin $T/repo/sub $T/loose $T/other
export OCS_DB=$T/db OCS_CCMUX_JSON=/dev/null
OCS=~/projects/proveasio/ansible/roles/config/files/ocs
```

Fixture DB (`sqlite3 $T/db`): tables `project(id, worktree, ...)`, `session_v2(id, project_id, directory, title, time_updated, time_archived)`, `session_message(session_id, type, seq, data)` with only the columns `ocs` reads. Rows:

| session | project_id | directory | title | note |
|---|---|---|---|---|
| ses_a | p1 | `$T/repo` | `Fix abc parser` | newest |
| ses_b | p1 | `$T/repo/sub` | `a big cat` | |
| ses_c | p2 (worktree `$T/repo` too) | `$T/repo` | `dup id same tree` | |
| ses_d | global | `$T/loose` | `tab<TAB>title` | title contains a tab |
| ses_e | global | `$T/other` | `x` | archived |
| ses_f | p3 (worktree `$T/gone`) | `$T/gone` | `gone dir` | directory does not exist |

A v1 fixture (`$T/db1`, tables `session`, `message`, `part`, `project`) with ses_a and ses_b only.

Throwaway tmux: `tmux -L ocs-test -f /dev/null new -d -s t -c $T/repo`, then `export TMUX=$(tmux -L ocs-test display -p '#{socket_path}'),0,0`. Fake opencode `$T/bin/opencode` (`#!/bin/sh` + `exec sleep 100000`), started in panes as `$T/bin/opencode $T/repo --session ses_b`. Teardown: `tmux -L ocs-test kill-server; rm -rf /tmp/opencode/ocs-test`.

## Review Focus

1. A title or path containing a tab, a quote, `$` or a space must not shift fields or break a `reload(...)`: fzf placeholders (`{n}`, `{3}`) carry values, never string interpolation into the bound command. → Task 1 row c, Task 2 row d.
2. ccmux reports panes of a stale or different tmux server (`%3` may exist in another server): drop entries whose pane is not in `tmux list-panes -a`. → Task 3 row c.
3. `ocs` outside tmux while a tmux server runs the picked session: the marker shows, but the pick runs opencode in place (cannot switch a client that is not attached). → Task 3 row f.
4. Picked session's directory was deleted: error `ocs: directory gone: <dir>`, exit 1, no new window. → Task 3 row g.
5. `ocs .` from a directory with no sessions in any project: start on all sessions, with no error. → Task 2 row f.

---

### Task 1: Data layer and hidden subcommands

**Files:**
- Modify: `ansible/roles/config/files/ocs` (header comment, arg parsing, SQL)

**Interfaces:**
- Produces:
  - `ocs --_sessions [<project_key>]`: rows `date \t marker \t path \t title \t S \t <sid> \t <dir> \t <project_key>` (ANSI colours on fields 1-4), newest first; without a key, all sessions. Marker comes from Task 3; until then it is blank padding.
  - `ocs --_projects`: first row `ALL \t \t (all sessions) \t <total count> \t P \t \t \t`, then one row per project key: `last-used date \t marker \t ~path \t <n> sessions \t P \t \t \t <project_key>`, ordered by last used desc.
  - `ocs --_preview S|P <sid> <project_key>`: S → first user message (existing queries); P → titles of that project's newest 20 sessions.
  - `db`, `sessions` table name and the project-key SQL expression as shared zsh variables.

- [ ] **Step 1: Build the fixture DBs from the harness.**
- [ ] **Step 2: Run the checks below against the current script; expect a–d to fail (unknown option).**

| row | command | expected |
|---|---|---|
| a | `$OCS --_sessions \| cut -f6` | `ses_a ses_b ses_c ses_d ses_f` (one per line, newest first); no `ses_e` |
| b | `$OCS --_sessions $T/repo \| cut -f6` | `ses_a ses_b ses_c` (p1 and p2 merged by worktree, `sub` included) |
| c | `$OCS --_sessions \| awk -F'\t' '{print NF}' \| sort -u` | `8` (tab in ses_d title replaced by a space) |
| d | `$OCS --_projects \| cut -f8` | empty (ALL), `$T/repo`, `$T/loose`, `$T/gone` in last-used order; `$T/repo` row says `3 sessions` |
| e | `OCS_DB=$T/db1 $OCS --_sessions \| cut -f6` | `ses_a ses_b` |
| f | `$OCS --_preview P '' $T/repo` | the three titles |
| g | `$OCS --bogus; echo $?` | usage on stderr, `2` |

- [ ] **Step 3: Implement.** `OCS_DB` defaults to the current path. SQL replaces `char(9)` and `char(31)` in title and directory with a space. Path display keeps `~` replacement and left truncation to width 42.
- [ ] **Step 4: Run the checks; all pass.**

### Task 2: Two-mode fzf UI and stricter search

**Files:**
- Modify: `ansible/roles/config/files/ocs` (fzf invocation, `-p`, `.`)

**Interfaces:**
- Consumes: Task 1 subcommands.
- Produces: `ocs --_enter <kind> <project_key>`: prints fzf actions. Kind `P` → `reload(ocs --_sessions <key>)+change-prompt(  <~key>  )+clear-query+first` (ALL row → no key, prompt `  session  `). Kind `S` → `accept`. The script calls itself through `$0` resolved to an absolute path (`${0:A}`), quoted for fzf with `${(q)}`.
- fzf options: `--exact --delimiter='\t' --with-nth=1,2,3,4 --nth=2,3,4` (verify that `--nth` indexes are interpreted against the original fields in fzf 0.75 with `fzf --filter`, and adjust so the date is out of scope). Bindings: `enter:transform:<self> --_enter {5} {8}`, `ctrl-p:reload(<self> --_projects)+change-prompt(  project  )+clear-query`, `ctrl-a:reload(<self> --_sessions)+change-prompt(  session  )+clear-query`, preview `<self> --_preview {5} {6} {8}`.
- Start state: `-p` → load `--_projects` with the project prompt; `.` → longest project key that is a prefix of `$PWD:A` (or equal), else all sessions.

- [ ] **Step 1: Run the checks below; expect failures.**

| row | command | expected |
|---|---|---|
| a | `$OCS --_sessions \| fzf --filter abc --exact --delimiter='\t' --with-nth=1,2,3,4 --nth=<chosen> \| cut -f6` | `ses_a` only (not `ses_b` "a big cat") |
| b | same with filter `2026` | no rows (date not searched; fixture titles/paths have no `2026`) |
| c | same with filter `abc fix` | `ses_a` |
| d | `$OCS --_enter P "$T/it's \$x"` | one line, `reload(...)` with the key quoted so fzf passes it as one argument |
| e | `$OCS --_enter S ''` | `accept` |
| f | `cd /tmp && $OCS .` (interactive) | opens on all sessions, no error |
| g | interactive in the fixture: `CTRL+P`, pick `$T/repo`, `CTRL+P`, pick `(all sessions)`, `CTRL+A`, `-p`, `cd $T/repo/sub && $OCS .` | lists and prompts switch as described; `ocs .` in `sub` shows the `$T/repo` project |

- [ ] **Step 2: Implement.**
- [ ] **Step 3: Run the checks; all pass.**

### Task 3: tmux awareness and pick dispatch

**Files:**
- Modify: `ansible/roles/config/files/ocs`

**Interfaces:**
- Consumes: rows from Task 1 (`<sid>`, `<dir>`, `<project_key>` in fields 6-8).
- Produces:
  - `open_panes`: prints `sid \t pane_id \t session:window \t pane_current_path \t pane_title` for live panes only. Built from `OCS_CCMUX_JSON` or `ccmux show --json` (with `jq`), else the process fallback. Empty when no tmux server.
  - Marker filled in `--_sessions` from `open_panes`.
  - Dispatch after the pick (`sid`, `dir`, `key`):
    1. `[[ -d $dir ]]` else `ocs: directory gone: <dir>`, exit 1.
    2. Inside tmux (`$TMUX` set) and sid open → `switch-client -t <pane>`, `select-window`, `select-pane`; `--print` prints nothing; exit 0.
    3. Inside tmux, sid not open, panes whose path is the key or below it → window picker (fzf, `--exact`): first row `+ open in new window`, then `session:window  title  ~path`; preview `tmux capture-pane -ep -t <pane>`; ESC → exit 130 with nothing done. Picking a window → as in 2.
    4. Otherwise: `--print` → print `sid\tdir`; inside tmux → `tmux new-window -c <dir> -n <basename of key> -- opencode <dir> --session <sid>`; outside tmux → `cd` + `exec opencode` (as today).

- [ ] **Step 1: Start the throwaway tmux server; open pane 1 with fake opencode for `ses_b`, pane 2 with fake opencode for a session id not in the DB (`ses_zz`) in `$T/repo`.**
- [ ] **Step 2: Run the checks below; expect failures.**

| row | command | expected |
|---|---|---|
| a | `$OCS --_sessions \| grep ses_b \| cut -f2` (strip ANSI) | `● t:<window of pane 1>` |
| b | `OCS_CCMUX_JSON=$T/ccmux.json $OCS --_sessions \| grep ses_a \| cut -f2` with a JSON listing `ses_a` on pane 2's id | marker on ses_a |
| c | same with JSON listing `ses_a` on pane `%999` | no marker |
| d | pick ses_b (inside the test tmux, e.g. from a third pane) | client switches to pane 1; no new window (`tmux list-windows` count unchanged) |
| e | pick ses_a | window picker shows `+ open in new window`, pane 1 and pane 2 windows; picking `+` creates a window named `repo` running `opencode $T/repo --session ses_a` (`PATH=$T/bin:$PATH`) |
| f | `env -u TMUX $OCS --print`, pick ses_b | prints `ses_b\t$T/repo/sub` (no switch outside tmux) |
| g | pick ses_f | `ocs: directory gone: $T/gone`, exit 1, window count unchanged |
| h | `$OCS --print` inside tmux, pick ses_b | switches, stdout empty |

- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the checks; all pass. Tear down the tmux server.**

### Task 4: tmux binding, docs, image check, gates

**Files:**
- Modify: `ansible/roles/config/files/tmux.conf` (next to the ccmux block, ~line 133)
- Modify: `docs-web/docs/usage/20-terminal.md` (section "Browse opencode sessions with `ocs`": exact search, projects, keys, marker, pick behaviour, update the example block)
- Modify: `docs-web/docs/usage/30-tmux.md` (new bullet list entry: `<Alt><Shift>o` or `<C-b>O`)
- Modify: `docs-web/docs/usage/80-ai.md` (`ocs` paragraph and the `<Space>OS` row: open sessions switch instead of opening a second pane)
- Modify: `docker/test.sh` `check_config_zsh` (add `OCS_DB=/nonexistent ocs --_sessions` → expect exit 1 and `no db` message, proving the script runs under the image's zsh)

**Interfaces:**
- Consumes: CLI and keys from Tasks 2-3.

- [ ] **Step 1: Add the bindings with a comment in the style of the ccmux block.**
- [ ] **Step 2: `tmux -L ocs-test -f ansible/roles/config/files/tmux.conf start \; list-keys | grep -E 'M-O| O '`** → both bindings listed (plugins may warn; the bindings must be present).
- [ ] **Step 3: Update the docs pages.**
- [ ] **Step 4: Gates.**
  - `cd ansible && ansible-lint` → `Passed: 0 failure(s)`
  - `cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check` → no error
  - `cd docs-web && npm install && npm run build` → success (broken links throw)
  - `PROVEASIO_HOME="$PWD" bash docker/test.sh --coverage` → no missing checks
- [ ] **Step 5: Manual check on the real tmux (user):** `Alt+Shift+O` opens the popup; picking an open session switches; picking a closed one opens a new window.
