# Required tasks, slim image and image updates: design

- Date: 2026-09-25
- Status: approved section by section in chat; spec accepted 2026-09-25 with the
  `*_tasks_include` addition. Implemented on `develop` 2026-09-28 (not committed); see the
  PROFILE note in section 3.
- Branch: `develop`
- Builds on: `2026-09-24-docker-image-design.md`

## Goal

Three changes to the Docker image work, done in this order:

1. **Required tasks.** Fix the eza tag bug, and make the tasks that every setup needs
   impossible to exclude, on native runs and in Docker builds.
2. **Slim image.** A `slim` variant without the largest tools that nothing else needs.
   It keeps the default Neovim config fully working and the DevOps tools. Users can add
   single tools back (for example Azure CLI) at build time or through an update.
3. **Image updates.** Update one tool (or a few) in an image that is already built,
   without a full rebuild, and test the result.

## Decisions

| Topic | Decision |
|---|---|
| Required tasks | `packages`, `yq`, `zsh` (software) and `zsh` (config). Enforced everywhere, native included. Breaking change. |
| Excluding a required task | The run fails at the start with a message. Not silently ignored, because a user with `config_tasks_exclude: [zsh]` would get `.zshrc` replaced without notice. |
| Tags on native runs | Unrestricted. `--skip-tags zsh` stays valid on a machine that is already set up. |
| Tags in Docker full builds | Rejected before the playbook when they deselect a required include. |
| eza and `.zshrc` | The completion moves to the version-independent `~/.zfunc/_eza`, so `.zshrc` no longer embeds the eza version and the zsh config task drops the `eza` tag. |
| `p10k` | Stays excludable (users keep their own `~/.p10k.zsh`). |
| Slim contents | Full profile minus `sdkman`, `azurecli`, `az-account-switcher`, `rust`, `puppet`, `awscli` (software) and `sdkman` (config). `nvm`, `gvm`, `rvm` stay. |
| Variant selection | Bake variable and build arg `PROFILE` (`full` default). `docker/profile-<PROFILE>.yml` is layered between `docker/profile.yml` and `docker/overrides.yml`. |
| Adding tools back to a profile | `software_tasks_include` / `config_tasks_include` in `docker/overrides.yml` remove names from the merged exclude lists. Docker only. Works in full builds and in updates. |
| Slim image names | Local `proveasio:slim`. Published `slim`, `YYYY-MM-DD-slim`, `X.Y.Z-slim`, `X.Y-slim`, `sha-<short>-slim`. |
| Updates | New Bake target `update`: `FROM` the existing image, playbook with `ANSIBLE_TAGS`, full smoke tests, same image name. |
| Shared build logic | The playbook RUN heredoc moves to `docker/provision.sh`, used by the full build and the update. |

## Facts this design relies on

Checked on 2026-09-25 unless noted otherwise.

- The eza bug is filed at `TODO.md:76`. Cause: `zshrc.j2:129-134` writes
  `~/.local/opt/eza-<version>` into `FPATH`, so `[Config] Configure zsh` carries the `eza`
  tag (`config/tasks/main.yml:22-34`) to be re-rendered on `--tags eza`. Ansible applies
  tags in both directions, so `--skip-tags eza` also skips it.
- `~/.zfunc` exists already: `software/tasks/ccmux.yml:76-96` creates it and writes
  `_ccmux`; `zshrc.j2:139-141` adds it to `fpath` before `compinit` when `_ccmux` exists.
- `packages` installs `jq` and `curl` (`software/vars/main.yml`), which every
  `gh_curl ... | jq` version query needs. `.zshrc` sources oh-my-zsh from software `zsh`.
  The config `zsh` template exports `NVIM_APPNAME` and loads nvm, gvm, rvm and git-fuzzy.
- Default Neovim config (`https://github.com/Ziwi01/astronvim.git`, 40 Mason packages):
  - npm (nvm): `ansible-language-server`, `bash-language-server`, `json-lsp`,
    `yaml-language-server`.
  - go (gvm): `gopls`, `delve`, `goimports`, `gomodifytags`, `gotests`, `iferr`, `impl`.
  - gem (rvm): `solargraph`, `standardrb`.
  - 4 + 7 + 2 = 13, the count of expected Mason failures in the smoke build (which has no
    nvm, gvm or rvm). The individual names were derived from the package list and the
    Mason registry sources, not read from that build's log.
  - mason-tool-installer runs with its default `run_on_start = true`; AstroNvim's
    `configs/mason-tool-installer.lua` does not change it. A missing package is retried on
    every Neovim start.
  - The Java packages (`jdtls`, `java-debug-adapter`, `java-test`, `lemminx`,
    `vscode-spring-boot-tools`) install without Java; `jdtls` cannot start without it.
- `software/tasks/ansible.yml:21-30` runs `npm install -g @ansible/ansible-language-server`
  with nvm's PATH and no guard, so the playbook fails without nvm.
- Sizes from `docker/40-limitations.md` (image built with defaults): `~/.sdkman` 0.9 GB,
  `/opt/az` 0.6 GB, `~/.rustup` 0.6 GB, `/opt/puppetlabs` 0.4 GB, `~/.local/opt/aws-cli`
  0.3 GB. Slim estimate: 8.55 - 2.8, about 5.7 GB. Not measured yet.
- Probe in `/tmp/opencode/probe` with the local `docker` buildx driver (BuildKit v0.33):
  - `FROM ${BASE_IMAGE}` with `--pull=false` resolves `proveasio:local` from the local
    image store.
  - `FROM ${PROVISIONED}` selects an earlier stage by name.
  - A stage that the target does not reach is not resolved, even when its `FROM` image
    does not exist (`nonexistent-proveasio/unused:nope`).
  - Bake: `variable "IMAGE" { default = PROFILE == "full" ? "proveasio:local" :
    "proveasio:${PROFILE}" }` gives `proveasio:slim` for `PROFILE=slim`, and an explicit
    `IMAGE` still wins (`--print`).
- docker/metadata-action: every tag type accepts `prefix=` and `suffix=` attributes
  (Context7, `/docker/metadata-action`).

## Files

New:

```
docker/profile-slim.yml     slim excludes
docker/provision.sh         playbook step for full builds and updates
```

Modified:

```
ansible/roles/software/tasks/main.yml     required-task assert (both lists); no exclude guard on packages, zsh
ansible/roles/software/tasks/eza.yml      link ~/.zfunc/_eza
ansible/roles/config/tasks/main.yml       no exclude guard and no eza tag on zsh
ansible/roles/config/tasks/zsh.yml        eza_version fallback removed
ansible/roles/config/templates/zshrc.j2   versioned eza FPATH removed; ~/.zfunc guard on the directory
docker/Dockerfile                         BASE_IMAGE/PROVISIONED args, update and provisioned stages
docker/render-overrides.sh                PROFILE layer, *_tasks_include, base-overrides carry-over; no longer writes build-info.env
docker/test.sh                            --tags/--skip-tags for --list, UPDATES in the selection
docker-bake.hcl                           PROFILE, BASE_IMAGE, derived IMAGE, update target
.github/workflows/docker.yml              profile matrix, per-profile tags and receipts
docs-web/docs/main/docker/10-build.md
docs-web/docs/main/docker/20-customize.md
docs-web/docs/main/docker/40-limitations.md
docs-web/docs/main/roles/10-software.md
docs-web/docs/main/roles/20-config.md
docs-web/docs/main/customization/40-excludes.md
AGENTS.md
TODO.md                                   fix(zsh) item at line 76 removed
.serena/memories/docker-image.md
.serena/memories/ansible-architecture.md
```

Not touched: `docs-web/versioned_docs/`, `CHANGELOG.md`, `ansible/vars/overrides.yml`.

## 1. Required tasks and the eza fix

### eza

- `eza.yml`, after `[EZA] Link ... binary`: ensure `~/.zfunc` exists (`state: directory`,
  `mode: "0755"`), then force-link `~/.zfunc/_eza` to
  `~/.local/opt/eza-{{ eza_version }}/_eza`. The `_eza` file is already downloaded into
  every versioned directory by the install block.
- `zshrc.j2`: delete the `{% if eza_version is defined %}` block (lines 129-134). The
  `~/.zfunc` block adds the directory to `fpath` when the directory exists instead of when
  `_ccmux` exists; its comment names both completions.
- `config/tasks/main.yml`: remove `eza` from the `apply.tags` and outer `tags` of
  `[Config] Configure zsh`.
- `config/tasks/zsh.yml`: delete the two eza tasks (lines 16-30).
- Result: `--skip-tags eza` skips only software eza. `--tags eza` updates eza and the
  link; `.zshrc` does not change.

### Required tasks

- Remove the `when:` exclude guards from `[Software] Install packages`,
  `[Software] Install zsh` and `[Config] Configure zsh`. `yq` has none already.
- One `ansible.builtin.assert` in `software/tasks/main.yml`, tagged `always`, right after
  `[Software] Merge overridden version catalogs back onto defaults`. It checks both lists:
  `software_tasks_exclude` contains none of `packages`, `yq`, `zsh`, and
  `config_tasks_exclude | default([])` does not contain `zsh`. The failure message names
  the entries found and the list each is in.
- Both lists are checked in the software role because it runs first
  (`setup-ubuntu.yml` imports `software`, then `config`). An assert in the config role
  would fail only after the whole software role, which can take an hour. The software
  role's `include_vars` loads the whole overrides file, so a user's
  `config_tasks_exclude` is already defined there; `default([])` covers the case where
  it is not set.
- The only tasks before the assert are the `always` tasks that create `~/.local/bin`,
  `~/.local/opt`, `~/.config`, `~/.lsp`, and the play's `[Init] Check sudo password`.
- Native `--tags` and `--skip-tags` are not restricted.

### Docker full builds

- `docker/test.sh --list` gains `--tags <list>` and `--skip-tags <list>`. When either is
  given, the selection uses exactly those values instead of `build-info.env`. An empty
  value means "not passed", as in the Dockerfile's argument handling.
- `provision.sh` (full mode), after rendering the overrides and before the playbook, runs
  `test.sh --list --tags "$ANSIBLE_TAGS" --skip-tags "$ANSIBLE_SKIP_TAGS"`. If the output
  lacks any of `software/packages`, `software/yq`, `software/zsh`, `config/zsh`, it fails
  and lists them, saying that a new image needs them and that excludes are the way to
  leave tools out. This also catches a required task in the excludes before the
  playbook's assert does.

### Compatibility

Breaking: overrides that exclude `packages`, `yq` or `zsh` make the run fail until the
entry is removed. Suggested commits: `fix(zsh): ...` for eza, `feat!: ...` for the
required tasks.

## 2. Slim image

### Profile

`docker/profile-slim.yml`:

```yaml
software_tasks_exclude:
  - sdkman
  - azurecli
  - az-account-switcher
  - rust
  - puppet
  - awscli
config_tasks_exclude:
  - sdkman
```

With a header comment that says why `nvm`, `gvm` and `rvm` stay (the Mason packages
above and `software/ansible.yml`).

### Rendering

- `render-overrides.sh` reads `PROFILE` (default `full`). Inputs, in merge order:
  `profile.yml`, `profile-<PROFILE>.yml` unless `PROFILE` is `full`, then
  `overrides.yml` if present. The merge expression is unchanged (maps merge, lists
  append).
- Any `docker/profile-<name>.yml` is a valid profile. A missing file fails with the list
  of existing `profile-*.yml` names. `PROFILE` must match `^[a-z0-9-]+$`.
- Appending means `docker/overrides.yml` can add excludes but not remove them. The
  include keys below remove them.

### Adding tools back: `*_tasks_include`

`docker/overrides.yml` may contain `software_tasks_include` and `config_tasks_include`:

```yaml
software_tasks_include:
  - azurecli
  - az-account-switcher
```

```shell
PROFILE=slim IMAGE=proveasio:slim-az docker buildx bake
```

- After the merge, `render-overrides.sh` removes every name in `software_tasks_include`
  from `software_tasks_exclude`, the same for `config_*`, and deletes both include keys.
  The rendered `ansible/vars/overrides.yml` never contains them, so the roles and
  `test.sh` see only the resulting exclude lists. No Ansible change.
- Valid names are the include names of the role (the `file:` of each `include_tasks` in
  `roles/<role>/tasks/main.yml`, minus `.yml`), read with yq the way `test.sh` reads
  them. An unknown name fails with the list of valid names (typo protection). A valid
  name that is not excluded prints a note and is otherwise ignored, so one
  `docker/overrides.yml` works with every profile.
- An include key that is not a list fails.
- `test.sh` tests the tools added back, because it reads the resulting exclude lists.
- Docs list the pairs to add back together: `sdkman` in both keys; `azurecli` with
  `az-account-switcher`. `puppet` needs `rvm`, which slim keeps.
- Docs state that the keys only take names out of excludes; they do not mean "install
  only these". They are ignored on native runs (nothing reads them there).

### Bake

- `variable "PROFILE" { default = "full" }`, passed as build arg `PROFILE`.
- `variable "IMAGE" { default = PROFILE == "full" ? "proveasio:local" : "proveasio:${PROFILE}" }`.
- `PROFILE=slim docker buildx bake` builds, tests and loads `proveasio:slim`.
  `PROFILE=slim docker buildx bake image receipt` writes the slim receipt.
- The docs say to build variants one after the other, never in one Bake call, because
  of the WSL memory limit.

### Build info and tests

- `build-info.env` records `PROFILE`.
- `test.sh` needs no change for slim; it reads the merged excludes.

### CI

`.github/workflows/docker.yml`, job `image`:

- `strategy: { fail-fast: false, matrix: { include: [ {profile: full, suffix: "", latest: latest}, {profile: slim, suffix: "-slim", latest: slim} ] } }`.
- `PROFILE: ${{ matrix.profile }}` in the job env, so both Bake steps (image and receipt)
  use it.
- metadata-action tags:

  ```
  type=raw,value=${{ matrix.latest }},enable=${{ needs.plan.outputs.publish == 'true' && !startsWith(github.ref, 'refs/tags/') }}
  type=raw,value={{date 'YYYY-MM-DD'}}${{ matrix.suffix }},enable=${{ needs.plan.outputs.publish == 'true' && !startsWith(github.ref, 'refs/tags/') }}
  type=semver,pattern={{version}},suffix=${{ matrix.suffix }}
  type=semver,pattern={{major}}.{{minor}},suffix=${{ matrix.suffix }}
  type=sha,prefix=sha-,suffix=${{ matrix.suffix }},format=short
  ```

- Artifact `current-versions-${{ matrix.profile }}`; the step summary heading names the
  profile.
- The header comment lists the slim tags.

## 3. Image updates

### Dockerfile

Global args before the first `FROM`: `BASE_IMAGE=proveasio:local`, `PROVISIONED=build`.

```
FROM scratch AS nvim-config
FROM ubuntu:${UBUNTU_VERSION} AS build
    (root bootstrap, Python layer, COPY ansible: unchanged)
    RUN --mount=... PROVEASIO_IMAGE_BUILD=1 bash /tmp/proveasio-docker/provision.sh
    COPY docker/test.sh; CMD ["zsh", "-l"]
FROM ${BASE_IMAGE} AS update
    ARG USERNAME USER_UID USER_GID
    COPY --chown=${USER_UID}:${USER_GID} ansible /home/${USERNAME}/proveasio/ansible
    ARG REFRESH ANSIBLE_TAGS ANSIBLE_SKIP_TAGS
    RUN --mount=... PROVEASIO_IMAGE_BUILD=1 bash /tmp/proveasio-docker/provision.sh --update
    COPY docker/test.sh
FROM ${PROVISIONED} AS provisioned
FROM provisioned AS test          RUN test.sh | tee tests-passed
FROM scratch AS receipt           COPY --from=provisioned current-versions.yml
FROM provisioned AS final         COPY --from=test tests-passed
```

- Both RUN steps have the same three mounts as today (docker dir, nvim-config, secret).
- `--set image.target=build` still gives an untested full image;
  `--set update.target=update` gives an untested update.
- `final` stays the last stage, so a plain `docker build` still builds the full image.

### provision.sh

Refuses to run unless `PROVEASIO_IMAGE_BUILD=1`, like `cleanup.sh`. It unsets the
variable in its own environment and sets it again only on the `render-overrides.sh` and
`cleanup.sh` calls, so the playbook never sees it.

Full mode (no argument), the current heredoc plus the required-task check:

1. `apt-get update`, `apt-get -y upgrade`.
2. `render-overrides.sh`.
3. Required-task check (section 1).
4. Write `build-info.env`: `PROFILE`, `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `REFRESH`,
   `BUILD_DATE`, `UPDATES=()`. This moves out of `render-overrides.sh`.
5. Playbook, with the `ANSIBLE_CONFIG` export as today.
6. `nvim-install.lua` under the zsh PATH, as today.
7. `cleanup.sh`, zsh warm-up, as today.

Update mode (`--update`), each check failing with a message that says what to do:

1. `ANSIBLE_TAGS` is not empty. Otherwise: run a full build.
2. `~/proveasio/docker/build-info.env` and `~/proveasio/ansible/vars/overrides.yml`
   exist (the base is a Proveasio image). `$HOME` is `/home/$USERNAME`, `id -u` is
   `$USER_UID`, `id -g` is `$USER_GID`. Otherwise: pass the values the base was built
   with.
3. Source the base `build-info.env`. Its `PROFILE` is used; a non-empty `PROFILE` build arg
   that differs fails the update (changed during implementation: a mismatch would load a slim
   image as proveasio:local).
4. Copy the base `overrides.yml` to a temporary file. Run `render-overrides.sh` with
   `PROFILE` from step 3 and `PROVEASIO_BASE_OVERRIDES=<copy>`.
5. Compute the update selection with
   `test.sh --list --tags "$ANSIBLE_TAGS" --skip-tags "$ANSIBLE_SKIP_TAGS"` (it uses the
   new exclude lists).
6. Compare `software_tasks_exclude` and `config_tasks_exclude` (sorted, unique) between
   the copy (base) and the new file, per role:
   - A name excluded now but not in the base fails: an update cannot remove a tool from
     the image, it would stay installed and untested. Run a full build.
   - A name excluded in the base but not now (added back, usually through
     `*_tasks_include`) must be in the update selection, so the update installs it.
     Otherwise fail and name the tag to add to `ANSIBLE_TAGS`.
   - Example: on `proveasio:slim`, `software_tasks_include: [azurecli,
     az-account-switcher]` with `ANSIBLE_TAGS=azurecli,az-account-switcher` passes;
     with `ANSIBLE_TAGS=terraform` it fails.
7. If the copy has `neovim_config_source: local`, the nvim-config context is empty and
   the selection contains `config/neovim-config`, fail: pass the same `NVIM_CONFIG`.
8. `apt-get update` (no upgrade).
9. Playbook with `--tags` and `--skip-tags`.
10. `nvim-install.lua` only when the selection contains `software/neovim` or
    `config/neovim-config`. It otherwise waits up to 120 s for Mason on every update.
11. `cleanup.sh`, zsh warm-up.
12. Append `<BUILD_DATE>|<ANSIBLE_TAGS>|<ANSIBLE_SKIP_TAGS>` to `UPDATES` in
    `build-info.env`. The base values stay unchanged.

### render-overrides.sh in update mode

When `PROVEASIO_BASE_OVERRIDES` is set, the nvim-config context is empty, and the base
file has `neovim_config_source: local`, the script copies `neovim_config_source` and
`neovim_config_local_path` from the base file into the result. So an update that does
not touch the Neovim config keeps the image's record of where its config came from.

### test.sh selection

Without `--tags`/`--skip-tags`: an include is selected when it is not excluded and the
base `ANSIBLE_TAGS`/`ANSIBLE_SKIP_TAGS` select it, or any `UPDATES` entry's tags select
it. A tool that an update installed for the first time is therefore tested, and the rest
of the image is tested again.

### Bake

```hcl
variable "BASE_IMAGE" {
  default = IMAGE
}

target "update" {
  inherits = ["_common", "docker-metadata-action"]
  target   = "final"
  pull     = false
  args     = { PROVISIONED = "update", BASE_IMAGE = BASE_IMAGE }
  output   = ["type=docker"]
}
```

Not in the `default` group. Usage:

```shell
ANSIBLE_TAGS=terraform docker buildx bake update                  # proveasio:local in place
PROFILE=slim ANSIBLE_TAGS=terraform docker buildx bake update     # proveasio:slim in place
BASE_IMAGE=docker.io/CHANGEME/proveasio:latest IMAGE=proveasio:local \
  ANSIBLE_TAGS=neovim,neovim-config docker buildx bake update     # after docker pull
```

`pull = false` is required: with `pull = true` BuildKit looks for `proveasio:local` in a
registry. The base image must be in the local image store (`docker` driver).

### Costs, documented

- About 4 layers per update. The overlay limit of 127 layers allows about 25 updates.
- Replaced files stay in the lower layers, so the image grows by roughly the size of
  each updated tool.
- Ubuntu packages are not upgraded.
- A full build resets all of this.

## 4. Docs and verification

### Docs

- `docker/10-build.md`: "Slim image" section; "Updating tools in a built image" section
  under "Getting the latest versions"; slim rows in the pre-built tags table.
- `docker/20-customize.md`: the zsh and eza/zsh/config warnings become the required-task
  rule (and the early failure); profile files; `*_tasks_include` with the slim + Azure
  CLI example and the pairs to add together; `PROFILE` and `BASE_IMAGE` in the
  variables table.
- `docker/10-build.md` update section: adding a tool back to an existing image
  (`*_tasks_include` plus its tag in `ANSIBLE_TAGS`); removing one needs a full build.
- `docker/40-limitations.md`: measured slim size; update growth and layer limit.
- `roles/10-software.md`: `packages` and `zsh` leave the exclude list; one line says
  `packages`, `yq` and `zsh` cannot be excluded.
- `roles/20-config.md`: `zsh` leaves the list, with the same note.
- `customization/40-excludes.md`: the example uses `tmux` instead of `zsh`.
- AGENTS.md: Tags section (eza no longer pulls in config zsh; `--skip-tags eza` is safe),
  Docker section (`provision.sh`, profiles, `update`, required-task check), Architecture
  (the `config/tasks/zsh.yml:16-30` workaround is gone).
- Memories: `docker-image`, `ansible-architecture` (cross-role coupling via
  `eza_version` is gone).
- `TODO.md`: remove the `fix(zsh)` item at line 76.

### Verification

Each step reports the command and its output.

1. `cd ansible && ansible-lint` prints `Passed: 0 failure(s)`.
   `ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check` passes.
   `--list-tasks --skip-tags eza` still lists `[Config] Configure zsh`.
   `--list-tags` matches `customization/50-partial-run.md`.
2. On the host: `PROVEASIO_HOME="$PWD" bash docker/test.sh --coverage` reports 0 without a
   check. `test.sh --list` with `--tags`/`--skip-tags` gives the expected selection for:
   no tags, the smoke tags, `neovim`, `--skip-tags config`, `--skip-tags eza`.
   `render-overrides.sh` in a copy of the repository under `/tmp/opencode` (never with
   `PROVEASIO_HOME` at the checkout: the script overwrites
   `$PROVEASIO_HOME/ansible/vars/overrides.yml`, which in the checkout is your native
   file): `PROFILE=slim` with `software_tasks_include: [azurecli, az-account-switcher]`
   renders excludes without them, and `test.sh --list` on that copy lists
   `software/azurecli` and `software/az-account-switcher`. A typo such as `azcli` fails
   with the list of valid names; a name that is not excluded prints a note and passes.
3. `docker buildx bake --print` for the default, `PROFILE=slim`, and `update`.
4. `cd docs-web && npm install && npm run build`.
5. Builds. Before each: Windows free physical memory and free commit both at least
   10 GB (`powershell.exe -Command "Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory,FreeVirtualMemory"`).
   Stop and report if not. `docker/overrides.yml` does not exist now (checked
   2026-09-25); steps that create it delete it when they finish.
   1. Smoke build, full profile:
      `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke docker buildx bake`.
      9 checks pass. In the container, `~/.zfunc/_eza` links to the current version and
      zsh has an `eza` completion.
   2. Early failures, each within seconds of the playbook step starting:
      `ANSIBLE_TAGS=neovim`, `ANSIBLE_SKIP_TAGS=config`, and a `docker/overrides.yml`
      with `software_tasks_exclude: [zsh]`.
   3. Updates on `proveasio:smoke`: `ANSIBLE_TAGS=eza` passes 9 checks and records
      `UPDATES`; `ANSIBLE_TAGS=terraform` passes 10; an added exclude fails. Record the
      image size after each.
   4. Slim build: `PROFILE=slim docker buildx bake`. Record the check count (expected
      45: the full profile's 52 minus 6 software and 1 config exclude),
      the size, the build time, and the Mason result (expected 40 installed, 0 failed).
   5. Adding a tool back through an update on `proveasio:slim`, with
      `software_tasks_include: [azurecli, az-account-switcher]` in `docker/overrides.yml`:
      `PROFILE=slim ANSIBLE_TAGS=terraform docker buildx bake update` fails (azurecli not
      in the selection); `PROFILE=slim ANSIBLE_TAGS=azurecli,az-account-switcher docker
      buildx bake update` passes 47 checks. Record the size.
6. Not done: a full-profile full build (skipped by decision). Not verifiable locally: the
   CI matrix and metadata tags. The native playbook is not run; the eza change is tested
   in a container only.
