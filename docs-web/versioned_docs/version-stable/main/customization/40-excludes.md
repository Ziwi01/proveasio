# Excluding code

## Ad-hoc

To leave something out of a single run, use `--skip-tags` (from the `ansible/` directory):

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --skip-tags "software" -K
ansible-playbook -i inventory.yml setup-ubuntu.yml --skip-tags "puppet,azurecli" -K
```

The tags are listed in [Run particular code](./50-partial-run.md).

## Permanent

To leave something out of every run, list it in `ansible/vars/overrides.yml`:

```yaml
software_tasks_exclude:
  - azurecli # do not install azurecli
  - puppet # do not install Puppet
config_tasks_exclude:
  - tmux # do not configure tmux
```

The names are listed in the [software](../roles/10-software.md) and [config](../roles/20-config.md) roles.

Excluding a tool does not uninstall it if an earlier run installed it. When you exclude a software task that has a config task of the same name (`tmux`, `ccmux`, `sdkman`, `lazygit`, `ansible`), exclude the config task too; for `neovim`, exclude `neovim-config`. Excluding `opencode` also skips `opencode-config`.

`packages`, `yq` and `zsh` in `software_tasks_exclude`, and `zsh` in `config_tasks_exclude`, are required. The playbook stops at the start when an overrides file excludes one of them.

## Old versions cleanup

Old versioned installs under `~/.local/opt` are removed automatically. This can
be disabled globally or per-tool — see [Cleaning up old versions](./cleanup).
