# OpenCode baseline build in the Docker image

## Intent

The published image must run OpenCode on any x64 CPU. The trigger is a QNAP NAS with
an Intel Celeron N5095, which has no AVX2: the image is meant to run OpenCode there as
an always-on server. Today `roles/software/tasks/opencode.yml` picks the `-baseline`
asset only when the machine running the playbook lacks AVX2. CI runners have AVX2, so
the published image ships the AVX2 build, which crashes (SIGILL) on such CPUs. The docs
list this as a limitation (`docker/40-limitations.md`, the opencode row and footnote in
`docker/10-build.md`).

## Goals

- Image builds (full and slim, local and CI) install the baseline OpenCode build.
- Native installs keep today's behaviour by default.
- The image test fails if an image that should have the baseline build does not.

## Non-goals

- Changing the `~/.local/opt/opencode-<version>` layout or the install gate.
- Building or publishing a release. The maintainer does that.

## Approaches

1. **Chosen:** a variable `opencode_baseline` (`auto` | `true`). `auto` keeps the AVX2
   check on the machine that runs the playbook, `true` always uses `-baseline` on x64.
   `docker/profile.yml` sets `true`.
2. Baseline everywhere: simpler, but native installs on modern CPUs get the slower build
   for nothing.
3. Ship both builds and pick at container start: more moving parts for no gain.

## Decisions

- `opencode_baseline: auto` in `roles/software/vars/main.yml`; `true` in
  `docker/profile.yml`, with a comment saying why. A `docker/overrides.yml` can set it
  back to `auto`.
- `true` only adds `-baseline` on x64. arm64 has no baseline asset and is unchanged.
- The asset that was actually installed is recorded in `current-versions.yml` as
  `opencode_asset`, written only by the run that downloads it. A later run that skips
  the install (same version already present) leaves the key alone, so it keeps
  describing the binary on disk.
- `check_software_opencode` in `docker/test.sh` fails when the effective
  `opencode_baseline` is `true` and `opencode_asset` does not end in
  `-baseline.tar.gz`.
- Upgrade caveat, documented rather than fixed: the install is skipped when
  `~/.local/opt/opencode-<version>/opencode` exists, so on an existing machine or with
  the `update` target the setting takes effect with the next OpenCode version.
- Docs: drop the limitation, mark the opencode row ✅ in the "Full and slim compared"
  table and remove its footnote, add `opencode_baseline` to
  `customization/10-variables.md`.

## Verification

`ansible-lint`, `--syntax-check`, the test.sh check against a scratch receipt, a smoke
build with `opencode` in `ANSIBLE_TAGS`, `npm run build`, and on the NAS: the binary
from the smoke image runs `--version` in a throwaway `ubuntu:24.04` container, and the
AVX2 build fails there.
