# Docker launcher and image defaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users start the Proveasio image with `proveasio` from a project directory; per-user
settings (image, ssh, kube, CA bundle, Docker socket, fonts, git identity, ADO PAT, GitHub
token) live in a config file written by `proveasio init`, and flags that are the same for
everyone become image defaults.

**Architecture:** The image gains ENV defaults, a state directory and two env-driven git
credential helpers (`docker/gitconfig` → `/etc/gitconfig`), in both the `build` and
`update` stages, plus an always-selected `image/defaults` check in `docker/test.sh`. A
standalone bash launcher, `docker/proveasio`, sources `~/.config/proveasio/config` and
`conf.d/*.sh`, then builds one `docker run` command. Docs lead with the launcher.

**Tech Stack:** bash, Dockerfile (buildx bake), git credential helpers, Docusaurus docs.

**Spec:** `docs/superpowers/specs/2026-11-10-docker-launcher-design.md`

## Global Constraints

- Do not commit, push or create branches; the user commits. (User's global rule; it
  overrides the usual per-task commit step.)
- State path in the image: `/home/${USERNAME}/.local/state/proveasio`;
  `HISTFILE=<that>/zsh_history`, `_ZO_DATA_DIR=<that>/zoxide`.
- CA env defaults: `NODE_EXTRA_CA_CERTS` and `REQUESTS_CA_BUNDLE` =
  `/etc/ssl/certs/ca-certificates.crt`.
- Credential helpers answer only for `https://dev.azure.com`, `https://*.visualstudio.com`
  (variable `ADO_PAT`, username `pat`) and `https://github.com` (variable `GH_TOKEN`,
  username `x-access-token`), and only when the variable is non-empty.
- Every image change goes into both the `build` and the `update` stage.
- Launcher defaults: `PROVEASIO_IMAGE=ziwi/proveasio:latest`; `PROVEASIO_PULL=missing`,
  but `never` when the image name has no `/`; `PROVEASIO_USER_HOME=/home/dev`;
  `PROVEASIO_ARGS=()`.
- Launcher config dir: `${PROVEASIO_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/proveasio}`.
- The state volume keeps the name `proveasio-state` and is mounted at
  `$PROVEASIO_USER_HOME/.local/state/proveasio`. (Plan decision for the spec's
  rename-or-move choice: the old volume's root held `zsh_history`, so mounted at the new
  path it lands exactly on the new `HISTFILE`; only zoxide's `db.zo` needs copying.)
- Secrets are passed as `-e NAME` only, never `-e NAME=value`, so `ps` and `--dry-run`
  never show them.
- Script download URL in the docs:
  `https://raw.githubusercontent.com/ziwi01/proveasio/master/docker/proveasio`. (Plan
  decision: `publish.sh` rsyncs `docs/` to the stable docs verbatim, so a branch-specific
  URL would be wrong in one of the two; `master` is right after every release.)
- Docs: edit `docs-web/docs/` only. Gate: `cd docs-web && npm install && npm run build`.
- On WSL, before any `docker buildx bake`: at least 10 GB free physical memory and 10 GB
  free commit on the Windows host (`AGENTS.md`, "Docker image").
- The pre-built image is not published yet (`10-build.md`, "Pre-built image"). The
  default image stays `ziwi/proveasio:latest` as the spec says; the docs and the `init`
  template tell users to set `PROVEASIO_IMAGE=proveasio:local` until it is.

## Review Focus

- `PWD` is a symlink to, or a subdirectory spelled differently from, `$HOME` → the
  launcher still refuses `$HOME` itself and allows a real subdirectory (compare
  `pwd -P` with `cd "$HOME" && pwd -P`). Test in Task 2.
- `PROVEASIO_IMAGE` set in the environment *and* in the config → the environment wins;
  `--image` beats both. Test in Task 2.
- Running non-interactively (`proveasio -- true </dev/null`, or in a pipe) → no `-t`,
  so Docker does not fail with "the input device is not a TTY". Test in Task 2.
- A config line with a syntax error or a `conf.d/` file that is not `*.sh` → the
  launcher stops with the file name on a syntax error, and ignores non-`*.sh` files.
  Test in Task 2.
- An existing `proveasio-state` volume (old layout) has no `zoxide/` subdirectory →
  zoxide still works (creates the directory or the docs' migration creates it). Test in
  Task 1.

---

### Task 1: Image defaults, credential helpers and the `image/defaults` check

**Files:**
- Create: `docker/gitconfig`
- Modify: `docker/Dockerfile` (after the `provision.sh` RUN in `build`, lines ~118-123;
  in `update`, lines ~145-150)
- Modify: `docker/test.sh` (new `check_image_defaults`; `main()` selection, ~line 752)
- Modify: `docker/provision.sh:229-236` (the "fresh items" loop)
- Modify: `AGENTS.md` ("Docker image" section: check counts, the new check)

**Interfaces:**
- Produces: image ENV `HISTFILE`, `_ZO_DATA_DIR`, `NODE_EXTRA_CA_CERTS`,
  `REQUESTS_CA_BUNDLE`; directory `~/.local/state/proveasio/zoxide` owned by the user;
  `/etc/gitconfig` with three credential sections; `docker/test.sh` item `image/defaults`.
  Task 2's old-image warning looks for `HISTFILE=` in `.Config.Env`.

- [ ] **Step 1: Write `check_image_defaults` in `docker/test.sh`**

Place it after the other checks. It must fail on today's images. Assertions:

```bash
check_image_defaults() {
  local state="$HOME/.local/state/proveasio"
  [ "${HISTFILE:-}" = "$state/zsh_history" ] || fail "HISTFILE is '${HISTFILE:-}'" || return 1
  [ "${_ZO_DATA_DIR:-}" = "$state/zoxide" ] || fail "_ZO_DATA_DIR is '${_ZO_DATA_DIR:-}'" || return 1
  [ "${NODE_EXTRA_CA_CERTS:-}" = /etc/ssl/certs/ca-certificates.crt ] || fail "NODE_EXTRA_CA_CERTS" || return 1
  [ "${REQUESTS_CA_BUNDLE:-}" = /etc/ssl/certs/ca-certificates.crt ] || fail "REQUESTS_CA_BUNDLE" || return 1
  [ -d "$state/zoxide" ] && [ -O "$state" ] || fail "$state missing or not owned by $(id -un)" || return 1
  # helper answers with the variable set, stays silent without it
  # (assert on `printf 'protocol=https\nhost=dev.azure.com\n\n' | ADO_PAT=t git credential fill`
  #  containing 'password=t', same for host=x.visualstudio.com and, with GH_TOKEN=t,
  #  host=github.com containing 'username=x-access-token' and 'password=t';
  #  without the variables, run with GIT_TERMINAL_PROMPT=0 and expect no 'password=' line)
}
```

The commented assertions are required; write them as real code in the same style.

- [ ] **Step 2: Always select it**

In `main()`, after the role loop and only when `tags_given` is 0, append `image/defaults`
to `selected`. `--only image/defaults` must work; `--list --tags ...` (used by
`provision.sh` for its required-include check) must not print it.

- [ ] **Step 3: Skip `image/*` in `provision.sh`'s "fresh" loop**

In the loop at `provision.sh:231-236`, `continue` for items matching `image/*`: the update
stage sets the defaults itself, so an older base image without them is not an error.

- [ ] **Step 4: Run the check against the current image to see it fail**

Run: `docker run --rm -v "$PWD/docker/test.sh":/tmp/test.sh:ro ziwi/proveasio:lor bash /tmp/test.sh --only image/defaults`
Expected: `not ok image/defaults: HISTFILE is ''` and exit code 1. (`--only` needs the
item in `selected`, which Step 2 provides.)

- [ ] **Step 5: Create `docker/gitconfig`**

Three `[credential "<url>"]` sections, `helper` values exactly as in the spec, with
`ADO_PAT`/`pat` for `https://dev.azure.com` and `https://*.visualstudio.com` and
`GH_TOKEN`/`x-access-token` for `https://github.com`. A leading comment says what it is
and that the native `.gitconfig` template is separate.

- [ ] **Step 6: Bake the defaults in `docker/Dockerfile`, both stages**

After the `provision.sh` RUN in `build`, and after the `provision.sh --update` RUN in
`update` (next to the existing `ENV TERM` there):
- `ENV` for the four variables (paths built from `${USERNAME}`), with a comment on why
  each is safe for everyone (spec, section 1).
- `RUN mkdir -p "$HOME/.local/state/proveasio/zoxide"` (as the user).
- `COPY --chmod=0644 docker/gitconfig /etc/gitconfig`.

Placing them after the playbook keeps the cached bootstrap and pyenv layers.

- [ ] **Step 7: Verify the bake file and run the smoke build**

Check host memory first (Global Constraints). Then:
Run: `docker buildx bake --print >/dev/null && ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke docker buildx bake`
Expected: build succeeds; the test stage prints `ok image/defaults` and
`# 10 selected, 10 passed, 0 failed` (9 before).

- [ ] **Step 8: Run the smoke update**

Run: `IMAGE=proveasio:smoke ANSIBLE_TAGS=eza docker buildx bake update`
Expected: succeeds, `# 10 selected, 10 passed, 0 failed`.

- [ ] **Step 9: Check zoxide with an old-layout volume (Review Focus)**

Run:
```bash
docker volume create pv-old-test
docker run --rm -v pv-old-test:/home/dev/.local/state/proveasio proveasio:smoke zsh -lc 'echo x > $HISTFILE; z /tmp; zoxide query -l; ls -ld $_ZO_DATA_DIR'
docker volume rm pv-old-test
```
Expected: `/tmp` listed (or no error), `zoxide` directory exists owned by `dev`, no
permission errors. If zoxide does not create the directory, note it for the migration
docs in Task 4 (the migration command must `mkdir -p .../zoxide`).

- [ ] **Step 10: Update `AGENTS.md`**

"Docker image" section: smoke build and update now run 10 checks; one line that
`image/defaults` is always selected and `provision.sh` skips `image/*` in the update's
"new include" check; one line that `docker/gitconfig` becomes `/etc/gitconfig` in both
stages.

---

### Task 2: Launcher run path (`docker/proveasio`)

**Files:**
- Create: `docker/proveasio` (mode 0755)

**Interfaces:**
- Consumes: from Task 1, `HISTFILE=` in an image's `.Config.Env` marks a current image.
- Produces: CLI `proveasio [--image IMAGE] [--pull POLICY] [--dry-run] [--] [COMMAND...]`,
  `proveasio --help`; config variables `PROVEASIO_IMAGE`, `PROVEASIO_PULL`,
  `PROVEASIO_ARGS`, `PROVEASIO_USER_HOME`; Task 3 adds the `init` subcommand to the same
  argument parser and reuses the config-dir function `config_dir()` (prints the path).

- [ ] **Step 1: Write the checks (run from a scratch directory)**

Use a throwaway config dir so nothing touches the user's real config:

```bash
export PROVEASIO_CONFIG_DIR=/tmp/opencode/pv-cfg; rm -rf "$PROVEASIO_CONFIG_DIR"
mkdir -p /tmp/opencode/pv-ws && cd /tmp/opencode/pv-ws
P=~/projects/proveasio/docker/proveasio
```

| # | Command | Expected |
|---|---|---|
| a | `$P --dry-run` | one line starting `docker run --rm -i`, containing `-v /tmp/opencode/pv-ws:/workspace -w /workspace`, `-v proveasio-state:/home/dev/.local/state/proveasio`, `--pull missing`, ending in `ziwi/proveasio:latest`; stderr has one hint naming `proveasio init` |
| b | `$P --dry-run </dev/null \| cat` | no `-t` in the command |
| c | `$P --image proveasio:local --dry-run` | `--pull never ... proveasio:local` |
| d | config with `PROVEASIO_IMAGE=a/b:1`; `PROVEASIO_IMAGE=c/d:2 $P --dry-run`; then add `--image e/f:3` | `c/d:2`, then `e/f:3` |
| e | `conf.d/10-x.sh` with `PROVEASIO_ARGS+=(-e FOO=1)`, `conf.d/ignored.txt` with `exit 7` | `-e FOO=1` present, exit 0 |
| f | `conf.d/20-bad.sh` containing `PROVEASIO_ARGS+=(` | non-zero exit, stderr names `20-bad.sh` |
| g | config with `export ADO_PAT=secret; PROVEASIO_ARGS+=(-e ADO_PAT)`; `$P --dry-run` | `-e ADO_PAT` present, `secret` absent |
| h | `cd ~ && $P --dry-run`; `cd / && $P --dry-run`; `ln -s ~ /tmp/opencode/home-link && cd /tmp/opencode/home-link && $P --dry-run` | all three refuse, non-zero exit, message says to `cd` into a project |
| i | `$P --dry-run -- ansible --version` | command ends `ziwi/proveasio:latest ansible --version` |
| j | `$P --image proveasio:does-not-exist` (no `--dry-run`) | exits non-zero before `docker run`, message names the image and `docker buildx bake` |
| k | `$P --image ziwi/proveasio:lor -- true` | runs; stderr warns once that the image predates the launcher defaults (pull or rebuild) |
| l | `$P --image proveasio:smoke -- zsh -lc 'echo $HISTFILE; pwd'` | prints `/home/dev/.local/state/proveasio/zsh_history` and `/workspace`, no warning |
| m | `$P --pull sometimes --dry-run` | non-zero exit, message lists `missing`, `always`, `never` |

- [ ] **Step 2: Run them to see them fail**

Run: row a.
Expected: `No such file or directory` (the script does not exist yet).

- [ ] **Step 3: Implement `docker/proveasio`**

`#!/usr/bin/env bash`, `set -euo pipefail`. A header comment: what it is, where the config
lives, link to the run docs page. Behaviour, in order:

1. Save `PROVEASIO_IMAGE`/`PROVEASIO_PULL` from the environment before anything else.
2. Parse options until the first non-option or `--`; the rest is `COMMAND`.
3. `config_dir()`; source `config` if present, then `conf.d/*.sh` in glob order
   (`nullglob`). Source each with a wrapper that, on failure, prints
   `proveasio: error in <file>` and exits 1. No config at all → one stderr hint line.
4. Apply precedence: flag > saved environment > config > default (Global Constraints).
   Validate the pull policy.
5. Refuse when `pwd -P` equals `/` or `(cd "$HOME" && pwd -P)`.
6. Assemble: `docker run --rm -i` (`-t` too when `[ -t 0 ] && [ -t 1 ]`), workspace
   mount and `-w`, state volume, `"${PROVEASIO_ARGS[@]}"`, `--pull "$pull"`, image,
   `COMMAND`.
7. `--dry-run`: print the array with `printf '%q '` and a newline; exit 0. No image
   checks in dry-run.
8. Otherwise: if `docker image inspect` finds the image, warn when its `.Config.Env`
   has no `HISTFILE=`; if it does not and the policy is `never`, stop with the
   build/pull message. Then `exec docker run ...`.

`--help` prints usage (including `init`, which Task 3 implements) and the config path.

- [ ] **Step 4: Run all checks a-m**

Expected: every row as in the table. Rows k and l need the images from Task 1; if
`proveasio:smoke` is not built, say so and leave l unverified.

- [ ] **Step 5: Lint**

Run: `bash -n docker/proveasio && (command -v shellcheck >/dev/null && shellcheck docker/proveasio || echo "shellcheck not installed")`
Expected: no output from `bash -n`; shellcheck clean or reported as not installed.

---

### Task 3: `proveasio init` and the presets

**Files:**
- Modify: `docker/proveasio`

**Interfaces:**
- Consumes: `config_dir()` and the argument parser from Task 2.
- Produces: `proveasio init [--force]`; the template text, which Task 4 copies into the
  docs preset by preset.

- [ ] **Step 1: Write the checks**

With the same scratch `PROVEASIO_CONFIG_DIR` (empty):

| # | Command | Expected |
|---|---|---|
| a | `$P init` | creates `$PROVEASIO_CONFIG_DIR/config`, prints its path, exit 0 |
| b | `$P init` again | non-zero exit, message mentions `--force`, file unchanged |
| c | `$P init --force` | `config.bak` exists with the previous content; new `config` written |
| d | `bash -n "$PROVEASIO_CONFIG_DIR/config"` | no errors |
| e | `$P --dry-run` with the fresh config | same command as Task 2 row a minus the hint: everything optional is commented |
| f | `grep -c '^#.*PROVEASIO_ARGS+=' config` | ≥ 9 (presets below) |
| g | `grep 'GIT_AUTHOR_NAME' config` | commented line with the host's `git config user.name`, shell-quoted |
| h | Uncomment the ADO and GitHub blocks, create the two token files, `$P --dry-run` | `-e ADO_PAT -e GH_TOKEN`, no token values |

- [ ] **Step 2: Run row a to see it fail**

Expected: unknown argument / usage error.

- [ ] **Step 3: Implement `init`**

Template as a heredoc inside the script. Each block: a one-line comment saying what it
does, then the commented lines. Blocks, in this order:
- Image: `PROVEASIO_IMAGE` (with `proveasio:local` noted for local builds and for now,
  since the pre-built image is not published) and `PROVEASIO_PULL` with its three values;
  `PROVEASIO_USER_HOME` for images built with another `USERNAME`.
- SSH keys; SSH agent (Linux/WSL Docker Engine only).
- Kubernetes (`~/.kube`).
- Git identity: the four `GIT_*` variables from the host's `git config`, quoted with
  `printf %q`; placeholders when empty.
- No Nerd Font.
- Corporate CA bundle: the comment says it must be a full bundle, and points to the
  `CORP_CA` build secret for a single root certificate.
- Docker socket with `--group-add "$(stat -c %g /var/run/docker.sock)"`.
- Azure DevOps: `export ADO_PAT="$(<"$PROVEASIO_CONFIG_DIR_OR_DEFAULT/ado-pat")"` and
  `PROVEASIO_ARGS+=(-e ADO_PAT)`; comment: file mode 600, narrowest scope (Code read or
  read & write, one organisation).
- GitHub: same with `github-token` and `GH_TOKEN`; comment: fine-grained token limited to
  the needed repositories; also used by `gh` and the playbook's API calls.
- Keeping other tools' state: commented Neovim volume example, with the note that the
  directory must exist in the image.

Token file paths use the actual config dir at `init` time. `--force` moves the old file to
`config.bak` before writing.

- [ ] **Step 4: Run rows a-h**

Expected: as in the table.

- [ ] **Step 5: Lint**

Same command as Task 2, Step 5.

---

### Task 4: Docs

**Files:**
- Modify: `docs-web/docs/main/docker/30-run.md` (restructure)
- Modify: `docs-web/docs/main/docker/10-build.md` ("Pre-built image" and wherever it says
  how to start a built image)
- Modify: `docs-web/docs/main/about.md` (its `docker run` line)
- Modify: `README.md:33-41`

**Interfaces:**
- Consumes: the template blocks from Task 3 (copy them, uncommented, as presets).

- [ ] **Step 1: Restructure `30-run.md`**

Sections, in order (keep existing anchors that other pages link to: `#user-id`,
`#devcontainer`; check with `grep -rn 'run#' docs-web/docs`):
1. **Launcher**: install (clone the repo and link `docker/proveasio` into `~/.local/bin`,
   or `curl -fsSLo ~/.local/bin/proveasio <URL> && chmod +x ...`), `proveasio init`,
   `proveasio`, `proveasio -- <command>`, `--dry-run`. Linux and WSL; macOS untested.
   Refuses `$HOME` and `/`. Needs an image built after this change (warning otherwise).
2. **Choosing the image**: the variables, `--image`/`--pull`, precedence, the `never`
   default for local names, `proveasio:local` until the pre-built image is published.
3. **Config files**: `config`, `conf.d/*.sh`, `PROVEASIO_CONFIG_DIR`, that they are bash,
   and the secrets rule (`-e NAME` only).
4. **Presets**: one subsection per preset from Task 3 (SSH keys and agent, Kubernetes, git
   identity, Nerd Font, corporate CA, Docker socket, Azure DevOps, GitHub), each the
   config lines plus the existing explanations moved from today's sections (the UID notes
   for SSH, the socket notes). Azure DevOps and GitHub each end with a `git clone`
   example (`https://dev.azure.com/<org>/<project>/_git/<repo>`,
   `https://github.com/<owner>/<repo>.git`); GitHub also shows `gh repo list` working
   without `gh auth login`. PAT scope advice as in the template.
5. **Keeping state**: what is kept (`~/.local/state/proveasio`: history, zoxide), that
   other tools start fresh, the Neovim volume example. Migration from the old two volumes:
   ```bash
   docker run --rm -v proveasio-zoxide:/from:ro -v proveasio-state:/to \
     --entrypoint bash <image> -c 'mkdir -p /to/zoxide && cp /from/db.zo /to/zoxide/'
   docker volume rm proveasio-zoxide
   ```
   plus a note that old files from other tools in `proveasio-state` are harmless and can
   be removed.
6. **User ID**, **Terminal colors**, **Devcontainer**, **Running the tests**: keep.
7. **Without the launcher**: the minimal `docker run` line and "`proveasio --dry-run`
   prints the full command for your config".

- [ ] **Step 2: Update `10-build.md`, `about.md`, `README.md`**

Where they show `docker run -it --rm -v "$PWD":/workspace ...`, show `proveasio` (after
`PROVEASIO_IMAGE=proveasio:local` or with `--image proveasio:local`) and link to the run
page. `README.md` keeps the build line and replaces the `docker run` line.

- [ ] **Step 3: Build the docs**

Run: `cd docs-web && npm install && npm run build`
Expected: `[SUCCESS] Generated static files`, no broken-link error.

- [ ] **Step 4: Check that no doc still teaches the removed flags**

Run: `grep -rn 'proveasio-zoxide\|HISTFILE=\|NODE_EXTRA_CA_CERTS=' docs-web/docs README.md`
Expected: only the migration command (`proveasio-zoxide`) matches.

---

### Task 5: Final verification

- [ ] **Step 1: Repository gates**

Run: `git status --short` (no change under `ansible/`, so `ansible-lint` is not required;
if anything under `ansible/` changed, run `cd ansible && ansible-lint` and expect
`Passed: 0 failure(s)`).

- [ ] **Step 2: End-to-end with the smoke image**

From a project directory, with a real config written by `init`,
`PROVEASIO_IMAGE=proveasio:smoke` and the GitHub preset enabled with a token the user
provides: `proveasio -- git ls-remote https://github.com/ziwi01/proveasio.git HEAD`.
Expected: a commit hash. If no token is available, run it without the preset and record
that the authenticated path was only checked with `git credential fill` (Task 1).

- [ ] **Step 3: Report**

List what ran and what it printed, including anything left unverified (a real ADO clone
needs the user's PAT; macOS untested).
