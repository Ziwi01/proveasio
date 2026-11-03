# opencode via Homebrew Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `opencode_package: brew` installs opencode through a preinstalled Homebrew, avoiding opencode.ai.

**Architecture:** One switch variable; `roles/software/tasks/opencode.yml` keeps the tarball tasks behind `opencode_package == 'tarball'` and adds a brew branch. Docs updated in the same change.

**Tech Stack:** Ansible, `community.general.homebrew` (already a dependency), Docusaurus.

**Spec:** `docs/superpowers/specs/2026-11-03-opencode-brew-design.md`

## Global Constraints

- Default stays `opencode_package: tarball`; tarball behaviour unchanged.
- Every `shell:` task: `args.executable: /bin/bash`, starts with `set -e -o pipefail`.
- Task names prefixed `"[opencode] ..."`.
- `ansible-lint` must report `Passed: 0 failure(s)`.
- Edit `docs-web/docs/` only; no commits unless asked.

## Review Focus

- Homebrew missing → clear failure naming the docs page, not a module traceback.
- `opencode_package: brew` with a pinned `github_packages.opencode` → fails instead of silently installing latest v2.
- Invalid `opencode_package` value → assert failure.
- Switching tarball → brew: `~/.local/bin/opencode` must point at brew's binary afterwards (forced link).
- Brew version with a revision suffix (`2.2.5_1`) → receipt stores `2.2.5`.

Covered by Task 1 step 3 (`--check` runs with each override) where the machine allows; the brew install itself cannot run here (no Homebrew).

---

### Task 1: Brew branch in opencode.yml

**Files:**
- Modify: `ansible/roles/software/vars/main.yml` (after `opencode_baseline`)
- Modify: `ansible/roles/software/tasks/opencode.yml`

**Interfaces:**
- Produces: variable `opencode_package` (`tarball` | `brew`); fact `opencode_brew_prefix` (string, brew `--prefix`).

- [ ] **Step 1:** Add `opencode_package: tarball` with a comment (values, needs Homebrew preinstalled, use where opencode.ai is blocked).
- [ ] **Step 2:** In `opencode.yml`:
  - first task asserts `opencode_package in ['tarball', 'brew']` (tag `versions`, like the baseline assert);
  - move the existing tasks into a `block` with `when: opencode_package == 'tarball'`;
  - brew `block` with `when: opencode_package == 'brew'`:
    1. shell: print `brew --prefix` from the first executable of `command -v brew`, `/home/linuxbrew/.linuxbrew/bin/brew`, `$HOME/.linuxbrew/bin/brew`; `changed_when: false`, `failed_when: false`, `check_mode: false`.
    2. assert rc == 0 with fail_msg "opencode_package: brew needs Homebrew preinstalled (https://brew.sh). See docs: Versions management > Install opencode with Homebrew".
    3. assert `github_packages.opencode == 'latest'`, fail_msg explains brew cannot pin.
    4. `community.general.homebrew`: `name: opencode`, `state: latest`, `update_homebrew: true`, `path: "{{ opencode_brew_prefix }}/bin"`.
    5. `file` link `~/.local/bin/opencode` → `{{ opencode_brew_prefix }}/bin/opencode`, `force: true`.
    6. shell `brew list --versions opencode`, strip name and `_N` revision → `opencode_version`; `changed_when: false`.
    7. `save_version.yml` with the same vars/tags as the tarball "Save used version" task.
- [ ] **Step 3: Verify**
  - `cd ansible && ansible-lint` → `Passed: 0 failure(s)`
  - `cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check` → no errors
  - Temporarily add `opencode_package: brew` to `ansible/vars/overrides.yml` (restore afterwards), run `ansible-playbook -i inventory.yml setup-ubuntu.yml --tags opencode --check -K` → fails at the Homebrew assert with the message above. Needs the user's sudo password; ask them to run it if needed.

### Task 2: Docs

**Files:**
- Modify: `docs-web/docs/main/customization/20-versions.md` (new `## Install opencode with Homebrew` after `## opencode v1 and v2`)
- Modify: `docs-web/docs/main/customization/10-variables.md` (row after `opencode_baseline`)
- Modify: `docs-web/docs/main/roles/10-software.md:101`

- [ ] **Step 1:** Section content: why (opencode.ai blocked; formula comes from GitHub/ghcr.io); `:::warning` Homebrew must be preinstalled, link https://brew.sh, searched locations; override snippet `opencode_package: brew`; limits: latest only (pins fail), `opencode_baseline` ignored, old `~/.local/opt/opencode-*` dirs are kept, the Docker image does not support it.
- [ ] **Step 2:** Variables row: `opencode_package` | `tarball` | `brew` installs with a preinstalled Homebrew, link to the section.
- [ ] **Step 3:** Software row: append "or with Homebrew (`opencode_package: brew`)".
- [ ] **Step 4: Verify** `cd docs-web && npm run build` → `[SUCCESS]`, no broken links.
