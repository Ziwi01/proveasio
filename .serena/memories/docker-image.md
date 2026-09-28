# Docker image

Built on `develop` in Sept 2026 (spec `docs/superpowers/specs/2026-09-24-docker-image-design.md`,
plan `docs/superpowers/plans/2026-09-24-docker-image.md`). The playbook runs inside
`docker buildx bake`; the image is tested in the build before it exists.

## Files

- `docker-bake.hcl` (repo root): variables `REFRESH`, `UBUNTU_VERSION`, `USERNAME`, `USER_UID`,
  `USER_GID`, `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `NVIM_CONFIG`, `IMAGE`, `HOME`. Targets
  `image` (default group, target `final`, `type=docker`) and `receipt` (writes
  `./out/current-versions.yml`). `docker-metadata-action` target is replaced by CI.
  Secret `id=GITHUB_TOKEN,env=GITHUB_TOKEN` (string form; the HCL object form fails when unset).
  Bake does not expand `~`: `regex_replace(NVIM_CONFIG, "^~", HOME)`.
  An `NVIM_CONFIG` dir outside the working directory needs `--allow fs.read=<dir>`; without
  it buildx 0.37 stops with `ERROR: additional privileges requested` (probed 2026-09-25;
  `--print` does not check). `docker buildx bake image receipt` builds both from one REFRESH;
  a separate `bake receipt` run gets a new timestamp and re-runs the playbook.
- `.dockerignore`: allowlist (`ansible/`, `prepare-ubuntu.sh`, `docker/`), then excludes
  `ansible/vars/*overrides.yml*` and `ansible/.ansible/`.
- `docker/Dockerfile`: stages `nvim-config` (empty scratch, replaced by the named context),
  `build`, `test`, `receipt` (copies from `build`), `final` (last stage, copies
  `tests-passed` from `test`). `--set image.target=build` gives an untested image.
- `docker/profile.yml`: committed container defaults (excludes w32yank, wsl-notify-send;
  `neovim_package: tarball`; `docker_manage_service: false`; docker-ce/containerd `absent`;
  `config_files_backup: false`).
- `docker/render-overrides.sh`: writes `~/proveasio/ansible/vars/overrides.yml` and
  `~/proveasio/docker/build-info.env` (ANSIBLE_TAGS, ANSIBLE_SKIP_TAGS, REFRESH, BUILD_DATE).
  Exits 2 unless `PROVEASIO_IMAGE_BUILD=1` (same opt-in as cleanup.sh), exits 1 when the
  nvim-config dir exists but `ls -A` fails.
- `docker/nvim-install.lua`: starts `MasonToolsInstall`, waits until no Mason package is
  installing, then treesitter (`TSUpdateSync` or nvim-treesitter `main` `install():wait()`
  with AstroNvim's list). Called via `pcall(dofile, ...)` + `cquit 1`.
- `docker/cleanup.sh`: caches, rvm src/archives, rust-docs, awscli installer, gvm archive,
  SDKMAN tmp, Go module cache (`chmod -R u+w` first), npm logs, apt lists, `/tmp`.
- `docker/test.sh`: smoke checks; flags `--list`, `--only <role>/<name>`, `--coverage`.
- `.github/workflows/docker.yml`: `plan` job + `image` job.
- User docs: `docs-web/docs/main/docker/{10-build,20-customize,30-run,40-limitations}.md`.
- `.gitignore`: `docker/overrides.yml`, `/out/`.

## Merge rule

`yq eval-all '. as $i ireduce ({}; . *+ $i)' profile.yml overrides.yml`: maps merge
recursively, lists append. A user cannot drop a profile list entry without editing the
profile. The result then goes through the roles' normal include_vars/combine sandwich (only
`github_packages`, `pip_packages`, `docker_apt_packages` merge per key). `github_api_token` is
always deleted (the file stays in the image); the token only comes in as the build secret.

## Five-edit rule for new software

The fourth edit is `check_software_<tool>` (dashes to underscores) in `docker/test.sh`. A
selected include without a check fails the image build. `PROVEASIO_HOME="$PWD" bash
docker/test.sh --coverage` lists missing checks on the host without building
(expected: `# 54 includes, 0 without a check` at the time of writing).

## test.sh selection and strictness

Reads includes from `software`/`config` `tasks/main.yml` with yq (name = `file:` minus
`.yml`, plus outer `tags:`), subtracts effective `*_tasks_exclude`, applies build tags
(`all`/`tagged` select everything; skip-tags match literally). Fails when: zero checks
selected, a role's includes cannot be read, a list-driven check has an empty list
(so `npm_default_packages: []` or `omz_plugins: {}` fail the build; exclude the tool instead).

## zsh PATH capture and why

Checks run in bash, not zsh: oh-my-zsh enables `EXTENDED_GLOB`, which breaks ordinary
shell code. They use the PATH of an interactive zsh so they see what a user sees (nvm, gvm,
rvm put tools on PATH only via `.zshrc`). zsh without a terminal prints
`can't change option: zle` and p10k's `gitstatus failed to initialize`, so the capture runs
under `script`:
`timeout 60 script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null </dev/null | tr -d '\r' | tail -n 1`
(accepted only if it contains `/usr/bin`). `</dev/null` is required with `timeout`: timeout
puts script in its own process group, and with a terminal on stdin (test.sh run by hand in
`docker run -it`) script stops on terminal access and hangs until the timeout (rc 124). The same capture is duplicated in the Dockerfile
for the nvim-install step (Mason needs npm/go/gem). `config/zsh` deliberately uses the
container's start PATH instead (the zsh PATH has RVM's ruby without `GEM_HOME`, RVM warns).
`script` is from `bsdutils` (essential).

## Build behaviour

- `REFRESH` defaults to `timestamp()`, evaluated per Bake invocation, so every local build
  re-runs the playbook and re-resolves `latest`. `REFRESH=dev` keeps the cached layer. CI
  pins `REFRESH=<run_id>-<run_attempt>` so the receipt step hits the cache.
- The whole `docker/` dir is bind-mounted into the playbook RUN, so editing any file in it
  (even test.sh) re-runs the playbook regardless of REFRESH.
- `cleanup.sh` and `render-overrides.sh` exit 2 unless `PROVEASIO_IMAGE_BUILD=1`; the
  Dockerfile sets it on those two commands only. Never set it on a workstation.
- `ENV DISABLE_AUTO_UPDATE=true` in the build stage: oh-my-zsh otherwise prompts to update
  in containers 13+ days old, which breaks non-interactive zsh starts (test.sh).
- The playbook RUN exports `ANSIBLE_CONFIG` (COPY from a world-writable /mnt/c checkout
  would make Ansible ignore `ansible.cfg` in the CWD). The zsh capture, nvim step and zsh
  warm-up run with `env -u GITHUB_TOKEN`.
- Root bootstrap reuses an existing group when `USER_GID` is taken (`getent group`).
- A zsh warm-up under `script` at the end of the playbook RUN downloads p10k's gitstatusd,
  so containers start offline. `config/p10k` asserts it when `.zshrc` selects p10k.
- Bootstrap installs `bsdextrautils` (hexdump for gvm); native gets it via recommends.
- Mason/treesitter failures are logged, not fatal (depends on user config/registries).

## Verify

- `docker buildx bake --print`
- Smoke build (quick check, 9 checks, ~5-7 min with cached bootstrap layers; its 13 Mason
  failures are expected because nvm/gvm/rvm are not in the tag set):
  `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke docker buildx bake`
- WSL: check free host memory first. A full build drove WSL to its 20 GB cap and, with a
  game running on Windows, exhausted host memory; Windows shut WSL down and `/tmp` was lost.

## Measured (WSL, 16 cores, default profile, 2026-09-24)

Image 8.55 GB; playbook layer 7.25 GB; Python layer 1.07 GB. Full build 13m26s with the
bootstrap layers cached (playbook step 759 s, tests 10 s); about 18-20 min with them rebuilt
(17m51s measured before Mason got the zsh PATH). Cleanup removed 2874 MiB (rust-docs 916 MiB,
go-build 492 MiB, SDKMAN tmp 447 MiB). 52/52 checks. Mason 40, lazy 113, identical to native.
A custom build (rust excluded, eza pinned, local NVIM_CONFIG) gave 51/51 and 7.9 GB.

## Known gaps and gotchas

- `ANSIBLE_SKIP_TAGS` with `eza`, `zsh` or `config` is unsupported: `[Config] Configure zsh`
  has outer tags `config`, `zsh`, `eza`, so the default oh-my-zsh `.zshrc` stays in place and
  the tests fail. Use `software_tasks_exclude: [eza]`. `zsh` cannot be excluded at all (CMD
  is zsh; test.sh needs the zsh configuration).
- Images built with `NVIM_CONFIG` persist `neovim_config_local_path: /tmp/nvim-config`; to
  re-run the playbook in such a container, add `neovim-config` to `config_tasks_exclude`.
- `opencode.yml` picks AVX2 from the build host's `/proc/cpuinfo` (SIGILL risk on old CPUs).
- `.zcompdump-buildkitsandbox-*` files are named after the build host.
- The ignored `[Neovim] Check installed exact Neovim version` prints a red error in every
  fresh build (pre-existing pipe-in-command bug, in TODO.md).

## Unverified CI items

- The workflow has never run on GitHub. Not verified: disk space on a standard runner
  (image ~9 GB, playbook step peaks above 11 GB before cleanup), Docker Hub per-layer size
  limit, metadata-action/bake-action integration, `type=cacheonly` on non-publishing runs.
- Scheduled runs start on `develop` (default branch) and check out `master`, which has no
  `docker/` until the next release, so they fail until then.
- Publishing needs `CHANGEME` in `IMAGE_NAME`, `vars.DOCKERHUB_USERNAME` and
  `secrets.DOCKERHUB_TOKEN` set.
- At release, the `master` push and the `v*` tag both push `sha-<short>` from different
  concurrency groups; last one wins.
