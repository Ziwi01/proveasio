# CI and verification

Deeper detail behind the "Verifying your work" section of `AGENTS.md`.

## Workflows (6 files, all in `.github/workflows/`)

`lint.yml` and `docker.yml` are the only `pull_request`-triggered workflows; the other four
run on push, schedule, tag or dispatch only.

### `build.yml` — "Build"
- Triggers: push to `master`, weekly cron `0 6 * * 5`, `workflow_dispatch`
- Runner `ubuntu-24.04`
- `sudo apt remove shim-signed grub-efi-amd64-bin -y --allow-remove-essential` (frees disk)
  → `sudo sh prepare-ubuntu.sh` → `ansible-playbook -i inventory.yml setup-ubuntu.yml`
  in `./ansible` (no `-K`; runners have passwordless sudo)
- Then: force-push `latest` tag, generate changelog via `requarks/changelog-action@v1`,
  create prerelease via `ncipollo/release-action@v1.12.0`, auto-commit `CHANGELOG.md`
  with `stefanzweifel/git-auto-commit-action@v4`
- **One of two functional tests**, with `docker.yml` (below). No linters run here.

### `build-26.yml` — "Build (26)"
`workflow_dispatch` only. `ubuntu-26.04`, same two steps, no release plumbing. Forward-
looking LTS smoke test.

### `pages.yml` — "Documentation"
- Triggers: push to **`develop`**, `workflow_dispatch`
- `npm install` then `npm run build` in `docs-web`, upload `docs-web/build`, deploy via
  `actions/deploy-pages@v4`
- Reproducible locally with the command below, like `lint.yml` (`cd ansible &&
  ansible-lint`). The smoke build in `AGENTS.md` covers the image path.

### `release.yml` — "Release"
Triggers on `v*` tags. Changelog + non-prerelease GitHub Release + prune old prereleases.
No build, no lint.

### `lint.yml` — "Lint"
- Triggers: `push` **and** `pull_request`, both path-filtered to `ansible/**` and
  `.github/workflows/lint.yml`; plus `workflow_dispatch`
- `ubuntu-latest`, `actions/setup-python@v5` with `3.12` (ansible-core 2.21 needs >= 3.12)
- `pip install "ansible-lint~=26.8"` → `ansible-galaxy collection install ansible.windows
  chocolatey.chocolatey community.general` → `ansible-lint --offline` in `./ansible`
- The `~=` pin is deliberate: it lets patch fixes through but blocks a major rule overhaul
  from breaking the gate. **Nothing bumps it** — Dependabot runs on this repo but only for
  `/docs-web` npm, and there is no `.github/dependabot.yml`.
- The collections are not needed for a *pass* (without them ansible-lint still exits 0),
  but without them the log fills with "Unable to load module ..." warnings and module
  option validation is silently skipped.

### `docker.yml` — "Docker image"
- Triggers: push to `master`/`develop`, `v*` tags, `pull_request` (path-filtered), weekly
  cron, `workflow_dispatch`. A `plan` job path-filters `develop` pushes.
- Runs the playbook inside `docker buildx bake`, then `docker/test.sh` in the `test` stage;
  publishes to Docker Hub only for pushes to `master`, manual runs on `master`, the
  schedule, and `v*` tags.
- **Has not run on GitHub yet.** Details in the `docker-image` memory. Locally, the smoke
  build in `AGENTS.md` is the non-destructive functional check.

## What "done" actually means

CI verifies three things: the playbook runs green on Ubuntu 24.04, the Docusaurus site
builds, and `ansible/` passes ansible-lint. Nothing else is gated yet; `docker.yml` adds
the image build and `docker/test.sh` once it runs on GitHub.

## Commands

```bash
cd docs-web && npm install && npm run build   # gate 1; CI uses `install`, not `ci`
cd ansible && ansible-lint                    # gate 2; must say `Passed: 0 failure(s)`
cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check
```

**There is exactly one ansible-lint config: `ansible/.ansible-lint`.** A second copy at
the repo root was deleted — the two disagreed (111 findings vs 25) depending on CWD.

`npm run build` **is** the docs lint: `docusaurus.config.js:24` sets
`onBrokenLinks: 'throw'`, so any broken internal link fails the build.
`onBrokenMarkdownLinks: 'warn'` only warns.

## Confirmed absent — do not invent

- No `npm run lint` / `test` / `typecheck` (`docs-web/package.json` scripts are only
  `start build serve clear deploy swizzle write-translations write-heading-ids`)
- No markdownlint binary, dependency, or workflow reference. `.markdownlint.json`
  (`{"line-length": false}`) is editor-only
- No Lua linter. `.luarc.json` is a lua-language-server setting. The only `.lua` file is
  `docker/nvim-install.lua`, and nothing lints it (the Neovim config lives in an external
  repo cloned by Ansible)
- No `.pre-commit-config.yaml`, no `.editorconfig`, no installed git hooks
  (`.git/hooks/` has only the stock samples, `core.hooksPath` unset)
- No husky, lint-staged, eslint, prettier, Makefile, Taskfile, justfile, tox, pytest
- No `CONTRIBUTING.md`
- `yamllint` happens to be installed but there is no `.yamllint` and no convention around
  it; ansible-lint bundles its own yamllint pass

**ansible-lint is enforced by `lint.yml`** (see above).

## Docs site

Docusaurus 3.9.2, classic preset, ESM config, Node >= 18. `routeBasePath: '/'`,
`blog: false`, local search via `@easyops-cn/docusaurus-search-local`.

- `docs-web/docs/` = the `develop`/current version. `docs/main/` → `mainSidebar`,
  `docs/usage/` → `usageSidebar`, both autogenerated. Numeric filename prefixes control
  order; `_category_.yml` sets group position/label
- `docs-web/versioned_docs/version-stable/` = frozen stable, regenerated by `rsync` in
  `publish.sh:19`. **Never hand-edit**
- `docs-web/README.md` documents yarn — stale `create-docusaurus` boilerplate, there is no
  `yarn.lock`, CI uses npm

## Bootstrap scripts

`prepare-ubuntu.sh` (89 L, mode 755) is the intended first-run entry point and is what CI
runs. Requires root, re-drops to `$SUDO_USER` for the user half. Installs pyenv build deps,
`yq` → `/usr/bin`, pyenv, Python 3.14.0, then pip-installs `ansible` (full distribution),
`setuptools`, `pywinrm[credssp]`/`[kerberos]`. It reads the desired Ansible version with
`yq '.ansible_pip_version' ansible/roles/software/vars/main.yml` — a hard coupling to
`software/vars/main.yml:178`.

`prepare-windows.ps1` (38 L) runs first on the Windows side, as Administrator: installs
WSL2 + Ubuntu-24.04, `winrm quickconfig`, Ansible's `ConfigureRemotingForAnsible.ps1
-EnableCredSSP -DisableBasicAuth`, `Enable-WSManCredSSP -Role Server`, Chocolatey.
Documented as experimental (`:::danger` admonition in the docs).

## Commit statistics (last 400 commits)

`fix` 115, `feat` 85, `build` 78 (49 of them Dependabot), `release` 61, `chore` 34,
`refactor` 5, `docs` 3, `test` 1. Scopes are lowercase, often a tool name; compound scopes
occur (`fix(tmux/opencode):`). Subject after the colon is Capitalized, no trailing period.
Breaking changes use `!`.

`CHANGELOG.md` is machine output (emoji section headers, commit-SHA links, `*(commit by
[@Ziwi01])*` attribution) committed by CI. It is currently stale — top section says
`[latest] - 2024-08-28` while the newest tag is `v3.0.0`.
