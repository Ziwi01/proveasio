---
sidebar_position: 6
---

# Installation

:::tip[Docker]
To build Proveasio as a Docker image instead of installing it on your machine, see [Docker image](./docker/10-build.md).
:::

Make sure the [requirements](./requirements.md) are met, then:

1. Open an Ubuntu terminal. On WSL, check that it runs with `systemd` (see [manual setup](./windows/10-manual.md)).
2. Download the project, see [Download](./download.md).
3. Go to the project directory: `cd ~/proveasio`
4. Create `ansible/vars/overrides.yml` and set your git name and e-mail. More examples are in `ansible/vars/README.md`.

   ```yaml
   git:
     name: James
     mail: james.doe@hell.no
   ```

5. Run `sudo ~/proveasio/prepare-ubuntu.sh`, unless you already ran it during the Windows setup. It updates the system and installs Python (with pyenv) and Ansible.
6. Close the terminal and open it again, so the new Python and Ansible are on your `PATH`.
7. Log in to GitHub, so the version lookups do not hit the API rate limit (optional, but recommended):

   ```shell
   gh auth login   # or: export GITHUB_TOKEN=<token>
   ```

   `gh` is installed by the playbook. On the first run, use `GITHUB_TOKEN`. See [GitHub API rate limits](./customization/20-versions.md#github-api-rate-limits).

8. Run the playbook. Run it from the `ansible/` directory, because Ansible reads `ansible.cfg` from the current directory only. `-K` asks for your sudo password and is required:

   ```shell
   cd ~/proveasio/ansible
   ansible-playbook -i inventory.yml setup-ubuntu.yml -K
   ```

9. When the run ends with the green summary of installed versions, close the terminal and open it again.

To update everything later, pull the repository and run step 8 again. See [Download](./download.md#updating).

## sudo-rs

Ubuntu 26.04 uses `sudo-rs` as `sudo`. Ansible does not recognize its password prompt, so `-K` fails even with the correct password. Proveasio uses the classic sudo (`/usr/bin/sudo.ws`) when it is installed. If it is missing, install it with `sudo apt install sudo`.

:::note
If the preparation or the playbook fails (steps 5 or 8), see [Troubleshooting](./troubleshooting.md). If it does not cover your problem, open an issue on GitHub.
:::
