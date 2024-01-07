---
sidebar_position: 6
---

# Ansible roles

This project is mostly based on [Ansible](https://www.ansible.com/). Below are the implementation details. You can browse through the configuration/task files to get a grip on what's going on exactly.

There are 2 essential roles:

- `software` - installs everything that needs to be installed
- `config` - configures everything that needs to be configured

Each role has their main configuration in `ansible/roles/<role>/vars/main.yml`. Also, their tasks are gathered in `ansible/roles/<role>/tasks/main.yml`. It is good idea to take a peek on all the .yml files in `tasks/` directories also. For detailed description of how those things work together, see [Usages](../../usage/about). To override any variable(s), please use `ansible/vars/overrides.yml` - see [Customizations](../../category/customizations).

:::note
There is also `common` role, to keep internal helper tasks.
:::
