# Required tasks, slim image and image updates: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the eza tag coupling, make `packages`/`yq`/`zsh` non-excludable, add a `slim` image profile whose excludes users can take back (`*_tasks_include`), and add a Bake `update` target that updates tools in an existing image.

**Architecture:** Ansible changes are small (one assert, removed guards, eza completion in `~/.zfunc`). The Docker playbook step moves from a Dockerfile heredoc into `docker/provision.sh`, which has a full mode (`build` stage) and an update mode (`update` stage, `FROM ${BASE_IMAGE}`). A global `ARG PROVISIONED` picks which stage the `test`, `receipt` and `final` stages start from. `render-overrides.sh` layers `docker/profile-<PROFILE>.yml` and applies `*_tasks_include`. `test.sh` gains `--list --tags/--skip-tags` and tests the union of the build's and the updates' tag selections.

**Tech stack:** Ansible (existing roles), bash, yq v4.52, Docker BuildKit v0.33 and Bake (buildx 0.37, `docker` driver), GitHub Actions, Docusaurus docs.

**Spec:** `docs/superpowers/specs/2026-09-25-docker-slim-and-update-design.md`

## Global constraints

- Required tasks: `packages`, `yq`, `zsh` in `software_tasks_exclude`; `zsh` in `config_tasks_exclude`. Required includes for a new image: `software/packages`, `software/yq`, `software/zsh`, `config/zsh`.
- Slim profile excludes: software `sdkman`, `azurecli`, `az-account-switcher`, `rust`, `puppet`, `awscli`; config `sdkman`. `nvm`, `gvm`, `rvm` stay.
- `PROFILE` default `full`; valid names match `^[a-z0-9-]+$`; `IMAGE` default `proveasio:local` for `full`, `proveasio:<PROFILE>` otherwise.
- Published slim tags: `slim`, `YYYY-MM-DD-slim`, `X.Y.Z-slim`, `X.Y-slim`, `sha-<short>-slim`.
- `UPDATES` entries in `build-info.env`: `<BUILD_DATE>|<ANSIBLE_TAGS>|<ANSIBLE_SKIP_TAGS>`, appended as `UPDATES+=(<%q entry>)` lines.
- `cd ansible && ansible-lint` must print `Passed: 0 failure(s)` after every task that touches `ansible/`.
- Ansible conventions: task names `"[Tool] ..."`; every `shell:` task sets `args.executable: /bin/bash` and starts with `set -e -o pipefail`.
- Never run `ansible-playbook setup-ubuntu.yml` on the host except with `--list-tasks`, `--list-tags` or `--syntax-check`. Playbook runs happen only inside `docker buildx bake` or in a `docker run --rm` container (helper `in_image`).
- Never set `PROVEASIO_IMAGE_BUILD=1` on the host. Tests of `render-overrides.sh` run inside a throwaway container.
- Before every `docker buildx bake` that builds (not `--print`): run `mem_ok`. It must print a line and return 0 (at least 10 GB free physical memory and 10 GB free commit on Windows). If it fails, stop and report the numbers; do not build. At planning time the host had 8.6 GB free physical memory.
- Never build two images in one Bake call.
- `docker/overrides.yml` does not exist (checked 2026-09-25). A step that creates it deletes it in the same step.
- User docs go in `docs-web/docs/` only. Docs prose follows the unslop rules: sentence-case headings, no em dashes, plain words, active voice.
- No commits, pushes, branches or tags unless the user asks. Each task ends with a checkpoint that shows `git status --short` and `git diff --stat`; suggested commit subjects are given for when the user asks.
- Throwaway files go in `/tmp/opencode/pv/`.

## Facts established while planning

Checked on 2026-09-25 on this machine (WSL, Docker with the `docker` buildx driver, BuildKit v0.33, yq 4.52.2):

- `ansible-playbook setup-ubuntu.yml --list-tasks` prints role tasks as `      <role> : <name>	TAGS: [...]`. Today `--skip-tags eza` lists no `config : [Config] Configure zsh`, and `--tags eza` lists it with `TAGS: [config, eza, zsh]`.
- `--list-tags` minus the tag list in `customization/50-partial-run.md` is exactly `always config software versions` (the doc lists those elsewhere).
- `docker/test.sh --list` on a copy without overrides or build info prints 54 includes (45 software, 9 config). With `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker` in the build info it prints 9: `software/packages software/yq software/eza software/zsh software/docker software/neovim config/zsh config/p10k config/neovim-config`. `--tags` is rejected today (`unknown argument: --tags`, exit 2).
- yq: `.a - .b` removes every occurrence (`[x, y, x, z] - [x]` is `[y, z]`); `.[strenv(K)] | type` is `!!null` for a missing key, `!!seq` for a list, `!!str` for a string.
- `config_tasks_exclude: []` is the default in `roles/config/vars/main.yml:10`.
- `FROM ${BASE_IMAGE}` with `--pull=false` resolves the local `proveasio:local`; `FROM ${PROVISIONED}` selects a stage; a stage the target does not reach is not resolved (probe in `/tmp/opencode/probe`).
- `variable "IMAGE" { default = PROFILE == "full" ? "proveasio:local" : "proveasio:${PROFILE}" }` works in Bake; an explicit `IMAGE` wins.
- docker/metadata-action accepts `prefix=`/`suffix=` on every tag type.
- The Windows memory query that works from WSL: `powershell.exe -NoProfile -Command 'Get-CimInstance Win32_OperatingSystem | ForEach-Object { "$($_.FreePhysicalMemory) $($_.FreeVirtualMemory)" }'` prints `<KB> <KB>`.
- `proveasio:local` (8.55 GB, built from the current working tree before this plan) exists and is the image `in_image` uses.
- No `shellcheck` on PATH. Mason's copy is at `~/.local/share/astronvim/mason/bin/shellcheck`; use it as an optional extra check, it is not a project gate.

## File map

```
ansible/roles/software/tasks/eza.yml        Task 1: ~/.zfunc/_eza link
ansible/roles/config/templates/zshrc.j2     Task 1: no versioned eza FPATH
ansible/roles/config/tasks/main.yml         Task 1: no eza tag; Task 2: no zsh guard
ansible/roles/config/tasks/zsh.yml          Task 1: eza fallback removed
ansible/roles/software/tasks/main.yml       Task 2: assert, no packages/zsh guard
docker/test.sh                              Task 3: --list --tags/--skip-tags; Task 7: UPDATES
docker/provision.sh (new, 0755)             Task 4: full mode; Task 7: update mode
docker/Dockerfile                           Task 4: RUN provision.sh; Task 5: ARG PROFILE; Task 7: update stage
docker/render-overrides.sh                  Task 4: no build info; Task 5: profiles, includes; Task 7: base carry-over
docker/cleanup.sh, docker/nvim-install.lua  Task 4: header comments only
docker/profile-slim.yml (new)               Task 5
docker-bake.hcl                             Task 5: PROFILE, IMAGE; Task 7: BASE_IMAGE, update target
.github/workflows/docker.yml                Task 6
docs-web/docs/main/...                      Tasks 1, 2, 4, 5, 6, 7
AGENTS.md, TODO.md                          Tasks 1, 2, 4, 5, 7
.serena/memories/{docker-image,ansible-architecture}.md   Task 8
```

## Test helpers

Create once, before Task 1. Every test step starts with `cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh`.

`/tmp/opencode/pv/helpers.sh`:

```bash
# Sourced by the plan's test steps. Run from the repository root.
REPO=/home/ziwi/projects/proveasio
PV=/tmp/opencode/pv

# in_image <image> <script under $PV> [args...]: run the script with bash in a
# throwaway container of <image>. The working tree is mounted read-only at
# /repo and $PV at /t. Nothing outside the container changes.
in_image() {
  local image="$1" script="$2"
  shift 2
  docker run --rm -e GITHUB_TOKEN -e TERM=xterm-256color \
    -v "$REPO:/repo:ro" -v "$PV:/t:ro" "$image" bash "/t/$script" "$@"
}

# host_copy: fresh copy of ansible/ and docker/ in $PV/home, without overrides
# or build info, for docker/test.sh --list on the host.
host_copy() {
  rm -rf "$PV/home"
  mkdir -p "$PV/home"
  cp -r "$REPO/ansible" "$REPO/docker" "$PV/home/"
  rm -f "$PV/home/ansible/vars/overrides.yml" "$PV/home/docker/overrides.yml" "$PV/home/docker/build-info.env"
}

# list [args...]: the working tree's docker/test.sh --list against $PV/home.
list() { PROVEASIO_HOME="$PV/home" bash "$REPO/docker/test.sh" --list "$@"; }

# mem_ok: 0 when Windows has at least 10 GB free physical memory and commit.
mem_ok() {
  local phys virt
  read -r phys virt < <(powershell.exe -NoProfile -Command 'Get-CimInstance Win32_OperatingSystem | ForEach-Object { "$($_.FreePhysicalMemory) $($_.FreeVirtualMemory)" }' | tr -d '\r')
  echo "mem_ok: free physical ${phys:-?} KB, free commit ${virt:-?} KB (need 10485760 each)"
  [ "${phys:-0}" -ge 10485760 ] && [ "${virt:-0}" -ge 10485760 ]
}

# sizes: sizes of the local proveasio images.
sizes() { docker image ls --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep '^proveasio:' | sort; }
```

`/tmp/opencode/pv/sync-ansible.sh` (sourced by container scripts):

```bash
# Inside a container: replace the image's roles and playbook with the working
# tree's, keep the image's rendered vars/overrides.yml.
cp -r /repo/ansible/roles /repo/ansible/setup-ubuntu.yml "$HOME/proveasio/ansible/"
cd "$HOME/proveasio/ansible"
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
```

- [ ] **Create the helpers**

```bash
mkdir -p /tmp/opencode/pv
# write the two files above, then:
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh && type in_image list mem_ok >/dev/null && echo helpers-ok
```

Expected: `helpers-ok`.

---

### Task 1: eza completion in `~/.zfunc`, no eza tag on the zsh config

**Files:**
- Modify: `ansible/roles/software/tasks/eza.yml` (after the `[EZA] Link ... binary` task, lines 57-62)
- Modify: `ansible/roles/config/templates/zshrc.j2:129-141`
- Modify: `ansible/roles/config/tasks/main.yml:22-34`
- Modify: `ansible/roles/config/tasks/zsh.yml:16-30` (delete)
- Modify: `docs-web/docs/main/docker/20-customize.md:84-93`, `AGENTS.md:83-85` and `:203-206`, `TODO.md` (the `fix(zsh): --skip-tags eza` line)

**Interfaces:**
- Produces: `~/.zfunc/_eza` symlink to `~/.local/opt/eza-<version>/_eza`; `.zshrc` adds `~/.zfunc` to `fpath` when the directory exists. `[Config] Configure zsh` has outer tags `config, zsh` only. No task reads `eza_version` in the config role any more.

- [ ] **Step 1: Write the failing checks**

`/tmp/opencode/pv/eza-check.sh`:

```bash
# Runs in a proveasio:local container. Exit 0 only when the eza fix works.
set -uo pipefail
source /t/sync-ansible.sh
before="$(md5sum < "$HOME/.zshrc")"
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags eza > /tmp/eza.log 2>&1 || { tail -n 30 /tmp/eza.log; exit 1; }
fail=0
if grep -q '\[Config\]\[ZSH\]' /tmp/eza.log; then echo "FAIL: --tags eza ran the zsh config"; fail=1; fi
[ "$(md5sum < "$HOME/.zshrc")" = "$before" ] || { echo "FAIL: --tags eza changed .zshrc"; fail=1; }
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags zsh --skip-tags software > /tmp/zsh.log 2>&1 || { tail -n 30 /tmp/zsh.log; exit 1; }
link="$(readlink "$HOME/.zfunc/_eza" || true)"
case "$link" in "$HOME"/.local/opt/eza-*/_eza) echo "ok: ~/.zfunc/_eza -> $link" ;; *) echo "FAIL: ~/.zfunc/_eza is '$link'"; fail=1 ;; esac
if grep -q 'local/opt/eza-' "$HOME/.zshrc"; then echo "FAIL: .zshrc still has the versioned eza path"; fail=1; fi
comp="$(timeout 60 script -qec 'zsh -i -c "print -r -- \${_comps[eza]}"' /dev/null </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)"
[ "$comp" = _eza ] && echo "ok: zsh completion for eza is $comp" || { echo "FAIL: zsh completion for eza is '$comp'"; fail=1; }
exit "$fail"
```

Run:

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --skip-tags eza 2>/dev/null | grep -c 'config : \[Config\] Configure zsh')
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --tags eza 2>/dev/null | grep -c 'config : \[Config\] Configure zsh')
in_image proveasio:local eza-check.sh; echo "rc=$?"
```

Expected now: `0`, `1`, then `FAIL: --tags eza ran the zsh config`, a `FAIL` for the link and for the versioned path, `rc=1`. (The completion may already resolve through the old FPATH line; that is fine.)

- [ ] **Step 2: Link the completion in `eza.yml`**

Insert after the task `[EZA] Link {{ eza_version }} binary to ~/.local/bin/eza` (ends at line 62):

```yaml

# The zsh completion is linked to a fixed path, so .zshrc does not need the
# eza version and the zsh config task does not need the `eza` tag.
- name: "[EZA] Ensure ~/.zfunc exists for the completion file"
  ansible.builtin.file:
    path: "{{ ansible_facts['env']['HOME'] }}/.zfunc"
    state: directory
    mode: "0755"

- name: "[EZA] Link {{ eza_version }} zsh completion to ~/.zfunc/_eza"
  ansible.builtin.file:
    src: "{{ ansible_facts['env']['HOME'] }}/.local/opt/eza-{{ eza_version }}/_eza"
    dest: "{{ ansible_facts['env']['HOME'] }}/.zfunc/_eza"
    state: link
    force: true
```

- [ ] **Step 3: Update `zshrc.j2`**

Delete lines 129-134 (the `{% if eza_version is defined %}` block through `{% endif %}`) and the blank line after them. Replace the ccmux block (lines 136-141):

```
# ccmux completions - must be added to fpath before oh-my-zsh runs compinit.
# The file is generated by Proveasio only when the installed ccmux build
# supports `ccmux completion zsh` (see roles/software/tasks/ccmux.yml).
if [[ -f "${HOME}/.zfunc/_ccmux" ]]; then
  fpath=("${HOME}/.zfunc" $fpath)
fi
```

with:

```
# Completions installed by Proveasio - must be added to fpath before oh-my-zsh
# runs compinit. roles/software/tasks/eza.yml links _eza here, and
# roles/software/tasks/ccmux.yml writes _ccmux when the installed ccmux build
# supports `ccmux completion zsh`.
if [[ -d "${HOME}/.zfunc" ]]; then
  fpath=("${HOME}/.zfunc" $fpath)
fi
```

- [ ] **Step 4: Drop the eza tag and the fallback**

In `config/tasks/main.yml`, `[Config] Configure zsh`: delete `- eza` from `apply.tags` and from `tags` (keep `config`, `zsh`).

In `config/tasks/zsh.yml`: delete the tasks `[Config][ZSH] Resolve EZA version for FPATH` and `[Config][ZSH] Set eza_version fact from installed directory` (lines 16-30) and one of the blank lines around them, so `Get exact node version` is followed by one blank line and `Configure .zshrc`.

- [ ] **Step 5: Run the checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
(cd ansible && ansible-lint) 2>&1 | tail -n 3
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check) | tail -n 2
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --skip-tags eza 2>/dev/null | grep -c 'config : \[Config\] Configure zsh')
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --tags eza 2>/dev/null | grep -c 'config : \[Config\] Configure zsh')
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tags 2>/dev/null) | sed -n 's/.*TASK TAGS: \[\(.*\)\]/\1/p' | tr ',' '\n' | tr -d ' ' | sort -u > "$PV/tags-playbook.txt"
sed -n '/below tags are available:/,/There is also/p' docs-web/docs/main/customization/50-partial-run.md | sed -n 's/^- //p' | sort -u > "$PV/tags-doc.txt"
comm -3 "$PV/tags-playbook.txt" "$PV/tags-doc.txt" | tr -d '\t' | tr '\n' ' '; echo
in_image proveasio:local eza-check.sh; echo "rc=$?"
```

Expected: `Passed: 0 failure(s)`; syntax check prints `playbook: setup-ubuntu.yml`; `1`; `0`; `always config software versions`; `ok: ~/.zfunc/_eza -> /home/dev/.local/opt/eza-<version>/_eza`, `ok: zsh completion for eza is _eza`, `rc=0`.

- [ ] **Step 6: Docs, AGENTS.md, TODO.md**

`docs-web/docs/main/docker/20-customize.md`, replace lines 84-93 (from `Do not skip the tags` through the closing ```` ``` ```` of the eza example) with:

```
Do not skip the tags `zsh` or `config`. Both skip the zsh configuration task,
and the image tests then fail.
```

`AGENTS.md:83-85`, replace

```
  dependencies. `config` reads variables and facts set by `software` — this only works
  because `import_role` is static and keeps vars in play scope. A `--tags config`-only run
  is a degraded mode; `config/tasks/zsh.yml:16-30` exists purely to paper over it.
```

with

```
  dependencies. `config` reads variables set by `software` (`sdkman_dir`, `node_version`) —
  this only works because `import_role` is static and keeps vars in play scope, so it also
  works on `--tags config` runs.
```

`AGENTS.md:203-206`, replace the `--tags eza` bullet with

```
- `--tags zsh` also selects config's zsh and p10k tasks (both carry the `zsh` tag), so
  `--skip-tags zsh` skips all three. eza has no such coupling: its completion is linked to
  `~/.zfunc/_eza`, so `--tags eza` does not touch `.zshrc` and `--skip-tags eza` skips only eza.
```

`TODO.md`: delete the line starting `- [ ] fix(zsh): \`--skip-tags eza\``.

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm install --no-audit --no-fund >/dev/null && npm run build 2>&1 | tail -n 3
```

Expected: the build ends with `[SUCCESS] Generated static files in "build".`

- [ ] **Step 7: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Suggested commit (only when the user asks): `fix(zsh): Link the eza completion into ~/.zfunc so --skip-tags eza keeps the zsh config`

---

### Task 2: Required tasks

**Files:**
- Modify: `ansible/roles/software/tasks/main.yml` (assert after line 47; delete line 57 and line 336 `when:`)
- Modify: `ansible/roles/config/tasks/main.yml` (delete `when: "'zsh' not in config_tasks_exclude"`)
- Modify: `docs-web/docs/main/roles/10-software.md`, `docs-web/docs/main/roles/20-config.md`, `docs-web/docs/main/customization/40-excludes.md`, `docs-web/docs/main/docker/20-customize.md:62-63`, `AGENTS.md` (Architecture section)

**Interfaces:**
- Produces: task `[Software] Check that no required task is excluded` (tag `always`), failing with a message that starts `packages, yq and zsh are required and cannot be excluded.` Task 4's Docker check relies on the same required set.

- [ ] **Step 1: Write the failing check**

`/tmp/opencode/pv/required-check.sh`:

```bash
# Runs in a proveasio:local container. --tags never runs only `always` tasks.
set -uo pipefail
source /t/sync-ansible.sh
run() { ansible-playbook -i inventory.yml setup-ubuntu.yml --tags never -e "$1" > /tmp/run.log 2>&1; echo $?; }
fail=0
rc="$(run '{"software_tasks_exclude": ["zsh", "fx"], "config_tasks_exclude": ["zsh"]}')"
if [ "$rc" != 0 ] && grep -q 'software_tasks_exclude: zsh' /tmp/run.log && grep -q 'config_tasks_exclude: zsh' /tmp/run.log; then
  echo "ok: excluded zsh fails (rc=$rc)"
else
  echo "FAIL: excluded zsh gave rc=$rc"; grep -E 'required|fatal' /tmp/run.log | head -n 5; fail=1
fi
rc="$(run '{"software_tasks_exclude": ["packages"]}')"
[ "$rc" != 0 ] && echo "ok: excluded packages fails" || { echo "FAIL: excluded packages gave rc=0"; fail=1; }
rc="$(run '{"software_tasks_exclude": ["fx"]}')"
[ "$rc" = 0 ] && echo "ok: excluded fx passes" || { echo "FAIL: excluded fx gave rc=$rc"; tail -n 20 /tmp/run.log; fail=1; }
exit "$fail"
```

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
in_image proveasio:local required-check.sh; echo "rc=$?"
```

Expected now: two `FAIL` lines (rc=0 for the zsh and packages cases), `ok: excluded fx passes`, `rc=1`.

- [ ] **Step 2: Add the assert**

In `software/tasks/main.yml`, insert after the task `[Software] Merge overridden version catalogs back onto defaults` (ends at line 47):

```yaml

# packages (jq and curl for every version lookup), yq (save_version.yml) and
# zsh (oh-my-zsh, and the .zshrc that sets NVIM_APPNAME and loads nvm, gvm and
# rvm) are required, so their includes have no exclude guard. Both roles are
# checked here, before anything is installed: the config role runs after the
# whole software role, so a check there would fail an hour into the run.
- name: "[Software] Check that no required task is excluded"
  vars:
    _proveasio_required_software: "{{ software_tasks_exclude | intersect(['packages', 'yq', 'zsh']) }}"
    _proveasio_required_config: "{{ config_tasks_exclude | default([]) | intersect(['zsh']) }}"
  ansible.builtin.assert:
    that:
      - _proveasio_required_software | length == 0
      - _proveasio_required_config | length == 0
    fail_msg: >-
      packages, yq and zsh are required and cannot be excluded.
      Remove software_tasks_exclude: {{ _proveasio_required_software | join(', ') or '-' }}
      and config_tasks_exclude: {{ _proveasio_required_config | join(', ') or '-' }}
      from ansible/vars/overrides.yml (docker/overrides.yml in an image build).
    quiet: true
  tags:
    - always
```

- [ ] **Step 3: Remove the three guards**

- `software/tasks/main.yml`, `[Software] Install packages`: delete `  when: "'packages' not in software_tasks_exclude"`.
- `software/tasks/main.yml`, `[Software] Install zsh`: delete `  when: "'zsh' not in software_tasks_exclude"`.
- `config/tasks/main.yml`, `[Config] Configure zsh`: delete `  when: "'zsh' not in config_tasks_exclude"`.

- [ ] **Step 4: Run the checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
(cd ansible && ansible-lint) 2>&1 | tail -n 3
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check) | tail -n 2
in_image proveasio:local required-check.sh; echo "rc=$?"
```

Expected: `Passed: 0 failure(s)`; `playbook: setup-ubuntu.yml`; three `ok:` lines; `rc=0`.

- [ ] **Step 5: Docs and AGENTS.md**

`docs-web/docs/main/roles/10-software.md`: replace `Available software excludes:` with

```
`packages`, `yq` and `zsh` are required. The playbook stops at the start if
`software_tasks_exclude` lists one of them.

Available software excludes:
```

and delete the list items `- packages (default apt packages installation, including **dependencies**)` and `- zsh`.

`docs-web/docs/main/roles/20-config.md`: replace `Available configs excludes:` with

```
`zsh` is required. The playbook stops at the start if `config_tasks_exclude`
lists it.

Available configs excludes:
```

and delete the list item `- zsh`.

`docs-web/docs/main/customization/40-excludes.md`: in the Permanent example replace `  - zsh # do not configure ZSH` with `  - tmux # do not configure tmux`, and after the paragraph `For full list of exclude options, ...` add:

```

`packages`, `yq` and `zsh` (in both lists) are required. The playbook stops at
the start when an overrides file excludes one of them.
```

`docs-web/docs/main/docker/20-customize.md:62-63`, replace

```
Do not exclude `zsh`, in either list. The image's default command is zsh, and
the smoke tests need the zsh configuration.
```

with

```
`packages`, `yq` and `zsh` cannot be excluded, as on a native run. The
playbook stops at its first tasks when `docker/overrides.yml` excludes one.
```

`AGENTS.md`, Architecture section: after the bullet that starts `- **`software`** (47 task files)`, add

```
- **Required tasks:** `packages`, `yq` and `zsh` (software) and `zsh` (config) have no
  exclude guard. `[Software] Check that no required task is excluded` (tag `always`, right
  after the overrides sandwich) fails the run when an overrides file lists one of them; it
  checks `config_tasks_exclude` too, because the config role runs an hour later.
```

In `AGENTS.md` "Adding software" step 2, keep the `when:` guard text (new tools are excludable).

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm run build 2>&1 | tail -n 3
```

Expected: `[SUCCESS] Generated static files in "build".`

- [ ] **Step 6: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Suggested commit: `feat!: Make packages, yq and zsh required`, with a body that says overrides listing them now fail the run.

---

### Task 3: `test.sh --list --tags/--skip-tags`

**Files:**
- Modify: `docker/test.sh` (header comment lines 1-15, `tags_select` lines 374-395, `usage` lines 437-444, `main` lines 446-486)

**Interfaces:**
- Produces: `docker/test.sh --list --tags <tags> --skip-tags <skip>` prints one `<role>/<name>` per line for the includes those tags select, minus the excludes of `$PROVEASIO_HOME/ansible/vars/overrides.yml`, ignoring `build-info.env`. Either option alone switches to explicit mode; an empty value means "not passed". An empty selection prints nothing and exits 0 in explicit mode. `--tags`/`--skip-tags` without `--list` exit 2.
- Produces: `tags_select <outer tags> <tags> <skip-tags>` (three arguments; Task 7 calls it per update).

- [ ] **Step 1: Write the failing checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh && host_copy
list | wc -l
list --tags software_packages,yq,eza,zsh,neovim,neovim-config,docker | tr '\n' ' '; echo
list --tags neovim; echo "rc=$?"
```

Expected now: `54`, then `unknown argument: --tags` twice with the usage text, `rc=2`.

- [ ] **Step 2: Header comment**

Replace lines 6-13 of `docker/test.sh` with:

```bash
#   ~/proveasio/docker/test.sh                      run every selected check
#   ~/proveasio/docker/test.sh --list               print the selected checks
#   ~/proveasio/docker/test.sh --list --tags <t> --skip-tags <s>
#                                                   print what these tags select
#   ~/proveasio/docker/test.sh --only config/zsh    run one check (repeatable)
#   ~/proveasio/docker/test.sh --coverage           fail if an include has no check
#
# Selection comes from the real inputs: every include in
# roles/{software,config}/tasks/main.yml, minus the excludes in the effective
# ansible/vars/overrides.yml, filtered by the tags in docker/build-info.env
# (or by --tags/--skip-tags; docker/provision.sh uses those).
```

- [ ] **Step 3: Three-argument `tags_select`**

Replace lines 374-395 (the comment and function `tags_select`) with:

```bash
# tags_select <outer tags> <--tags value> <--skip-tags value>: mirrors
# ansible-playbook --tags / --skip-tags on one include. Ansible's special tags
# in --tags: `all` selects every include, `tagged` every include with a tag
# (all of them here). --skip-tags matches literally. Empty means not passed.
tags_select() {
  local outer="$1" run="$2" skip="$3" t hit=0
  if [ -n "$run" ]; then
    for t in ${run//,/ }; do
      case "$t" in
        all) hit=1 ;;
        tagged) if [ -n "$outer" ]; then hit=1; fi ;;
        *) if [[ ",$outer," == *",$t,"* ]]; then hit=1; fi ;;
      esac
    done
    [ "$hit" -eq 1 ] || return 1
  fi
  if [ -n "$skip" ]; then
    for t in ${skip//,/ }; do
      if [[ ",$outer," == *",$t,"* ]]; then return 1; fi
    done
  fi
  return 0
}
```

- [ ] **Step 4: `usage` and `main`**

Replace `usage` with:

```bash
usage() {
  cat <<'EOF'
Usage: docker/test.sh [--list [--tags <tags>] [--skip-tags <tags>]] [--coverage] [--only <role>/<name>]...
  --list        print the checks selected for this image and exit
  --tags        with --list: select as `ansible-playbook --tags` would, instead
                of using docker/build-info.env
  --skip-tags   with --list: the same for `--skip-tags`
  --coverage    exit non-zero if any include in the roles has no check function
  --only        run only the given check; repeatable
EOF
}
```

In `main`, replace everything from `local list_only=0 ...` through the line `if [ "$list_only" -eq 1 ]; then printf '%s\n' "${selected[@]}"; exit 0; fi` with:

```bash
  local list_only=0 do_coverage=0 tags_given=0 opt_tags="" opt_skip=""
  local only=() selected=() role name tags item fn o lines
  while [ $# -gt 0 ]; do
    case "$1" in
      --list) list_only=1 ;;
      --coverage) do_coverage=1 ;;
      --only)
        [ $# -ge 2 ] || { echo "--only needs a value" >&2; exit 2; }
        only+=("$2"); shift ;;
      --tags)
        [ $# -ge 2 ] || { echo "--tags needs a value" >&2; exit 2; }
        tags_given=1; opt_tags="$2"; shift ;;
      --skip-tags)
        [ $# -ge 2 ] || { echo "--skip-tags needs a value" >&2; exit 2; }
        tags_given=1; opt_skip="$2"; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done

  if [ "$do_coverage" -eq 1 ]; then coverage; exit $?; fi
  if [ "$tags_given" -eq 1 ] && [ "$list_only" -eq 0 ]; then
    echo "--tags and --skip-tags only work with --list" >&2
    exit 2
  fi

  ANSIBLE_TAGS=""
  ANSIBLE_SKIP_TAGS=""
  if [ "$tags_given" -eq 1 ]; then
    ANSIBLE_TAGS="$opt_tags"
    ANSIBLE_SKIP_TAGS="$opt_skip"
  elif [ -f "$BUILD_INFO" ]; then
    # shellcheck source=/dev/null
    source "$BUILD_INFO"
  fi

  for role in "${ROLES[@]}"; do
    lines="$(role_includes "$role")" || exit 1
    while read -r name tags; do
      [ -n "$name" ] || continue
      excluded "$role" "$name" && continue
      tags_select "$tags" "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS" || continue
      selected+=("$role/$name")
    done <<<"$lines"
  done
  # Explicit tags may select nothing (provision.sh reports that itself); an
  # image with nothing to check is an error.
  if [ ${#selected[@]} -eq 0 ] && [ "$tags_given" -eq 0 ]; then
    echo "# error: no checks selected" >&2
    exit 1
  fi

  if [ ${#only[@]} -gt 0 ]; then
    for o in "${only[@]}"; do
      printf '%s\n' "${selected[@]}" | grep -qxF -- "$o" || { echo "not selected in this image: $o" >&2; exit 2; }
    done
    selected=("${only[@]}")
  fi

  if [ "$list_only" -eq 1 ]; then
    if [ ${#selected[@]} -gt 0 ]; then printf '%s\n' "${selected[@]}"; fi
    exit 0
  fi
```

The rest of `main` (`use_zsh_path` and the check loop) stays.

- [ ] **Step 5: Run the checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh && host_copy
bash -n docker/test.sh && echo syntax-ok
list | wc -l
list --tags software_packages,yq,eza,zsh,neovim,neovim-config,docker | tr '\n' ' '; echo
list --tags neovim
list --skip-tags config | wc -l
list --skip-tags config | grep -c '^config/'
list --skip-tags eza | grep -cx config/zsh
list --tags no-such-tag | wc -l; echo "rc=${PIPESTATUS[0]}"
printf 'ANSIBLE_TAGS=neovim\n' > "$PV/home/docker/build-info.env"
list | tr '\n' ' '; echo
list --tags '' | wc -l
PROVEASIO_HOME="$PV/home" bash docker/test.sh --tags neovim; echo "rc=$?"
PROVEASIO_HOME="$PV/home" bash docker/test.sh --coverage | tail -n 1
```

Expected, in order: `syntax-ok`, `54`, `software/packages software/yq software/eza software/zsh software/docker software/neovim config/zsh config/p10k config/neovim-config`, `software/neovim`, `45`, `0`, `1`, `0` and `rc=0`, `software/neovim`, `54`, `--tags and --skip-tags only work with --list` and `rc=2`, `# 54 includes, 0 without a check`.

Optional: `~/.local/share/astronvim/mason/bin/shellcheck docker/test.sh`; fix findings on the changed lines, report the rest.

- [ ] **Step 6: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

No separate commit; Task 4 includes this change.

---

### Task 4: `docker/provision.sh` (full mode) and the required-task check

**Files:**
- Create: `docker/provision.sh` (mode 0755)
- Modify: `docker/Dockerfile:85-148` (the REFRESH args and the playbook RUN)
- Modify: `docker/render-overrides.sh` (no build info; header comment)
- Modify: `docker/cleanup.sh:4,11-12`, `docker/nvim-install.lua:2-4` (header comments)
- Modify: `docs-web/docs/main/docker/20-customize.md` (Turning tools off, Tags), `AGENTS.md` (Docker image section)

**Interfaces:**
- Consumes: `test.sh --list --tags/--skip-tags` (Task 3); the required set (Task 2).
- Produces: `docker/provision.sh` reads env `PROVEASIO_HOME` (default `$HOME/proveasio`), `DOCKER_DIR` (`/tmp/proveasio-docker`), `NVIM_CONFIG_DIR` (`/tmp/nvim-config`), `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `REFRESH`, `PROFILE` (default `full`). It writes `$PROVEASIO_HOME/docker/build-info.env` with `PROFILE`, `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `REFRESH`, `BUILD_DATE`, `UPDATES=()`. Functions Task 7 reuses: `die`, `selection`, `render`, `run_playbook`, `zsh_path`, `nvim_install`, `cleanup`, `warm_zsh`.
- Produces: `render-overrides.sh` no longer writes `build-info.env`.

- [ ] **Step 1: Write the failing check**

```bash
cd /home/ziwi/projects/proveasio
bash docker/provision.sh; echo "rc=$?"
```

Expected now: `bash: docker/provision.sh: No such file or directory`, `rc=127`.

- [ ] **Step 2: Create `docker/provision.sh`**

```bash
#!/usr/bin/env bash
# Playbook step of a Proveasio image build.
#
# docker/Dockerfile runs it in the RUN step of the `build` stage. It is
# bind-mounted with the rest of docker/ at DOCKER_DIR, so it is not part of
# the image. Steps: render ansible/vars/overrides.yml, stop when the tags or
# excludes leave out a task every image needs, write docker/build-info.env,
# upgrade the Ubuntu packages, run the playbook, install Mason tools and
# treesitter parsers, remove build leftovers, and start zsh once.
#
# It runs render-overrides.sh and cleanup.sh, so it refuses to run unless
# PROVEASIO_IMAGE_BUILD=1. docker/Dockerfile sets it for this one command.
# Never set it on a workstation.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "provision: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi
# The opt-in goes to render-overrides.sh and cleanup.sh only, not to the playbook.
unset PROVEASIO_IMAGE_BUILD

if [ $# -gt 0 ]; then
  echo "usage: provision.sh" >&2
  exit 2
fi

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"
ANSIBLE_DIR="$PROVEASIO_HOME/ansible"
OVERRIDES="$ANSIBLE_DIR/vars/overrides.yml"
BUILD_INFO="$PROVEASIO_HOME/docker/build-info.env"
ANSIBLE_TAGS="${ANSIBLE_TAGS:-}"
ANSIBLE_SKIP_TAGS="${ANSIBLE_SKIP_TAGS:-}"
PROFILE="${PROFILE:-full}"
# The includes every new image needs (docs-web/docs/main/docker/20-customize.md).
REQUIRED=(software/packages software/yq software/zsh config/zsh)

die() {
  echo "provision: $*" >&2
  exit 1
}

# selection <tags> <skip-tags>: the includes these tags run, minus the
# excludes of the rendered overrides, one "<role>/<name>" per line.
selection() {
  PROVEASIO_HOME="$PROVEASIO_HOME" bash "$DOCKER_DIR/test.sh" --list --tags "$1" --skip-tags "$2"
}

# render: write ansible/vars/overrides.yml (docker/render-overrides.sh).
render() {
  PROVEASIO_IMAGE_BUILD=1 PROVEASIO_HOME="$PROVEASIO_HOME" DOCKER_DIR="$DOCKER_DIR" \
    NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" PROFILE="$PROFILE" \
    bash "$DOCKER_DIR/render-overrides.sh"
}

# check_required: stop before the playbook when a new image would miss a
# required include. The playbook alone would fail much later, in the tests.
check_required() {
  local selected r missing=()
  selected="$(selection "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS")" || die "docker/test.sh --list failed"
  for r in "${REQUIRED[@]}"; do
    grep -qxF -- "$r" <<<"$selected" || missing+=("$r")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    die "a new image needs ${missing[*]}, but ANSIBLE_TAGS='$ANSIBLE_TAGS' ANSIBLE_SKIP_TAGS='$ANSIBLE_SKIP_TAGS' or the excludes in docker/overrides.yml leave them out. To leave tools out, exclude them in docker/overrides.yml."
  fi
}

# write_build_info: what docker/test.sh needs to select the checks of this image.
write_build_info() {
  mkdir -p "$(dirname "$BUILD_INFO")"
  {
    printf 'PROFILE=%q\n' "$PROFILE"
    printf 'ANSIBLE_TAGS=%q\n' "$ANSIBLE_TAGS"
    printf 'ANSIBLE_SKIP_TAGS=%q\n' "$ANSIBLE_SKIP_TAGS"
    printf 'REFRESH=%q\n' "${REFRESH:-}"
    printf 'BUILD_DATE=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'UPDATES=()\n'
  } > "$BUILD_INFO"
}

run_playbook() {
  local args=()
  if [ -n "$ANSIBLE_TAGS" ]; then args+=(--tags "$ANSIBLE_TAGS"); fi
  if [ -n "$ANSIBLE_SKIP_TAGS" ]; then args+=(--skip-tags "$ANSIBLE_SKIP_TAGS"); fi
  # Ansible ignores ansible.cfg in a world-writable current directory, which is
  # what COPY produces from a checkout under /mnt/c. ANSIBLE_CONFIG always loads it.
  (cd "$ANSIBLE_DIR" && ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" \
    ansible-playbook -i inventory.yml setup-ubuntu.yml "${args[@]}")
}

# zsh_path: the PATH of an interactive zsh, read the way docker/test.sh's
# use_zsh_path does. nvm, gvm and rvm add to PATH only there. Prints nothing
# when zsh is missing or the PATH looks wrong. GITHUB_TOKEN is only for the
# playbook's version lookups, so zsh runs without it.
zsh_path() {
  local p=""
  if [ -f "$HOME/.zshrc" ] && command -v zsh >/dev/null 2>&1; then
    p="$(env -u GITHUB_TOKEN TERM=xterm-256color timeout 60 script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)" || p=""
  fi
  case "$p" in */usr/bin*) printf '%s' "$p" ;; esac
}

# nvim_install: Mason and treesitter install in the background, so the role's
# headless `nvim +q` can exit before they finish. nvim-install.lua starts them
# and waits; it skips what the config does not use. It runs under pcall so
# that a missing or broken helper fails the build instead of exiting 0.
# Mason installs some packages with npm, go or gem, so nvim gets the zsh PATH.
# Mason sets GOBIN and GEM_HOME itself; PATH is the only variable it needs.
nvim_install() {
  local app nvim_path lua
  app="$(yq -r '.neovim_config_appname // ""' "$OVERRIDES")"
  if [ -z "$app" ]; then app="$(yq -r '.neovim_config_appname' "$ANSIBLE_DIR/roles/config/vars/main.yml")"; fi
  if ! command -v nvim >/dev/null 2>&1 || [ ! -d "$HOME/.config/$app" ]; then return 0; fi
  nvim_path="$(zsh_path)"
  if [ -z "$nvim_path" ]; then
    echo "WARNING: could not read PATH from zsh; nvim uses the build PATH, so Mason packages that need npm, go or gem fail" >&2
    nvim_path="$PATH"
  fi
  printf -v lua 'lua local ok, err = pcall(dofile, "%s/nvim-install.lua") if not ok then io.stderr:write("\\n" .. tostring(err) .. "\\n") vim.cmd("cquit 1") end' "$DOCKER_DIR"
  env -u GITHUB_TOKEN PATH="$nvim_path" NVIM_APPNAME="$app" timeout 1800 nvim --headless -c "$lua" -c 'qa'
}

cleanup() {
  PROVEASIO_IMAGE_BUILD=1 bash "$DOCKER_DIR/cleanup.sh"
}

# warm_zsh: the first interactive zsh start downloads gitstatusd for p10k and
# builds caches, so containers can start without network access. p10k fetches
# gitstatusd before the first prompt, so the shell has to draw one
# (`zsh -i -c exit` does not); `exit` on stdin then ends it.
warm_zsh() {
  if [ -f "$HOME/.zshrc" ]; then
    env -u GITHUB_TOKEN TERM=xterm-256color POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true \
      timeout 300 script -qec 'zsh -i' /dev/null <<<'exit'
  fi
}

echo "provision: PROFILE=$PROFILE REFRESH=${REFRESH:-} ANSIBLE_TAGS=$ANSIBLE_TAGS ANSIBLE_SKIP_TAGS=$ANSIBLE_SKIP_TAGS"
render
check_required
write_build_info
sudo apt-get update
sudo apt-get -y upgrade
run_playbook
nvim_install
cleanup
warm_zsh
```

```bash
chmod 0755 docker/provision.sh
```

- [ ] **Step 3: Dockerfile RUN step**

Replace lines 85-148 of `docker/Dockerfile` (from `# Everything below re-runs when REFRESH changes.` through the `EOF` that closes the playbook heredoc) with:

```dockerfile
# Everything below re-runs when REFRESH changes. docker-bake.hcl sets it to the
# current time by default, so every build resolves `latest` again.
ARG REFRESH=manual
ARG ANSIBLE_TAGS=""
ARG ANSIBLE_SKIP_TAGS=""

# docker/provision.sh renders the overrides, checks the tags, runs the
# playbook, installs Mason tools and treesitter parsers, removes build
# leftovers and warms zsh. docker/ is bind-mounted, so the scripts are not
# part of the image.
RUN --mount=type=bind,source=docker,target=/tmp/proveasio-docker \
    --mount=type=bind,from=nvim-config,target=/tmp/nvim-config \
    --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
    PROVEASIO_IMAGE_BUILD=1 bash /tmp/proveasio-docker/provision.sh
```

- [ ] **Step 4: `render-overrides.sh` without build info, comments**

In `docker/render-overrides.sh`:
- Line 4: `# Runs in the playbook RUN step of docker/Dockerfile. Inputs are the committed` becomes `# docker/provision.sh runs it in the playbook step. Inputs are the committed`.
- Line 12: `# PROVEASIO_IMAGE_BUILD=1. docker/Dockerfile sets it for this one command.` becomes `# PROVEASIO_IMAGE_BUILD=1. docker/provision.sh sets it for this one command.`
- Delete line 28 `build_info="$PROVEASIO_HOME/docker/build-info.env"`.
- Line 65 `mkdir -p "$(dirname "$target")" "$(dirname "$build_info")"` becomes `mkdir -p "$(dirname "$target")"`.
- Delete lines 67-73 (the blank line and the `{ printf 'ANSIBLE_TAGS=... } > "$build_info"` block).

In `docker/cleanup.sh`:
- Line 4: `# Runs at the end of the playbook RUN step in docker/Dockerfile. It has to run` becomes `# docker/provision.sh runs it at the end of the playbook RUN step. It has to run`.
- Line 11: `# refuses to run unless PROVEASIO_IMAGE_BUILD=1. docker/Dockerfile sets it.` becomes `# refuses to run unless PROVEASIO_IMAGE_BUILD=1. docker/provision.sh sets it.`

In `docker/nvim-install.lua`, lines 2-4:

```lua
-- for them to finish. docker/provision.sh runs it in the playbook step with
-- `dofile` inside `pcall`, so a missing file or a load error also fails:
--   NVIM_APPNAME=<app> nvim --headless -c 'lua ... pcall(dofile, ...) ...' -c qa
```

- [ ] **Step 5: Static checks**

```bash
cd /home/ziwi/projects/proveasio
bash docker/provision.sh; echo "rc=$?"
bash -n docker/provision.sh && bash -n docker/render-overrides.sh && bash -n docker/cleanup.sh && echo syntax-ok
grep -c build_info docker/render-overrides.sh
docker buildx bake --print image 2>/dev/null | jq -c '.target.image | {target, args, tags}'
```

Expected: `provision: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)`, `rc=2`; `syntax-ok`; `0`; `{"target":"final","args":{...ANSIBLE_SKIP_TAGS:"",ANSIBLE_TAGS:"",REFRESH:"<timestamp>",UBUNTU_VERSION:"24.04",USERNAME:"dev",USER_GID:"1000",USER_UID:"1000"},"tags":["proveasio:local"]}`.

Optional: `~/.local/share/astronvim/mason/bin/shellcheck docker/provision.sh` prints no errors (warnings are reported, not gated).

- [ ] **Step 6: Smoke build**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
mem_ok && time (ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke \
  docker buildx bake --progress=plain > "$PV/smoke.log" 2>&1); echo "rc=$?"
grep -E 'provision: PROFILE|# [0-9]+ selected|nvim-install: mason' "$PV/smoke.log"
```

Expected: `mem_ok: ...` line; `rc=0`; `provision: PROFILE=full ...`, `nvim-install: mason: ... failed: ...` (13 Mason failures are expected for this tag set), `# 9 selected, 9 passed, 0 failed`. Record the real time.

`/tmp/opencode/pv/image-info.sh`:

```bash
# Runs in a container: build info, eza completion link and zsh completion.
set -uo pipefail
cat "$HOME/proveasio/docker/build-info.env"
echo "zfunc: $(readlink "$HOME/.zfunc/_eza" || echo missing)"
echo "completion: $(timeout 60 script -qec 'zsh -i -c "print -r -- \${_comps[eza]}"' /dev/null </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)"
```

```bash
in_image proveasio:smoke image-info.sh
```

Expected: `PROFILE=full`, `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker`, `ANSIBLE_SKIP_TAGS=''`, `REFRESH=...`, `BUILD_DATE=...`, `UPDATES=()`, `zfunc: /home/dev/.local/opt/eza-<version>/_eza`, `completion: _eza`.

- [ ] **Step 7: Early failures**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
mem_ok && { ANSIBLE_TAGS=neovim IMAGE=proveasio:fail docker buildx bake --progress=plain > "$PV/fail1.log" 2>&1; echo "rc=$?"; grep -m1 'provision: a new image needs' "$PV/fail1.log"; }
mem_ok && { ANSIBLE_SKIP_TAGS=config IMAGE=proveasio:fail docker buildx bake --progress=plain > "$PV/fail2.log" 2>&1; echo "rc=$?"; grep -m1 'provision: a new image needs' "$PV/fail2.log"; }
printf 'software_tasks_exclude:\n  - zsh\n' > docker/overrides.yml
mem_ok && { IMAGE=proveasio:fail docker buildx bake --progress=plain > "$PV/fail3.log" 2>&1; echo "rc=$?"; grep -m1 'provision: a new image needs' "$PV/fail3.log"; }
rm -f docker/overrides.yml
docker image ls -q proveasio:fail | wc -l
```

Expected: each run `rc=1` and a line naming the missing includes: run 1 `software/packages software/yq software/zsh config/zsh`, run 2 `config/zsh`, run 3 `software/zsh`. Each fails within about a minute (bootstrap layers are cached). Final line `0` (no image was loaded). `docker/overrides.yml` is gone.

- [ ] **Step 8: Docs and AGENTS.md**

`docs-web/docs/main/docker/20-customize.md`, Turning tools off: replace

```
`packages`, `yq` and `zsh` cannot be excluded, as on a native run. The
playbook stops at its first tasks when `docker/overrides.yml` excludes one.
```

with

```
`packages`, `yq` and `zsh` cannot be excluded, as on a native run. The build
stops before the playbook runs when `docker/overrides.yml` excludes one.
```

Tags section: replace

```
Do not skip the tags `zsh` or `config`. Both skip the zsh configuration task,
and the image tests then fail.

`--tags` builds an image from scratch with only the selected tasks, so it has
to include what those tasks depend on. For example, `ANSIBLE_TAGS=neovim`
alone fails, because the version lookups need `curl` and `jq` from
`software_packages`. Excludes are the better way to leave tools out. The tag
list is in [Partial run](../customization/partial-run).
```

with

```
`--tags` builds an image from scratch with only the selected tasks. A new
image needs the package, yq and zsh tasks, including the zsh configuration.
The build stops before the playbook runs when the tags leave one of them out,
and names the missing tasks. For example, `ANSIBLE_TAGS=neovim` stops, and so
does `ANSIBLE_SKIP_TAGS=config`, because it also skips the zsh configuration.
Excludes are the better way to leave tools out. The tag list is in
[Partial run](../customization/partial-run).
```

`AGENTS.md`, Docker image section: after the `- Inputs: ...` bullet add

```
- `docker/provision.sh` is the playbook step (bind-mounted with `docker/`, not in the image):
  render the overrides; stop when the tags or excludes leave out `software/packages`,
  `software/yq`, `software/zsh` or `config/zsh` (it asks `docker/test.sh --list --tags ...`);
  write `docker/build-info.env`; apt upgrade; playbook; `nvim-install.lua`; `cleanup.sh`;
  zsh warm-up.
```

and in the `docker/cleanup.sh` bullet replace

```
  "already installed" gates. It exits 2 unless `PROVEASIO_IMAGE_BUILD=1`, which the Dockerfile
  sets on that one command. Never set it on a workstation.
```

with

```
  "already installed" gates. It exits 2 unless `PROVEASIO_IMAGE_BUILD=1`. The Dockerfile sets
  it on `provision.sh`, which unsets it and passes it only to `render-overrides.sh` and
  `cleanup.sh`. Never set it on a workstation.
```

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm run build 2>&1 | tail -n 3
```

Expected: `[SUCCESS] Generated static files in "build".`

- [ ] **Step 9: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Suggested commit: `feat(docker): Move the playbook step into provision.sh and stop early without required tasks` (includes Task 3).

---

### Task 5: Profiles, the slim profile and `*_tasks_include`

**Files:**
- Create: `docker/profile-slim.yml`
- Modify: `docker/render-overrides.sh` (whole file below)
- Modify: `docker/Dockerfile` (one `ARG` after `ARG ANSIBLE_SKIP_TAGS=""`)
- Modify: `docker-bake.hcl` (header, `PROFILE`, `IMAGE`, `_common.args`)
- Modify: `docs-web/docs/main/docker/10-build.md`, `docs-web/docs/main/docker/20-customize.md`, `docs-web/docs/main/docker/40-limitations.md`, `AGENTS.md`

**Interfaces:**
- Consumes: `provision.sh` passes `PROFILE` to `render-overrides.sh` and writes it to `build-info.env` (Task 4).
- Produces: `render-overrides.sh` env `PROFILE`; keys `software_tasks_include`, `config_tasks_include` in `docker/overrides.yml`; Bake variable `PROFILE`; build arg `PROFILE`.

- [ ] **Step 1: Write the failing checks**

`/tmp/opencode/pv/render-case.sh`:

```bash
# Runs in a proveasio:local container. Usage: render-case.sh <PROFILE> [overrides file under /t]
# Renders with the working tree's render-overrides.sh into /tmp/t and prints
# the resulting excludes and the number of checks test.sh would select.
set -euo pipefail
T=/tmp/t
rm -rf "$T"
mkdir -p "$T/home" "$T/dd"
cp -r /repo/ansible "$T/home/"
rm -f "$T/home/ansible/vars/overrides.yml"
cp /repo/docker/profile*.yml "$T/dd/"
if [ -n "${2:-}" ]; then cp "/t/$2" "$T/dd/overrides.yml"; fi
PROVEASIO_IMAGE_BUILD=1 PROVEASIO_HOME="$T/home" DOCKER_DIR="$T/dd" NVIM_CONFIG_DIR="$T/none" \
  PROFILE="$1" bash /repo/docker/render-overrides.sh > "$T/render.log"
grep -E 'profile |_tasks_include:' "$T/render.log" || true
out="$T/home/ansible/vars/overrides.yml"
echo "software: $(yq -r '(.software_tasks_exclude // []) | join(" ")' "$out")"
echo "config: $(yq -r '(.config_tasks_exclude // []) | join(" ")' "$out")"
echo "include keys: $(yq -r '[keys[] | select(test("_tasks_include$"))] | length' "$out")"
echo "selected: $(PROVEASIO_HOME="$T/home" bash /repo/docker/test.sh --list --tags '' --skip-tags '' | wc -l)"
```

Case files in `/tmp/opencode/pv/`:

```yaml
# ov-az.yml
software_tasks_include:
  - azurecli
  - az-account-switcher
```

```yaml
# ov-sdkman.yml
software_tasks_include:
  - sdkman
config_tasks_include:
  - sdkman
```

```yaml
# ov-typo.yml
software_tasks_include:
  - azcli
```

```yaml
# ov-string.yml
software_tasks_include: azurecli
```

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
in_image proveasio:local render-case.sh slim; echo "rc=$?"
in_image proveasio:local render-case.sh slim ov-az.yml; echo "rc=$?"
```

Expected now: `software: w32yank wsl-notify-send`, `selected: 52`, `rc=0` (the profile is ignored), then the same with `include keys: 1`.

- [ ] **Step 2: Create `docker/profile-slim.yml`**

```yaml
# Slim image profile (PROFILE=slim). docker/render-overrides.sh merges it
# after docker/profile.yml and before docker/overrides.yml; lists append.
# It leaves out the largest tools that nothing else in the image needs.
#
# nvm, gvm and rvm stay: the default Neovim config installs Mason packages
# with npm (yaml, json, bash and ansible language servers), go (gopls, delve
# and other Go tools) and gem (solargraph, standardrb), and
# mason-tool-installer retries missing packages on every Neovim start.
# roles/software/tasks/ansible.yml also installs the Ansible language server
# with nvm's npm.
#
# To add a tool back, list it in software_tasks_include (and
# config_tasks_include for sdkman) in docker/overrides.yml.
software_tasks_exclude:
  - sdkman
  - azurecli
  - az-account-switcher
  - rust
  - puppet
  - awscli
# The config task writes ~/.sdkman/etc/config, which needs SDKMAN.
config_tasks_exclude:
  - sdkman
```

- [ ] **Step 3: Replace `docker/render-overrides.sh`**

```bash
#!/usr/bin/env bash
# Build the effective ansible/vars/overrides.yml for a Docker image build.
#
# docker/provision.sh runs it in the playbook step. Inputs, bind-mounted at
# DOCKER_DIR, merged in this order: the committed docker/profile.yml,
# docker/profile-<PROFILE>.yml unless PROFILE is "full", and the optional,
# gitignored docker/overrides.yml. Maps merge recursively and lists are
# appended. Then software_tasks_include and config_tasks_include take names
# out of software_tasks_exclude and config_tasks_exclude. The nvim-config
# build context at NVIM_CONFIG_DIR switches the Neovim config to that
# directory. The roles then merge github_packages, pip_packages and
# docker_apt_packages with their defaults per key; every other variable
# replaces the role default.
#
# It overwrites ansible/vars/overrides.yml, so it refuses to run unless
# PROVEASIO_IMAGE_BUILD=1. docker/provision.sh sets it for this one command.
# Never set it on a workstation: there it would replace your own overrides.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "render-overrides: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"
PROFILE="${PROFILE:-full}"

profile="$DOCKER_DIR/profile.yml"
user_overrides="$DOCKER_DIR/overrides.yml"
target="$PROVEASIO_HOME/ansible/vars/overrides.yml"

if [ ! -f "$profile" ]; then
  echo "render-overrides: missing $profile" >&2
  exit 1
fi
if ! [[ "$PROFILE" =~ ^[a-z0-9-]+$ ]]; then
  echo "render-overrides: invalid PROFILE '$PROFILE' (use lowercase letters, digits and dashes)" >&2
  exit 1
fi

inputs=("$profile")
if [ "$PROFILE" != full ]; then
  if [ ! -f "$DOCKER_DIR/profile-$PROFILE.yml" ]; then
    available=full
    for f in "$DOCKER_DIR"/profile-*.yml; do
      [ -e "$f" ] || continue
      f="${f##*/profile-}"
      available+=" ${f%.yml}"
    done
    echo "render-overrides: no docker/profile-$PROFILE.yml. Profiles: $available" >&2
    exit 1
  fi
  inputs+=("$DOCKER_DIR/profile-$PROFILE.yml")
  echo "render-overrides: profile $PROFILE (docker/profile-$PROFILE.yml)"
fi
if [ -f "$user_overrides" ]; then
  inputs+=("$user_overrides")
  echo "render-overrides: merging docker/overrides.yml"
else
  echo "render-overrides: no docker/overrides.yml"
fi

merged="$(yq eval-all '. as $i ireduce ({}; . *+ $i)' "${inputs[@]}")"

# The merged file stays in the image, so a token must never be written to it.
# The delete is unconditional so that a failing check cannot leave it in.
if [ "$(yq 'has("github_api_token")' <<<"$merged")" = true ]; then
  echo "render-overrides: WARNING: removed github_api_token. Pass the token as the GITHUB_TOKEN build secret instead." >&2
fi
merged="$(yq 'del(.github_api_token)' <<<"$merged")"

# role_includes <role>: the include names of roles/<role>/tasks/main.yml,
# which are the names <role>_tasks_exclude uses.
role_includes() {
  yq -r '.[] | select(has("ansible.builtin.include_tasks")) | .["ansible.builtin.include_tasks"].file | sub("\.yml$"; "")' \
    "$PROVEASIO_HOME/ansible/roles/$1/tasks/main.yml"
}

# apply_includes <role>: take the names in <role>_tasks_include out of
# <role>_tasks_exclude, then drop <role>_tasks_include. An unknown name fails;
# a name that is not excluded is reported, so one docker/overrides.yml works
# with every profile.
apply_includes() {
  local inc="${1}_tasks_include" exc="${1}_tasks_exclude" kind valid names excluded name
  kind="$(KEY="$inc" yq '.[strenv(KEY)] | type' <<<"$merged")"
  case "$kind" in
    '!!null') return 0 ;;
    '!!seq') ;;
    *) echo "render-overrides: $inc must be a list" >&2; exit 1 ;;
  esac
  if ! valid="$(role_includes "$1")" || [ -z "$valid" ]; then
    echo "render-overrides: cannot read the includes of roles/$1/tasks/main.yml" >&2
    exit 1
  fi
  names="$(KEY="$inc" yq -r '.[strenv(KEY)][]' <<<"$merged")"
  excluded="$(KEY="$exc" yq -r '(.[strenv(KEY)] // [])[]' <<<"$merged")"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if ! grep -qxF -- "$name" <<<"$valid"; then
      echo "render-overrides: $inc: unknown name '$name'. Valid names: $(tr '\n' ' ' <<<"$valid")" >&2
      exit 1
    fi
    if grep -qxF -- "$name" <<<"$excluded"; then
      echo "render-overrides: $inc: $name is no longer excluded"
    else
      echo "render-overrides: $inc: $name is not excluded, nothing to do"
    fi
  done <<<"$names"
  merged="$(INC="$inc" EXC="$exc" yq '.[strenv(EXC)] = ((.[strenv(EXC)] // []) - .[strenv(INC)]) | del(.[strenv(INC)])' <<<"$merged")"
}
apply_includes software
apply_includes config

# A directory that exists but cannot be listed is an error: falling back to
# the git config would build an image without the config the user asked for.
if [ -d "$NVIM_CONFIG_DIR" ]; then
  if ! nvim_entries="$(ls -A "$NVIM_CONFIG_DIR")"; then
    echo "render-overrides: cannot list $NVIM_CONFIG_DIR (the nvim-config build context)" >&2
    exit 1
  fi
  if [ -n "$nvim_entries" ]; then
    echo "render-overrides: using the local Neovim config from the nvim-config build context"
    merged="$(NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" yq '.neovim_config_source = "local" | .neovim_config_local_path = strenv(NVIM_CONFIG_DIR)' <<<"$merged")"
  fi
fi

mkdir -p "$(dirname "$target")"
printf '%s\n' "$merged" > "$target"

echo "render-overrides: effective overrides ($target):"
sed 's/^/  /' "$target"
```

- [ ] **Step 4: Dockerfile and Bake**

`docker/Dockerfile`, after `ARG ANSIBLE_SKIP_TAGS=""` (added in Task 4):

```dockerfile
# docker/profile-<PROFILE>.yml is merged unless PROFILE is "full".
ARG PROFILE=full
```

`docker-bake.hcl`:
- Header: after the line `#   docker buildx bake                          build, test and load proveasio:local` add `#   PROFILE=slim docker buildx bake             the slim image, loaded as proveasio:slim`.
- After `variable "ANSIBLE_SKIP_TAGS" { ... }` add:

```hcl
# docker/profile-<PROFILE>.yml is merged unless PROFILE is "full".
variable "PROFILE" {
  default = "full"
}
```

- Replace `variable "IMAGE" { default = "proveasio:local" }` with:

```hcl
# proveasio:local for the full profile, proveasio:<PROFILE> for the others.
variable "IMAGE" {
  default = PROFILE == "full" ? "proveasio:local" : "proveasio:${PROFILE}"
}
```

- In `target "_common"` `args`, add `PROFILE           = PROFILE` after `ANSIBLE_SKIP_TAGS = ANSIBLE_SKIP_TAGS`.

- [ ] **Step 5: Run the render and Bake checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
bash -n docker/render-overrides.sh && echo syntax-ok
for c in "slim" "slim ov-az.yml" "slim ov-sdkman.yml" "full" "full ov-az.yml" "slim ov-typo.yml" "slim ov-string.yml" "nope" "Bad_Name"; do
  echo "== $c"; in_image proveasio:local render-case.sh $c; echo "rc=$?"
done 2>&1
docker buildx bake --print image 2>/dev/null | jq -c '.target.image | {tags, profile: .args.PROFILE}'
PROFILE=slim docker buildx bake --print image receipt 2>/dev/null | jq -c '[.target.image.tags, .target.image.args.PROFILE, .target.receipt.args.PROFILE]'
PROFILE=slim IMAGE=me/x:y docker buildx bake --print image 2>/dev/null | jq -c '.target.image.tags'
```

Expected:

| Case | Output |
|---|---|
| `slim` | `render-overrides: profile slim (docker/profile-slim.yml)`, `software: w32yank wsl-notify-send sdkman azurecli az-account-switcher rust puppet awscli`, `config: sdkman`, `include keys: 0`, `selected: 45`, `rc=0` |
| `slim ov-az.yml` | two `... is no longer excluded` lines, `software: w32yank wsl-notify-send sdkman rust puppet awscli`, `config: sdkman`, `include keys: 0`, `selected: 47`, `rc=0` |
| `slim ov-sdkman.yml` | `software: w32yank wsl-notify-send azurecli az-account-switcher rust puppet awscli`, `config: ` (empty), `selected: 47`, `rc=0` |
| `full` | `software: w32yank wsl-notify-send`, `config: `, `selected: 52`, `rc=0` |
| `full ov-az.yml` | two `... is not excluded, nothing to do` lines, `selected: 52`, `rc=0` |
| `slim ov-typo.yml` | `render-overrides: software_tasks_include: unknown name 'azcli'. Valid names: packages yq fx ...`, `rc=1` |
| `slim ov-string.yml` | `render-overrides: software_tasks_include must be a list`, `rc=1` |
| `nope` | `render-overrides: no docker/profile-nope.yml. Profiles: full slim`, `rc=1` |
| `Bad_Name` | `render-overrides: invalid PROFILE 'Bad_Name' ...`, `rc=1` |

Bake: `{"tags":["proveasio:local"],"profile":"full"}`, `[["proveasio:slim"],"slim","slim"]`, `["me/x:y"]`.

- [ ] **Step 6: Slim build**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
mem_ok && time (PROFILE=slim docker buildx bake --progress=plain > "$PV/slim.log" 2>&1); echo "rc=$?"
grep -E 'provision: PROFILE|render-overrides: profile|nvim-install: mason|cleanup: .* in total|# [0-9]+ selected' "$PV/slim.log"
sizes
```

Expected: `rc=0`; `provision: PROFILE=slim ...`; `render-overrides: profile slim (docker/profile-slim.yml)`; `nvim-install: mason: 40 packages installed` with no `failed:` part; `# 45 selected, 45 passed, 0 failed`; `proveasio:slim` about 5.7 GB. Record the time, the size and the cleanup total. If Mason reports failures, list them in the report; fix them only if this change caused them.

- [ ] **Step 7: Docs and AGENTS.md**

`docs-web/docs/main/docker/10-build.md`: insert after the paragraph that starts `A build took about 15 minutes` (before `## Getting the latest versions`), with `<size>` replaced by the size from Step 6 rounded to one decimal:

~~~markdown
## Slim image

The slim image leaves out SDKMAN (Java, Gradle, Groovy, Maven), Azure CLI,
az-account-switcher, Rust, Puppet and AWS CLI:

```shell
PROFILE=slim docker buildx bake
```

It is loaded as `proveasio:slim` and is about <size> GB. It keeps nvm, gvm and
rvm, because the default Neovim config installs language servers with npm, Go
and gem, and Neovim would otherwise try to install them again on every start.
The Java language server is installed but does not start, because the image
has no Java.

To add one of the left-out tools, see
[Adding tools back](./customize#adding-tools-back). The list is in
`docker/profile-slim.yml`.

Build the images one at a time. Two builds at once need twice the memory.
~~~

`docs-web/docs/main/docker/20-customize.md`: insert after the line `To change one of these for every build, edit \`docker/profile.yml\`.`:

~~~markdown

## Profiles

`PROFILE` selects an extra settings file, `docker/profile-<PROFILE>.yml`. The
build merges it after `docker/profile.yml` and before your
`docker/overrides.yml`, with the same rules. The default, `full`, uses no
extra file. The project has one profile, `slim` (see
[Slim image](./build#slim-image)).

```shell
PROFILE=slim docker buildx bake
```

The image is loaded as `proveasio:<PROFILE>` unless you set `IMAGE`. The
`full` image is `proveasio:local`. To make your own profile, create
`docker/profile-<name>.yml` in the same format and build with
`PROFILE=<name>`. Names use lowercase letters, digits and dashes.

## Adding tools back

The excludes of a profile are lists, and `docker/overrides.yml` can only add
to them. To take tools out of those lists again, name them in
`software_tasks_include` or `config_tasks_include`:

```yaml
software_tasks_include:
  - azurecli
  - az-account-switcher
```

```shell
PROFILE=slim IMAGE=proveasio:slim-az docker buildx bake
```

These keys only remove names from the excludes. They do not limit the build
to the named tools. The build stops on a name that is not a task and prints
the valid names. A name that is not excluded is reported and ignored, so the
same file works with every profile. The keys work only in Docker builds.

Add these tools back together:

- `sdkman` in both `software_tasks_include` and `config_tasks_include`,
- `azurecli` and `az-account-switcher`.
~~~

Build variables table: add after the `ANSIBLE_SKIP_TAGS` row

```
| `PROFILE` | `full` | Extra settings file `docker/profile-<PROFILE>.yml`, see [Profiles](#profiles). Also sets the default `IMAGE`. |
```

and replace the `IMAGE` row with

```
| `IMAGE` | `proveasio:local`, or `proveasio:<PROFILE>` for other profiles | Name of the loaded image. |
```

`docs-web/docs/main/docker/40-limitations.md`: replace

```
To make the image smaller, exclude what you do not need. See
[Turning tools off](./customize#turning-tools-off).
```

with (same `<size>` as above)

```
To make the image smaller, exclude what you do not need. See
[Turning tools off](./customize#turning-tools-off). The slim image leaves out
the largest tools that nothing else needs and is about <size> GB. See
[Slim image](./build#slim-image).
```

`AGENTS.md`, Docker image section: replace the `- Inputs: ...` bullet (5 lines) with

```
- Inputs, merged in this order by `docker/render-overrides.sh` (`yq *+`: maps merge, lists
  append): `docker/profile.yml` (committed container defaults), `docker/profile-<PROFILE>.yml`
  unless `PROFILE` is `full` (only `slim` is committed), and the gitignored
  `docker/overrides.yml`. Then `software_tasks_include`/`config_tasks_include` from
  `docker/overrides.yml` take names out of the exclude lists (Docker only; unknown names fail).
  The native `ansible/vars/overrides.yml` is excluded by `.dockerignore`. `render-overrides.sh`
  overwrites `ansible/vars/overrides.yml`, so it has the same `PROVEASIO_IMAGE_BUILD=1` opt-in
  as `cleanup.sh` below.
- The slim profile keeps nvm, gvm and rvm: the default Neovim config installs Mason packages
  with npm, go and gem, and mason-tool-installer retries missing ones on every start.
  `software/ansible.yml` also needs nvm (npm installs the Ansible language server).
```

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm run build 2>&1 | tail -n 3
```

Expected: `[SUCCESS] Generated static files in "build".`

- [ ] **Step 8: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Suggested commit (with Task 6): `feat(docker): Add image profiles, the slim image and *_tasks_include`

---

### Task 6: CI matrix for the slim image

**Files:**
- Modify: `.github/workflows/docker.yml` (header comment, job `image`)
- Modify: `docs-web/docs/main/docker/10-build.md` (Pre-built image)

**Interfaces:**
- Consumes: Bake variable `PROFILE` (Task 5).

- [ ] **Step 1: Header comment**

After the header bullet that ends with the line `#   and tests.` (line 9), add:

```yaml
# - The `image` job is a matrix over two profiles. `full` gets the tags above.
#   `slim` (PROFILE=slim, docker/profile-slim.yml) gets `slim` instead of
#   `latest` and a `-slim` suffix on the others.
```

- [ ] **Step 2: Job `image`**

Replace the job header (from `  image:` through the `env:` block with `REFRESH`) with:

```yaml
  image:
    name: "Build, test and publish (${{ matrix.profile }})"
    needs: plan
    if: needs.plan.outputs.build == 'true'
    runs-on: ubuntu-24.04
    timeout-minutes: 240
    strategy:
      # A failed slim build must not stop the full image from publishing.
      fail-fast: false
      matrix:
        include:
          - profile: full
            suffix: ""
            latest: latest
          - profile: slim
            suffix: "-slim"
            latest: slim
    env:
      # timestamp() in docker-bake.hcl changes per call; one value per run
      # keeps the receipt step on the cached build.
      REFRESH: ${{ github.run_id }}-${{ github.run_attempt }}
      # docker-bake.hcl reads PROFILE in both Bake steps below.
      PROFILE: ${{ matrix.profile }}
```

Replace the metadata `tags:` block with:

```yaml
          tags: |
            type=raw,value=${{ matrix.latest }},enable=${{ needs.plan.outputs.publish == 'true' && !startsWith(github.ref, 'refs/tags/') }}
            type=raw,value={{date 'YYYY-MM-DD'}}${{ matrix.suffix }},enable=${{ needs.plan.outputs.publish == 'true' && !startsWith(github.ref, 'refs/tags/') }}
            type=semver,pattern={{version}},suffix=${{ matrix.suffix }}
            type=semver,pattern={{major}}.{{minor}},suffix=${{ matrix.suffix }}
            type=sha,prefix=sha-,suffix=${{ matrix.suffix }},format=short
```

In `Version receipt summary`, replace `echo "### Versions in this image"` with `echo "### Versions in the $PROFILE image"`. In `actions/upload-artifact`, replace `name: current-versions` with `name: current-versions-${{ matrix.profile }}`.

- [ ] **Step 3: Check what can be checked locally**

```bash
cd /home/ziwi/projects/proveasio
yq -r '.jobs.image.strategy.matrix.include[] | .profile + " [" + .suffix + "] " + .latest' .github/workflows/docker.yml
yq -r '.jobs.image.env.PROFILE, .jobs.image.strategy["fail-fast"]' .github/workflows/docker.yml
yq -r '.jobs.image.steps[] | select(.uses == "actions/upload-artifact@v7") | .with.name' .github/workflows/docker.yml
command -v actionlint || echo "actionlint not installed: workflow syntax beyond YAML is unverified"
```

Expected: `full [] latest`, `slim [-slim] slim`; `${{ matrix.profile }}`, `false`; `current-versions-${{ matrix.profile }}`; the actionlint line.

- [ ] **Step 4: Docs**

`docs-web/docs/main/docker/10-build.md`, Pre-built image: after the line ```` docker pull CHANGEME/proveasio:latest ```` add `docker pull CHANGEME/proveasio:slim` inside the same code block, and after the `sha-<short>` table row add:

```
| `slim` | The newest slim build of `master`, rebuilt every week. See [Slim image](#slim-image). |
| `YYYY-MM-DD-slim`, `X.Y.Z-slim`, `X.Y-slim`, `sha-<short>-slim` | The slim image for each tag above. |
```

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm run build 2>&1 | tail -n 3
```

Expected: `[SUCCESS] Generated static files in "build".`

- [ ] **Step 5: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Report: the workflow changes are unverified until the workflow runs on GitHub.

---

### Task 7: The `update` target

**Files:**
- Modify: `docker/test.sh` (header comment, new `image_selects`, `main`)
- Modify: `docker/render-overrides.sh` (Neovim block, base carry-over)
- Modify: `docker/provision.sh` (whole file below)
- Modify: `docker/Dockerfile` (header, global args, stages after `build`)
- Modify: `docker-bake.hcl` (header, `BASE_IMAGE`, target `update`)
- Modify: `docs-web/docs/main/docker/10-build.md`, `docs-web/docs/main/docker/20-customize.md`, `docs-web/docs/main/docker/40-limitations.md`, `AGENTS.md`

**Interfaces:**
- Consumes: `tags_select` with three arguments (Task 3); `render`, `selection`, `run_playbook`, `nvim_install`, `cleanup`, `warm_zsh`, `write_build_info` (Task 4); `PROFILE` in `build-info.env` (Task 4); `*_tasks_include` (Task 5).
- Produces: `provision.sh --update`; `render-overrides.sh` env `PROVEASIO_BASE_OVERRIDES`; `UPDATES+=(...)` lines in `build-info.env`; Bake variable `BASE_IMAGE`, target `update`; Dockerfile args `BASE_IMAGE`, `PROVISIONED`, stages `update`, `provisioned`.

- [ ] **Step 1: Write the failing host checks**

Replace `/tmp/opencode/pv/render-case.sh` with (adds a third argument, the base overrides file):

```bash
# Runs in a proveasio:local container.
# Usage: render-case.sh <PROFILE> [overrides file under /t or ""] [base overrides file under /t]
set -euo pipefail
T=/tmp/t
rm -rf "$T"
mkdir -p "$T/home" "$T/dd"
cp -r /repo/ansible "$T/home/"
rm -f "$T/home/ansible/vars/overrides.yml"
cp /repo/docker/profile*.yml "$T/dd/"
if [ -n "${2:-}" ]; then cp "/t/$2" "$T/dd/overrides.yml"; fi
base=""
if [ -n "${3:-}" ]; then base="/t/$3"; fi
PROVEASIO_IMAGE_BUILD=1 PROVEASIO_HOME="$T/home" DOCKER_DIR="$T/dd" NVIM_CONFIG_DIR="$T/none" \
  PROFILE="$1" PROVEASIO_BASE_OVERRIDES="$base" bash /repo/docker/render-overrides.sh > "$T/render.log"
grep -E 'profile |_tasks_include:|keeping' "$T/render.log" || true
out="$T/home/ansible/vars/overrides.yml"
echo "software: $(yq -r '(.software_tasks_exclude // []) | join(" ")' "$out")"
echo "config: $(yq -r '(.config_tasks_exclude // []) | join(" ")' "$out")"
echo "include keys: $(yq -r '[keys[] | select(test("_tasks_include$"))] | length' "$out")"
echo "nvim: $(yq -r '(.neovim_config_source // "git") + " " + (.neovim_config_local_path // "")' "$out")"
echo "selected: $(PROVEASIO_HOME="$T/home" bash /repo/docker/test.sh --list --tags '' --skip-tags '' | wc -l)"
```

`/tmp/opencode/pv/base-local.yml`:

```yaml
software_tasks_exclude:
  - w32yank
  - wsl-notify-send
neovim_config_source: local
neovim_config_local_path: /tmp/nvim-config
```

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh && host_copy
printf '%s\n' "ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker" "ANSIBLE_SKIP_TAGS=''" "UPDATES=()" > "$PV/home/docker/build-info.env"
list | wc -l
printf 'UPDATES+=(%q)\n' "2026-09-25T00:00:00Z|terraform|" >> "$PV/home/docker/build-info.env"
list | wc -l
in_image proveasio:local render-case.sh full "" base-local.yml | grep -E 'keeping|nvim:'
```

Expected now: `9`, `9` (updates ignored), `nvim: git ` (no carry-over).

- [ ] **Step 2: `test.sh` tests what the updates installed**

Replace the header lines added in Task 3

```bash
# ansible/vars/overrides.yml, filtered by the tags in docker/build-info.env
# (or by --tags/--skip-tags; docker/provision.sh uses those).
```

with

```bash
# ansible/vars/overrides.yml, filtered by the tags in docker/build-info.env:
# an include counts when the build's tags or the tags of any recorded update
# select it. --tags/--skip-tags replace all of those (docker/provision.sh
# uses them).
```

Insert after `tags_select`:

```bash
# image_selects <outer tags>: whether this image ran the include, because the
# tags of the build (ANSIBLE_TAGS, ANSIBLE_SKIP_TAGS) or of any update select
# it. UPDATES entries are "<date>|<tags>|<skip-tags>" (provision.sh --update).
image_selects() {
  local u rest
  if tags_select "$1" "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS"; then return 0; fi
  for u in "${UPDATES[@]}"; do
    rest="${u#*|}"
    if tags_select "$1" "${rest%%|*}" "${rest#*|}"; then return 0; fi
  done
  return 1
}
```

In `main`, replace

```bash
  ANSIBLE_TAGS=""
  ANSIBLE_SKIP_TAGS=""
```

with

```bash
  ANSIBLE_TAGS=""
  ANSIBLE_SKIP_TAGS=""
  UPDATES=()
```

and replace `      tags_select "$tags" "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS" || continue` with `      image_selects "$tags" || continue`.

- [ ] **Step 3: `render-overrides.sh` keeps a local Neovim config record**

Replace the Neovim block (from `# A directory that exists but cannot be listed is an error:` through its closing `fi`) with:

```bash
# A directory that exists but cannot be listed is an error: falling back to
# the git config would build an image without the config the user asked for.
nvim_local=0
if [ -d "$NVIM_CONFIG_DIR" ]; then
  if ! nvim_entries="$(ls -A "$NVIM_CONFIG_DIR")"; then
    echo "render-overrides: cannot list $NVIM_CONFIG_DIR (the nvim-config build context)" >&2
    exit 1
  fi
  if [ -n "$nvim_entries" ]; then
    nvim_local=1
    echo "render-overrides: using the local Neovim config from the nvim-config build context"
    merged="$(NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" yq '.neovim_config_source = "local" | .neovim_config_local_path = strenv(NVIM_CONFIG_DIR)' <<<"$merged")"
  fi
fi

# An update (docker/provision.sh --update) passes the image's previous
# overrides in PROVEASIO_BASE_OVERRIDES. When the image was built from a local
# Neovim config and this build has none, keep that record, so later updates
# and playbook runs in the container know where the config came from.
base="${PROVEASIO_BASE_OVERRIDES:-}"
if [ -n "$base" ] && [ "$nvim_local" -eq 0 ] && [ "$(yq -r '.neovim_config_source // ""' "$base")" = local ]; then
  base_path="$(yq -r '.neovim_config_local_path // ""' "$base")"
  echo "render-overrides: keeping the local Neovim config source of the base image"
  merged="$(BASE_PATH="$base_path" yq '.neovim_config_source = "local" | .neovim_config_local_path = strenv(BASE_PATH)' <<<"$merged")"
fi
```

- [ ] **Step 4: Run the host checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh && host_copy
bash -n docker/test.sh && bash -n docker/render-overrides.sh && echo syntax-ok
printf '%s\n' "ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker" "ANSIBLE_SKIP_TAGS=''" "UPDATES=()" > "$PV/home/docker/build-info.env"
list | wc -l
printf 'UPDATES+=(%q)\n' "2026-09-25T00:00:00Z|terraform|" >> "$PV/home/docker/build-info.env"
list | wc -l; list | grep -x software/terraform
printf 'UPDATES+=(%q)\n' "2026-09-25T01:00:00Z|kubectl,helm|helm" >> "$PV/home/docker/build-info.env"
list | wc -l; list | grep -cx software/helm
list --tags neovim
in_image proveasio:local render-case.sh full "" base-local.yml | grep -E 'keeping|nvim:'
in_image proveasio:local render-case.sh full | grep 'nvim:'
```

Expected: `syntax-ok`; `9`; `10` and `software/terraform`; `11` and `0` (kubectl added, helm skipped); `software/neovim`; `render-overrides: keeping the local Neovim config source of the base image` and `nvim: local /tmp/nvim-config`; `nvim: git `.

- [ ] **Step 5: Replace `docker/provision.sh`**

```bash
#!/usr/bin/env bash
# Playbook step of a Proveasio image build.
#
# docker/Dockerfile runs it in the RUN step of the `build` stage (a new image)
# and, with --update, in the `update` stage (docker-bake.hcl target `update`,
# on top of an existing image). It is bind-mounted with the rest of docker/ at
# DOCKER_DIR, so it is not part of the image.
#
# New image: render ansible/vars/overrides.yml, stop when the tags or excludes
# leave out a task every image needs, write docker/build-info.env, upgrade the
# Ubuntu packages, run the playbook, install Mason tools and treesitter
# parsers, remove build leftovers, and start zsh once.
#
# Update: check that the base image and the settings allow an update (see
# update below), render the overrides with the base image's profile, run the
# playbook with ANSIBLE_TAGS without upgrading Ubuntu, install Mason tools
# only when the tags touch Neovim, remove leftovers, start zsh, and record the
# update in docker/build-info.env.
#
# It runs render-overrides.sh and cleanup.sh, so it refuses to run unless
# PROVEASIO_IMAGE_BUILD=1. docker/Dockerfile sets it for this one command.
# Never set it on a workstation.
set -euo pipefail

if [ "${PROVEASIO_IMAGE_BUILD:-}" != 1 ]; then
  echo "provision: refusing to run outside an image build (set PROVEASIO_IMAGE_BUILD=1)" >&2
  exit 2
fi
# The opt-in goes to render-overrides.sh and cleanup.sh only, not to the playbook.
unset PROVEASIO_IMAGE_BUILD

MODE=full
case "$#:${1:-}" in
  0:) ;;
  1:--update) MODE=update ;;
  *)
    echo "usage: provision.sh [--update]" >&2
    exit 2
    ;;
esac

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"
ANSIBLE_DIR="$PROVEASIO_HOME/ansible"
OVERRIDES="$ANSIBLE_DIR/vars/overrides.yml"
BUILD_INFO="$PROVEASIO_HOME/docker/build-info.env"
ANSIBLE_TAGS="${ANSIBLE_TAGS:-}"
ANSIBLE_SKIP_TAGS="${ANSIBLE_SKIP_TAGS:-}"
PROFILE="${PROFILE:-full}"
# The includes every new image needs (docs-web/docs/main/docker/20-customize.md).
REQUIRED=(software/packages software/yq software/zsh config/zsh)

die() {
  echo "provision: $*" >&2
  exit 1
}

# selection <tags> <skip-tags>: the includes these tags run, minus the
# excludes of the rendered overrides, one "<role>/<name>" per line.
selection() {
  PROVEASIO_HOME="$PROVEASIO_HOME" bash "$DOCKER_DIR/test.sh" --list --tags "$1" --skip-tags "$2"
}

# render [base overrides]: write ansible/vars/overrides.yml
# (docker/render-overrides.sh). An update passes the image's previous file.
render() {
  PROVEASIO_IMAGE_BUILD=1 PROVEASIO_HOME="$PROVEASIO_HOME" DOCKER_DIR="$DOCKER_DIR" \
    NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" PROFILE="$PROFILE" PROVEASIO_BASE_OVERRIDES="${1:-}" \
    bash "$DOCKER_DIR/render-overrides.sh"
}

# check_required: stop before the playbook when a new image would miss a
# required include. The playbook alone would fail much later, in the tests.
check_required() {
  local selected r missing=()
  selected="$(selection "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS")" || die "docker/test.sh --list failed"
  for r in "${REQUIRED[@]}"; do
    grep -qxF -- "$r" <<<"$selected" || missing+=("$r")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    die "a new image needs ${missing[*]}, but ANSIBLE_TAGS='$ANSIBLE_TAGS' ANSIBLE_SKIP_TAGS='$ANSIBLE_SKIP_TAGS' or the excludes in docker/overrides.yml leave them out. To leave tools out, exclude them in docker/overrides.yml."
  fi
}

# write_build_info: what docker/test.sh needs to select the checks of this image.
write_build_info() {
  mkdir -p "$(dirname "$BUILD_INFO")"
  {
    printf 'PROFILE=%q\n' "$PROFILE"
    printf 'ANSIBLE_TAGS=%q\n' "$ANSIBLE_TAGS"
    printf 'ANSIBLE_SKIP_TAGS=%q\n' "$ANSIBLE_SKIP_TAGS"
    printf 'REFRESH=%q\n' "${REFRESH:-}"
    printf 'BUILD_DATE=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'UPDATES=()\n'
  } > "$BUILD_INFO"
}

run_playbook() {
  local args=()
  if [ -n "$ANSIBLE_TAGS" ]; then args+=(--tags "$ANSIBLE_TAGS"); fi
  if [ -n "$ANSIBLE_SKIP_TAGS" ]; then args+=(--skip-tags "$ANSIBLE_SKIP_TAGS"); fi
  # Ansible ignores ansible.cfg in a world-writable current directory, which is
  # what COPY produces from a checkout under /mnt/c. ANSIBLE_CONFIG always loads it.
  (cd "$ANSIBLE_DIR" && ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" \
    ansible-playbook -i inventory.yml setup-ubuntu.yml "${args[@]}")
}

# zsh_path: the PATH of an interactive zsh, read the way docker/test.sh's
# use_zsh_path does. nvm, gvm and rvm add to PATH only there. Prints nothing
# when zsh is missing or the PATH looks wrong. GITHUB_TOKEN is only for the
# playbook's version lookups, so zsh runs without it.
zsh_path() {
  local p=""
  if [ -f "$HOME/.zshrc" ] && command -v zsh >/dev/null 2>&1; then
    p="$(env -u GITHUB_TOKEN TERM=xterm-256color timeout 60 script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)" || p=""
  fi
  case "$p" in */usr/bin*) printf '%s' "$p" ;; esac
}

# nvim_install: Mason and treesitter install in the background, so the role's
# headless `nvim +q` can exit before they finish. nvim-install.lua starts them
# and waits; it skips what the config does not use. It runs under pcall so
# that a missing or broken helper fails the build instead of exiting 0.
# Mason installs some packages with npm, go or gem, so nvim gets the zsh PATH.
# Mason sets GOBIN and GEM_HOME itself; PATH is the only variable it needs.
nvim_install() {
  local app nvim_path lua
  app="$(yq -r '.neovim_config_appname // ""' "$OVERRIDES")"
  if [ -z "$app" ]; then app="$(yq -r '.neovim_config_appname' "$ANSIBLE_DIR/roles/config/vars/main.yml")"; fi
  if ! command -v nvim >/dev/null 2>&1 || [ ! -d "$HOME/.config/$app" ]; then return 0; fi
  nvim_path="$(zsh_path)"
  if [ -z "$nvim_path" ]; then
    echo "WARNING: could not read PATH from zsh; nvim uses the build PATH, so Mason packages that need npm, go or gem fail" >&2
    nvim_path="$PATH"
  fi
  printf -v lua 'lua local ok, err = pcall(dofile, "%s/nvim-install.lua") if not ok then io.stderr:write("\\n" .. tostring(err) .. "\\n") vim.cmd("cquit 1") end' "$DOCKER_DIR"
  env -u GITHUB_TOKEN PATH="$nvim_path" NVIM_APPNAME="$app" timeout 1800 nvim --headless -c "$lua" -c 'qa'
}

cleanup() {
  PROVEASIO_IMAGE_BUILD=1 bash "$DOCKER_DIR/cleanup.sh"
}

# warm_zsh: the first interactive zsh start downloads gitstatusd for p10k and
# builds caches, so containers can start without network access. p10k fetches
# gitstatusd before the first prompt, so the shell has to draw one
# (`zsh -i -c exit` does not); `exit` on stdin then ends it.
warm_zsh() {
  if [ -f "$HOME/.zshrc" ]; then
    env -u GITHUB_TOKEN TERM=xterm-256color POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true \
      timeout 300 script -qec 'zsh -i' /dev/null <<<'exit'
  fi
}

# excludes <overrides file> <role>: the effective <role>_tasks_exclude, sorted.
# A missing key means the role default, which is [] for both roles.
excludes() {
  KEY="${2}_tasks_exclude" yq -r '(.[strenv(KEY)] // [])[]' "$1" | sort -u
}

full() {
  echo "provision: PROFILE=$PROFILE REFRESH=${REFRESH:-} ANSIBLE_TAGS=$ANSIBLE_TAGS ANSIBLE_SKIP_TAGS=$ANSIBLE_SKIP_TAGS"
  render
  check_required
  write_build_info
  sudo apt-get update
  sudo apt-get -y upgrade
  run_playbook
  nvim_install
  cleanup
  warm_zsh
}

update() {
  local base role now base_ex added readded name selected
  [ -n "$ANSIBLE_TAGS" ] || die "an update needs ANSIBLE_TAGS, the tags of the tools to update. To update everything, run a full build."
  if [ ! -f "$BUILD_INFO" ] || [ ! -f "$OVERRIDES" ]; then
    die "the base image has no $BUILD_INFO or $OVERRIDES. BASE_IMAGE must be a Proveasio image built with docker-bake.hcl."
  fi
  if [ "$HOME" != "/home/${USERNAME:-}" ] || [ "$(id -u)" != "${USER_UID:-}" ] || [ "$(id -g)" != "${USER_GID:-}" ]; then
    die "USERNAME=${USERNAME:-} USER_UID=${USER_UID:-} USER_GID=${USER_GID:-} do not match the base image user $(id -un) ($(id -u):$(id -g), HOME=$HOME). Pass the values the base image was built with."
  fi
  # The base image's profile, not the build argument. Images built before
  # profiles existed have no PROFILE line and are full images.
  # shellcheck source=/dev/null
  PROFILE="$(PROFILE=full; source "$BUILD_INFO"; printf '%s' "$PROFILE")"
  echo "provision: update of a $PROFILE image, REFRESH=${REFRESH:-} ANSIBLE_TAGS=$ANSIBLE_TAGS ANSIBLE_SKIP_TAGS=$ANSIBLE_SKIP_TAGS"

  base="$(mktemp)"
  cp "$OVERRIDES" "$base"
  render "$base"

  selected="$(selection "$ANSIBLE_TAGS" "$ANSIBLE_SKIP_TAGS")" || die "docker/test.sh --list failed"
  [ -n "$selected" ] || die "ANSIBLE_TAGS='$ANSIBLE_TAGS' ANSIBLE_SKIP_TAGS='$ANSIBLE_SKIP_TAGS' select no task. The tags are listed in docs-web/docs/main/customization/50-partial-run.md."
  for role in software config; do
    now="$(excludes "$OVERRIDES" "$role")"
    base_ex="$(excludes "$base" "$role")"
    added="$(comm -13 <(printf '%s\n' "$base_ex") <(printf '%s\n' "$now") | sed '/^$/d' | tr '\n' ' ')"
    if [ -n "$added" ]; then
      die "${role}_tasks_exclude now also has: ${added}. An update cannot remove a tool from the image (it would stay installed and untested). Run a full build."
    fi
    readded="$(comm -23 <(printf '%s\n' "$base_ex") <(printf '%s\n' "$now") | sed '/^$/d')"
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      grep -qxF -- "$role/$name" <<<"$selected" \
        || die "$role/$name is no longer excluded, but ANSIBLE_TAGS does not select it. Add its tag to ANSIBLE_TAGS so the update installs it."
    done <<<"$readded"
  done
  if [ "$(yq -r '.neovim_config_source // ""' "$base")" = local ] \
    && [ -z "$(ls -A "$NVIM_CONFIG_DIR" 2>/dev/null)" ] \
    && grep -qxF config/neovim-config <<<"$selected"; then
    die "the base image was built with NVIM_CONFIG and these tags update config/neovim-config. Pass the same NVIM_CONFIG (and --allow fs.read=<dir>) to the update."
  fi
  rm -f "$base"

  sudo apt-get update
  run_playbook
  if grep -qxE 'software/neovim|config/neovim-config' <<<"$selected"; then nvim_install; fi
  cleanup
  warm_zsh
  printf 'UPDATES+=(%q)\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)|$ANSIBLE_TAGS|$ANSIBLE_SKIP_TAGS" >> "$BUILD_INFO"
}

"$MODE"
```

- [ ] **Step 6: Dockerfile stages**

Header comment, replace lines 5-6

```dockerfile
# The playbook runs at build time. The `final` stage exists only when
# docker/test.sh passed in the `test` stage.
```

with

```dockerfile
# The playbook runs at build time. The `final` stage exists only when
# docker/test.sh passed in the `test` stage. The `update` target of
# docker-bake.hcl builds the `update` stage on an existing image instead of
# `build`.
```

After `ARG USER_GID=1000` (line 11) add:

```dockerfile
# The `update` target sets PROVISIONED=update, so the test, receipt and final
# stages start from the `update` stage, which builds on BASE_IMAGE. Docker
# resolves BASE_IMAGE only when that stage is built.
ARG BASE_IMAGE=proveasio:local
ARG PROVISIONED=build
```

Replace everything from `FROM build AS test` to the end of the file with:

```dockerfile
# Update of an existing Proveasio image: the playbook with ANSIBLE_TAGS on
# top of BASE_IMAGE. docker/provision.sh --update lists the checks. The base
# image's user, ENV, SHELL and CMD carry over.
FROM ${BASE_IMAGE} AS update
ARG USERNAME
ARG USER_UID
ARG USER_GID
COPY --chown=${USER_UID}:${USER_GID} ansible /home/${USERNAME}/proveasio/ansible
ARG REFRESH=manual
ARG ANSIBLE_TAGS=""
ARG ANSIBLE_SKIP_TAGS=""
RUN --mount=type=bind,source=docker,target=/tmp/proveasio-docker \
    --mount=type=bind,from=nvim-config,target=/tmp/nvim-config \
    --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
    PROVEASIO_IMAGE_BUILD=1 bash /tmp/proveasio-docker/provision.sh --update
COPY --chown=${USER_UID}:${USER_GID} --chmod=0755 docker/test.sh /home/${USERNAME}/proveasio/docker/test.sh

# `build` for a new image, `update` for an update.
FROM ${PROVISIONED} AS provisioned

FROM provisioned AS test
RUN "$HOME/proveasio/docker/test.sh" | tee "$HOME/proveasio/docker/tests-passed"

# Version receipt for CI. Copies from `provisioned` so that `final` stays the
# last stage and a plain `docker build` produces the image.
FROM scratch AS receipt
ARG USERNAME
COPY --from=provisioned /home/${USERNAME}/proveasio/current-versions.yml /current-versions.yml

FROM provisioned AS final
ARG USERNAME
ARG USER_UID
ARG USER_GID
COPY --from=test --chown=${USER_UID}:${USER_GID} /home/${USERNAME}/proveasio/docker/tests-passed /home/${USERNAME}/proveasio/docker/tests-passed
```

- [ ] **Step 7: Bake**

`docker-bake.hcl` header: after the line `#   docker buildx bake image receipt            also write ./out/current-versions.yml` add

```hcl
#   ANSIBLE_TAGS=terraform docker buildx bake update
#                                               update tools in proveasio:local in place
```

After `variable "IMAGE" { ... }` add:

```hcl
# Image the `update` target starts from. Defaults to the image it replaces.
variable "BASE_IMAGE" {
  default = IMAGE
}
```

After `target "receipt" { ... }` add:

```hcl
# Runs the playbook with ANSIBLE_TAGS on top of BASE_IMAGE, runs the smoke
# tests and loads the result as IMAGE. pull = false because BASE_IMAGE is
# usually only in the local image store.
target "update" {
  inherits = ["_common", "docker-metadata-action"]
  target   = "final"
  pull     = false
  args = {
    PROVISIONED = "update"
    BASE_IMAGE  = BASE_IMAGE
  }
  output = ["type=docker"]
}
```

- [ ] **Step 8: Static checks**

```bash
cd /home/ziwi/projects/proveasio
bash -n docker/provision.sh && echo syntax-ok
bash docker/provision.sh --update; echo "rc=$?"
docker buildx bake --print update 2>/dev/null | jq -c '.target.update | {target, pull, tags, PROVISIONED: .args.PROVISIONED, BASE_IMAGE: .args.BASE_IMAGE, has_refresh: (.args.REFRESH != null), output}'
PROFILE=slim docker buildx bake --print update 2>/dev/null | jq -c '.target.update | {tags, BASE_IMAGE: .args.BASE_IMAGE}'
BASE_IMAGE=x/y:z IMAGE=proveasio:local docker buildx bake --print update 2>/dev/null | jq -c '.target.update | {tags, BASE_IMAGE: .args.BASE_IMAGE}'
docker buildx bake --print image 2>/dev/null | jq -c '.target.image.args | has("PROVISIONED")'
```

Expected: `syntax-ok`; the refusal message and `rc=2`; `{"target":"final","pull":false,"tags":["proveasio:local"],"PROVISIONED":"update","BASE_IMAGE":"proveasio:local","has_refresh":true,"output":[...docker...]}`; `{"tags":["proveasio:slim"],"BASE_IMAGE":"proveasio:slim"}`; `{"tags":["proveasio:local"],"BASE_IMAGE":"x/y:z"}`; `false`.

If `has_refresh` is `false`, Bake replaced the inherited `args` instead of merging them: repeat every `_common` arg in the `update` target's `args` and run the check again.

- [ ] **Step 9: Update builds**

`proveasio:smoke` from Task 4 and `proveasio:slim` from Task 5 are the bases. If either is missing, rebuild it with the Task 4 Step 6 or Task 5 Step 6 command first.

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh
sizes
up() {  # up <log name> <env assignments...>: one update build, prints rc and key lines
  local log="$PV/$1.log"; shift
  mem_ok || return 99
  env "$@" docker buildx bake --progress=plain update > "$log" 2>&1; echo "rc=$?"
  grep -E 'provision: |nvim-install: mason|# [0-9]+ selected' "$log" | grep -v '^#[0-9]* \[' | head -n 5
}
up up-eza IMAGE=proveasio:smoke ANSIBLE_TAGS=eza
in_image proveasio:smoke image-info.sh | grep -E 'PROFILE|UPDATES|zfunc'
sizes
up up-tf IMAGE=proveasio:smoke ANSIBLE_TAGS=terraform
sizes
up up-none IMAGE=proveasio:smoke
up up-nomatch IMAGE=proveasio:smoke ANSIBLE_TAGS=no-such-tag
up up-user IMAGE=proveasio:smoke ANSIBLE_TAGS=eza USERNAME=other
printf 'software_tasks_exclude:\n  - fx\n' > docker/overrides.yml
up up-addex IMAGE=proveasio:smoke ANSIBLE_TAGS=eza
rm -f docker/overrides.yml
printf 'software_tasks_include:\n  - azurecli\n  - az-account-switcher\n' > docker/overrides.yml
up up-az-bad PROFILE=slim BASE_IMAGE=proveasio:slim IMAGE=proveasio:slim-az ANSIBLE_TAGS=terraform
up up-az PROFILE=slim BASE_IMAGE=proveasio:slim IMAGE=proveasio:slim-az ANSIBLE_TAGS=azurecli,az-account-switcher
rm -f docker/overrides.yml
sizes
test -e docker/overrides.yml && echo "overrides left behind" || echo "overrides removed"
```

Expected:

| Run | Result |
|---|---|
| `up-eza` | `rc=0`, `provision: update of a full image ...`, no `nvim-install` line, `# 9 selected, 9 passed, 0 failed`; image info shows `PROFILE=full` and `UPDATES+=(...\|eza\|)` |
| `up-tf` | `rc=0`, `# 10 selected, 10 passed, 0 failed` |
| `up-none` | `rc=1`, `provision: an update needs ANSIBLE_TAGS ...` |
| `up-nomatch` | `rc=1`, `provision: ANSIBLE_TAGS='no-such-tag' ... select no task ...` |
| `up-user` | `rc=1`, `provision: USERNAME=other ... do not match the base image user dev ...` |
| `up-addex` | `rc=1`, `provision: software_tasks_exclude now also has: fx ...` |
| `up-az-bad` | `rc=1`, `provision: software/az-account-switcher is no longer excluded, but ANSIBLE_TAGS does not select it ...` |
| `up-az` | `rc=0`, `provision: update of a slim image ...`, `# 47 selected, 47 passed, 0 failed` |

Final lines: `proveasio:slim` unchanged in size, `proveasio:slim-az` present, `overrides removed`. Record the size of `proveasio:smoke` before and after each successful update and of `proveasio:slim-az`.

- [ ] **Step 10: Docs and AGENTS.md**

`docs-web/docs/main/docker/10-build.md`: insert before `## GitHub token`:

~~~markdown
## Updating tools in a built image

A full build runs the whole playbook again. To update only some tools in an
image you already have, use the `update` target with the tags of those tools:

```shell
ANSIBLE_TAGS=terraform docker buildx bake update
```

The update starts from `proveasio:local`, runs the playbook with
`--tags terraform`, runs all smoke tests again and loads the result as
`proveasio:local`. The tags are listed in
[Partial run](../customization/partial-run). For the slim image, add
`PROFILE=slim`. For any other image, set `BASE_IMAGE` to the image to start
from and `IMAGE` to the name of the result. The base image has to be in your
local image store, so pull a published image first:

```shell
docker pull CHANGEME/proveasio:latest
BASE_IMAGE=CHANGEME/proveasio:latest IMAGE=proveasio:local \
  ANSIBLE_TAGS=neovim,neovim-config docker buildx bake update
```

An update:

- needs `ANSIBLE_TAGS`. To update everything, run a full build.
- uses the profile the base image was built with.
- reads `docker/overrides.yml` again, so version pins and other settings can
  change. Excludes can only get shorter. A tool you add back with
  `software_tasks_include` must also be in `ANSIBLE_TAGS`, so that the update
  installs it. A new exclude stops the build, because the tool would stay in
  the image. To remove a tool, run a full build.
- needs the same `NVIM_CONFIG` as the base build when it updates
  `neovim-config` in an image built from a local Neovim config.
- does not upgrade the Ubuntu packages.
- needs the `USERNAME`, `USER_UID` and `USER_GID` the base image was built with.

For example, to add Azure CLI to the slim image, put this in
`docker/overrides.yml`:

```yaml
software_tasks_include:
  - azurecli
  - az-account-switcher
```

and run:

```shell
PROFILE=slim ANSIBLE_TAGS=azurecli,az-account-switcher docker buildx bake update
```

Each update adds about four layers, and the files it replaces stay in the
layers below. The image grows by about the size of each tool you update. The
updates of an image are listed in `~/proveasio/docker/build-info.env`. A full
build starts from an empty image again.
~~~

`docs-web/docs/main/docker/20-customize.md`:
- Tags section: after the sentence `` `--tags` builds an image from scratch with only the selected tasks. `` insert `To update tools in an image you already have, use the \`update\` target instead, see [Updating tools in a built image](./build#updating-tools-in-a-built-image).`
- End of "Adding tools back": add the paragraph `To add a tool to an image you already built, see [Updating tools in a built image](./build#updating-tools-in-a-built-image).`
- Build variables table, after the `IMAGE` row: `| \`BASE_IMAGE\` | the value of \`IMAGE\` | Image the \`update\` target starts from. It has to be in the local image store. |`

`docs-web/docs/main/docker/40-limitations.md`, Other limitations: add as the second bullet

```
- **Updates make the image grow.** Each `docker buildx bake update` adds about
  four layers, and the files it replaces stay in the layers below. After about
  25 updates the image reaches Docker's limit of 127 layers. A full build
  starts from an empty image again.
```

`AGENTS.md`, Docker image section: after the `docker/provision.sh` bullet add

```
- `docker buildx bake update` (target `update`, `pull = false`, `PROVISIONED=update`) builds
  the `update` stage `FROM ${BASE_IMAGE}` (default: `IMAGE`) and runs `provision.sh --update`:
  it needs `ANSIBLE_TAGS`, reuses the base image's `PROFILE`, rejects new excludes, requires
  tools taken back with `*_tasks_include` to be in the tags, skips the apt upgrade, and appends
  `UPDATES+=(...)` to `build-info.env`. `test.sh` then tests everything the build's or any
  update's tags selected. Each update adds about 4 layers; replaced files stay below.
```

and extend the `- Verify Docker changes ...` bullet with: `For update changes, also run an update on the smoke image: \`IMAGE=proveasio:smoke ANSIBLE_TAGS=eza docker buildx bake update\` (9 checks).`

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm run build 2>&1 | tail -n 3
```

Expected: `[SUCCESS] Generated static files in "build".`

- [ ] **Step 11: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Suggested commit: `feat(docker): Add an update target for tools in a built image`

---

### Task 8: Memories and final verification

**Files:**
- Modify: `.serena/memories/docker-image.md`, `.serena/memories/ansible-architecture.md`

- [ ] **Step 1: `docker-image` memory**

Edit with Serena `edit_memory` (or rewrite the file):
- Files section: add `docker/provision.sh` (playbook step; full and `--update` modes; writes `build-info.env` with `PROFILE`, tags, `REFRESH`, `BUILD_DATE`, `UPDATES`; required-task check via `test.sh --list --tags`), `docker/profile-slim.yml` (slim excludes and why nvm/gvm/rvm stay). Change the `render-overrides.sh` entry: profiles, `*_tasks_include`, `PROVEASIO_BASE_OVERRIDES` carry-over, no build info. Change the Dockerfile entry: global `BASE_IMAGE`/`PROVISIONED`, stages `build`, `update`, `provisioned` (alias), `test`, `receipt`, `final`. Change the Bake entry: `PROFILE`, derived `IMAGE`, `BASE_IMAGE`, target `update` (`pull = false`). Add to `test.sh`: `--list --tags/--skip-tags`, `UPDATES` union.
- Merge rule: add the profile layer and the include step.
- Known gaps: replace the `ANSIBLE_SKIP_TAGS with eza, zsh or config is unsupported` bullet with: `A new image needs software/packages, software/yq, software/zsh, config/zsh; provision.sh stops before the playbook otherwise. Excluding packages, yq or zsh fails the playbook's assert everywhere.` Add: updates grow the image and cannot remove tools.
- Verify: add the update check and the slim build.
- Measured: add the slim numbers from Task 5 Step 6 and the update size deltas from Task 7 Step 9.

- [ ] **Step 2: `ansible-architecture` memory**

- Cross-role coupling: replace the `config/templates/zshrc.j2:129-134 uses eza_version ...` bullet with `eza has no cross-role coupling any more: software/tasks/eza.yml links ~/.zfunc/_eza, and .zshrc adds ~/.zfunc to fpath when the directory exists.`
- Add a section "Required tasks": `packages`, `yq`, `zsh` (software) and `zsh` (config) have no exclude guard; `[Software] Check that no required task is excluded` checks both lists.

- [ ] **Step 3: Final checks**

```bash
cd /home/ziwi/projects/proveasio && source /tmp/opencode/pv/helpers.sh && host_copy
(cd ansible && ansible-lint) 2>&1 | tail -n 3
(cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check) | tail -n 2
PROVEASIO_HOME="$PV/home" bash docker/test.sh --coverage | tail -n 1
for p in "" "PROFILE=slim"; do env $p docker buildx bake --print image 2>/dev/null | jq -c '.target.image | {tags, PROFILE: .args.PROFILE}'; done
docker buildx bake --print update 2>/dev/null | jq -c '.target.update | {tags, BASE_IMAGE: .args.BASE_IMAGE}'
(cd docs-web && npm run build 2>&1 | tail -n 1)
test -e docker/overrides.yml && echo "overrides left behind" || echo "no docker/overrides.yml"
git status --short
sizes
```

Expected: `Passed: 0 failure(s)`; `playbook: setup-ubuntu.yml`; `# 54 includes, 0 without a check`; `{"tags":["proveasio:local"],"PROFILE":"full"}`, `{"tags":["proveasio:slim"],"PROFILE":"slim"}`, `{"tags":["proveasio:local"],"BASE_IMAGE":"proveasio:local"}`; `[SUCCESS] ...`; `no docker/overrides.yml`.

- [ ] **Step 4: Report**

Report to the user, with the commands and outputs from each task:
- measured: slim size, build time and Mason result; smoke size before and after the eza and terraform updates; `proveasio:slim-az` size;
- unverified: the CI matrix and metadata tags (never ran on GitHub); the native playbook (not run; the eza and assert changes were tested in containers);
- the local images this plan created (`proveasio:smoke`, `proveasio:slim`, `proveasio:slim-az`) and their sizes. Ask whether to remove them; do not remove them unasked;
- the suggested commits, to be made only when the user asks.

---

## Spec coverage

| Spec item | Task |
|---|---|
| eza completion in `~/.zfunc`, no `eza` tag on config zsh, fallback removed | 1 |
| Required tasks: guards removed, one assert for both lists in the software role | 2 |
| Docker full build stops early without required includes | 3 (`--list --tags`), 4 |
| `provision.sh` shared by build and update; opt-in only for the two scripts | 4, 7 |
| `build-info.env` written by `provision.sh`, with `PROFILE` and `UPDATES` | 4, 7 |
| `docker/profile-slim.yml`, `PROFILE`, derived `IMAGE`, unknown profile fails | 5 |
| `*_tasks_include`: removal, unknown name fails, not-excluded note, list type check | 5 |
| CI matrix, slim tags, per-profile receipts | 6 |
| `update` stage and target, `BASE_IMAGE`, `PROVISIONED`, `pull = false` | 7 |
| Update checks: tags, base image, user, profile, excludes shrink only with tags, local Neovim config | 7 |
| `test.sh` union of build and update selections | 7 |
| nvim-install only when the update touches Neovim; no apt upgrade in updates | 7 |
| Docs, AGENTS.md, TODO.md, memories | 1, 2, 4, 5, 6, 7, 8 |
| Verification 1-6 of the spec | 1-8 (5.5 is Task 7 Step 9 `up-az`) |
