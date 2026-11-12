# Launcher cleanup and uninstall

## Intent

`proveasio` (the host-side launcher, `docker/proveasio`) leaves named volumes,
images and a config directory behind. Some volumes come from the user's own
`PROVEASIO_ARGS` lines, and volumes stay in Docker after their config line is
removed (`proveasio-zoxide` is an example). There is no way to list or remove
any of it. This change adds `proveasio cleanup` (selective) and
`proveasio uninstall` (everything), and makes the launcher label the volumes it
creates so cleanup can find them later.

## Goals

- Every named volume the launcher mounts is labeled when the launcher creates it.
- `cleanup` removes a chosen subset: volumes (all, some, all but some),
  images, config.
- `uninstall` removes everything the launcher created, plus the launcher itself.
- Unlabeled volumes that look like ours are reported. The user decides whether
  to remove them.

## Non-goals

- Migrating existing unlabeled volumes to labeled ones (tested and possible, but
  it copies user data twice and can leave it only in a temporary volume if
  interrupted).
- Stopping containers.
- The Windows host, anything under `ansible/`.

## Anti-goals

- Deleting a bind-mount source (`~/.ssh`, `~/.kube`, the Docker socket, the CA
  bundle, the `/workspace` directory). These are the user's host files.
- Deleting the repository checkout when the launcher is a symlink into it.
- Removing anything without listing it first and asking (unless `--yes`).

## Constraints (tested on Docker 29.9.3)

- `docker volume create --label L NAME` labels a new volume.
- On an existing volume the same command exits 0 and changes nothing; labels
  stay `null`. The launcher must check existence itself (`docker volume inspect`)
  and must not report an existing volume as labeled.
- `docker volume update` works on Swarm cluster volumes only; there is no way to
  add a label to an existing local volume.
- A pre-created empty labeled volume still gets the image's content and
  ownership copied in on first mount at a path that exists in the image.
- A volume mounted at a path the image does not have is created as root,
  pre-created or not. This change does not fix that (the config template
  already warns about it).

## Approaches

1. **Config plus name prefix.** Collect volumes from the config and any
   `proveasio-*` volume. No run-path change. Misses custom-named volumes after
   their config line is gone.
2. **Labels (chosen).** The launcher creates each named volume with a label
   before `docker run`; cleanup filters on the label. Finds custom names after
   their line is gone. Existing volumes cannot be labeled, so approach 1 is
   kept as the fallback for them.
3. **Config only.** Cannot find leftovers, which is the case that prompted this.

The user picked 2. For existing unlabeled volumes the user picked the fallback
without migration, with a notice asking whether to remove them as well.

## Design

### Label

`io.github.ziwi01.proveasio.launcher=1` (my call: reverse-DNS key, per Docker's
label convention).

### Run path

- Collect named volumes from the built-in `proveasio-state` mount and
  `PROVEASIO_ARGS`:
  - `-v`/`--volume` as a separate argument or with `=`: the part before the
    first `:` is a named volume when it does not start with `/`, `.` or `~`
    and the spec has a `:` (a spec without `:` is an anonymous volume).
  - `--mount` (separate or `=`): CSV fields; a named volume when `type` is
    missing or `volume` and `src`/`source` is set.
- For each name that `docker volume inspect` does not find:
  `docker volume create --label io.github.ziwi01.proveasio.launcher=1 NAME`.
- `--dry-run` prints those create commands before the `docker run` line and
  creates nothing.

### `proveasio cleanup`

```
proveasio cleanup [--mounts[=NAME,...]] [--exclude-mount NAME]...
                  [--include-unlabeled] [--images[=all]] [--config]
                  [--yes] [--dry-run]
```

- With no selector (`--mounts`, `--images`, `--config`), prints usage and exits
  2 (my call: nothing is removed implicitly).
- `--mounts`: all labeled volumes. `--mounts=a,b`: only those names (labeled or
  unlabeled candidates; a name that is neither is reported and ignored).
  `--exclude-mount NAME`, repeatable, takes names out of the selection.
- Unlabeled candidates: volumes that exist, lack the label, and are either named
  in the current config (same parsing as the run path) or start with
  `proveasio-`. With `--mounts` they are listed separately and the user is
  asked `Also remove these unlabeled volumes? [y/N]`. `--include-unlabeled`
  includes them without asking. With `--yes` and no `--include-unlabeled` they
  are listed and kept. Exclusions apply to them too.
- `--images`: the configured image (resolved as in a run: option, environment,
  config, default). `--images=all`: every image whose repository is `proveasio`
  or ends in `/proveasio` (opt-in, my call: on a developer machine this
  includes local builds such as `proveasio:smoke`).
- `--config`: the launcher's files in the config directory: `config`,
  `config.bak`, `conf.d/*.sh` and the token files `ado-pat` and `github-token`.
  Other files are listed as not removed; `conf.d/` and the directory are
  removed only when empty. A directory that is `/`, `$HOME` or above it is
  refused. (Changed after review: removing the whole directory deleted any
  directory `PROVEASIO_CONFIG_DIR` pointed at.)
- One list of everything to remove, then one `Remove these? [y/N]`. `--yes`
  skips it; `--dry-run` prints the list and exits 0.
- A volume still used by a container (`docker ps -a --filter volume=NAME`) is
  reported and skipped. An image used by a container is reported and skipped.
  Nothing is stopped or forced (my call).
- Without a TTY on stdin and without `--yes`, it refuses (exit 1) instead of
  reading an empty answer as "no" silently (my call).
- Exit status: 0 when everything selected was removed or skipped as in use;
  1 when a removal failed.

### `proveasio uninstall`

```
proveasio uninstall [--include-unlabeled] [--yes] [--dry-run]
```

- Same as `cleanup --mounts --images=all --config`, including the unlabeled
  question, then removes the launcher:
  - the path the script was started from (`$0`, or `command -v proveasio`
    when `$0` has no `/`);
  - a symlink: remove the link only;
  - a regular file: remove it;
  - the launcher is listed with the rest before the single confirmation.

### Usage text and config template

`usage()` gains both commands. The config template does not change.

## Documentation

`docs-web/docs/main/docker/30-run.md`: a "Cleanup and uninstall" section
(commands, options, the label, why older volumes show as unlabeled, bind mounts
are never touched). The launcher's starter config template and the docs presets
are unaffected.

## Verification

- `bash -n docker/proveasio`; `shellcheck docker/proveasio` if installed (not a
  project gate).
- A case table run with a temporary `PROVEASIO_CONFIG_DIR` and throwaway volumes
  and image tags (prefix `pvt-` or a `proveasio-pvt-` name for prefix cases):
  run path labels new volumes and leaves existing ones; `--dry-run` creates
  nothing; each cleanup selector; exclusions; unlabeled notice with and without
  `--include-unlabeled` and `--yes`; in-use volume skipped; no-TTY refusal;
  uninstall removes a symlink but not its target, and a regular file.
- `cd docs-web && npm run build`.

## Left to the builder

- Function layout inside `docker/proveasio` (keep the `_pv_` prefix for
  variables set while a config is sourced).
- Exact wording of messages.
