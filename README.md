<p align="center">

░▒█░░▒█░▒█▀▀▀█░▒█░░░░█▀█░░░▒█▀▀█░▄▀▀▄░█░░░█░█▀▀░█▀▀▄░░░▒█▀▀▀░▒█▄░▒█░▒█░░▒█
░▒█▒█▒█░░▀▀▀▄▄░▒█░░░░▒▄▀░░░▒█▄▄█░█░░█░▀▄█▄▀░█▀▀░█▄▄▀░░░▒█▀▀▀░▒█▒█▒█░░▒█▒█░
░▒▀▄▀▄▀░▒█▄▄▄█░▒█▄▄█░█▄▄░░░▒█░░░░░▀▀░░░▀░▀░░▀▀▀░▀░▀▀░░░▒█▄▄▄░▒█░░▀█░░░▀▄▀░
</p>

# Introduction

Repository containing bunch of automation scripts (mostly Ansible tasks) to install, configure and maintain Windows WSL2 environment based on Ubuntu 20.04, including set of very useful dev tools and customizations to ease out and speed up terminal usage during day-to-day work and bump up productivity.

# Concept

The idea is to have something consistent when trying to configure new Windows machine with WSL2 for automation development purposes (like DevOps/SysAdmin thingy). Also, it should be able to run it repeatably to also update installed tools and customizations to latest versions. Last, but not least, it should be easily extendable and configurable to suit personal needs.

# Notice

Below project is an opinionated set of tools which I use for my everyday work, but I hope someone will find it useful after tailoring it to ones needs. Please read below README carefully and go through the scripts to see whats going on there before using on existing Windows/WSL. All the tools/customizations I use will be listed, described and if there are any customizations they will be shown. If you clone this repository and have some new ideas/functionalities/fixes, feel free to create a Pull Request, it will be very much appreciated!

# TODO

- describe customizations (Tips and tricks), add usage videos
- (?) add [SDKMan](https://sdkman.io) installation (with Groovy/Gradle?)
- (?) Use [ASDF](https://github.com/asdf-vm/asdf) version manager instead of RVM/NVM etc.

# Table of contents

@TODO

# Requirements

- (obviously) Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- WSL2 configured
- Ubuntu 20.04 installed
- Any terminal using any iconic font (like [Nerd Fonts](https://www.nerdfonts.com/) - see windows setup for details)

If you have all that, you can skip to [WSL2 setup](#wsl2-setup).

## Windows setup

Windows setup should be done manually, however there is an experimental automation for that (see [Automated](#automated) section)

### Manual

1. Install WSL, if not already installed - from Powershell (Administrator):

    ```shell
    wsl.exe --install -d 'Ubuntu-20.04'
    wsl.exe --set-default 'Ubuntu-20.04'
    ```

    For details, see [Microsoft WSL installation docs](https://docs.microsoft.com/en-us/windows/wsl/install)

2. Install DejaVuSans fonts (it can be found in this repo in `ansible/roles/windows/files/fonts`)
3. Install [Microsoft Terminal](https://github.com/microsoft/terminal) and configure Ubuntu profile with DejaVuSans font. You can check `ansible/roles/windows/templates/settings.json.j2` for settings reference with useful overrides.

Points #2 and #3 are optional (I use them personally) - you can use any terminal of your choice and any font supporting iconic fonts (like [Nerd Fonts](https://www.nerdfonts.com/) - please note that not all fonts have the same amount of glyphs/icons. DejaVu has lots of them)

Thats it, you can move to [WSL2 setup](#wsl2-setup)

### Automated

There is an initial automation for setting up Windows, which includes the steps above and some more things, like installing software I commonly use.

#### prepare-windows.ps1

There is a script `prepare-windows.ps1`, which will:

- Install WSL with Ubuntu 20.04
- Enable WinRM protocol with CredSSP authentication transport (to be able to run Ansible from WSL2 to configure Windows)
- Install [Chocolatey](https://chocolatey.org/) package manager to install software

#### prepare-wsl.sh

From Ubuntu, run `sudo ./prepare-wsl.sh` - this will update the system and install required ansible packages.

#### setup-windows.yml

After `prepare-windows.ps1` is run, login to Ubuntu WSL and clone this repository.

1. Modify `ansible/roles/vars/environment.yml` and set `win_username` to your windows User
2. Investigate `ansible/roles/windows/tasks/main.yml` and review all other tasks in that directory to see what would be done
    1. `common.yml` will install common software packages, like 7Zip, Firefox, BitWarden etc.
    2. `dev.yml` will install GIT, Windows Terminal, IntelliJ, VSCode, Docker Desktop, Postman
    3. `context_menu.yml` will clean up context menu from things added by some of the packages above
    4. `terminal.yml` will install MesloLGS fonts and apply custom settings for Windows Terminal
    5. `entertainment.yml` will install additional software, like Spotify, VLC, Discord etc.

You can switch off the whole sections from #2 by modifying `ansible/roles/windows/vars/main.yml`. For customization, just edit the yaml files.

After everything is prepared, you can run (from `ansible/` dir):

```shell
ansible-playbook -i inventory.yml setup-windows.yaml -k
```

It will prompt for you Windows password. If the terminal hangs during an execution for more than couple minutes, just break it (CTRL+C) and run again. This is because Chocolatey installations from WSL ansible can get clogged up sometimes (not sure why this happens).

## WSL2 setup

Now for the main part :). Assuming all the [requirements](#requirements) are met:

1. Clone this repository in WSL Ubuntu.
2. Run `sudo ./prepare-wsl.sh` (if not already run during windows setup) to update the system and install required ansible packages.
3. Run ansible (from `ansible/` dir):

    ```shell
    ansible-playbook -i inventory.yml setup-wsl.yaml -K
    ```

This will install everything see [tools overview](#tools-overview) for details. You might want to go through [very basic config](#roles-overview) before running the installation. Most of the software packages are installed directly from Github repositories and are placed in `${HOME}/.local/` directory, however others are installed either from PIP, direct links or other things.

## Roles overview

All of the roles have their main configuration in `ansible/roles/<role>/vars/main.yml`. Also, their tasks are gathered in `ansible/roles/<role>/tasks/main.yml`. It is good idea to take a peek on all the .yml files in `tasks/` directories also. For detailed description of how do those things work together, see [Usage](#usage) section below.

### `software` role

This role will install all necessary things to have the WSL pretty and useful.

1. ZSH shell based on [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme, and some custom plugins.
2. [LS with GIT status](https://github.com/gerph/ls-with-git-status) - list files/directories with GIT info
3. [FZF Fuzzy finder](https://github.com/junegunn/fzf) - insane speed fuzzy finder with milion usage scenarios
4. [Diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - alternate GIT DIFF presentation
5. [Git fuzzy](https://github.com/bigH/git-fuzzy.git) - managing GIT commands using FZF
6. [Gita](https://github.com/nosarthur/gita) - managing multiple GIT repositories at once (add groups, execute git or shell commands for those groups etc.)
6. [TheFuck](https://github.com/nvbn/thefuck) - corrects errors in previous console commands
7. [BAT](https://github.com/sharkdp/bat) - (much) better CAT
8. [Zoxide](https://github.com/ajeetdsouza/zoxide) - traverse directories with ease (also with FZF)
9. [Helm](https://github.com/helm/helm) - Kubernetes 'package manager'

Also, common useful packages, like:

- tmux (terminal multiplexer)
- mlocate (file search)
- tree (directory tree)
- htop (better top)
- jq (json/yaml parser)

More useful packages will be installed in `dev` role.

In `roles/software/vars/main.yml` file, you can configure for example:

- particular versions of software in `versions` key - by default they are set to `latest`, so that they will get updated when re-running the `setup-wsl.yml` playbook
- list of packages that will get installed from apt repository (like git, tmux, tree, htop etc.)
- Oh-My-ZSH plugin list

### `config` role

This role is mostly `dotfiles` management. It will apply configuration for:

- ZSH/powerlevel10k theme (`.zshrc` / `.p10k.zsh`)
- Tmux (`.tmux.conf`)
- VIM (`.vimrc`)
- GIT config (`.gitconfig`)

If you already have any of those files, you can either turn off overwrites, or back them up before overwriting, by setting appropriate option in `roles/config/vars/main.yml`:

- `dotfiles_overwrite` (default: true)
- `dotfiles_backup` (default: false)

You can also granulize this on per-component basis - see mentioned `vars/main.yml`.

### `dev` role

This role installs programming-related tools which I currently use in my work.

Essential:
 - [Neovim](https://github.com/neovim/neovim) - more handsome VIM brother
 - [LunarVIM](https://github.com/LunarVim/LunarVim) - Neovim IDE-like extension with awesome plugins/configurations included out of the box

Programming:
- [RVM](https://rvm.io/) (Ruby enVironment Manager, installed using [rvm1-ansible-role](https://github.com/rvm/rvm1-ansible)), along with Rubies: 2.4.10, 2.7.6 and 3.1.2
- [PDK](https://puppet.com/try-puppet/puppet-development-kit/) (Puppet Development Kit)
- [NVM](https://github.com/nvm-sh/nvm) (Node Version Manager) with latest LTS Node version (by default). Among all - dependency for LunarVIM installation

In `roles/dev/vars/main.yml` you can specify Neovim/LunarVIM and RVM/PDK/NVM versions.

## Tips and tricks

Below you can find some useful commands/shortcuts/tips on how to use all of this fancy software. For more details, see the [software role](#software-role) section and take a look at the links there. Below you will find most common scenarios I use and custom added things (configs, modifications, functions).

# Author

Eryk 'Ziwi' Kozakiewicz

# Mentions

- Windows setup was inspired and mostly based on [lholota/dev-setup](https://github.com/lholota/dev-setup)