# Version management

Deeper detail behind the Version management section of `AGENTS.md`.

## Precedence chain

| # | Source | Ansible precedence |
|---|---|---|
| 1 | `roles/software/vars/main.yml` catalogs | role vars (15) |
| 2 | `roles/config/vars/main.yml` (`neovim_config_version`) | role vars (15) |
| 3 | `ansible/vars/overrides.yml` | `include_vars` (18) |
| 4 | merge-back at `software/tasks/main.yml:41-47` | `set_fact` (19) — beats #3 |
| 5 | `<app>_version` fact from `github_version.yml:66-67` | `set_fact` (19) |
| 6 | `-e` on the CLI | extra vars (22) |

`current-versions.yml` never enters this chain. It is write-only.

## Worked trace (eza)

1. `software/tasks/eza.yml:4-17` sets `app`, `repo`, `version_query`, `github_uri` and
   delegates to `common/github_version.yml`
2. token resolved once per play (`:15-42`)
3. `version_query` runs **only if** `(github_packages[app] | default('latest')) == 'latest'`
   — a pinned version means no network call at all
4. `set_fact: "{{ app }}_version"` with `version.stdout | default(github_packages[app] | default('latest'))`,
   so a skipped lookup falls through to the pinned literal
5. fail-if-empty guard
6. `<app>_url` built from `artifact_url` or `https://github.com/{repo}/releases/download/{github_uri}`
7. back in `eza.yml`: `stat` gate → install to `~/.local/opt/eza-<version>` → forced
   symlink in `~/.local/bin` → `save_version.yml` → `cleanup_versions.yml`

## GitHub authentication (commit 834c772)

33 call sites use `version_query`. Token precedence, resolved once per run and guarded by
`github_api_token_resolved`:

1. `github_api_token` var (e.g. in `overrides.yml`)
2. `GITHUB_TOKEN` / `GH_TOKEN` env
3. `gh auth token` (`failed_when: false`, so it degrades silently)

`default(..., true)` means an *empty-string* token also falls through, not just an
undefined one. All token tasks are `no_log: true`.

The token reaches curl through a bash function injected into every query's preamble:

```bash
gh_curl() {
  auth=()
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  curl -s "${auth[@]}" "$@"
}
```

This is why all 33 queries start with `gh_curl`, and why `executable: /bin/bash` matters
(bash arrays). **Exception:** `neovim.yml:29-42` (the `nightly` branch) bypasses
`github_version.yml` and inlines the same auth logic by hand. Any new ad-hoc GitHub query
must do the same.

Rate limits: 60/hour unauthenticated per public IP, 5000/hour authenticated. A full run
makes ~33 calls, so two consecutive runs exhaust the unauthenticated budget. On exhaustion
`github_version.yml:69-79` hard-fails the play with an explanatory message — it does not
fall back to the installed version. Token needs **no scopes**.

Three tools query the *commits* endpoint rather than releases, so they resolve to a 40-char
SHA: `git-fuzzy.yml:10`, `tmux.yml:23` (tpm), `puppet.yml:55` (pes).

## Resolution paths that bypass github_version.yml

| Mechanism | Example | How `latest` resolves |
|---|---|---|
| GitHub API (33 sites) | `eza.yml` | `common/github_version.yml` |
| k8s release channel | `kubectl.yml:8-19` | `curl https://dl.k8s.io/release/stable.txt` |
| APT `state: latest` | `git.yml`, `azurecli.yml`, `docker.yml` | apt resolves, version read back |
| pip | `gita.yml`, `ansible.yml`, `tmux.yml` | `--upgrade`, then `pip3 show` |
| nvm | `nvm.yml:40-60` | `node_version` is an alias (`lts/jod`) |
| SDKMAN | `sdkman.yml` | **`latest` unsupported** — literal versions only |
| git checkout | `config/tasks/neovim-config.yml` | `neovim_config_version: main` (a ref) |
| hard-pinned | `software/vars/main.yml:94,157,159-160,223-224` | `rvm1_ansible: 2.2.0`, `puppet_version: 8.4.0`, ... |

## Pinning a version

Edit `ansible/vars/overrides.yml` (gitignored) with only the pins:

```yaml
github_packages:
  tmux: "3.7c"
  neovim: "0.12.5"
```

- **No `v` prefix** — `software/vars/main.yml:68` says so; the `v` is re-added by each
  task's `github_uri`
- Quote values that look numeric
- Pinning skips the API call, so it doubles as the rate-limit workaround
- Only the three catalogs merge; anything else in `overrides.yml` is a full replace
- Do **not** paste a whole `current-versions.yml` — it carries dead keys such as
  `astronvim_config_version` (renamed to `neovim_config_version`)

## publish.sh

52 lines, maintainer-only, most of it commented out. Live path: rsync
`docs-web/docs/` → `docs-web/versioned_docs/version-stable/`, commit
`build: Release updated docs`, push, checkout `master`, pull, rebase `develop`, push,
checkout `develop`.

The commented halves (`:9-16`, `:42-52`) were a two-phase pin/unpin release cycle,
disabled by commit `c28f984` (Sep 2024). `git show master:...vars/main.yml` confirms
`master` is also all-`latest`, so the model is genuinely abandoned, not paused.
