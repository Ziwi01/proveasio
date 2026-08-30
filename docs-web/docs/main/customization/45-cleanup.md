# Cleaning up old versions

Most tools are installed into versioned directories under `~/.local/opt`,
following the pattern `~/.local/opt/<tool>-<version>` (for example
`~/.local/opt/eza-0.23.5`). The matching binary is then symlinked into
`~/.local/bin`.

Whenever a newer version is installed, a brand new directory is created next to
the old one. Without any cleanup these directories pile up over time and waste
disk space:

```text
~/.local/opt/
├── eza-0.22.0
├── eza-0.23.4
└── eza-0.23.5   <- currently in use
```

## Automatic cleanup

Auto-cleanup is **enabled by default**. After a tool is installed/updated,
proveasio removes every older `~/.local/opt/<tool>-*` directory and keeps only
the version that is currently in use. After a run the example above becomes:

```text
~/.local/opt/
└── eza-0.23.5   <- currently in use
```

The cleanup only ever touches directories that match the tool it just
installed, and never removes the version that is currently linked, so it is safe
to leave on.

## Turning it off globally

To keep every installed version of every tool, set the global switch in your
`ansible/vars/overrides.yml`:

```yaml
cleanup_old_versions: false
```

## Turning it off for particular software only

If you only want to keep old versions of some specific tools (for example to be
able to quickly roll back `helm` or `k9s`), leave the global switch on and add
those tools to `cleanup_old_versions_exclude` in your
`ansible/vars/overrides.yml`:

```yaml
cleanup_old_versions_exclude:
  - helm # keep every ~/.local/opt/helm-* version
  - k9s  # keep every ~/.local/opt/k9s-* version
```

The names used here are the directory prefixes under `~/.local/opt` (the part
before `-<version>`). This mirrors the way
[`software_tasks_exclude`](./excludes) works, so the convention should feel
familiar.

## AWS CLI

AWS CLI is also cleaned up, but it uses its own on-disk layout. Its bundled
installer keeps every version under `~/.local/opt/aws-cli/v2/<version>` and
points a `current` symlink at the active one:

```text
~/.local/opt/aws-cli/v2/
├── 2.34.33
├── 2.36.34        <- current
└── current -> 2.36.34
```

The cleanup keeps only the version the `current` symlink points to and removes
the rest. To keep every AWS CLI version, add `aws-cli` to the exclude list:

```yaml
cleanup_old_versions_exclude:
  - aws-cli
```

## Node (nvm)

Node versions are installed by `nvm` under
`~/.local/opt/nvm/versions/node/<version>` and are never removed when a new
default is installed:

```text
~/.local/opt/nvm/versions/node/
├── v20.19.5
├── v22.22.2
└── v22.23.2   <- default
```

The cleanup resolves the concrete version behind the `default` alias (the
`node_version` variable may be an alias such as `lts/jod`) and removes every
other installed Node version. To keep every Node version, add `node` to the
exclude list:

```yaml
cleanup_old_versions_exclude:
  - node
```

:::note[Neovim]
Neovim is intentionally left out of the automatic cleanup because it uses a
different on-disk layout (a shared `neovim-nightly` directory holding the
downloaded appimages). Its old artifacts are not removed automatically.
:::

:::tip
Cleanup runs as part of the `versions` tag, so a run limited to updating
versions will also prune old directories:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags versions -K
```

To skip the cleanup while still running everything else, use
`--skip-tags cleanup`.
:::
