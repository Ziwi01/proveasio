# Excluding code

## Ad-hoc

You can disable whole functionalities during ansible run using `--skip-tags`, for example:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --skip-tags "software" -K
```

See [ansible roles](../roles) section for full list.

## Permanent

To exclude certain parts of ansible code for every subsequent runs, you can add to your `ansible/vars/overrides.yml` which sections you want to exclude:

```yaml
software_tasks_exclude:
  - azurecli # do not install azurecli
  - puppet # do not install Puppet
config_tasks_exclude:
  - tmux # do not configure tmux
```

For full list of exclude options, see [software](../roles/software) or [config](../roles/config) role description.

`packages`, `yq` and `zsh` in `software_tasks_exclude`, and `zsh` in `config_tasks_exclude`, are required. The playbook stops at the start when an overrides file excludes one of them.

## Old versions cleanup

Old versioned installs under `~/.local/opt` are removed automatically. This can
be disabled globally or per-tool — see [Cleaning up old versions](./cleanup).
