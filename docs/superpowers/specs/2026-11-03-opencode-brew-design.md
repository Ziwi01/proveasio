# Install opencode with Homebrew

## Intent

Some machines sit behind a firewall that blocks `opencode.ai`. The default
opencode install resolves the version from the opencode.ai update service and
downloads the tarball from `opencode.ai/files/bin`, so it fails there. The
homebrew-core `opencode` formula is v2 (2.2.5 at the time of writing, same as
opencode.ai), builds from the GitHub source tag and ships Linux bottles
(x86_64, arm64) from `ghcr.io`. It never touches opencode.ai.

## Goals

- `opencode_package: brew` installs and upgrades opencode through an existing
  Homebrew.
- The docs state that Homebrew must be preinstalled.

## Non-goals

- Installing Homebrew.
- Homebrew in the Docker image (it has none; `docker/test.sh` is unchanged).
- Uninstalling the brew formula when switching back to `tarball`.

## Approaches

1. **Use an existing brew** (picked). Smallest change, no new dependency.
2. Playbook also installs Homebrew. Rejected: installer script, sudo-created
   `/home/linuxbrew`, `brew shellenv` in `.zshrc`, Docker check and docs, all
   for one tool.
3. Pull the bottle from ghcr.io directly. Rejected: Linux bottles are relocated
   by brew at pour time, so the raw binary may not run outside brew; relies on
   an undocumented registry layout.

## Decisions

- `opencode_package` in `roles/software/vars/main.yml`, default `tarball`,
  values `tarball` | `brew`. Mirrors `neovim_package`.
- Tarball path unchanged, gated by `opencode_package == 'tarball'`.
- Brew path:
  - Find brew: `brew` on PATH, `/home/linuxbrew/.linuxbrew/bin/brew`,
    `~/.linuxbrew/bin/brew`. None → fail with a message pointing at the docs.
  - `github_packages.opencode` other than `latest` → fail (brew cannot pin).
  - `community.general.homebrew`, `name: opencode`, `state: latest`,
    `update_homebrew: true`.
  - Force-link `~/.local/bin/opencode` to `<brew prefix>/bin/opencode`.
  - Save the installed version to `.github_packages.opencode`.
  - No opencode.ai lookup, no `opencode_baseline`, no `~/.local/opt` cleanup;
    old tarball dirs remain so switching back is free.
- Docs: `customization/20-versions.md` (new section), `customization/10-variables.md`
  (row), `roles/10-software.md` (opencode row).
