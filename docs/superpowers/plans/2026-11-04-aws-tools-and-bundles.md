# AWS/IaC tools and bundles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 12 AWS/IaC tools, tool bundles (tags + exclude names), a trimmed slim profile, tenv-managed Terraform/OpenTofu/Terragrunt, and the matching docs.

**Architecture:** Every tool is a standard software task. `software_bundles` in `roles/software/vars/main.yml` is the single bundle definition; Ansible expands bundle names in `software_tasks_exclude` after the overrides sandwich, and `docker/render-overrides.sh` expands them in the Docker inputs, so the rest only sees tool names.

**Tech Stack:** Ansible, bash, yq, Docusaurus.

**Spec:** `docs/superpowers/specs/2026-11-04-aws-tools-and-bundles-design.md`

## Global Constraints

- Shape after `eza.yml`: `github_version.yml` → `stat` gate → `~/.local/opt/<app>-<version>` → forced link in `~/.local/bin` → `save_version.yml` → `cleanup_versions.yml`.
- Shell tasks: `executable: /bin/bash`, `set -e -o pipefail`, correct `changed_when`/`creates`.
- Verified release assets (2026-11-04): granted `granted_<v>_linux_x86_64.tar.gz` (granted, assume, assumego); taws `taws-x86_64-unknown-linux-musl.tar.gz`; eksctl `eksctl_Linux_amd64.tar.gz`; eks-node-viewer raw `eks-node-viewer_Linux_x86_64`; stern `stern_<v>_linux_amd64.tar.gz`; crane `go-containerregistry_Linux_x86_64.tar.gz`; spacectl `spacectl_<v>_linux_amd64.zip`; tenv `tenv_v<v>_Linux_x86_64.tar.gz` (tenv + proxies terraform, tofu, terragrunt, terramate, tf, atmos); tflint `tflint_linux_amd64.zip`; terraform-docs `terraform-docs-v<v>-linux-amd64.tar.gz`; steampipe `steampipe_linux_amd64.tar.gz`; session-manager-plugin `https://s3.amazonaws.com/session-manager-downloads/plugin/<v>/ubuntu_64bit/session-manager-plugin.deb`, binary at `usr/local/sessionmanagerplugin/bin/session-manager-plugin` (extract with `dpkg-deb --fsys-tarfile | tar --strip-components=4`).
- tenv layout: `~/.tenv/{Terraform,OpenTofu,Terragrunt}/<version>/`, global version in `~/.tenv/<Tool>/version` (no trailing newline). Proxies need `tenv` on PATH.

## Review Focus

- Bundle in exclude + member in Docker `software_tasks_include` → member is installed and tested.
- `--tags terraform` with tenv missing → clear failure, not a broken symlink.
- Upgrade from a pre-tenv machine → old `~/.local/opt/terraform-*` gone, `~/.local/bin/terraform` points at tenv's proxy.
- Slim build → no Kubernetes/IaC/cloud check is selected by `test.sh --list`.
- Bundle member typo in `software_bundles` → run fails at start.

---

### Task 1: Bundles core
Files: `roles/software/vars/main.yml`, `roles/software/tasks/main.yml`.
- [ ] Add `software_bundles` (members per spec) and new `github_packages` keys.
- [ ] Add "[Software] Expand and check tool bundles" (tag `always`) after the merge and before the required check: assert members are include names and bundle names are not; `set_fact` expanded `software_tasks_exclude`.
- [ ] Add bundle tag to outer and `apply` tags of every member include.
- [ ] Verify: `ansible-lint`, `--syntax-check`, `--list-tags` shows the six bundles.

### Task 2: New tool tasks + tenv migration
Files: 12 new `roles/software/tasks/<tool>.yml`, rewritten `terraform.yml`, `tofu.yml`, `terragrunt.yml`, includes in `main.yml`, `config/templates/zshrc.j2` (`TENV_AUTO_INSTALL`, `assume` alias).
- [ ] Write tasks; verify with `ansible-lint`.

### Task 3: Docker
Files: `docker/render-overrides.sh`, `docker/profile-slim.yml`, `docker/test.sh`.
- [ ] Expand bundle names in `software_tasks_exclude`/`_include` before `apply_includes`.
- [ ] Slim: exclude the six bundles.
- [ ] `check_software_<tool>` for all 12; `test.sh --coverage` passes; `shellcheck` if available.

### Task 4: Docs
Files per spec "Docs" section; `npm run build` passes.
