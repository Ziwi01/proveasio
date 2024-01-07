# Automated

:::danger
This is just experimental feature, it is not tested thoroughly, use at your own risk (with some feedback if you do, please)
:::

This is an initial automation for setting up Windows, which includes the steps from [Windows manual setup](./manual) and some more things, like installing software I commonly use.

## prepare-windows.ps1

Download this repository somewhere on Windows.

There is a script `prepare-windows.ps1`, which will:

- Install WSL with Ubuntu 22.04.
- Enable WinRM protocol with CredSSP authentication transport (to be able to run Ansible from WSL2 to configure Windows)
- Install [Chocolatey](https://chocolatey.org/) package manager to install software

It must be run as Administrator from `cmd` or `powershell`.

## prepare-ubuntu.sh

After `prepare-windows.ps1` is run, login to Ubuntu WSL and also [download](../download) this repo.

Before running below script, ensure your WSL distro is using `systemd`. See [Requirements](../requirements)

From Ubuntu, in repo root, run `sudo ./prepare-ubuntu.sh` - this will update the system and install required Ansible packages.

## setup-windows.yml

This is the main playbook to setup Windows.

1. Create `ansible/vars/overrides.yml` and set `win_username` to your windows User. See `ansible/vars/README.md` for example
2. Investigate `ansible/roles/windows/tasks/main.yml` and review all other tasks in that directory to see what would be done
    1. `common.yml` will install common software packages, like 7Zip, Firefox, BitWarden etc.
    2. `dev.yml` will install GIT, Windows Terminal, IntelliJ, VSCode, Docker Desktop, Postman
    3. `context_menu.yml` will clean up context menu from things added by some of the packages above
    4. `terminal.yml` will install FiraCode font and apply custom settings for Windows Terminal
    5. `entertainment.yml` will install additional software, like Spotify, VLC, Discord etc.

You can switch off the whole sections from #2 by adding to `vars/overrides.yml` (change `true` to `false` to exclude):

```
bundle_include:
  common: true
  dev: true
  terminal: true
  entertainment: true
  context_menu: true
```

:::tip
Instead of excluding whole section, you can also modify its task directly (e.g `ansible/roles/windows/tasks/entertainment.yml`) and just comment out/remove particular things you don't want to be installed
:::

After everything is prepared, you can run (from `ansible/` dir):

```shell
ansible-playbook -i inventory.yml setup-windows.yml -k
```

It will prompt for your Windows password. If the terminal hangs during an execution for more than couple minutes, just break it (`<C-c>`) and run again. This is because Chocolatey installations from WSL Ansible can get clogged up sometimes (not sure why this happens).

