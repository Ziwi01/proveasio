```text
 _ _ _ _____ __       _____                      _____
| | | |   __|  |     |  _  |___ _ _ _ ___ ___   |   __|___ _ _ 
| | | |__   |  |__   |   __| . | | | | -_|  _|  |   __|   | | |
|_____|_____|_____|  |__|  |___|_____|___|_|    |_____|_|_|\_/ 
```

![WSL build](https://github.com/Ziwi01/wsl-power-env/actions/workflows/ci.yml/badge.svg?branch=master)
![license](https://img.shields.io/github/license/Ziwi01/wsl-power-env)
![last commit](https://img.shields.io/github/last-commit/Ziwi01/wsl-power-env)

# Introduction

Repository containing bunch of automation scripts (mostly Ansible tasks) to install, configure and maintain Windows WSL2 environment based on Ubuntu 20.04, including set of very useful dev tools and customizations to ease out and speed up terminal usage during day-to-day work and bump up productivity.

# Concept

The idea is to have something consistent when trying to configure new Windows machine with WSL2 for automation development purposes (like DevOps/SysAdmin thingy). Also, it should be able to run it repeatably to also update installed tools and customizations to latest versions. Last, but not least, it should be easily extendable and configurable to suit personal needs.

# Notice

Below project is an opinionated set of tools which I use for my everyday work, but I hope someone will find it useful after tailoring it to ones needs. Please read below README carefully and go through the scripts to see whats going on there before using on existing Windows/WSL. All the tools/customizations I use will be listed, described and if there are any customizations they will be shown. If you clone this repository and have some new ideas/functionalities/fixes, feel free to create a Pull Request, it will be very much appreciated!

# TODO

- feat: add [SDKMan](https://sdkman.io), install Groovy/Gradle/java
- feat: add [GVM (Go Version Manager)](https://github.com/moovweb/gvm), install GO
- docs: add usage descriptions with videos and images
- docs: update lunarvim.md with detailed workflow examples and shortcuts


# Table of contents

- [Introduction](#introduction)
- [Concept](#concept)
- [Notice](#notice)
- [TODO](#todo)
- [Table of contents](#table-of-contents)
- [Requirements](#requirements)
- [Windows setup](#windows-setup)
  - [Manual](#manual)
  - [Automated](#automated)
    - [prepare-windows.ps1](#prepare-windowsps1)
    - [prepare-wsl.sh](#prepare-wslsh)
    - [setup-windows.yml](#setup-windowsyml)
- [WSL2 setup](#wsl2-setup)
- [Roles overview](#roles-overview)
  - [`software` role](#software-role)
  - [`config` role](#config-role)
  - [`dev` role](#dev-role)
- [Usages](#usages)
  - [Terminal](#terminal)
    - [Tmux](#tmux)
  - [Git](#git)
  - [Neovim with LunarVIM](#neovim-with-lunarvim)
  - [Helm](#helm)
  - [Languages](#languages)
    - [Ruby](#ruby)
    - [Node](#node)
    - [Puppet](#puppet)
    - [Ansible](#ansible)
    - [Rust](#rust)
- [Author](#author)
- [Mentions](#mentions)

# Requirements

- (obviously) Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- WSL2 configured
- Ubuntu 20.04 installed
- Any terminal using any iconic font (like [Nerd Fonts](https://www.nerdfonts.com/) - see windows setup for details)

Please verify you have correct Windows setup by going through Windows manual setup below, or try experimental Windows automation even more below (feedback welcome!)

# Windows setup

Windows setup should be done manually, however there is an experimental automation for that (see [Automated](#automated) section)

## Manual

1. Install WSL, if not already installed - from Powershell (Administrator):

    ```shell
    wsl.exe --install -d 'Ubuntu-20.04'
    wsl.exe --set-default 'Ubuntu-20.04'
    ```

    For details, see [Microsoft WSL installation docs](https://docs.microsoft.com/en-us/windows/wsl/install)

2. Install DejaVuSans fonts (it can be found in this repo in `ansible/roles/windows/files/fonts`)
3. Install [Microsoft Terminal](https://github.com/microsoft/terminal) and configure this Terminals Ubuntu profile with DejaVuSans font. You can check `ansible/roles/windows/templates/settings.json.j2` for settings reference with useful overrides.

In points #2 and #3 specific font+terminal duo is just a suggestion (I use them personally) - you can use any terminal of your choice and any font supporting iconic fonts (like [Nerd Fonts](https://www.nerdfonts.com/) - please note that not all fonts have the same amount of glyphs/icons. DejaVu has lots of them. Remember to configure you terminal to use this font!

Thats it, you can move to [WSL2 setup](#wsl2-setup)

## Automated

There is an initial automation for setting up Windows, which includes the steps above and some more things, like installing software I commonly use.

### prepare-windows.ps1

There is a script `prepare-windows.ps1`, which will:

- Install WSL with Ubuntu 20.04
- Enable WinRM protocol with CredSSP authentication transport (to be able to run Ansible from WSL2 to configure Windows)
- Install [Chocolatey](https://chocolatey.org/) package manager to install software

It must be run as Administrator.

### prepare-wsl.sh

After `prepare-windows.ps1` is run, login to Ubuntu WSL and clone this repository.

From Ubuntu, run `sudo ./prepare-wsl.sh` - this will update the system and install required ansible packages.

### setup-windows.yml

1. Modify `ansible/roles/vars/environment.yml` and set `win_username` to your windows User
2. Investigate `ansible/roles/windows/tasks/main.yml` and review all other tasks in that directory to see what would be done
    1. `common.yml` will install common software packages, like 7Zip, Firefox, BitWarden etc.
    2. `dev.yml` will install GIT, Windows Terminal, IntelliJ, VSCode, Docker Desktop, Postman
    3. `context_menu.yml` will clean up context menu from things added by some of the packages above
    4. `terminal.yml` will install DejaVu font and apply custom settings for Windows Terminal
    5. `entertainment.yml` will install additional software, like Spotify, VLC, Discord etc.

You can switch off the whole sections from #2 by modifying `ansible/roles/windows/vars/main.yml`. For customization, just edit the yaml files.

After everything is prepared, you can run (from `ansible/` dir):

```shell
ansible-playbook -i inventory.yml setup-windows.yaml -k
```

It will prompt for you Windows password. If the terminal hangs during an execution for more than couple minutes, just break it (CTRL+C) and run again. This is because Chocolatey installations from WSL ansible can get clogged up sometimes (not sure why this happens).

# WSL2 setup

Now for the main part :). Assuming all the [requirements](#requirements) are met (Windows manual or automatic setup covered):

1. Update variables in `ansible/vars/environment.yml` - set `user` to your Ubuntu user and desired GIT config info. Optionally change your hostname to whatever you like.
2. Clone this repository in WSL Ubuntu if not yet already.
3. Run `sudo ./prepare-wsl.sh` (if not already run during windows setup) to update the system and install required ansible packages.
4. Run ansible (from `ansible/` dir):

    ```shell
    ansible-playbook -i inventory.yml setup-wsl.yaml -K
    ```
5. Open new shell, launch vim (`vim` or `lvim`) and execute:
    - `:PackerInstall`
    - `:PackerCompile`
    - exit (`:q!`)

You might want to go through [very basic config](#roles-overview) before running the installation. This will install everything - see [usages](#usages) for details. Most of the software packages are installed directly from Github repositories and are placed in `${HOME}/.local/` directory, however others are installed either from PIP, direct links or other things.

# Roles overview

All of the roles have their main configuration in `ansible/roles/<role>/vars/main.yml`. Also, their tasks are gathered in `ansible/roles/<role>/tasks/main.yml`. It is good idea to take a peek on all the .yml files in `tasks/` directories also. For detailed description of how do those things work together, see [Usages](#usages) section below.

## `software` role

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
10. [Ripgrep](https://github.com/BurntSushi/ripgrep) - `grep` on steroids. Blazing fast, easy to use
11. [fd](https://github.com/sharkdp/fd) - `find` alternative, much faster
12. [htop](https://htop.dev/) - process viewer, prettier `top` alternative

Also, common useful packages, like:

- tmux (terminal multiplexer)
- mlocate (file search)
- tree (directory tree)
- jq (json/yaml parser)

More useful packages will be installed in `dev` role.

In `roles/software/vars/main.yml` file, you can configure for <b>Example:</b>

- particular versions of software in `versions` key - by default they are set to `latest`, so that they will get updated when re-running the `setup-wsl.yml` playbook
- list of packages that will get installed from apt repository (like git, tmux, tree, htop etc.)
- Oh-My-ZSH plugin list

## `dev` role

This role installs programming-related tools which I currently use in my work.

Essential:
 - [Neovim](https://github.com/neovim/neovim) - more handsome VIM brother
 - [LunarVIM](https://github.com/LunarVim/LunarVim) - Neovim IDE-like extension with awesome plugins/configurations included out of the box

Programming:
- [RVM](https://rvm.io/) (Ruby enVironment Manager, installed using [rvm1-ansible-role](https://github.com/rvm/rvm1-ansible)), along with Rubies: 2.4.10, 2.7.6 and 3.1.2
- [PDK](https://puppet.com/try-puppet/puppet-development-kit/) (Puppet Development Kit)
- [NVM](https://github.com/nvm-sh/nvm) (Node Version Manager) with latest LTS Node version (by default). Among all - dependency for LunarVIM installation

In `roles/dev/vars/main.yml` you can specify Neovim/LunarVIM and RVM/PDK/NVM versions.

## `config` role

This role is mostly `dotfiles` or configs management. It will apply configuration for:

- ZSH/powerlevel10k theme (`.zshrc` / `.p10k.zsh`)
- Tmux (`.tmux.conf`)
- GIT config (`.gitconfig`)

If you already have any of those files, you can either turn off overwrites, or back them up before overwriting, by setting appropriate option in `roles/config/vars/main.yml`:

- `dotfiles_overwrite` (default: true)
- `dotfiles_backup` (default: false)

You can also granulize this on per-component basis - see mentioned `vars/main.yml`.

Additionally, configs for below apps will be updated (disable overwrite in `vars/main.yml` if needed)

- thefuck (`~/.config/thefuck/settings.py`)
- LazyGIT (`~/.config/lazygit/config.yml`)
- ansible-lint (`~/.ansible-lint`)
- lunarvim (`~/.config/lvim/config.lua`)

# Usages

Below you can find some useful commands/shortcuts/tips on how to use all of this fancy software. For more details, see the [software role](#software-role) section and take a look at the links there. Below you will find most common scenarios I use and custom added things (configs, modifications, functions).

## Terminal

Terminal is ZSH-based, configured with [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k):

<details>
  <summary><b>Example:</b> Terminal commandline</summary>
  ![terminal](resources/terminal_preview.png?raw=true)
</details>

There are couple of useful plugins installed there (you can find them in `roles/config/files/.zshrc`), like:

- syntax highlighting
- commands autocompletion (based on history and/or completion scripts)
- [`FZF`](https://github.com/junegunn/fzf) integration (fuzzy search command history with `CTRL+r` and lots other places - try using TAB or `**TAB` here and there)
    <details>
    <summary><b>Example:</b> History/file FZF search</summary>
    @TODO: video
    </details>
- fuzzy search/go to directory with `ALT+c`
- traversing directories back and forth (and parent/child) with `ALT+<left|right|up|down>`
- aliases autosuggestions - tells you that you have an alias for particular commands
    <details>
    <summary><b>Example:</b> Alias suggestion</summary>
    @TODO: image
    </details>
- easily traversing through visited directories (using [`zoxide`](https://github.com/ajeetdsouza/zoxide))
    <details>
    <summary><b>Example:</b> Zoxide usage</summary>
    ![zoxide](https://github.com/ajeetdsouza/zoxide/raw/main/contrib/tutorial.webp)
    </details>
- correct your commands with `fuck` or `ESC ESC`
    <details>
    <summary><b>Example:</b> `thefuck` correction</summary>
    @TODO: video
    </details>
- finding files with FZF using custom `bfind` alias - with preview and all
    <details>
    <summary><b>Example:</b> FZF file search with preview</summary>
    @TODO: image
    </details>
- prettier cat (with [`bat`](https://github.com/sharkdp/bat)) with syntax highlight and all
    <details>
    <summary><b>Example:</b> BAT output</summary>
    @TODO: video
    </details>

### Tmux

For TMUX overall usage, please see its documentation with `man tmux`.

Basic usage:

- start with `tmux new`
- `<C-b>c` - new window
- `<C-b>%` - split window vertically
- `<C-b>"` - split window horizontally
- `<C-b><arrows>` - move between panes
- `<C-b>xy` - kill pane
- `<C-b>n` - next window
- `<C-b>l` - last window
- `<C-b>p` - previous window (in order)

Custom modifications in `roles/config/files/.tmux.conf` include:

- colorscheme
- session management (`<C-b><C-s>` to save session, `<C-b><C-r>` to restore)
- enabled mouse support
- prevent deselect+auto scroll on mouse selection copy (very annoying..)

## Git

For smooth GIT experience there are some tools configured:

- [LazyGIT](https://github.com/jesseduffield/lazygit) - great GUI terminal GIT wrapper. Command: `lazygit`. See docs for usages. Also available through LunarVIM (see Neovim/LunarVIM section)
    <details>
    <summary><b>Example:</b> Using LazyGIT</summary>
    @TODO: link to video
    </details>
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - better looking diffs.
- [git-fuzzy](https://github.com/bigH/git-fuzzy) - GIT on FZF steroids. I use LazyGIT now instead, but maybe useful for simpler checkups. Commands:
    - `git-fuzzy`
    - `git-fuzzy status` (alias: `gst`)
    - `git-fuzzy log` (alias: `glo`)
    <details>
    <summary><b>Example:</b> Browsing GIT log/status</summary>
    @TODO: video
    </details>
- **truly** useful: `gco` alias for searching and checking out branch with FZF. You can also use it to checkout without searching (`gco branch_name`)
- [Gita](https://github.com/nosarthur/gita) - gather your GIT repositories in groups and execute command on them at once (either GIT command or shell commands)
    <details>
    <summary><b>Example:</b> Grouping GIT repositories</summary>
    @TODO: video
    </details>
- [LS with GIT status](https://github.com/gerph/ls-with-git-status) and `k` ohmyzsh plugin - list directories/files and show their GIT status. Command:
    - `lsg` - list directories
    - `k` - list files
    <details>
    <summary><b>Example:</b> Listing GIT files/directories</summary>
    @TODO: image
    </details>

## Neovim with LunarVIM

Neovim/LunarVIM configuration/post setup is a continouous work in progress, as I recently switched to it from pure VIM and still polish it here and there with new keybindings and plugins. It is still light years better than my previous VIM config, and I will never go back to pure VIM (I think)

[LunarVIM](https://github.com/LunarVim/LunarVim) is set as default `EDITOR`, also aliased as `vim` (you can change it `~/.zshrc`).

Core Neovim plugins, which are installed by LunarVIM, can be found [here](https://www.lunarvim.org/plugins/01-core-plugins-list.html).

Additionally, I setup the plugins below:

- [folke/trouble.nvim](https://github.com/folke/trouble.nvim) - Toggle diagnostic windows and browse through them (`<Space>td` for document diagnostic items)
- [rodjek/vim-puppet](https://github.com/rodjek/vim-puppet) - Puppet syntax support
- [nanotee/zoxide.vim](https://github.com/nanotee/zoxide.vim) - Zoxide inside VIM: `:Zi` or `:Z <query>`.For Zoxide descrption see above for Zoxide descprition
- [plasticboy/vim-markdown]() - Markdown support
- [pearofducks/ansible-vim]() - Ansible support
- [junegunn/fzf](https://github.com/junegunn/fzf) and [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim) - FZF integration in VIM
- GIT integration plugins:
    - [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) - Neovim integration with awesome GIT wrapper (LazyGIT). See `software` role description for details.
    - [mhinz/vim-signify](https://github.com/mhinz/vim-signify) - shows GIT info about modified/added/removed lines
    - [f-person/git-blame.nvim](https://github.com/f-person/git-blame.nvim) - show Git blame in-line virtual text.
- [tzachar/cmp-tabnine](https://github.com/tzachar/cmp-tabnine) - AI completion mechanism
- [rmagatti/goto-preview](https://github.com/rmagatti/goto-preview) - do not jump around the definition in new tabs/buffers - show floating preview window and edit it there, close the preview. Being on top of searched function: `gpd` (for definition).
- [itchyny/vim-cursorword](https://github.com/itchyny/vim-cursorword) - underline all the words that the cursor is on right now. Handy for typo spotting.
- [folke/persistence.nvim](https://github.com/folke/persistence.nvim) - session management. Restore all your buffers and windows. Saving is done automatically, restore with: `<Space>Sl`. Awesome!

In LunarVIM there is an automatic [LSP installer plugin](https://github.com/williamboman/nvim-lsp-installer) which will install supported language servers and use them, when you open a specific filetype. This should work out of the box in most cases, however for Puppet I setup the LSP server manually, as it doesn't work with RVM by default. Also Ansible gets linter configuration override.

For all configuration overrides, see `ansible/roles/dev/files/lvim-config.lua` in this repo or `~/.config/lvim/config.lua` on the filesystem.

If you have problems with plugins, try to execute `:PackerInstall` and `:PackerCompile` commands from `lvim`. From time to time also `:PackerUpdate` would be nice.

For detailed usage examples, shortcuts and basic workflow videos, please see [`lunarvim.md`](./lunarvim.md)

## Helm

[Helm](https://github.com/helm/helm) gets installed with latest 3.x version. To work with it properly, you need to either be running [Docker for Desktop](https://docs.docker.com/get-docker/) on Windows machine, with Kubernetes launched (so `kubectl` command is available in WSL terminal), or properly configured docker+kubernetes on WSL. I'd say use the first method if you can, definitely.

## Languages

### Ruby

For Ruby management, there is [Ruby Version Manager (RVM)](https://rvm.io/) installed. See available Ruby's with `rvm list`, use particular with `rvm use <ruby_version>`. There are some gems alredy preinstalled on Rubys available here (mostly for Puppet support).

**NOTE:** By default, Puppet gets installed in version 5.5.22 **for all rubies**. If you choose to install latest puppet, there might be some dependencies errors for lower ruby versions (for example 2.4.10). If you don't want to install Puppet for all rubies, set `puppet_rubies`  in `ansible/roles/dev/vars/main.yml` to an array with rubies names.

### Node

For Node, there is [NVM](https://github.com/nvm-sh/nvm) installed. See NPM versions with `nvm list`. By default there is latest LTS installed (currently `gallium` 16.x)

### Puppet

`Puppet` and `puppet-lint` gems are installed on all configured rubys. Also, latest [PDK](https://puppet.com/try-puppet/puppet-development-kit/) is available.

There is Puppet LSP (language server protocol) called [Puppet Editor Services](https://github.com/puppetlabs/puppet-editor-services) installed in `~/.lsp/puppet-editor-services`.

**NOTE:** By default, Puppet gets installed in version 5.5.22 **for all rubies**. If you choose to install latest puppet, there might be some dependencies errors for lower ruby versions (for example 2.4.10). If you don't want to install Puppet for all rubies, set `puppet_rubies` in `ansible/roles/dev/vars/main.yml` to an array with rubies names.

<details>
<summary><b>Example:</b> Puppet autocompletion/LSP</summary>
@TODO: Add working Puppet LSP autocompletion/goto defition videos
</details>

#### Ansible

Ansible gets installed using both APT (during first step in `setup-wsl.sh`, for further installation) and then the playbooks install PIP3 Ansible in latest available version, along with ansible-lint.

Also, there is an [Ansible Language Server](https://github.com/ansible/ansible-language-server) installed globally using default NPM, but LunarVIM uses it's own, auto-installed language server.

To configure linter diagnostics (enable/disable some checks) in LunarVIM for Ansible files, please edit `~/.ansible-lint` on filesystem, source: `ansible/roles/dev/files/.ansible-lint`

<details>
<summary><b>Example:</b> Ansible lint/autocompletion</summary>
@TODO: Add working Ansible LSP autocompletion/linting image
</details>

### Rust

As LunarVIM requires it, [Rust](https://www.rust-lang.org/) is installed with [Cargo](https://github.com/rust-lang/cargo/) package manager.

# Author

Eryk 'Ziwi' Kozakiewicz

# Mentions

- Windows setup was inspired and mostly based on [lholota/dev-setup](https://github.com/lholota/dev-setup)
