# Ansible architecture

Deeper detail behind the Architecture section of `AGENTS.md`.

## Playbooks

Only two: `ansible/setup-ubuntu.yml` (61 lines) and `ansible/setup-windows.yml` (6 lines).

`setup-ubuntu.yml` structure:
- `:2` `hosts: ubuntu` — targets the **host**, not the `linux` group
- `:5-28` play-level `summary` var: ASCII banner + `{{ current_versions | to_nice_yaml }}`
- `:30-35` `[Init] Check sudo password` — a throwaway `echo` with `become: true`, tagged
  `always`, purely to fail fast on a bad sudo password before an hour of work
- `:37-42` resets the `current_versions` fact to `{}`
- `:43-50` `copy` with `force: false` to guarantee `current-versions.yml` exists
- `:51,54` `import_role` (static) — `software` then `config`
- `:57-61` `debug: var=summary`, tagged `always`

Neither `prepare-ubuntu.sh` nor `prepare-windows.ps1` runs `ansible-playbook`. They are
bootstrap-only; invocation is manual and documented only in `docs-web/docs/`.
No `--extra-vars` is used anywhere. `GITHUB_TOKEN` is passed as an environment variable.

## Role file counts

| Role | `tasks/*.yml` | `vars/` | `files/` | `templates/` | `handlers/` |
|---|---|---|---|---|---|
| `common` | 4 | no | no | no | no |
| `config` | 10 | yes | yes | yes | no |
| `software` | 47 | yes | yes | no | yes |
| `windows` | 6 | yes | yes | yes | no |

No role has `defaults/` or `meta/`. That is load-bearing: `vars/` outranks `group_vars`,
and the absence of `meta/` means zero declared dependencies.

## The four `common` contracts

- **`github_version.yml`** (84 L) — in: `app`, `version_query`, plus `repo`+`github_uri`
  or `artifact_url`. `:15-42` resolves a GitHub token once per run (sentinel
  `github_api_token_resolved`). `:44-63` runs `version_query` in bash with an injected
  `gh_curl()` helper, only when `github_packages[app] == 'latest'`. `:65-67` sets fact
  `<app>_version`. `:69-79` fails with a rate-limit message if empty. `:81-84` sets `<app>_url`.
- **`save_version.yml`** (12 L) — in: `app`, `yq_query`, `target_version`. Shells out to
  `yq -i` against `current-versions.yml`, then merges `target_version` into the
  `current_versions` fact (this one *does* use `recursive=true`).
- **`config_file.yml`** (33 L) — in: `app`, `target_file`, and one of
  `source_template` / `source_file`. Branches template-vs-copy, both with
  `backup: {{ config_files_backup }}`, then relocates the backup into
  `{{ config_backup_dir }}/<app>-<basename>-<timestamp>`.
- **`cleanup_versions.yml`** (38 L) — in: `app`, `keep`. Finds `~/.local/opt/<app>-*` and
  deletes all but `<app>-<keep>`. Gated on `cleanup_old_versions` and
  `cleanup_old_versions_exclude`.

## Ordering inside `software/tasks/main.yml` (666 lines)

`packages` (apt deps) → `yq` → ... → `nvm` (`:463`) → `ansible` (`:505`, sources
`~/.local/opt/nvm/nvm.sh`) → ... → `ccmux` (`:655`, last).

`yq` (`:64-74`) is the **only** tool with no `software_tasks_exclude` guard — it cannot be
excluded because `common/save_version.yml` shells out to `yq` for every other tool.

## Cross-role coupling (software -> config)

`config` reads things `software` defines. Concrete cases:
- `config/tasks/sdkman.yml:7` uses `sdkman_dir` from `software/vars/main.yml:193`
- `config/tasks/zsh.yml:8` uses `node_version` from `software/vars/main.yml:172`
- `config/templates/zshrc.j2:120` uses `eza_version`, a **fact** set at runtime by
  `software/tasks/eza.yml`; `config/tasks/zsh.yml:16-30` greps `~/.local/opt/eza-*` as a
  fallback for `--tags config`-only runs

## Inventory and connections

`ansible/inventory.yml` (8 lines) defines groups `linux`/`windows` with hosts
`ubuntu`/`win`. Playbooks target the **hosts**; `group_vars/` files are named for the
**groups**. The scalar `hosts: ubuntu` form (rather than a mapping) is unusual but valid.

- Ubuntu is pure localhost: `ansible_connection: local` (`group_vars/linux.yml:2-3`)
- Interpreter split: modules run under `/usr/bin/python3`, while `ansible-playbook` itself
  runs from the pyenv 3.14.0 install created by `prepare-ubuntu.sh`. `pip` tasks therefore
  target `~/.pyenv/shims/pip3` explicitly
- `group_vars/windows.yml:3` derives the Windows host IP by scraping `/etc/resolv.conf`.
  Breaks under WSL2 mirrored networking or `generateResolvConf=false`. WinRM over
  HTTPS/5986 with credssp, cert validation disabled
- No `delegate_to` anywhere. Windows interop is done by shipping `.exe` files into
  `~/.local/bin` inside WSL (`w32yank.yml`, `wsl-notify-send.yml`)

## Adding a `config` entry

Create `config/tasks/<tool>.yml`, drop the asset in `config/files/` (pass `source_file:`)
or `config/templates/*.j2` (pass `source_template:`), call `common/config_file.yml`, then
register in `config/tasks/main.yml` with a `config_tasks_exclude` guard and
`tags: [config, <tool>]`. Only zsh and git use templates.

## Linting nuance

Two `.ansible-lint` files exist and differ. Root skips `name[template]`,
`command-instead-of-module`, `var-naming[no-role-prefix]`; `ansible/.ansible-lint` skips
only the last. A third copy at `config/files/ansible-lint` is a *product artifact*
deployed to `~/.ansible-lint` — not a repo lint config.
