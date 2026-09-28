# Docker image for Proveasio: design

- Date: 2026-09-24
- Status: approved section by section in chat. Implemented on `develop`; synced with the
  implementation on 2026-09-25 (see "Changes during implementation")
- Branch: `develop`

## Goal

Build a Docker image by running the existing Ubuntu playbook (`ansible/setup-ubuntu.yml`)
inside `docker build`. The result matches a native run: every tool resolves to `latest`
unless the user pins it. Users can:

- rebuild locally and get new versions without passing extra flags,
- customize the build with the same file format as `ansible/vars/overrides.yml`,
- take the Neovim config from a git URL or from a local directory,
- get an image that is tested before it is loaded or pushed.

A GitHub workflow builds, tests and pushes the image to Docker Hub.

## Decisions

| Topic | Decision |
|---|---|
| How users run it | Interactive dev shell and devcontainer base. `CMD ["zsh", "-l"]`, no `ENTRYPOINT`, non-root user, UID/GID set by build args. |
| Docker inside the image | `docker-ce-cli`, `docker-compose-plugin`, `docker-buildx-plugin` only. No engine. Users mount the host socket. |
| Neovim binary | New role variable `neovim_package: appimage \| tarball`. The image uses `tarball` because containers have no FUSE. |
| Default contents | Same as native minus the WSL-only tools `w32yank` and `wsl-notify-send`. One published variant. |
| Build entry point | `docker-bake.hcl` at the repo root. Local builds and CI use the same file. |
| GitHub token | Optional build secret. Without it the build runs unauthenticated (60 API requests per hour per IP, about 33 per build). |
| Local Neovim config | Named build context `nvim-config` plus role option `neovim_config_source: local`. |
| CI triggers | Mirror `build.yml` for publishing. PRs and `develop` pushes build and test without pushing. |
| Registry credentials | Repository-level `vars.DOCKERHUB_USERNAME` and `secrets.DOCKERHUB_TOKEN`. Image name placeholder `docker.io/CHANGEME/proveasio`. |
| Base image | `ubuntu:24.04`. It is already the minimized image (29.8 MB compressed, 78 MB unpacked, man pages and translations excluded by `/etc/dpkg/dpkg.cfg.d/excludes`). Size is reduced by same-layer cleanup and by disabling apt recommends, not by changing the base. |

## Files

New:

```
docker-bake.hcl
.dockerignore
docker/Dockerfile
docker/profile.yml              committed container defaults
docker/render-overrides.sh      merges profile + user overrides, writes build-info.env
docker/cleanup.sh               removes build leftovers, logs sizes
docker/nvim-install.lua         installs Mason tools and treesitter parsers, waits for them
docker/test.sh                  smoke tests
.github/workflows/docker.yml
docs-web/docs/main/docker/_category_.yml
docs-web/docs/main/docker/10-build.md
docs-web/docs/main/docker/20-customize.md
docs-web/docs/main/docker/30-run.md
docs-web/docs/main/docker/40-limitations.md
```

Modified:

```
ansible/roles/software/vars/main.yml        neovim_package, docker_manage_service
ansible/roles/software/tasks/neovim.yml     tarball branch
ansible/roles/software/tasks/docker.yml     service gate, skip `absent` in version read-back
ansible/roles/config/vars/main.yml          neovim_config_source, neovim_config_local_path
ansible/roles/config/tasks/neovim-config.yml  local copy branch
ansible/roles/config/templates/zshrc.j2     load tool integrations only when the tool exists
.gitignore                                  docker/overrides.yml, /out/
AGENTS.md                                   fifth "adding software" edit, Docker section
TODO.md                                     bugs found during design (see "Found, not fixed")
docs-web/docs/main/customization/30-config-files.md
docs-web/docs/main/features/50-neovim.md
docs-web/docs/main/installation.md
README.md
```

Unchanged on purpose: `prepare-ubuntu.sh`, `ansible/group_vars/`, `ansible/vars/overrides.yml`,
`.github/workflows/build.yml`, `docs-web/versioned_docs/`, `CHANGELOG.md`.

`docker/overrides.yml` is created by users and is gitignored.

## Build context

`.dockerignore` is an allowlist: everything is excluded, then `ansible/`,
`prepare-ubuntu.sh` and `docker/` are re-included. Inside those, `ansible/vars/*overrides.yml*`
(the native overrides file and its backup or swap copies) and `ansible/.ansible/` are excluded
again. The native overrides file therefore never reaches
a Docker build. `docker/overrides.yml` stays in the context because the build reads it.

## Dockerfile

Syntax `# syntax=docker/dockerfile:1`. `SHELL ["/bin/bash", "-o", "pipefail", "-c"]`.

### Stage `nvim-config`

`FROM scratch AS nvim-config`. Empty by default. When the Bake variable `NVIM_CONFIG` is set,
Bake passes that directory as a named context with the same name, which replaces the stage.

### Stage `build`

`FROM ubuntu:${UBUNTU_VERSION}` (default `24.04`). Build args `USERNAME=dev`,
`USER_UID=1000`, `USER_GID=1000`. `ARG DEBIAN_FRONTEND=noninteractive` (build time only),
`ENV LANG=en_US.UTF-8`, `TZ=Etc/UTC`, `USER=${USERNAME}`.

Steps in order:

1. Root bootstrap, one `RUN`:
   - Write `/etc/apt/apt.conf.d/99-proveasio` with `APT::Install-Recommends "false";` and
     `APT::Install-Suggests "false";`. Ansible's apt module follows the OS default when
     `install_recommends` is unset, so this applies to every apt task in the playbook.
   - Install what the base image lacks and what native gets only through recommends:
     `sudo git python3 python3-apt python3-packaging locales tzdata ca-certificates curl
     wget pkgconf bsdextrautils`. `bsdextrautils` provides `hexdump`, which gvm needs.
   - `locale-gen en_US.UTF-8`, link `/etc/localtime` to `Etc/UTC`.
   - `userdel -r ubuntu` (the stock user holds UID 1000), create the group and user with
     the build-arg IDs.
   - `/etc/sudoers.d/proveasio`: `${USERNAME} ALL=(ALL) NOPASSWD:ALL` and
     `Defaults env_keep += "DEBIAN_FRONTEND"`, validated with `visudo -cf`.
   - Remove `/var/lib/apt/lists/*`.
2. `USER ${USERNAME}`, `WORKDIR /home/${USERNAME}`. `ENV PATH` prepends `~/.local/bin`,
   `~/.pyenv/shims`, `~/.pyenv/bin` because `RUN` steps never read `.bashrc`.
3. `COPY --chown` only `prepare-ubuntu.sh` and `ansible/roles/software/vars/main.yml` into
   `~/proveasio/`. The script reads `ansible_pip_version` from that file. Copying only these
   two keeps the next layer cached when other Ansible files change.
4. Bootstrap `RUN`:
   - `sudo bash ~/proveasio/prepare-ubuntu.sh`.
   - The script has no `set -e` and its root check exits 0, so check its results in the
     same `RUN`: `python --version` equals the script's `PYTHON_VERSION`,
     `ansible-playbook --version` and `yq --version` succeed.
   - Purge `llvm` with `--auto-remove` (installed only to build Python), remove the CPython
     test suite (`~/.pyenv/versions/*/lib/python*/test`), the pip and pyenv caches and apt
     lists.
   - This layer is cached across refreshes. Building it took 2-3 minutes here.
5. `COPY --chown` the rest of `ansible/` into `~/proveasio/ansible/`. The directory must not
   be world-writable, or Ansible ignores `ansible.cfg`.
6. `ARG REFRESH`, `ARG ANSIBLE_TAGS=""`, `ARG ANSIBLE_SKIP_TAGS=""`. Every layer after this
   rebuilds when `REFRESH` changes.
7. Playbook `RUN` with three mounts:
   - `--mount=type=bind,source=docker,target=/tmp/proveasio-docker`
   - `--mount=type=bind,from=nvim-config,target=/tmp/nvim-config`
   - `--mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN` (optional by default)

   Commands, all in this one `RUN`:
   1. `sudo apt-get update && sudo apt-get -y upgrade`, because the cached bootstrap layer
      would otherwise keep old base packages.
   2. `/tmp/proveasio-docker/render-overrides.sh`.
   3. `cd ~/proveasio/ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml`, plus
      `--tags` / `--skip-tags` when the args are not empty. No `-K`: sudo is passwordless.
   4. Mason/treesitter sync, when `nvim` and the config directory exist:
      `nvim --headless` runs `docker/nvim-install.lua` through `pcall(dofile, ...)` and
      `cquit 1` on error, under `timeout 1800`. The helper starts `MasonToolsInstall` and
      waits until no package is installing, then runs `TSUpdateSync` (nvim-treesitter
      `master`) or, on the `main` branch, `install()` with AstroNvim's language list. Each
      part is skipped when the config does not use the plugin. nvim gets the PATH of an
      interactive zsh, captured through `script`, so Mason packages that need npm, go or gem
      install. Failed packages are logged, not fatal.
   5. `PROVEASIO_IMAGE_BUILD=1 /tmp/proveasio-docker/cleanup.sh`. The script exits 2 without
      that variable.
   6. Warm zsh once under `script` so p10k's gitstatusd is in the image. p10k fetches it
      before the first prompt, so the step runs `zsh -i` and feeds `exit` on stdin.

   Bind-mount contents are part of the cache key. The whole `docker/` directory is mounted,
   so editing any file in it (`docker/overrides.yml`, but also `test.sh` or the Dockerfile)
   or the local Neovim config re-runs the playbook, even with a fixed `REFRESH`. Secret
   contents are not part of the cache key.
8. `COPY --chown docker/test.sh ~/proveasio/docker/test.sh`, after the playbook layer.
9. `CMD ["zsh", "-l"]`.

### Stage `test`

`FROM build AS test`. Runs `~/proveasio/docker/test.sh` and writes its output (one line per
check and the summary) to `~/proveasio/docker/tests-passed`.

### Stage `final`

`FROM build AS final`. `COPY --from=test` the `tests-passed` file. This makes the tests a
dependency of the image: without passing tests there is no image, locally or in CI. An
untested image can be built with `--set image.target=build`.

### Stage `receipt`

`FROM scratch AS receipt`. Copies `~/proveasio/current-versions.yml` from `build`, so `final`
stays the last stage and a plain `docker build` produces the image. Used by CI to export the
version receipt.

## Configuration

### Override layers

`render-overrides.sh` runs inside the playbook `RUN`:

1. Merge with yq, maps recursively and lists appended:
   `yq eval-all '. as $i ireduce ({}; . *+ $i)' profile.yml overrides.yml`.
   `overrides.yml` is optional, and an empty file must work.
2. Delete `github_api_token` from the result, always, and print a warning when the key was
   there. The delete is unconditional so a failing check cannot leave the token in. The
   token must come in as the build secret, because the merged file stays in the image.
3. If `/tmp/nvim-config` is not empty, set `neovim_config_source: local` and
   `neovim_config_local_path: /tmp/nvim-config`.
4. Write the result to `~/proveasio/ansible/vars/overrides.yml`. From there the roles'
   existing snapshot, `include_vars`, `combine()` sequence
   (`software/tasks/main.yml:16-47`) runs unchanged: the three catalogs merge per key,
   everything else replaces the role value.
5. Create `~/proveasio/docker/` and write `~/proveasio/docker/build-info.env` with `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`,
   `REFRESH` and the build date. The tests read it.
6. Print the merged overrides to the build log.

`docker/profile.yml`:

```yaml
software_tasks_exclude: [w32yank, wsl-notify-send]
neovim_package: tarball
docker_manage_service: false
docker_apt_packages:
  docker-ce: absent
  containerd.io: absent
  docker-ce-cli: latest
  docker-buildx-plugin: latest
config_files_backup: false
```

Because lists append, a user who sets `software_tasks_exclude: [rvm]` gets
`[w32yank, wsl-notify-send, rvm]`. Dropping a profile entry needs an edit to the profile.

### Tags

`ANSIBLE_TAGS` and `ANSIBLE_SKIP_TAGS` become `--tags` / `--skip-tags`. In a fresh image,
excludes are the right way to turn tools off. `--tags neovim` alone skips
`software_packages` (curl, jq, unzip), so version lookups fail. `--skip-tags` is safe except
for `eza`: the outer tags of `[Config] Configure zsh` include `eza`, so skipping it leaves the
default oh-my-zsh `.zshrc`. The user docs mark it unsupported and say to add `eza` to
`software_tasks_exclude` instead.

### Neovim config

- Git: `neovim_config_url` and `neovim_config_version` in `docker/overrides.yml`, as native.
- Local: `NVIM_CONFIG="$HOME/my-nvim" docker buildx bake`. Uncommitted changes are included.
  The persisted overrides point at `/tmp/nvim-config`, which only exists during the build,
  so re-running the playbook inside a container needs `neovim-config` in
  `config_tasks_exclude`, which keeps the copied config as it is.

### Bake file

```hcl
variable "REFRESH"           { default = timestamp() }
variable "UBUNTU_VERSION"    { default = "24.04" }
variable "USERNAME"          { default = "dev" }
variable "USER_UID"          { default = "1000" }
variable "USER_GID"          { default = "1000" }
variable "ANSIBLE_TAGS"      { default = "" }
variable "ANSIBLE_SKIP_TAGS" { default = "" }
variable "NVIM_CONFIG"       { default = "" }
variable "IMAGE"             { default = "proveasio:local" }
variable "HOME"              { default = null }   # read from the environment

# docker/metadata-action writes a file that redefines this target in CI.
target "docker-metadata-action" { tags = [IMAGE] }

target "_common" {
  context    = "."
  dockerfile = "docker/Dockerfile"
  platforms  = ["linux/amd64"]
  pull       = true
  args = {
    REFRESH           = REFRESH
    UBUNTU_VERSION    = UBUNTU_VERSION
    USERNAME          = USERNAME
    USER_UID          = USER_UID
    USER_GID          = USER_GID
    ANSIBLE_TAGS      = ANSIBLE_TAGS
    ANSIBLE_SKIP_TAGS = ANSIBLE_SKIP_TAGS
  }
  contexts = NVIM_CONFIG == "" ? {} : { nvim-config = regex_replace(NVIM_CONFIG, "^~", HOME) }
  secret   = ["id=GITHUB_TOKEN,env=GITHUB_TOKEN"]
}

target "image"   { inherits = ["_common", "docker-metadata-action"], target = "final", output = ["type=docker"] }
target "receipt" { inherits = ["_common"], target = "receipt", output = ["type=local,dest=out"] }
group  "default" { targets = ["image"] }
```

Probed with `docker buildx bake --print` on buildx 0.37.0: `timestamp()` works as a
default, the conditional `contexts` works, and the string secret form works when
`GITHUB_TOKEN` is unset. The HCL object form (`{ type = "env", id = ... }`) fails with
`failed to stat GITHUB_TOKEN` when the variable is unset, so the string form is required.
Bake does not expand `~` in context paths, so `regex_replace` replaces a leading `~` with
`HOME`.

## Role changes

All new variables default to the current behaviour.

1. `neovim_package: appimage` in `software/vars/main.yml`. In `neovim.yml`, `github_uri`
   picks `nvim-linux-x86_64.appimage` or `nvim-linux-x86_64.tar.gz` for releases and
   nightly. The tarball branch unpacks into `~/.local/opt/neovim-<ver>/` and links
   `~/.local/bin/nvim` to `.../nvim-linux-x86_64/bin/nvim`, without `become`. The AppImage
   tasks get a `when:` and are otherwise unchanged.
2. `docker_manage_service: true` in `software/vars/main.yml`. `[Docker] Start docker daemon`
   gets `when: docker_manage_service | bool`. The version read-back loop skips entries whose
   value is `absent`, so the receipt does not record `(none)`.
3. `neovim_config_source: git` and `neovim_config_local_path: ""` in `config/vars/main.yml`.
   The git task runs only for `git`. A new `ansible.builtin.copy` from
   `{{ neovim_config_local_path }}/` to `neovim_config_path` runs for `local`. The receipt
   records `neovim_config_version: local`. An assert rejects other sources and `local`
   without a path. The headless `nvim +q` step keeps
   `failed_when: false`; `test.sh` detects a broken Neovim instead.
4. `zshrc.j2`: load every tool integration only when the tool exists (plugins `fzf`,
   `fzf-tab`, `fzf-tab-source`, `zoxide`; `pay-respects`, `switcher`, `kubectl`/`kubecolor`,
   `fzf --zsh`, the fzf-tab source line, `.cargo/env`, gvm) and render the eza FPATH block
   only when `eza_version` is defined. The last line, RVM sourcing, is an `if` block instead
   of `[[ ... ]] &&`, so a missing RVM leaves exit status 0 for the first prompt. Without
   these guards, zsh prints errors when a tool is excluded, on native installs too, and the
   zsh output test would fail.

## Size reduction

Measured on the native install of this machine (WSL, same tool set). Cache sizes there are
inflated by many past runs.

| Leftover | Size here | Removed by |
|---|---|---|
| pip, uv, npm, go-build caches | 3.1G, 2.3G, 566M, 216M | `cleanup.sh` |
| `~/.rvm/src`, `~/.rvm/archives` | 1.4G, 83M | `cleanup.sh` (`rvm cleanup all`) |
| `rust-docs` component | 917M | `cleanup.sh` (`rustup component remove rust-docs`) |
| `llvm-18-dev`, `llvm-18`, `libllvm18` | about 550M | bootstrap `RUN` after the Python build |
| `~/.local/opt/awscli-install`, `awscliv2.zip` | 479M, 71M | `cleanup.sh`. `awscli.yml` downloads and unpacks them on every run, nothing checks for them. |
| `~/.gvm/archive` | 128M | `cleanup.sh`. `gvm.yml` checks `~/.gvm` and `~/.gvm/environments/<ver>` only. |
| CPython test suite | 152M | bootstrap `RUN` |
| `~/.sdkman/archives`, `~/.sdkman/tmp`, `/tmp/*`, apt lists and archives | small | `cleanup.sh` |
| `~/go/pkg/mod`, `~/go/pkg/sumdb`, `~/.npm/_logs`, left by Mason's installs in the build | 274M in the image build | `cleanup.sh`. Go makes the module cache read-only, so the script adds write permission first. |

Rules for `cleanup.sh`:

- It runs in the same `RUN` as the playbook. Deleting in a later layer does not shrink the
  image.
- It must not delete paths the roles use to detect an existing install (for example
  `~/.local/opt/tmux-<ver>`, `~/.gvm/environments/<ver>`, `~/.local/opt/nvm/nvm.sh`), so
  re-running the playbook inside a container still works.
- It prints `du` for each path before removing it, so the build log shows the real saving.

Content that stays unless the user excludes the tool: Mason LSP servers 1.6G, lazy plugins
0.8G, SDKMAN 1.9G, rvm rubies and gems 1.2G, Python 854M, Node 601M, Rust 507M,
azure-cli 575M, aws-cli 479M, pdk 338M, Go 270M. The planning estimate was 10-12 GB. The
first full build measured 8.55 GB (see "Changes during implementation").

Not done: changing the base image (saves under 80 MB), `--squash` (nothing is overwritten
across layers), a multi-stage runtime-only copy (conflicts with Ansible installing in place,
and a dev image needs compilers), zstd push compression (transfer only).

## Tests

`docker/test.sh` runs as the container user. It runs in the `test` stage during every build,
and by hand with `docker run --rm <image> ~/proveasio/docker/test.sh`. Checks run in bash with
the PATH of an interactive zsh captured through `script`. Bash, because oh-my-zsh enables
`EXTENDED_GLOB`; `script`, because zsh without a terminal prints zle errors and p10k's
`gitstatus failed to initialize`. Flags: `--list`, `--only`, `--coverage`.

Selecting what to check:

1. yq reads `software/tasks/main.yml` and `config/tasks/main.yml`. Each include's name is
   its `file:` without `.yml` (the kebab-case exclude key). Its outer `tags:` are read too.
   If yq fails or finds no include for a role, the run fails.
2. Subtract `software_tasks_exclude` and `config_tasks_exclude` from
   `~/proveasio/ansible/vars/overrides.yml`.
3. Apply `ANSIBLE_TAGS` and `ANSIBLE_SKIP_TAGS` from `~/proveasio/docker/build-info.env`
   against the outer tags. `all` and `tagged` in `ANSIBLE_TAGS` select every include, as in
   Ansible.
4. Call `check_software_<name>` or `check_config_<name>` for each selected include. A
   selected include without a check function is a failure, and so is a run that selects no
   checks.

What checks verify:

- The tool's binary runs and exits 0.
- Where `current-versions.yml` has a version for the tool, that string appears in the
  tool's version output. SHA-based entries (`tpm`, `git_fuzzy`, `pes`) skip this.
- zsh: `zsh -i -c exit` under `script`, started with the container's start PATH, exits 0
  and prints nothing.
- p10k: when `.zshrc` selects powerlevel10k, gitstatusd is in `~/.cache/gitstatus`.
- Neovim: `nvim --headless +qa` exits 0 without errors, and `~/.local/share/$NVIM_APPNAME`
  is not empty.
- tmux: a detached server on a private socket starts and is killed; the TPM plugin
  directory is not empty.
- docker: `docker --version`, `docker compose version`, `docker buildx version` (always,
  compared with the receipt when it has the key). When `/var/run/docker.sock` exists,
  `docker info` must also succeed.
- SDKMAN, rvm: the managed language runs through its manager's init. nvm: `nvm` and the
  npm default packages run through nvm's init; node runs from the zsh PATH. gvm: Go runs
  from the zsh PATH.
- `packages`: each entry of the effective `default_apt_packages` is installed, by package
  or virtual name.
- Checks that loop over a list (apt packages, oh-my-zsh plugins, rvm rubies, SDKMAN
  defaults, npm packages) fail when the effective list is empty.

Output is one `ok` or `not ok` line per check and a summary. Exit code is non-zero on any
failure.

Not covered: whether config files have the right content, interactive behaviour, runtime
logins, native or WSL runs, the Windows role.

## CI workflow

`.github/workflows/docker.yml`, two jobs: `plan` on `ubuntu-latest` and `image` on
`ubuntu-24.04` with `timeout-minutes: 240`. `permissions: contents: read`. The concurrency
group is keyed on the ref being built: scheduled runs join `refs/heads/master`'s group, so
a scheduled run and a `master` push cannot publish `latest` out of order, and a `develop`
push cannot cancel a pending scheduled publish. Only PR runs cancel in-progress runs.
Maintainer notes live only as short comments in this file.

A `plan` job decides `build` and `publish`; it path-filters `develop` pushes because
`on.push.paths` would also filter `master`. It uses `git diff --quiet <before> <sha> --
<paths>` instead of a pipe into `grep -q`, which can SIGPIPE `git diff` under `pipefail`.
`REFRESH` is pinned per run (`<run_id>-<run_attempt>`) so the receipt step hits the cache.

| Event | Build and test | Push | Tags |
|---|---|---|---|
| push to `master`, weekly cron, `workflow_dispatch` on `master` | yes | yes | `latest`, `YYYY-MM-DD`, `sha-<short>` |
| push of a `v*` tag | yes | yes | `X.Y.Z`, `X.Y`, `sha-<short>` (`latest` not moved) |
| `workflow_dispatch` on any other ref | yes | no | none |
| PR or push to `develop` touching `docker/**`, `docker-bake.hcl`, `.dockerignore`, `ansible/**`, `prepare-ubuntu.sh` or the workflow | yes | no | none |

The GitHub default branch is `develop`, and scheduled workflows run on the default branch.
The scheduled run therefore checks out `master` explicitly. It combines the workflow file from
`develop` with `master`'s `docker-bake.hcl` and `docker/`, so it fails until a release puts
`docker/` on `master`.

Steps of the `image` job:

1. `actions/checkout`, with `ref: master` for `schedule`.
2. Free disk space inline: remove `/usr/share/dotnet`, `/usr/local/lib/android`, `/opt/ghc`
   and the CodeQL toolcache, and prune preinstalled Docker images.
3. `docker/setup-buildx-action`.
4. `docker/metadata-action` with the image name from the top-level `env:`, producing Bake
   files for tags and labels. Scheduled runs use `context: git`, so `sha-<short>` names the
   `master` commit, not the `develop` commit that triggered the run.
5. `docker/login-action` with `vars.DOCKERHUB_USERNAME` and `secrets.DOCKERHUB_TOKEN`,
   only for publishing runs.
6. `docker/bake-action` with `source: .`, files `docker-bake.hcl` plus the metadata files,
   target `image`. The output is set explicitly instead of using the action's `push:`
   input: `image.output=type=registry` for publishing events, `image.output=type=cacheonly`
   otherwise. The local default `type=docker` is never used in CI. The step's `env` sets
   `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}`.
7. A second `docker/bake-action` call for `receipt` (fully cached) writes
   `out/current-versions.yml`. It is appended to `$GITHUB_STEP_SUMMARY` and uploaded as an
   artifact.

Action major versions are checked against their current releases at implementation time.

## Documentation

User docs in `docs-web/docs/` only. Nothing describes the pipeline.

New category `docs-web/docs/main/docker/` (`position: 7.5`, label "Docker image"):

1. `10-build.md`: requirements (Docker Engine 23+ with buildx, or Docker Desktop; amd64
   host; about 25 GB free disk), quick start, how refresh works and `REFRESH=dev`, building
   with and without a GitHub token, expected time and size, the local tag, the pre-built
   image and its tags.
2. `20-customize.md`: `docker/overrides.yml` with links to the existing Customization
   pages, `profile.yml` and the merge rules, excludes versus tags, pins, git identity,
   Neovim config from git or a local directory, the Bake variable table.
3. `30-run.md`: interactive run with a workspace mount, the host Docker socket with
   `--group-add $(stat -c %g /var/run/docker.sock)`, git identity at runtime, named volumes
   for state, a minimal `devcontainer.json` (`updateRemoteUserUID` handles UID mismatches),
   running `test.sh`, the untested-build option.
4. `40-limitations.md`: the user-facing caveats below and the size table.

Updates: `customization/30-config-files.md` (local Neovim config source),
`features/50-neovim.md` (`neovim_package`), `installation.md` and root `README.md`
(one-line pointer). `customization/50-partial-run.md` does not change; confirm with
`--list-tags`.

`AGENTS.md`: "Adding software" becomes five edits (add a check to `docker/test.sh`), plus a
short Docker section listing the files and the profile.

## Caveats

1. Measured on this machine (16 cores): image 8.55 GB, playbook layer 7.25 GB. A full build
   took about 13.5 minutes with the Python layer cached and about 18-20 minutes with it
   rebuilt; the planning estimate was 10-12 GB and 45-90 minutes. One large layer is slow to
   push and pull. A possible Docker Hub per-layer size limit is unconfirmed.
2. CI disk space is the most likely failure. Fallbacks: a larger runner, or splitting the
   playbook `RUN` into a heavy-toolchain pass and the rest.
3. Builds are not reproducible by design. The dated tag and the version receipt (in the
   image and in the CI summary) are the record.
4. Without a token, about one full build per hour per IP. A failed build uses up quota too.
5. amd64 only. About 25 download URLs hardcode `amd64` or `x86_64`.
6. `opencode.yml:20` reads the build host's `/proc/cpuinfo` for AVX2, so the published image
   can crash with SIGILL on CPUs without AVX2.
7. Published defaults: git identity `Proveasio <Proveasio@hell.no>`, UID 1000, passwordless
   sudo.
8. ccmux notifications use the WSL toast bridge and do nothing in a container.
9. No man pages in the minimized base. `unminimize` restores them at a size cost; it is
   documented, not done.
10. Disabling apt recommends diverges from native. If it breaks something that cannot be
    fixed by installing a package explicitly, it is dropped.
11. Mason installs LSP servers in the background, so the headless `nvim +q` exits before
    they finish. The first build showed that; `docker/nvim-install.lua` is the Docker-side
    wait step. The role is not changed. A Mason or parser failure is logged, not fatal,
    because it depends on the user's config and third-party registries.
12. Tests prove tools are installed, run and match their receipt, and that zsh, tmux and
    Neovim start cleanly. They do not prove the configuration works well in use.

## Found, not fixed

- `neovim.yml:11-16` passes a pipe to `ansible.builtin.command`, so the installed-version
  check never works and Neovim is reinstalled on every run. Goes into `TODO.md`.
- `opencode.yml:20` build-host AVX2 detection (caveat 6). Goes into `TODO.md`.
- `build.yml`'s weekly cron runs on the default branch `develop`, not `master`. Whether
  that is intended is an open question for the maintainer; `build.yml` is not changed.

Found during implementation, also in `TODO.md`:

- `nvm.yml` installs with `creates:`, so nvm is never upgraded while the receipt records
  the newly resolved version.
- `.zshrc` does not load SDKMAN, so `sdk`, `java`, `gradle`, `groovy` and `mvn` are not on
  the interactive PATH. `test.sh` sources SDKMAN's init script itself.
- `source <(alias s=switch)` in `zshrc.j2` defines the alias in a subshell, so `s` never
  exists.
- `--skip-tags eza` also skips `[Config] Configure zsh` (see "Tags").
- The scheduled Docker run checks out `master`, which has no `docker/` until the next
  release. Publishing also needs the `CHANGEME`, `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
  placeholders replaced.

## Verification

1. `cd ansible && ansible-lint` prints `Passed: 0 failure(s)`.
2. `cd ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check` passes.
3. `--list-tags` output is unchanged.
4. `docker buildx bake --print` resolves with and without `NVIM_CONFIG`.
5. A full local `docker buildx bake` succeeds with all tests passing. Record the image size,
   `docker history` and the cleanup log.
6. A second build with a pin, an exclude and `NVIM_CONFIG` set: tests pass, the pinned
   version is in the receipt, the excluded tool is skipped, the local config is in place.
7. `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock --group-add <gid>
   proveasio:local ~/proveasio/docker/test.sh` passes, including `docker info`.
8. `cd docs-web && npm install && npm run build` passes.
9. The workflow can only be verified by running it on GitHub, which needs a push. Until
   then it is unverified.

Items to confirm early in implementation: bind-mounting the empty `FROM scratch` stage,
yq `*+` semantics including an empty overrides file, whether Bake expands `~` in context
paths (docs use `$HOME` either way), and that the metadata-action file overrides the local
`docker-metadata-action` tags. All four were probed while planning. Bake does not expand
`~`; the other three work as described.

## Out of scope

arm64 images, a slim variant, the Windows role, Docker-in-Docker, Docker Hub description
sync, zstd compression, splitting the playbook layer.

## Changes during implementation

The sections above describe what was built. These are the main points where it differs from
the approved design. The ids (R5 and so on) are rulings in the execution ledger,
`.superpowers/sdd/2026-09-24-docker-image/progress.md`, which is gitignored.

- `docker/cleanup.sh` exits 2 unless `PROVEASIO_IMAGE_BUILD=1`, because it deletes caches,
  apt lists and `/tmp` and must not run on a workstation. The Dockerfile sets the variable
  on that one command, not as `ENV` (R5).
- `render-overrides.sh` deletes `github_api_token` unconditionally and warns when it was
  present. `.dockerignore` excludes `ansible/vars/*overrides.yml*`, which also covers backup
  and swap copies of the native file (R6).
- `docker/test.sh`:
  - fails when no check is selected or a role's includes cannot be read (R7);
  - treats `all` and `tagged` in `ANSIBLE_TAGS` as selecting everything (R7);
  - fails list-driven checks on an empty list, and runs `sdk version` unconditionally (R7);
  - always runs `docker buildx version` (R8);
  - `config/p10k` asserts gitstatusd when `.zshrc` selects powerlevel10k (R10, narrowed in
    R11);
  - `config/zsh` starts zsh with the container's start PATH, because the zsh PATH has RVM's
    ruby without `GEM_HOME` and RVM warns about that (Task 8).
- `docker/nvim-install.lua` replaces the inline `MasonToolsInstallSync` / `TSUpdateSync`
  commands (R9). Under lazy.nvim the inline commands were a silent no-op, and
  `MasonToolsInstallSync` never returns when `ensure_installed` lists a package twice. The
  helper runs through `pcall(dofile, ...)` with `cquit 1` on error, so a missing or broken
  helper fails the build (R10, R11). It runs with the PATH of an interactive zsh, so Mason
  installs its npm, go and gem packages (R13). Mason and treesitter failures stay non-fatal
  (R12). `cleanup.sh` removes the Go module cache and npm logs this leaves.
- The root bootstrap installs `bsdextrautils`. gvm needs `hexdump`; native Ubuntu gets it
  through a recommend of the essential `bsdutils`.
- `zshrc.j2`: the RVM line is an `if` block, so a missing RVM leaves exit status 0.
- CI: the concurrency group is keyed on the built ref, and the `develop` path filter uses
  `git diff --quiet` without a pipe (R17).
- Measured on this machine (WSL, 16 cores), full build with the default profile:
  - image 8.55 GB; playbook layer 7.25 GB, Python layer 1.07 GB;
  - build 13m26s with the Python layer cached, about 18-20 minutes with it rebuilt (17m51s
    measured before R13, which added under a minute of Mason installs);
  - cleanup removed 2874 MiB;
  - 52 of 52 checks passed;
  - Mason 40 packages and lazy 113 plugins, the same lists as the native install.
- Not verified: the workflow has not run on GitHub; the Docker Hub per-layer size limit and
  CI disk space are unconfirmed.
