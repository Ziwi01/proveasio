# Proveasio

Ansible-based provisioning for a developer workstation: Ubuntu (native or WSL2) is the
primary target, with an experimental Windows-over-WinRM side. There is no application
code here — the "product" is the set of roles, the software catalog, and the docs site.

## Running it

Two requirements that are easy to get wrong:

```bash
cd ansible                                                    # ansible.cfg is discovered from CWD only
ansible-playbook -i inventory.yml setup-ubuntu.yml -K         # -K is mandatory, -i is now optional
```

- **`cd ansible/` first.** From the repo root, Ansible falls back to `/etc/ansible/ansible.cfg`.
- **`-K` is mandatory.** `ansible.cfg` deliberately does *not* set `become_ask_pass`: without a
  TTY it prompts, warns about echoed input, and silently accepts an empty password. CI gets away
  without `-K` only because runners have passwordless sudo.
- `-i inventory.yml` is **optional** — `ansible.cfg:3` sets `inventory = inventory.yml`. Every doc
  and both workflows still pass it explicitly; keep doing so for clarity.

Useful subsets: `--tags versions` (re-resolve + prune), `--tags config`, `--tags <tool>`,
`--skip-tags software`. Set `GITHUB_TOKEN` or run `gh auth login` first — a full run makes
~33 GitHub API calls against a 60/hour unauthenticated limit.

## Verifying your work

```bash
# Gate 1 (.github/workflows/pages.yml). Fails on broken internal links because
# docusaurus.config.js:24 sets onBrokenLinks: 'throw'.
cd docs-web && npm install && npm run build

# Gate 2 (.github/workflows/lint.yml). MANDATORY for any change under `ansible/` —
# the workflow is path-filtered to `ansible/**` and runs on push and pull_request.
# Must report `Passed: 0 failure(s)`; the tree is currently clean, so any finding is yours.
cd ansible && ansible-lint

# Cheap local proxy for the playbook. Does not catch errors in dynamic include_tasks
# (ansible-lint does — it is what caught the `enterntainment.yml` typo).
cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check
```

**There is exactly one ansible-lint config: `ansible/.ansible-lint`.** It lives there
because ansible-lint discovers config from the CWD and every invocation is
`cd ansible && ansible-lint`. A second, divergent copy used to sit at the repo root and
silently produced a different result (111 findings vs 25) depending on where you ran from
— do not reintroduce it.

To silence a finding, prefer an inline `# noqa: <rule>` on the offending line with a
comment explaining why; that is the existing convention (see `puppet.yml`, `nvm.yml`,
`docker.yml`). Only add to `skip_list` when the rule conflicts with a project-wide
convention. `roles/*/files/` is excluded because it is static payload copied to the
user's home, not Ansible code.

**These do not exist — do not invent or "restore" them:** `npm run lint`, `npm run test`,
any markdownlint runner, any Lua linter, `make`, `just`, `pytest`, pre-commit hooks.
`.markdownlint.json` and `.luarc.json` are editor-only settings; the repo contains zero
`.lua` files.

The only functional test in the project is `.github/workflows/build.yml`: a full playbook
run on a clean Ubuntu 24.04 runner, on push to `master` and weekly. It is destructive —
never run the full playbook to "check" something on a real machine.

## Architecture

Four roles, and that is all: `common`, `config`, `software`, `windows`. What looks like a
group of sub-roles is just task files inside one role's `tasks/`.

- **`common`** has no `tasks/main.yml` — it is a headless helper library, never run as a
  role. It is invoked ~85× via `include_role` + `tasks_from` with `vars:` as arguments.
  Four contracts: `github_version.yml` (resolve a version, set `<app>_version` and
  `<app>_url`), `save_version.yml` (write to `current-versions.yml` via `yq`),
  `config_file.yml` (template-or-copy with backup), `cleanup_versions.yml` (prune old
  `~/.local/opt` dirs).
- **`software`** (47 task files) installs things. **`config`** (10 task files) lays down
  dotfiles. **`windows`** is independent and shares nothing with the rest.
- **Order is hard-wired**, not declared: `setup-ubuntu.yml:51,54` statically imports
  `software` then `config`. No role has `meta/main.yml`, so there are zero declared
  dependencies. `config` reads variables and facts set by `software` — this only works
  because `import_role` is static and keeps vars in play scope. A `--tags config`-only run
  is a degraded mode; `config/tasks/zsh.yml:16-30` exists purely to paper over it.

## Variables and overrides — the most important non-obvious thing

The project uses **`vars/main.yml`, never `defaults/main.yml`**. Role `vars` sit at
precedence 15, which beats `group_vars` (7) and play `vars_files` (14). A naive override
therefore cannot win.

The Linux path solves this by loading `ansible/vars/overrides.yml` with `include_vars`
(precedence 18) from inside the role — `software/tasks/main.yml:32-39` and
`config/tasks/main.yml:13-20`, both with `skip: true` so the gitignored file is optional.

Because `include_vars` *replaces* a whole variable, pinning two tools under
`github_packages:` would wipe the other 31 entries. The fix is a sandwich at
`software/tasks/main.yml:16-47`: snapshot the catalogs → `include_vars` → `combine()` the
user's pins back on top (`set_fact`, precedence 19, outranks the include).

- **Only three catalogs merge:** `github_packages`, `pip_packages`, `docker_apt_packages`.
  Every other override is still a full replace.
- The merge is **shallow** — `combine()` is called without `recursive=true`. Equivalent for
  these flat dicts, but the commit message calling it "deep merge" is misleading.
- `group_vars/` holds **connection plumbing only**. All behavioural config lives in role `vars/`.
- `group_vars/windows.yml:3` scrapes the Windows host IP out of `/etc/resolv.conf`. This
  breaks under WSL2 mirrored networking or `generateResolvConf=false`.

To change behaviour: personal/machine-local → `ansible/vars/overrides.yml` (gitignored).
Project-wide default → `roles/<role>/vars/main.yml`.

## Version management

Flow: `github_version.yml` resolves `<app>_version` (skipping the API call entirely if the
version is pinned) → `stat` gate on `~/.local/opt/<app>-<version>` → install into that
versioned dir → forced symlink into `~/.local/bin` → `save_version.yml` → `cleanup_versions.yml`.

Two files that are the opposite of what their names suggest:

- **`current-versions.yml`** — gitignored, generated, and **write-only**. Nothing reads it.
  It is a per-machine receipt, written one key at a time by `yq`, never truncated, so it
  accumulates stale keys. Do not hand-edit it, and do not paste it wholesale into overrides.
- **`.latest-versions.yml`** — committed, hand-maintained, and read by **nothing**. Its only
  consumers in `publish.sh` are commented out. It has drifted from the real catalog.

`publish.sh` is a maintainer release script whose version-pinning half is commented out.
Do not run it. All versions have been `latest` since 2.0.0.

Not everything resolves through GitHub: `kubectl` uses `dl.k8s.io/release/stable.txt`, apt
and pip tools use `state: latest` / `--upgrade` and read the version back, SDKMAN does not
support `latest` at all, and a few entries are hard-pinned.

## Adding software — four edits minimum

1. `roles/software/tasks/<tool>.yml` — copy `hunk.yml` or `eza.yml`; they are the canonical shape.
2. Register in `roles/software/tasks/main.yml` with
   `when: "'<tool>' not in software_tasks_exclude"` and `tags: [software, versions, <tool>]`.
3. Add the key to `github_packages` in `roles/software/vars/main.yml`. **Required** —
   `common/tasks/github_version.yml` looks up `github_packages[app]`.
4. Update the docs (see below).

**The `app` naming trap.** Up to three spellings of the same tool coexist:

- filename, tag, and `software_tasks_exclude` key → **kebab-case** (`diff-so-fancy`)
- `github_packages` key and the `app:` passed to `github_version.yml`/`save_version.yml` →
  **snake_case** (`diff_so_fancy`)
- the `app:` passed to `cleanup_versions.yml` → the **on-disk directory prefix**, which may
  be a third form (`rvm.yml` uses `rvm1_ansible` for lookup and `rvm1-ansible` for cleanup)

Get this wrong and the lookup errors or cleanup silently no-ops.

Other conventions: every `shell:` task sets `args.executable: /bin/bash` and starts with
`set -e -o pipefail`; version queries must use the injected `gh_curl` helper, never bare
`curl`, or they lose authentication; task names are prefixed `"[Tool] ..."`.

## Tags: what actually works

Tags are attached twice — outer `tags:` select whether the dynamic `include_tasks` runs at
all, `apply.tags` stamp the tasks inside it. Only the outer ones can select.

- `--tags cleanup` and `--tags sdkman_privilege` **select nothing** — they exist only as
  `apply:`/inner tags, and that is deliberate: running them alone would skip the version
  resolution they depend on. Both work as `--skip-tags`; cleanup is reached via `--tags versions`.
- `--tags software_packages` **does** work (it is on the outer `tags:` of `[Software] Install
  packages`). Anything else you add must go on the outer `tags:` to be selectable.
- `--tags eza` also pulls in config's zsh task — deliberate, because `zshrc.j2` embeds the
  eza version. Same for `zsh` → p10k.
- The `windows` role has **zero tags**. Subset it with `bundle_include` instead.
- `ansible-playbook setup-ubuntu.yml --list-tags` is the source of truth; keep
  `docs-web/docs/main/customization/50-partial-run.md` in sync with it.

## Docs are part of the change

Every `feat:` commit touches `docs-web/docs/` in the same commit. Adding a tool means
updating `docs-web/docs/main/roles/10-software.md`,
`docs-web/docs/main/features/60-other-software.md`, and the tag list in
`docs-web/docs/main/customization/50-partial-run.md`.

Edit **`docs-web/docs/` only**. `docs-web/versioned_docs/version-stable/` is regenerated by
`rsync` in `publish.sh` at release time — never hand-edit it. `docs-web/README.md` mentions
yarn; that is stale boilerplate, the project uses npm.

## Commits and branches

Conventional Commits with a **capitalized subject**: `fix(neovim): Restore Mason bootstrap`.
Breaking changes use `!`. Work lands on **`develop`**; `master` is rebased from it at
release time. Docs deploy from `develop`, the full build runs on `master`.

`CHANGELOG.md` is generated by CI and auto-committed — **never hand-edit it**. `TODO.md` is
hand-maintained and uses the same `type(scope):` prefixes.

## Deeper context

Serena memories hold the detail that does not belong in this file: `ansible-architecture`,
`version-management`, `ci-and-verification`, `known-issues`. List and read them when a task
goes beyond what is above.
