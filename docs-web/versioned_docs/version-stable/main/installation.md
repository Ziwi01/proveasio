---
sidebar_position: 6
---

# Installation

Assuming all the [requirements](./requirements) are met:

0. Launch Ubuntu terminal (if using WSL - ensure it is running with `systemd`, see [manual setup](./windows/manual))
1. Download the project - see [Download](./download)
2. Go to downloaded directory: `cd ~/proveasio`
3. Create file `ansible/vars/overrides.yml` - set desired GIT config name and e-mail. See `ansible/vars/README.md` for more examples

   ```yaml
   git:
     name: James
     mail: james.doe@hell.no
   ```

4. (from repo root) Run `sudo ./prepare-ubuntu.sh` (if not already run during windows setup) to update the system and install required python and ansible packages
5. Reload your terminal (close and open again)
6. (from repo root) Run ansible: 

    ```shell
    cd ansible; ansible-playbook -i inventory.yml setup-ubuntu.yml -K
    ```

