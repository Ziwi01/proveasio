# OpenCode Baseline Build in the Docker Image Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Image builds install the `-baseline` OpenCode asset so the published image runs on x64 CPUs without AVX2.

**Architecture:** A new software-role variable `opencode_baseline` (`auto` | `true`) feeds the existing asset-selection shell step; `docker/profile.yml` sets `true`. The installed asset is recorded in `current-versions.yml`, and `docker/test.sh` checks it.

**Tech Stack:** Ansible, bash, yq, Docker Bake, Docusaurus.

**Spec:** `docs/superpowers/specs/2026-10-25-opencode-baseline-design.md`

## Global Constraints

- Variable name and values: `opencode_baseline`, default `auto`, image value `true`.
- Receipt key: `opencode_asset`, value = the tarball name, e.g. `opencode-linux-x64-baseline.tar.gz`.
- Every `shell:` task: `args.executable: /bin/bash` and starts with `set -e -o pipefail`. Task names start with `[opencode]`.
- No commits unless the user asks (user rule overrides the skill). Suggested message: `feat(opencode): Use the baseline build in Docker images`.
- Edit `docs-web/docs/` only, never `versioned_docs/`.
- `ansible-lint` from `ansible/` must report `Passed: 0 failure(s)`.

## Review Focus

- `opencode_baseline: true` on arm64 must still pick `opencode-linux-arm64.tar.gz` (no `-baseline` there). Covered by Task 1 Step 5.
- A re-run with the version already installed must not rewrite `opencode_asset` (it would then describe a binary that is not on disk). Covered by Task 1 (write lives inside the `Installation` block).
- An invalid value (`yes`, `false`) must not silently behave like `auto`. Task 1 adds an assert accepting only `auto` and `true` (YAML bool `true` and string `"true"`).
- musl detection must still append `-musl` after `-baseline` (asset order `linux-x64-baseline-musl`). Covered by Task 1 Step 5.
- The test must pass when the effective value is `auto` (no assertion on the asset). Covered by Task 1 Step 2.

---

### Task 1: Variable, asset selection, receipt, and image check

**Files:**
- Modify: `ansible/roles/software/vars/main.yml` (next to `github_packages.opencode`, line ~100)
- Modify: `ansible/roles/software/tasks/opencode.yml:13-35` (asset step), and the `Installation` block
- Modify: `docker/profile.yml`
- Modify: `docker/test.sh:378` (`check_software_opencode`)

**Interfaces:**
- Produces: `opencode_baseline` var; receipt key `.opencode_asset`.

- [ ] **Step 1: Build a scratch PROVEASIO_HOME for the check**

```bash
S=/tmp/opencode/pvh; rm -rf $S; mkdir -p $S/ansible/vars $S/docker
ln -s ~/projects/proveasio/ansible/roles $S/ansible/roles
printf 'opencode_baseline: true\n' > $S/ansible/vars/overrides.yml
printf 'github_packages:\n  opencode: "2.1.4"\nopencode_asset: opencode-linux-x64.tar.gz\n' > $S/current-versions.yml
```
(`opencode --version` on this machine prints 2.1.4; adjust if it differs.)

- [ ] **Step 2: Change `check_software_opencode` and watch it fail**

After the existing version check: read `effective opencode_baseline software`; when it is `true`, `receipt .opencode_asset` must end in `-baseline.tar.gz`, else `fail "opencode_baseline is true, but the installed asset is '<asset or unknown>'"`. Set `DETAIL` to `<version>, <asset>` when an asset is recorded.

Run: `PROVEASIO_HOME=/tmp/opencode/pvh bash docker/test.sh --only software/opencode`
Expected: FAIL with the message above.
Then set the receipt asset to `opencode-linux-x64-baseline.tar.gz` → PASS; then overrides `opencode_baseline: auto` with the non-baseline asset → PASS.

- [ ] **Step 3: Add the variable and the image setting**

`software/vars/main.yml`: `opencode_baseline: auto` with a comment (`auto` = check this CPU for AVX2; `true` = always the baseline build on x64, for images that run on other machines).
`docker/profile.yml`: `opencode_baseline: true` with a comment (the image runs on CPUs other than the build machine's; the AVX2 build crashes without AVX2).

- [ ] **Step 4: Use it in `opencode.yml`**

- Add an `ansible.builtin.assert` before the asset step: `opencode_baseline | string | lower in ['auto', 'true']`, `quiet: true`, tagged `versions`.
- In the asset step, pass the value as an env var (`OPENCODE_BASELINE: "{{ opencode_baseline | string | lower }}"`) and add `-baseline` when `arch = x64` and (`$OPENCODE_BASELINE = true` or no `avx2` in `/proc/cpuinfo`). Keep the musl suffix after it. Update the header comment.
- Inside the `Installation` block, after "Cleanup tar.gz file": include `common/save_version.yml` with `app: opencode`, `target_version: {opencode_asset: "{{ opencode_asset }}"}`, `yq_query: '.opencode_asset = "{{ opencode_asset }}"'`, apply-tag `versions` (same shape as "Save used version").

- [ ] **Step 5: Check the asset selection by hand**

Run the asset step's shell body with `OPENCODE_BASELINE=true` and with `auto` on this machine (has AVX2).
Expected: `opencode-linux-x64-baseline.tar.gz` and `opencode-linux-x64.tar.gz`. Read the case logic to confirm arm64 never gets `-baseline` and musl comes last.

- [ ] **Step 6: Lint and syntax**

Run: `cd ansible && ansible-lint` → `Passed: 0 failure(s)`.
Run: `cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check` → `playbook: setup-ubuntu.yml`.

### Task 2: Docs

**Files:**
- Modify: `docs-web/docs/main/docker/40-limitations.md:54-57` (remove the opencode bullet)
- Modify: `docs-web/docs/main/docker/10-build.md:96,107-109` (row → ✅ ✅ ✅, remove `[^opencode]`)
- Modify: `docs-web/docs/main/customization/10-variables.md` (row for `opencode_baseline`, near the opencode_config rows; mention the upgrade caveat: takes effect with the next OpenCode version on an existing install)

- [ ] **Step 1: Edit the three pages**
- [ ] **Step 2: Build**

Run: `cd docs-web && npm run build` → `[SUCCESS] Generated static files`.

### Task 3: Image and NAS verification

- [ ] **Step 1: Check host memory** (`powershell.exe ... FreePhysicalMemory,FreeVirtualMemory`, need ≥10 GB each, values in KB). Stop and tell the user if lower.
- [ ] **Step 2: Smoke build with opencode**

Run: `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker,opencode IMAGE=proveasio:smoke docker buildx bake`
Expected: build succeeds; the test stage reports `software/opencode` passing with a `-baseline` asset in its detail.

- [ ] **Step 3: Binary test on the NAS** (approved by the user)

Copy `~/.local/opt/opencode-<v>/opencode` out of `proveasio:smoke` (`docker create` + `docker cp`), `scp` it and the AVX2 binary (`~/.local/opt/opencode-<v>/opencode` from this machine) to a temp dir on the NAS, then for each run `docker run --rm -v <dir>:/oc:ro ubuntu:24.04 /oc/<bin> --version` with the NAS docker binary from `scripts/nas.conf`. Remove the temp dir and the `ubuntu:24.04` image afterwards.
Expected: baseline prints the version; AVX2 build exits non-zero (SIGILL, exit 132).
