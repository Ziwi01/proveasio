---
sidebar_position: 6
---

# Installation

:::tip[Docker]
To build Proveasio as a Docker image instead of installing it on your machine, see [Docker image](./docker/build).
:::

Assuming all the [requirements](./requirements) are met:

1. Launch Ubuntu terminal (if using WSL - ensure it is running with `systemd`, see [manual setup](./windows/manual))
2. Download the project - see [Download](./download)
3. Go to downloaded directory: `cd ~/proveasio`
4. Create file `ansible/vars/overrides.yml` - set desired GIT config name and e-mail. See `ansible/vars/README.md` for more examples

   ```yaml
   git:
     name: James
     mail: james.doe@hell.no
   ```

5. Run `sudo ~/proveasio/prepare-ubuntu.sh` (if not already run during windows setup) to update the system and install required python and ansible packages
6. Reload your terminal (close and open again)
7. Run ansible:

   ```shell
   cd ~/proveasio/ansible; ansible-playbook -i inventory.yml setup-ubuntu.yml -K
   ```

8. After successful installation (green summary of versions installed), reload you terminal.

:::note
If either the preparation or installation steps are failing for you (#4 or #6), please see [Troubleshooting](./troubleshooting) section. If there is no answer for your problem, please create an Issue in Github.
:::
