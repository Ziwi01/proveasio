# Known issues and drift

Found during a repo-wide audit. All also filed in `TODO.md`. Confidence noted per item.

## Confirmed bugs

**`overrides.yml` cannot override `windows` role vars.** `setup-windows.yml:2-3` uses
`vars_files` (precedence 14), which loses to `roles/windows/vars/main.yml` (15). So
`win_username` stays `Jimmy` despite `ansible/vars/README.md:12-13` and
`docs-web/docs/main/windows/20-automated.md` instructing users to set it there. The Linux
roles avoid this by using `include_vars` (18). Workaround: `--extra-vars` (22) or edit the
role vars directly. *Confidence: high — precedence reproduced in an isolated test playbook.
End-to-end WinRM run not performed.*

## Fixed

**`enterntainment.yml` typo — FIXED.** `windows/tasks/main.yml` now includes
`entertainment.yml`. Worth remembering *how* it was found: `--syntax-check` cannot see
dynamic `include_tasks`, but **ansible-lint reports it** as
`load-failure[filenotfounderror]`. Fixed together with the rest of that file's findings
(5 × `name[missing]`, 5 × `fqcn[action-core]`, missing trailing newline) and
`setup-windows.yml` (`name[play]`, `yaml[brackets]`). The `yaml[brackets]` fix removed
only the spaces inside `- [ vars/overrides.yml ]` → `- [vars/overrides.yml]`; the inner
list (first-found semantics) was left alone because the `vars_files` → `include_vars`
rework is still open.

**Two divergent ansible-lint configs — FIXED.** There used to be `.ansible-lint` at the
repo root *and* `ansible/.ansible-lint` with different `skip_list`s, so the result depended
on your CWD: `cd ansible && ansible-lint` → 111 findings, `ansible-lint -c .ansible-lint
ansible/` → 25. The delta was exactly the 86 `name[template]` findings caused by the
`"[Tool] ..."` task-name convention. The root file is deleted; `ansible/.ansible-lint` is
now the only config and also excludes `roles/*/files/` (static payload, not Ansible code).
The tree is now `Passed: 0 failure(s)` — treat any finding as newly introduced.

**ansible-lint is now enforced.** `.github/workflows/lint.yml`, path-filtered to
`ansible/**`, on `push` + `pull_request`. This is the repo's first PR-triggered workflow.
Installs `ansible-lint~=26.8` plus `ansible.windows`, `chocolatey.chocolatey` and
`community.general` — without those collections ansible-lint still exits 0 but floods the
log with "Unable to load module" warnings and skips module option validation. Verified by
simulating the whole job in a clean venv.

**`ansible.cfg` ineffective keys — FIXED.** `:3` is now `inventory = inventory.yml`, so
`-i inventory.yml` is optional (verified: `ansible-playbook setup-ubuntu.yml --list-hosts`
resolves host `ubuntu` with no `-i`). The invalid `[defaults] ask_become_pass` key was
**deleted**, not migrated: enabling the real `[privilege_escalation] become_ask_pass = True`
was tested in `/tmp` with stdin at `/dev/null` and it does not hang — it falls back to
`fallback_getpass`, prints `BECOME password:` plus `Warning: Password input may be echoed`,
reads EOF as an empty password and exits 0. That would make CI green on a swallowed EOF.
`-K` stays the explicit mechanism. *Note `ansible-config dump --only-changed` no longer lists
any become key; `DEFAULT_BECOME_ASK_PASS(default) = False`.*

**`software_packages` tag — FIXED.** Added to the outer `tags:` of `[Software] Install
packages` (`software/tasks/main.yml`). Verified: it now appears in `--list-tags` and
`--list-tasks --tags software_packages` selects the task.

**`cleanup` / `sdkman_privilege` still select nothing — deliberate, not a bug.** Making them
selectable would run `cleanup_versions.yml` with `keep: "{{ <app>_version }}"` undefined
(version resolution happens earlier in the same task file, e.g. `eza.yml:80-94`). Both work
as `--skip-tags` and cleanup is reachable via `--tags versions`. Now documented as skip-only
in `docs-web/docs/main/customization/50-partial-run.md`.

## Documentation errors

- Commit `9e1761d` says "Deep merge" but `combine()` at `software/tasks/main.yml:41-47`
  omits `recursive=true` — it is a shallow merge. Behaviourally identical for these flat
  dicts, but a reader grepping for `recursive` will not find it. (Contrast
  `save_version.yml:12`, which *does* pass it.)
- `ansible.cfg:6` `callback_result_format` appears to be a no-op — it does not show up in
  `ansible-config dump --type all`, unlike `result_format` at `:5`. *Confidence: medium,
  intent unclear.* (Line numbers shifted by one when `ask_become_pass` was deleted.)

## Dead code and drift

- **`software/tasks/lunarvim.yml`** — 5 lines of comments, not referenced from `main.yml`.
- **`.latest-versions.yml`** — committed, but its only consumers in `publish.sh:42-43` are
  commented out. Nothing reads it. Drifted from `software/vars/main.yml`: still lists
  `bat` (moved to `default_apt_packages`) and `pip_packages.thefuck` (replaced by
  `pay_respects`); missing `bottom`, `dry`, `hunk`, `kubecolor`, `kubeswitch`,
  `pay_respects`, `rvm1_ansible`. Updating it is inconsistently observed — commit
  `854cceb` did, `6c212de` did not.
- **`current-versions.yml`** accumulates stale keys because it is written one key at a time
  and never truncated. The checked-out copy still has `astronvim_config_version`, renamed
  to `neovim_config_version` long ago. Both keys are present.
- **`CHANGELOG.md`** is stale: top section `[latest] - 2024-08-28` vs newest tag `v3.0.0`.

## Deliberate, not bugs

- `git-fuzzy.yml`, `lsg.yml`, `rust.yml`, `gvm.yml`, `awscli.yml` skip `save_version`.
  Deliberate for most (`awscli.yml:41-80` has bespoke cleanup), though `git-fuzzy` resolves
  a version and then never records it.
- Task name prefix casing is inconsistent (`[EZA]`, `[Tmux]`, `[ccmux]`). No enforced rule.
- `allow_broken_conditionals = True` in `ansible.cfg:8` — several `when:` expressions rely
  on lenient evaluation (e.g. `neovim.yml:67`).
