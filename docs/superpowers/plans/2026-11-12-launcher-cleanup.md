# Launcher cleanup and uninstall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `proveasio` labels the named volumes it creates, and gains `cleanup` and `uninstall` subcommands that remove volumes, images, config and the launcher itself.

**Architecture:** All changes are in the single bash script `docker/proveasio`. The config loading moves out of `main()` into a function that `cleanup` and `uninstall` reuse. One parser turns `PROVEASIO_ARGS` into named-volume names; the run path uses it to pre-create labeled volumes, and cleanup uses it to find unlabeled candidates. Docs get one new section.

**Tech Stack:** bash 5, Docker CLI, Docusaurus (docs).

**Spec:** `docs/superpowers/specs/2026-11-12-launcher-cleanup-design.md`

## Global Constraints

- Label: `io.github.ziwi01.proveasio.launcher=1`. Filter with `--filter label=io.github.ziwi01.proveasio.launcher`.
- Unlabeled candidates: existing volumes without the label that are named in the current config or whose name starts with `proveasio-`.
- `--images` = the configured image (same precedence as a run: `--image`, then `PROVEASIO_IMAGE` from the environment, then config, then `ziwi/proveasio:latest`). `--images=all` = repository `proveasio` or ending in `/proveasio`.
- Bind mounts are never removed. Nothing is stopped or forced (`docker volume rm` and `docker image rm` without `-f`).
- One list, one `Remove these? [y/N]`; unlabeled volumes get their own `Also remove these unlabeled volumes? [y/N]` first. Without a TTY on stdin and without `--yes`: refuse, exit 1.
- Exit: 0 when everything was removed or skipped as in use; 1 when a removal failed; 2 for usage errors (as the existing parser).
- Variables set while a config is sourced keep the `_pv_` prefix (`load_file` comment, `docker/proveasio:37`).
- Do not commit. The working tree has unrelated uncommitted changes (`ansible/roles/software/vars/main.yml`, three docs pages); never stage them. The user commits.

## Test harness (all tasks)

Every check runs against a throwaway Docker daemon, never the host's: `--images=all` and `uninstall` would otherwise remove the user's real images (`proveasio:smoke`, `proveasio:slim`, `proveasio:lor`).

```bash
docker run -d --privileged --name pvt-dind -e DOCKER_TLS_CERTDIR= -p 127.0.0.1:23750:2375 docker:dind
export DOCKER_HOST=tcp://127.0.0.1:23750      # wait until `docker info` succeeds
docker pull busybox
docker tag busybox pvt/proveasio:x; docker tag busybox proveasio:y; docker tag busybox other:z
export PROVEASIO_CONFIG_DIR=/tmp/opencode/pvt-cfg; rm -rf "$PROVEASIO_CONFIG_DIR"; mkdir -p "$PROVEASIO_CONFIG_DIR"
mkdir -p /tmp/opencode/pvt-ws && cd /tmp/opencode/pvt-ws
P=~/projects/proveasio/docker/proveasio
```

Config used unless a row says otherwise (`$PROVEASIO_CONFIG_DIR/config`):

```bash
PROVEASIO_IMAGE=pvt/proveasio:x
PROVEASIO_ARGS+=(-v pvt-a:/home/dev/a --volume=pvt-b:/home/dev/b -v /tmp:/host-tmp)
PROVEASIO_ARGS+=(--mount type=volume,src=pvt-c,dst=/home/dev/c --mount "type=bind,src=/tmp,dst=/bt" --mount=source=pvt-d,target=/home/dev/d)
```

Teardown at the end: `unset DOCKER_HOST; docker rm -f pvt-dind; rm -rf /tmp/opencode/pvt-*`.

## Review Focus

1. `cleanup`/`uninstall` run from `~` or `/` must work: the "refusing to mount ... whole home directory" check belongs to the run path only. → Task 2 row l.
2. `uninstall` started as `bash docker/proveasio uninstall` (or through a symlink) must never delete the script inside the repository checkout. → Task 3 rows c, d.
3. A bind source in any spelling (`/abs`, `./rel`, `~/x`, `--mount type=bind`, quoted `"src=..."` CSV field) is never treated as a volume. → Task 1 row b.
4. A run with an existing unlabeled volume must not fail or claim to have labeled it. → Task 1 row d.
5. An answer other than `y`/`yes` (including empty) keeps everything. → Task 2 row g.

---

### Task 1: Labeled volumes on the run path

**Files:**
- Modify: `docker/proveasio:47-123` (`main`)

**Interfaces:**
- Produces:
  - `PV_LABEL=io.github.ziwi01.proveasio.launcher` (readonly, top of file).
  - `load_config()`: the code now at lines 73-83 (reset `PROVEASIO_*`, source `config` and `conf.d/*.sh`, the no-config hint). Callers keep the saved environment values as today.
  - `volume_names ARG...`: prints one named-volume name per line, de-duplicated, from a `docker run` argument list. Handles `-v X`, `--volume X`, `--volume=X`, `--mount X`, `--mount=X`. `-v`: named when the spec contains `:` and the part before the first `:` does not start with `/`, `.` or `~`. `--mount`: split on `,`, strip one pair of surrounding `"` from each field; named when `type` is absent or `volume` and `src`/`source` is set.
  - `ensure_volumes NAME...`: for each name that `docker volume inspect` does not find, `docker volume create --label "$PV_LABEL=1" NAME >/dev/null`. Exit 1 with `proveasio: cannot create volume NAME` on failure.
  - `--dry-run` prints `docker volume create --label io.github.ziwi01.proveasio.launcher=1 NAME`, one line per volume that does not exist yet, before the `docker run` line.

- [ ] **Step 1: Write the checks**

| # | Command | Expected |
|---|---|---|
| a | `$P --dry-run` | create lines for `proveasio-state`, `pvt-a`, `pvt-b`, `pvt-c`, `pvt-d` (in that order), then the `docker run` line; `docker volume ls -q` is empty afterwards |
| b | config adds `-v ./x:/x -v '~/y:/y' -v anon-only --mount 'type=volume,"src=pvt-e",dst=/e'` | `pvt-e` gets a create line; no line for `./x`, `~/y`, `anon-only`, `/tmp` |
| c | `$P -- true` | exit 0; `docker volume ls --filter label=io.github.ziwi01.proveasio.launcher -q` lists the five names of row a |
| d | `docker volume create pvt-old`, add `-v pvt-old:/o`, `$P -- true` | exit 0; `pvt-old` labels still `null`; no create line for it in `$P --dry-run` |
| e | `$P -- true` a second time | exit 0, no new volumes |

- [ ] **Step 2: Run row a and see it fail**

Expected: no `docker volume create` line.

- [ ] **Step 3: Implement `PV_LABEL`, `load_config`, `volume_names`, `ensure_volumes`; call them in `main`** before the dry-run branch (dry-run prints, real run creates, then `exec`).

- [ ] **Step 4: Run rows a-e.** Expected: as in the table.

- [ ] **Step 5: Lint.** Run: `bash -n docker/proveasio && shellcheck docker/proveasio`. Expected: no output.

---

### Task 2: `proveasio cleanup`

**Files:**
- Modify: `docker/proveasio` (`usage`, `main`'s dispatch next to `init`, new functions)

**Interfaces:**
- Consumes: `PV_LABEL`, `load_config`, `volume_names` from Task 1.
- Produces:
  - `cleanup ARG...` (CLI: `proveasio cleanup [--mounts[=NAME,...]] [--exclude-mount NAME]... [--include-unlabeled] [--images[=all]] [--config] [--image IMAGE] [--yes] [--dry-run]`).
  - `remove_all YES DRY INCLUDE_UNLABELED` operating on arrays `_pv_rm_volumes`, `_pv_rm_unlabeled`, `_pv_rm_images`, `_pv_rm_paths` (my call: globals, so Task 3 can append the launcher to `_pv_rm_paths`). It prints the list, asks, removes, sets the exit status.

- [ ] **Step 1: Write the checks** (after Task 1 row c and row d volumes exist; also `docker volume create proveasio-old`)

| # | Command | Expected |
|---|---|---|
| a | `$P cleanup` | usage on stderr, exit 2 |
| b | `$P cleanup --mounts --dry-run` | lists the five labeled volumes; separate unlabeled list `pvt-old`, `proveasio-old`; nothing removed |
| c | `$P cleanup --mounts --exclude-mount pvt-a --yes` | removes the other four labeled; lists unlabeled as kept; `pvt-a`, `pvt-old`, `proveasio-old` remain |
| d | `$P cleanup --mounts=pvt-a,pvt-old,nope --yes --include-unlabeled` | removes `pvt-a` and `pvt-old`; reports `nope` as not found; exit 0 |
| e | `docker run -d --name pvt-busy -v proveasio-old:/x busybox sleep 600`; `$P cleanup --mounts --include-unlabeled --yes` | `proveasio-old` reported in use and skipped; exit 0; then `docker rm -f pvt-busy` |
| f | `$P cleanup --mounts </dev/null` | refuses, message names `--yes`, exit 1, nothing removed |
| g | `printf '\n' \| script -qc "$P cleanup --mounts --include-unlabeled" /dev/null` and the same with `n` | nothing removed |
| h | `$P cleanup --images --yes` | removes `pvt/proveasio:x` only; `proveasio:y`, `other:z` remain |
| i | `$P cleanup --images=all --dry-run` | lists `proveasio:y` (and `pvt/proveasio:x` if present), never `other:z` or `busybox` |
| j | `$P cleanup --config --yes` with `config`, `config.bak`, `conf.d/10.sh`, `ado-pat` present | list names all four; `$PROVEASIO_CONFIG_DIR` gone |
| k | `$P cleanup --mounts --images=all --dry-run` with no config dir | works; no-config hint at most once |
| l | `cd ~ && $P cleanup --mounts --dry-run` | no "refusing to mount" error |

- [ ] **Step 2: Run row a and see it fail.** Expected: today `cleanup` is passed to `docker run` as a command (dry-run shows it at the end).

- [ ] **Step 3: Implement `cleanup` and `remove_all`.** Labeled set: `docker volume ls -q --filter label=$PV_LABEL`. Unlabeled set: entries of `docker volume ls -q` that are not labeled and are either `proveasio-state`, in `volume_names "${PROVEASIO_ARGS[@]}"`, or match `proveasio-*`. In use: `docker ps -aq --filter volume=NAME` non-empty; for images `docker ps -aq --filter ancestor=IMAGE`. `--images=all`: `docker image ls --format '{{.Repository}}:{{.Tag}}'`, match `proveasio` or `*/proveasio` on the repository. Answers come from stdin (`read -r`), only after the `[ -t 0 ]` check; `y` or `yes` (any case) accepts.

- [ ] **Step 4: Run rows a-l.** Expected: as in the table.

- [ ] **Step 5: Lint** as Task 1.

---

### Task 3: `proveasio uninstall`

**Files:**
- Modify: `docker/proveasio`

**Interfaces:**
- Consumes: `cleanup`'s selection code and `remove_all` from Task 2.
- Produces: `uninstall ARG...` (CLI: `proveasio uninstall [--include-unlabeled] [--yes] [--dry-run]`); `launcher_path` prints the path to remove or nothing.

`launcher_path`: `$0` when it contains `/`, else `command -v proveasio`. If it is a symlink, print it. If it is a regular file and `git -C "$(dirname "$(readlink -f "$path")")" rev-parse --is-inside-work-tree` succeeds, print nothing and report `proveasio: not removing <path>: it is inside a git checkout`. Otherwise print it. Removal of a symlink is `rm -- path` (never `readlink -f`).

- [ ] **Step 1: Write the checks** (recreate volumes, tags and config as in the harness first)

| # | Command | Expected |
|---|---|---|
| a | `$P uninstall --dry-run` | lists labeled volumes, unlabeled section, `pvt/proveasio:x`, `proveasio:y`, the config files; nothing removed |
| b | `cp $P /tmp/opencode/pvt-bin/proveasio`; `/tmp/opencode/pvt-bin/proveasio uninstall --yes` | everything in row a removed (unlabeled kept), the copy removed; `other:z` remains |
| c | `ln -s $P /tmp/opencode/pvt-bin/proveasio`; `/tmp/opencode/pvt-bin/proveasio uninstall --yes` | link gone, `$P` still exists |
| d | `bash $P uninstall --yes` | `$P` still exists, message says it is inside a git checkout |
| e | `$P uninstall` (no TTY) | refuses, exit 1 |

- [ ] **Step 2: Run row a and see it fail.**
- [ ] **Step 3: Implement `uninstall` and `launcher_path`.**
- [ ] **Step 4: Run rows a-e.**
- [ ] **Step 5: Lint** as Task 1.

---

### Task 4: Usage text and docs

**Files:**
- Modify: `docker/proveasio` (`usage`)
- Modify: `docs-web/docs/main/docker/30-run.md` (new `## Cleanup and uninstall` after `## Keeping state`, line 240)

Content: both commands with every option; the label name; that volumes created before this version (such as `proveasio-state`) are unlabeled, listed separately and removed only on confirmation or with `--include-unlabeled`; bind mounts are never removed; `--images=all` matches every `proveasio` image including local builds; `uninstall` removes a symlinked launcher's link but never a file inside a git checkout. Do not edit `docs-web/versioned_docs/`.

- [ ] **Step 1: `$P --help`** shows `cleanup` and `uninstall` lines.
- [ ] **Step 2: Docs build.** Run: `cd docs-web && npm run build`. Expected: `[SUCCESS]`, no broken-link error.
- [ ] **Step 3: Teardown** the harness and run `git status --short`. Expected: only `docker/proveasio`, `30-run.md`, the spec, this plan, plus the user's pre-existing changes, untouched.
