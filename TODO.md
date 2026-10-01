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
- [x] chore(versions): Decide the fate of `.latest-versions.yml` — it is committed but read by nothing
  - Deleted, with the commented-out lines in `publish.sh` and the reference in `docs-web/docs/main/download.md`
- [x] chore(software): Remove dead `software/tasks/lunarvim.yml` — comments only, not referenced from `main.yml`
  - Also removed the unused `lunarvim_remove` variable
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
- [ ] fix(neovim): `software/tasks/neovim.yml:11-16` passes a pipe to `ansible.builtin.command`, so the installed-version check never works and Neovim is reinstalled on every run
- [x] fix(nvm): `software/tasks/nvm.yml` installs with `creates:`, so nvm is never upgraded while `current-versions.yml` records the newly resolved version (native: installed 0.40.0, receipt 0.40.8)
  - The install now runs when `nvm --version` differs from `nvm_version`; install.sh upgrades the git checkout in place
- [ ] fix(opencode): `software/tasks/opencode.yml:24` picks the AVX2 build from the build host's `/proc/cpuinfo`; the published Docker image can crash with SIGILL on CPUs without AVX2
- [ ] fix(software): Most `software/tasks/*.yml` (incl. the canonical `eza.yml`/`hunk.yml`) gate the install on `~/.local/opt/<app>-<version>` existing, and create it before downloading. A failed download leaves the empty directory, so the next run skips the install, links a missing binary and `cleanup_versions.yml` deletes the working version. `opencode.yml` now checks the binary and retries the download; apply the same to the rest
- [ ] fix(ccmux): ccmux (<= 1.4.2) has no OpenCode v2 support. v2 rejects its v1 plugin, and runs plugins in the shared background service, outside any tmux pane, so ccmux's PID-to-pane lookup cannot work. `ccmux.yml` installs the plugin only when OpenCode is pinned to 1.x and removes it otherwise; re-enable it once ccmux supports v2
- [ ] fix(neovim): The AstroNvim config pins opencode.nvim to v1.0.2 and drives `opencode --port` servers; OpenCode v2 has no `--port`, so it must move to opencode.nvim `main`
- [x] fix(sdkman): `.zshrc` does not load SDKMAN, so `sdk`, `java`, `gradle`, `groovy`, `mvn` are not on the interactive PATH
- [x] chore(ci): `build.yml`'s weekly cron runs on the default branch `develop`, not `master`; confirm whether that is intended
  - Building `master` is intended (the checkout pins it), but three steps used `github.ref_name` (`develop`): the previous tag lookup failed, the 2026-09-25 run dropped the `[latest]` CHANGELOG section (`fd06813`), and the pre-release was named "develop". Fixed with `BUILD_BRANCH: master`; unverified until the next scheduled run
- [x] fix(neovim): The first Neovim start installs blink.cmp v2 from `main` (AstroNvim's `version = "^1"` is not loaded yet), which fails with "module 'blink.lib' not found" until `:AstroUpdate`
  - `config/neovim-config` runs `Lazy! update` once after a first install without a lockfile; `docker/test.sh` loads blink.cmp
- [x] fix(docker): Containers get `TERM=xterm`, so the p10k prompt has no colors; the image sets `TERM=xterm-256color`
- [x] docs(docker): Bind mounts need the image built with the user's UID/GID; build docs pass `USER_UID`/`USER_GID`, the entrypoint warns on a mismatch, and SSH key/agent mounts are documented
- [ ] fix(zsh): `source <(alias s=switch)` in `config/templates/zshrc.j2` defines the alias in a subshell, so `s` never exists; use `alias s=switch`
- [ ] chore(docker): The Docker workflow's scheduled run checks out `master`, which has no `docker/` until the next release. When the first image is published, remove the "not published yet" note in `docs-web/docs/main/docker/10-build.md`
