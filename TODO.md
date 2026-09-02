# TODO

- [x] fix(playbooks): Add idempotency checks to shell/command tasks that always report `changed` (TPM install, nvm install/alias, gvm default, puppet/rvm gems, ansible LS, FZF handler)
- [x] chore(playbooks): Document shell/command tasks that must run on every run (nvim headless sync, TPM update, version probes)
- [x] fix(playbooks): Fix tasks reporting `changed` on already-applied runs — Group A (from `ansible/playbook-run.log` analysis)
  - `setup-ubuntu.yml` ensure `current-versions.yml` → `copy` `content:""` `force:false` instead of `state: touch`
  - `software/tasks/rust.yml` → fix wrong `creates:` path (`~/.rust` never existed → `~/.cargo/bin/rustup`)
  - `software/tasks/nvm.yml` Install NVM → `changed_when` now ignores the `creates` "skipped, since … exists" stdout
  - `software/tasks/w32yank.yml` → stat-gate download/extract on existing `win32yank.exe`
  - `software/tasks/awscli.yml` → persistent download dest + drop `force: true`
  - `common/tasks/config_file.yml` → back up via module `backup: true` (only on change) + relocate into `config_backup_dir`; removed the always-changed timestamped copy
  - `software/tasks/puppet.yml` & `rvm.yml` gem installs → `gem install --conservative` (empty output when already present → green)
- [x] chore(playbooks): Treat npm global installs as must-run and document — Group B
  - `software/tasks/nvm.yml` npm default packages & `software/tasks/ansible.yml` language server: `npm install -g` always reports `changed N packages`; documented as accepted must-run
- [ ] fix(playbooks): Resolve Puppet Editor Services `changed` churn — Group C (needs further analysis)
  - `[Puppet Editor Services] Clone repository` reports `changed` every run: `rake gem_revendor` dirties `vendor/`, then `git force: true` resets it, which re-triggers the bundle/rake build
  - Options: gate the build on a real `pes_version` change (compare saved SHA) instead of `pes_clone.changed`; drop `force: true` or exclude vendored files; add `changed_when` to the rake task
  - Note: external `rvm1-ansible` role's "Install rvm installer" also reports `changed` (third-party, out of scope)
- [ ] docs(gita): Describe `gita` usage and example
- [x] fix(windows): `windows/tasks/main.yml:14` included `enterntainment.yml` (typo, double `n`) — actual file is `entertainment.yml`
  - `bundle_include.entertainment` defaults to `true` (`windows/vars/main.yml:10`), so the play failed for everyone
  - Dynamic `include_tasks`, so `--syntax-check` did not catch it — but `ansible-lint` did, as `load-failure[filenotfounderror]`
  - Fixed alongside the rest of the `windows` role's lint findings (task names, FQCN, trailing newline, play name)
- [x] chore(lint): Make ansible-lint a real gate
  - Consolidated the two divergent configs into `ansible/.ansible-lint` (root copy deleted); they disagreed
    111 findings vs 25 depending on the CWD you ran from
  - Added `exclude_paths` for `roles/*/files/` — static payload copied to the user's home, not Ansible code
  - Fixed: all 14 `windows` findings, 2 `yaml[trailing-spaces]` (`zsh.yml`), `recurse: no` → `false`
    (`config/tasks/tmux.yml`), `changed_when: true` on the two stat-gated tmux build steps
  - Suppressed with inline `# noqa` + a reason comment (matching the existing convention): `latest[git]`
    on the zsh plugin updater, `command-instead-of-shell` on the FZF handler, 3 × `yaml[line-length]`
  - New `.github/workflows/lint.yml`, path-filtered to `ansible/**`, on push + pull_request
  - Tree is now `Passed: 0 failure(s)`
- [ ] fix(windows): `ansible/vars/overrides.yml` cannot override `windows` role vars
  - `setup-windows.yml:2-3` loads it via `vars_files` (precedence 14), which loses to `roles/windows/vars/main.yml` (15)
  - So `win_username` stays `Jimmy` despite `ansible/vars/README.md:12-13` and `docs-web/docs/main/windows/20-automated.md` saying otherwise
  - Fix: switch to the `include_vars` pattern already used by `software`/`config`
- [x] fix(playbooks): `ansible.cfg` has two ineffective keys
  - `:3` `inventory = hosts` → `inventory = inventory.yml`; `-i inventory.yml` is now optional (still works when passed)
  - `:4` `ask_become_pass` removed — invalid under `[defaults]` and a confirmed no-op. Enabling the real
    `become_ask_pass` under `[privilege_escalation]` was rejected: with no TTY it prints a `BECOME password:`
    prompt, warns about echo, and silently accepts an empty password, so CI would go green on a swallowed EOF.
    `-K` stays the explicit mechanism, as every doc already states.
- [x] fix(tags): `software_packages`, `cleanup` and `sdkman_privilege` select nothing
  - `software_packages` added to the outer `tags:` of `[Software] Install packages`
    (`software/tasks/main.yml`) — now reachable via `--tags software_packages`
  - `cleanup` and `sdkman_privilege` left as skip-only by design: selecting them alone would run
    `cleanup_versions.yml` / the privileged SDKMAN tasks without the version resolution that happens
    earlier in the same task file. Documented as skip-only instead.
  - `docs-web/docs/main/customization/50-partial-run.md` tag list synced with `--list-tags` (added 12 missing
    tags, dropped removed `~thefuck~`), plus a "Skip-only tags" section and a note that `setup-windows.yml`
    has no tags
- [x] docs(vim): `docs-web/docs/usage/40-vim.md:385,391` show `setup-windows.yml --tags 'neovim,...'` — the windows playbook has no tags; should be `setup-ubuntu.yml`
- [ ] chore(versions): Decide the fate of `.latest-versions.yml` — it is committed but read by nothing
  - Its only consumers in `publish.sh:42-43` are commented out
  - Drifted: still lists `bat` and `pip_packages.thefuck`; missing `bottom`, `dry`, `hunk`, `kubecolor`, `kubeswitch`, `pay_respects`, `rvm1_ansible`
  - Either wire it back up or delete it and drop the reference in `docs-web/docs/main/download.md:20`
- [ ] chore(software): Remove dead `software/tasks/lunarvim.yml` — comments only, not referenced from `main.yml`
- [x] Migrate to AstroNvim / uninstall LunarVim / use Neovim release
- [x] install fswatch, ruby neovim-ruby-host, treesitter-cli, NPM neovim, gdu, bottom, NPM vscode-langservers-extracted
- [x] fix(neovim): Mason errors when opening VIM for the first time after new installation.
- [x] feat(go): Install GVM (Go Version Manager) and default GO.
- [x] feat(AWS): AWS cli installation
- [x] fix(vim): Markdown treesitter / LSP not working. Add/replace better plugins.
- [x] fix(ansible): Use the same version in `prepare-ubuntu.sh` which is set in vars.yml
- [x] feat(python): add and use `pyenv`, `pipenv`, use latest Python+Ansible
- [x] feat(kubernetes): install docker, kubectl, k9s, kind
- [x] feat(neovim): Install neovim-ruby-host for all rubies
- [x] docs: add usage descriptions with videos and images in `Usages.md`
