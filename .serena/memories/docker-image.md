# Docker image

Built on `develop` in Sept 2026 (spec `docs/superpowers/specs/2026-09-24-docker-image-design.md`,
plan `docs/superpowers/plans/2026-09-24-docker-image.md`; slim profile and updates:
spec `docs/superpowers/specs/2026-09-25-docker-slim-and-update-design.md`, plan
`docs/superpowers/plans/2026-09-25-docker-slim-and-update.md`). The playbook runs inside
`docker buildx bake`; the image is tested in the build before it exists.

## Files

- `docker-bake.hcl` (repo root): variables `REFRESH`, `UBUNTU_VERSION`, `USERNAME`, `USER_UID`,
  `USER_GID`, `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `PROFILE` (default `full`), `NVIM_CONFIG`,
  `IMAGE`, `BASE_IMAGE`, `HOME`. `IMAGE` is derived: `proveasio:local` for `full`,
  `proveasio:<PROFILE>` otherwise. `BASE_IMAGE` defaults to `IMAGE`. Targets `image` (default
  group, target `final`, `type=docker`), `receipt` (writes `./out/current-versions.yml`) and
  `update` (target `final`, args `PROVISIONED=update` and `BASE_IMAGE`, `pull = false` because
  the base image is usually only in the local store, `type=docker`). `docker-metadata-action`
  target is replaced by CI.
  Secret `id=GITHUB_TOKEN,env=GITHUB_TOKEN` (string form; the HCL object form fails when unset).
  Bake does not expand `~`: `regex_replace(NVIM_CONFIG, "^~", HOME)`.
  An `NVIM_CONFIG` dir outside the working directory needs `--allow fs.read=<dir>`; without
  it buildx 0.37 stops with `ERROR: additional privileges requested` (probed 2026-09-25;
  `--print` does not check). `docker buildx bake image receipt` builds both from one REFRESH;
  a separate `bake receipt` run gets a new timestamp and re-runs the playbook.
- `.dockerignore`: allowlist (`ansible/`, `prepare-ubuntu.sh`, `docker/`), then excludes
  `ansible/vars/*overrides.yml*` and `ansible/.ansible/`.
- `docker/Dockerfile`: global ARGs `BASE_IMAGE` (default `proveasio:local`) and `PROVISIONED`
  (default `build`). Stages: `nvim-config` (empty scratch, replaced by the named context),
  `build` (root bootstrap, `prepare-ubuntu.sh`, COPY `ansible/`, RUN `provision.sh`),
  `update` (`FROM ${BASE_IMAGE}`, COPY `ansible/`, RUN `provision.sh --update`),
  `provisioned` (`FROM ${PROVISIONED}`, an alias that picks `build` or `update`), `test`,
  `receipt` (copies from `provisioned`), `final` (last stage, copies `tests-passed` from
  `test`). Docker resolves `BASE_IMAGE` only when the `update` stage is built.
  `--set image.target=build` gives an untested image.
- `docker/provision.sh`: the playbook step, bind-mounted with `docker/` (not in the image).
  Exits 2 unless `PROVEASIO_IMAGE_BUILD=1`, then unsets it. Full mode: render overrides;
  required-task check (`test.sh --list --tags "$ANSIBLE_TAGS" --skip-tags ...` must list
  `software/packages`, `software/yq`, `software/zsh`, `config/zsh`, else it stops before the
  playbook); write `docker/build-info.env` (`PROFILE`, `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`,
  `REFRESH`, `BUILD_DATE`, `UPDATES=()`, values `printf %q`); `apt-get update` + `upgrade`;
  playbook; `nvim_install` (nvim-install.lua with the zsh PATH); `cleanup.sh`; zsh warm-up.
  `--update` mode: see "Updates".
- `docker/profile.yml`: committed container defaults (excludes w32yank, wsl-notify-send;
  `neovim_package: tarball`; `docker_manage_service: false`; docker-ce/containerd `absent`;
  `config_files_backup: false`).
- `docker/profile-slim.yml`: `PROFILE=slim`. Excludes sdkman, azurecli, az-account-switcher,
  rust, puppet, awscli (software) and sdkman (config: it writes `~/.sdkman/etc/config`).
  nvm, gvm and rvm stay: the default Neovim config installs Mason packages with npm (yaml,
  json, bash, ansible language servers), go (gopls, delve, ...) and gem (solargraph,
  standardrb), mason-tool-installer retries missing ones on every start, and
  `software/ansible.yml` installs the Ansible language server with nvm's npm.
- `docker/render-overrides.sh`: writes `~/proveasio/ansible/vars/overrides.yml` only (no build
  info; provision.sh writes `build-info.env`). Exits 2 unless `PROVEASIO_IMAGE_BUILD=1`.
  Inputs: `profile.yml`, `profile-<PROFILE>.yml` unless `PROFILE=full` (a missing profile
  file fails and lists the available ones; `PROFILE` must match `^[a-z0-9-]+$`), then the
  optional `docker/overrides.yml`. Then the include step (see "Merge rule"), the
  `nvim-config` switch (exits 1 when the dir exists but `ls -A` fails), and the
  `PROVEASIO_BASE_OVERRIDES` carry-over: in an update without `NVIM_CONFIG`, a base image
  built with a local Neovim config keeps `neovim_config_source: local` and its path.
- `docker/nvim-install.lua`: starts `MasonToolsInstall`, waits until no Mason package is
  installing, then treesitter (`TSUpdateSync` or nvim-treesitter `main` `install():wait()`
  with AstroNvim's list). Called via `pcall(dofile, ...)` + `cquit 1`.
- `docker/cleanup.sh`: caches, rvm src/archives, rust-docs, awscli installer, gvm archive,
  SDKMAN tmp, Go module cache (`chmod -R u+w` first), npm logs, apt lists, `/tmp`.
- `docker/test.sh`: smoke checks; flags `--list`, `--list --tags <t> --skip-tags <s>` (select
  as ansible-playbook would, instead of `build-info.env`; used by provision.sh; may print
  nothing without failing), `--only <role>/<name>`, `--coverage`. Without `--tags`, an
  include counts when the build's tags or the tags of any `UPDATES` entry select it (union).
- `.github/workflows/docker.yml`: `plan` job + `image` job, a matrix over `full` and `slim`
  (`slim` gets tag `slim` instead of `latest` and a `-slim` suffix on the others; receipt
  artifact `current-versions-<profile>`).
- User docs: `docs-web/docs/main/docker/{10-build,20-customize,30-run,40-limitations}.md`.
- `.gitignore`: `docker/overrides.yml`, `/out/`.

## Merge rule

`yq eval-all '. as $i ireduce ({}; . *+ $i)' profile.yml [profile-<PROFILE>.yml] overrides.yml`:
maps merge recursively, lists append. A user cannot drop a profile list entry by merging.
Instead, the include step: `software_tasks_include` / `config_tasks_include` in
`docker/overrides.yml` take names out of `software_tasks_exclude` / `config_tasks_exclude`,
then the include keys are deleted. They must be lists; an unknown name (not an include of
`roles/<role>/tasks/main.yml`) fails; a name that is not excluded is reported and ignored, so
one overrides file works with every profile. Docker only; the native path has no include
keys. The result then goes through the roles' normal include_vars/combine sandwich (only
`github_packages`, `pip_packages`, `docker_apt_packages` merge per key). `github_api_token` is
always deleted (the file stays in the image); the token only comes in as the build secret.

## Updates (`docker buildx bake update`, `provision.sh --update`)

- Needs `ANSIBLE_TAGS`. The base image needs `build-info.env` and `ansible/vars/overrides.yml`
  (a Proveasio image built with docker-bake.hcl). `USERNAME`/`USER_UID`/`USER_GID` must match
  the base image user.
- Keeps the base image's `PROFILE` from `build-info.env` (no line = `full`). A different
  `PROFILE` build argument fails. Bake always passes `PROFILE` (default `full`), so updating a
  slim image needs `PROFILE=slim` (which also derives `IMAGE` and `BASE_IMAGE`).
- Renders overrides with the base file as `PROVEASIO_BASE_OVERRIDES`. Fails when the tags
  select nothing, when an exclude list grows (an update cannot remove a tool), or when a name
  taken back with `*_tasks_include` is not selected by the tags. Fails when the base used a
  local Neovim config, no `NVIM_CONFIG` is passed and the tags select `config/neovim-config`.
- `apt-get update` only, no upgrade. `nvim_install` only when the tags select
  `software/neovim` or `config/neovim-config`. Then cleanup, zsh warm-up, and
  `UPDATES+=("<date>|<tags>|<skip-tags>")` appended to `build-info.env`.
- Each update adds about 4 layers (COPY ansible, RUN, COPY test.sh, tests-passed); replaced
  files stay in the layers below, so the image only grows.

## Five-edit rule for new software

The fourth edit is `check_software_<tool>` (dashes to underscores) in `docker/test.sh`. A
selected include without a check fails the image build. `PROVEASIO_HOME="$PWD" bash
docker/test.sh --coverage` lists missing checks on the host without building
(expected: `# 54 includes, 0 without a check` at the time of writing).

## test.sh selection and strictness

Reads includes from `software`/`config` `tasks/main.yml` with yq (name = `file:` minus
`.yml`, plus outer `tags:`), subtracts effective `*_tasks_exclude`, applies build tags
(`all`/`tagged` select everything; skip-tags match literally) and the tags of every
`UPDATES` entry. Fails when: zero checks selected (except with explicit `--list --tags`), a
role's includes cannot be read, a list-driven check has an empty list (so
`npm_default_packages: []` or `omz_plugins: {}` fail the build; exclude the tool instead).

## zsh PATH capture and why

Checks run in bash, not zsh: oh-my-zsh enables `EXTENDED_GLOB`, which breaks ordinary
shell code. They use the PATH of an interactive zsh so they see what a user sees (nvm, gvm,
rvm put tools on PATH only via `.zshrc`). zsh without a terminal prints
`can't change option: zle` and p10k's `gitstatus failed to initialize`, so the capture runs
under `script`:
`timeout 60 script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null </dev/null | tr -d '\r' | tail -n 1`
(accepted only if it contains `/usr/bin`). `</dev/null` is required with `timeout`: timeout
puts script in its own process group, and with a terminal on stdin (test.sh run by hand in
`docker run -it`) script stops on terminal access and hangs until the timeout (rc 124). The
same capture is duplicated in `provision.sh` (`zsh_path`) for the nvim-install step (Mason
needs npm/go/gem). `config/zsh` deliberately uses the container's start PATH instead (the
zsh PATH has RVM's ruby without `GEM_HOME`, RVM warns). `script` is from `bsdutils`
(essential).

## Build behaviour

- `REFRESH` defaults to `timestamp()`, evaluated per Bake invocation, so every local build
  re-runs the playbook and re-resolves `latest`. `REFRESH=dev` keeps the cached layer. CI
  pins `REFRESH=<run_id>-<run_attempt>` so the receipt step hits the cache.
- The whole `docker/` dir is bind-mounted into the playbook RUN (both `build` and `update`),
  so editing any file in it (even test.sh) re-runs the playbook regardless of REFRESH.
- `provision.sh`, `render-overrides.sh` and `cleanup.sh` exit 2 unless
  `PROVEASIO_IMAGE_BUILD=1`. The Dockerfile sets it on `provision.sh`, which unsets it and
  passes it to `render-overrides.sh` and `cleanup.sh` only (not to the playbook). Never set it
  on a workstation.
- `ENV DISABLE_AUTO_UPDATE=true` in the build stage: oh-my-zsh otherwise prompts to update
  in containers 13+ days old, which breaks non-interactive zsh starts (test.sh).
- `provision.sh` runs the playbook with `ANSIBLE_CONFIG` set (COPY from a world-writable
  /mnt/c checkout would make Ansible ignore `ansible.cfg` in the CWD). The zsh capture, nvim
  step and zsh warm-up run with `env -u GITHUB_TOKEN`.
- Root bootstrap reuses an existing group when `USER_GID` is taken (`getent group`).
- A zsh warm-up under `script` at the end of `provision.sh` downloads p10k's gitstatusd,
  so containers start offline. `config/p10k` asserts it when `.zshrc` selects p10k.
- Bootstrap installs `bsdextrautils` (hexdump for gvm); native gets it via recommends.
- Mason/treesitter failures are logged, not fatal (depends on user config/registries).

## Verify

- `docker buildx bake --print`, `PROFILE=slim docker buildx bake --print image` (tag
  `proveasio:slim`, `PROFILE` `slim`), `docker buildx bake --print update` (`BASE_IMAGE`
  `proveasio:local`).
- Smoke build (quick check, 9 checks, ~5-7 min with cached bootstrap layers; its 13 Mason
  failures are expected because nvm/gvm/rvm are not in the tag set):
  `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke docker buildx bake`
- Update check on the smoke image (9 checks):
  `IMAGE=proveasio:smoke ANSIBLE_TAGS=eza docker buildx bake update`
- Slim build: `PROFILE=slim docker buildx bake` (loads `proveasio:slim`; 45 checks expected).
- WSL: check free host memory first. A full build drove WSL to its 20 GB cap and, with a
  game running on Windows, exhausted host memory; Windows shut WSL down and `/tmp` was lost.

## Measured (WSL, 16 cores, default profile, 2026-09-24)

Image 8.55 GB; playbook layer 7.25 GB; Python layer 1.07 GB. Full build 13m26s with the
bootstrap layers cached (playbook step 759 s, tests 10 s); about 18-20 min with them rebuilt
(17m51s measured before Mason got the zsh PATH). Cleanup removed 2874 MiB (rust-docs 916 MiB,
go-build 492 MiB, SDKMAN tmp 447 MiB). 52/52 checks. Mason 40, lazy 113, identical to native.
A custom build (rust excluded, eza pinned, local NVIM_CONFIG) gave 51/51 and 7.9 GB.
Measured before `provision.sh`, profiles and updates existed.

## Measured (2026-09-28)

WSL, bootstrap layers cached, GitHub API unauthenticated (smoke used 8 and slim 30 of the
60 calls per hour). Nothing failed; `npm run build` in `docs-web/` passes.
- Smoke build: 5m11s, 9/9 checks, `proveasio:smoke` 3.37 GB (10 layers). Mason 27 installed,
  13 failed as expected (yaml, json, bash and ansible language servers, delve, gopls,
  gomodifytags, gotests, iferr, impl, goimports, solargraph, standardrb). Cleanup 181 MiB.
  `~/.zfunc/_eza` links into `~/.local/opt/eza-<version>/`, zsh completion is `_eza`.
  `build-info.env` holds `ANSIBLE_TAGS=software_packages\,yq\,...`: bash `printf %q`
  escapes commas; sourcing gives the plain value.
- Early failures (`ANSIBLE_TAGS=neovim`; `ANSIBLE_SKIP_TAGS=config`; `docker/overrides.yml`
  excluding `zsh`): each rc 1 after about 3 s, naming the missing includes; no image loaded.
- Slim build: 10m06s, 45/45 checks, `proveasio:slim` 5.69 GB (10 layers). Mason 40 installed,
  no failures. Cleanup 1144 MiB.
- Updates (`docker buildx bake update`), cleanup 51 MiB each, no nvim-install step:
  - eza on smoke: 14 s, 9/9, 3.37 -> 3.38 GB, 10 -> 14 layers, `UPDATES+=(<date>\|eza\|)`.
  - terraform on smoke: 15 s, 10/10, 3.38 -> 3.51 GB, 18 layers.
  - azurecli,az-account-switcher on slim (`proveasio:slim-az`, overrides with
    `software_tasks_include`): 38 s, 47/47, 6.30 GB, 14 layers; `proveasio:slim` unchanged.
  - Refusals, each rc 1 in 1-2 s with its message: no `ANSIBLE_TAGS`, `no-such-tag`,
    `USERNAME=other`, new exclude `fx`, `az-account-switcher` taken back but not in the tags.
- Host memory: after the slim build WSL kept ~12 GB of page cache (`.wslconfig` has only
  `memory=20GB`, no `autoMemoryReclaim`). Windows free physical memory stayed at 7.6-8.5 GB
  for about 30 minutes, then went back to 16.9 GB. Expect to wait between builds.

## Known gaps and gotchas

- A new image needs software/packages, software/yq, software/zsh, config/zsh; provision.sh
  stops before the playbook otherwise. Excluding packages, yq or zsh fails the playbook's
  assert everywhere.
- Updates grow the image (replaced files stay in lower layers) and cannot remove tools: a
  new exclude fails the update. Run a full build to remove a tool or to shrink the image.
- `docker buildx bake --call check <target>` on a target with `output=type=docker` loads an
  empty image under `IMAGE` and untags the real one (found while testing the `update` target). Use `--print` instead.
- Images built with `NVIM_CONFIG` persist `neovim_config_local_path: /tmp/nvim-config`; to
  re-run the playbook in such a container, add `neovim-config` to `config_tasks_exclude`.
- `opencode.yml` picks AVX2 from the build host's `/proc/cpuinfo` (SIGILL risk on old CPUs).
- `.zcompdump-buildkitsandbox-*` files are named after the build host.
- The ignored `[Neovim] Check installed exact Neovim version` prints a red error in every
  fresh build (pre-existing pipe-in-command bug, in TODO.md).

## Unverified CI items

- The workflow has never run on GitHub. Not verified: the full/slim matrix and its metadata
  tags, disk space on a standard runner (image ~9 GB, playbook step peaks above 11 GB before
  cleanup), Docker Hub per-layer size limit, metadata-action/bake-action integration,
  `type=cacheonly` on non-publishing runs.
- Scheduled runs start on `develop` (default branch) and check out `master`, which has no
  `docker/` until the next release, so they fail until then.
- Publishing needs `CHANGEME` in `IMAGE_NAME`, `vars.DOCKERHUB_USERNAME` and
  `secrets.DOCKERHUB_TOKEN` set.
- At release, the `master` push and the `v*` tag both push `sha-<short>` from different
  concurrency groups; last one wins.
