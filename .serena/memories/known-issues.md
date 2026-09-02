# Known issues and drift

Found during a repo-wide audit. All also filed in `TODO.md`. Confidence noted per item.

## Confirmed bugs

**`windows/tasks/main.yml:14` includes a file that does not exist.** It says
`enterntainment.yml` (double `n`); the file is `entertainment.yml`. Since
`bundle_include.entertainment` defaults to `true` (`windows/vars/main.yml:10`), the
Windows play should fail for everyone. Dynamic `include_tasks`, so `--syntax-check` does
not catch it. *Confidence: high — file listing verified. Not executed against a Windows host.*

**`overrides.yml` cannot override `windows` role vars.** `setup-windows.yml:2-3` uses
`vars_files` (precedence 14), which loses to `roles/windows/vars/main.yml` (15). So
`win_username` stays `Jimmy` despite `ansible/vars/README.md:12-13` and
`docs-web/docs/main/windows/20-automated.md` instructing users to set it there. The Linux
roles avoid this by using `include_vars` (18). Workaround: `--extra-vars` (22) or edit the
role vars directly. *Confidence: high — precedence reproduced in an isolated test playbook.
End-to-end WinRM run not performed.*

**`ansible.cfg` has two ineffective keys.** `:3` `inventory = hosts` points at a file that
does not exist, so `-i inventory.yml` is always required. `:4` `ask_become_pass` is not a
valid `[defaults]` key (correct: `become_ask_pass` under `[privilege_escalation]`), so `-K`
is genuinely required. *Confidence: high — `ansible-config dump` shows
`DEFAULT_BECOME_ASK_PASS(default) = False`.*

**Three tags select nothing.** `software_packages`, `cleanup`, `sdkman_privilege` exist
only as `apply:` tags, never on a top-level `include_tasks`, so `--tags <name>` cannot
reach them. `--list-tags` omits all three. `--skip-tags cleanup` *does* work.
`software_packages` is documented as usable at
`docs-web/docs/main/customization/50-partial-run.md:63`. *Confidence: high — verified with
`--list-tasks --tags`.*

## Documentation errors

- `docs-web/docs/usage/40-vim.md:385,391` show `setup-windows.yml --tags 'neovim,...'`.
  The windows playbook has zero tags; these almost certainly mean `setup-ubuntu.yml`.
- Commit `9e1761d` says "Deep merge" but `combine()` at `software/tasks/main.yml:41-47`
  omits `recursive=true` — it is a shallow merge. Behaviourally identical for these flat
  dicts, but a reader grepping for `recursive` will not find it. (Contrast
  `save_version.yml:12`, which *does* pass it.)
- `ansible.cfg:7` `callback_result_format` appears to be a no-op — it does not show up in
  `ansible-config dump --type all`, unlike `result_format` at `:6`. *Confidence: medium,
  intent unclear.*

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
- `allow_broken_conditionals = True` in `ansible.cfg:9` — several `when:` expressions rely
  on lenient evaluation (e.g. `neovim.yml:67`).
