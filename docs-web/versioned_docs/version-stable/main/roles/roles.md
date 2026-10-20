---
sidebar_position: 9
---

# Ansible roles

Proveasio is a set of [Ansible](https://www.ansible.com/) roles. This section describes what each role does. To see exactly what happens, read the task files.

There are four roles:

- [`software`](./10-software.md) - installs the tools.
- [`config`](./20-config.md) - lays down the configuration files (dotfiles). It runs after `software`.
- `common` - internal helper tasks used by the other two (version lookups, saving versions, config files with backups, cleanup of old versions). It never runs on its own.
- `windows` - the experimental Windows setup, run by `setup-windows.yml`. See [Windows automation](../windows/20-automated.md).

`setup-ubuntu.yml` runs `software`, then `config`.

Each role has its settings in `ansible/roles/<role>/vars/main.yml` and its task list in `ansible/roles/<role>/tasks/main.yml`; every included tool has its own task file next to it.

To change a setting, do not edit `vars/main.yml`. Set the variable in `ansible/vars/overrides.yml`, see [Customizations](../../category/customizations).
