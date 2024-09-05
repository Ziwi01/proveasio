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
  - zsh # do not configure ZSH
```

For full list of exclude options, see [software](../roles/software) or [config](../roles/config) role description.
