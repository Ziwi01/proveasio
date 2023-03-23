<div align="center">
  <img width=400 height=300 src="./resources/proveasio-logo.png">
</div>

<div align="center">

<a href="">![CI build](https://github.com/Ziwi01/proveasio/actions/workflows/pre-release.yml/badge.svg?branch=master)</a>
<a href="">![License](https://img.shields.io/github/license/Ziwi01/proveasio)</a>
<a href="">![Last commit](https://img.shields.io/github/last-commit/Ziwi01/proveasio)</a>

</div>

## TL;DR

Prepare your Ubuntu terminal dev environment with one command (well, sort of).

Using Ansible - install, configure and maintain Ubuntu 22.04 terminal environment focused on development and administration. This includes installation/configuration of very useful dev tools and customizations to ease out and speed up terminal usage during day-to-day work and to bump up productivity.

Below project is supported on Ubuntu running on Windows WSL2, but it is also tested on plain Ubuntu 22.04 on Github Runner, so it is expected to work there.

## About

The idea is to:

- have something consistent when trying to configure new machine, mainly for automation development purposes (like DevOps/SysAdmin thingy), but for general usage also.
- be able to run it repeatably to also update installed tools and customizations to latest versions (or stay on particular versions for stability)
- be easily extendable and configurable to suit personal needs.
- have all the features and usages described so they are easily assimilated for someone new to this, or for someone who wants to improve their workflow and need some ideas.

In the process of making, I figured out that this can be beneficial for all the people who want to learn how to use Linux as their development base. By documenting the tools and [usage scenarios](./Usages.md), this repository can be used by tech-savvy wannabies to get a grip of some advanced workflows and tools, with a little less effort than figuring it out themselves from scratch.

**NOTE**: Below project is an opinionated set of tools which I use for my everyday work, but I hope someone will find it useful after tailoring it to ones needs. All the tools I use will be listed, described and if there are any custom modifications, they will be shown. If you have some new ideas/functionalities/fixes, feel free to create a Pull Request, it will be very much appreciated! See [Contributing](#contributing).

Please read below README carefully and go through the scripts to see whats going on there before using on existing system.

## Table of contents

* [TL;DR](#tl;dr)
* [About](#about)
* [Table of contents](#table-of-contents)
* [Features](#features)
  * [Terminal](#terminal)
  * [Tmux](#tmux)
  * [Git](#git)
  * [DevOps](#devops)
  * [Neovim with LunarVIM](#neovim-with-lunarvim)
  * [Other software](#other-software)
  * [Languages](#languages)
    * [Python](#python)
    * [Ruby](#ruby)
    * [JAVA/groovy](#java/groovy)
    * [Node](#node)
    * [Puppet](#puppet)
    * [Ansible](#ansible)
    * [Rust](#rust)
* [Releases](#releases)
* [Requirements](#requirements)
* [Windows setup](#windows-setup)
  * [Manual](#manual)
  * [Automated](#automated)
    * [prepare-windows.ps1](#prepare-windows.ps1)
    * [prepare-ubuntu.sh](#prepare-ubuntu.sh)
    * [setup-windows.yml](#setup-windows.yml)
* [Installation](#installation)
* [Roles overview](#roles-overview)
  * [`software` role](#software-role)
  * [`config` role](#config-role)
* [Configuration customizations](#configuration-customizations)
  * [Overriding variables](#overriding-variables)
  * [Versions management](#versions-management)
  * [Own config files](#own-config-files)
  * [Excluding code](#excluding-code)
  * [Run particular code](#run-particular-code)
  * [Ansible tags](#ansible-tags)
* [Troubleshooting](#troubleshooting)
  * [Github tasks issues](#github-tasks-issues)
  * [VPN connectivity issues](#vpn-connectivity-issues)
  * [Ruby GPG keys import failed](#ruby-gpg-keys-import-failed)
  * [Unable to get https endpoints](#unable-to-get-https-endpoints)
* [Contributing](#contributing)
* [Author](#author)
* [Mentions](#mentions)

## Features

Below you can find brief summary of included tools and features. For more details for each tool, see the [software role](#software-role) section and take a look at the links there.

For usage scenarios with examples (screenshots, videos), see [Usages.md](./Usages.md).

### Terminal

Terminal is ZSH-based, configured with [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k):

<details>
  <summary><b>Example:</b> Terminal commandline</summary>
  <div align="center">
    <img src="./resources/terminal_preview.png">
  </div>
</details>
</br>

There are couple of useful plugins installed there (you can find them in `ansible/roles/config/files/zshrc`), which provide for example:

- syntax highlighting
- commands autocompletion (based on history and/or completion scripts)
- [FZF](https://github.com/junegunn/fzf) integration (command history search, directory search, integration with `fd`)
- fuzzy search/go to directory
- aliases autosuggestions - tells you that you have an alias for particular commands
- easily traversing through **visited** directories (using [zoxide](https://github.com/ajeetdsouza/zoxide))
- correct your commands automatically with [thefuck](https://github.com/nvbn/thefuck)
- finding files with FZF
- Windows clipboard support - also works from VIM (copying in VIM makes it available in Windows clipboard)

### Tmux

Custom modifications in `roles/config/files/tmux.conf` include:

- custom theme
- session management
- ability to search back tmux buffer with FZF
- ability to extract text from tmux buffer with FZF
- enabled mouse support
- prevent deselect+auto scroll on mouse selection copy (very annoying..)
- seamless navigation between TMUX splits and VIM splits

### Git

For smooth GIT experience there are some tools configured:

- [LazyGIT](https://github.com/jesseduffield/lazygit) - great GUI terminal GIT wrapper.
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - better looking diffs.
- [git-fuzzy](https://github.com/bigH/git-fuzzy) - GIT on FZF steroids.
- `gco` alias for searching and checking out branch with FZF. You can also use it to checkout without searching (`gco branch_name`)
- [Gita](https://github.com/nosarthur/gita) - gather your GIT repositories in groups and execute command on them at once (either GIT command or shell commands)
- [LS with GIT status](https://github.com/gerph/ls-with-git-status) and `k` ohmyzsh plugin - list directories/files and show their GIT status in the terminal

### DevOps

Strictly DevOps-related software

- [Docker](https://www.docker.com/) with [docker-compose](https://docs.docker.com/compose/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - manage kubernetes cluster
- [KinD](https://kind.sigs.k8s.io/) - Kubernetes in docker - create a cluster locally
- [k9s](https://github.com/derailed/k9s) - Terminal GUI for managing kubernetes clusters
- [Helm](https://github.com/helm/helm) - Kubernetes package manager
- [Terraform](https://github.com/hashicorp/terraform) - infrastructure as code tool
- [Terragrunt](https://github.com/gruntwork-io/terragrunt) - wrapper for Terraform to deal with multiple environments

### Neovim with LunarVIM

[LunarVIM](https://github.com/LunarVim/LunarVim) is set as default `EDITOR`, also aliased as `vim` (you can change it `~/.zshrc`).

Core Neovim plugins, which are installed by LunarVIM, can be found [here](https://www.lunarvim.org/plugins/01-core-plugins-list.html).

Additionally, I setup the plugins below:

- [folke/trouble.nvim](https://github.com/folke/trouble.nvim) - Toggle diagnostic windows and browse through them (`<Space>t` will list options to open)
- [rodjek/vim-puppet](https://github.com/rodjek/vim-puppet) - Puppet syntax support
- [pearofducks/ansible-vim](https://github.com/pearofducks/ansible-vim) - Ansible support
- [nanotee/zoxide.vim](https://github.com/nanotee/zoxide.vim) - Zoxide inside VIM: `:Zi` or `:Z <query>`.For Zoxide descrption see above for Zoxide descprition
- [will133/vim-dirdiff](https://github.com/will133/vim-dirdiff) - Diff directories. (`:DirDiff <dir1> <dir2>`)
- [plasticboy/vim-markdown](https://github.com/preservim/vim-markdown) - Markdown support
- [Sid0fc/mkdx](https://github.com/SidOfc/mkdx) - Markdown support #2
- [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) - Preview your markdown files in the browser (with dynamic scroll and refresh)
- [godlygeek/tabular](https://github.com/godlygeek/tabular) - easily line up text (like align with equal sign etc.)
- [junegunn/fzf](https://github.com/junegunn/fzf) and [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim) - FZF integration in VIM
- GIT integration plugins:
    - [tpope/fugitive](https://github.com/tpope/vim-fugitive) - Git wrapper, execute any Git command from VIM
    - [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) - Neovim integration with awesome GIT wrapper (LazyGIT). See `software` role description for details.
    - [mhinz/vim-signify](https://github.com/mhinz/vim-signify) - shows GIT info about modified/added/removed lines
    - [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) - great GIT diff plugin for comparing file tree with particular revision(s) or browse file/selection history
    - [f-person/git-blame.nvim](https://github.com/f-person/git-blame.nvim) - show Git blame in-line virtual text.
    - [junegunn/gv](https://github.com/junegunn/gv.vim) - show git commits graph
- [tzachar/cmp-tabnine](https://github.com/tzachar/cmp-tabnine) - AI completion mechanism
- [rmagatti/goto-preview](https://github.com/rmagatti/goto-preview) - do not jump around the definition in new tabs/buffers - show floating preview window and edit it there, close the preview. Being on top of searched function: `gpd` (for definition).
- [itchyny/vim-cursorword](https://github.com/itchyny/vim-cursorword) - underline all the words that the cursor is on right now. Handy for typo spotting.
- [auto-save.nvim](https://github.com/Pocco81/auto-save.nvim) - exactly what the name suggests.
- [tpope/vim-obsession](https://github.com/tpope/vim-obsession) - VIM session manager
- [tpope/vim-surround](https://github.com/tpope/vim-surround) - easily surrond text with brackets, braces, quotes
- [ntpeters/vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace) - automatically trim/prune obsolete whitespace
- [preservim/vimux](https://github.com/preservim/vimux) - integrate neovim with TMUX - run commands in splits easily (@TODO: Add keymappings)
- [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) - integrate movements between TMUX splits and VIM windows/splits
- [towolf/vim-helm](https://github.com/towolf/vim-helm) - Helm files support
- [jvgrootveld/telescope-zoxide](https://github.com/jvgrootveld/telescope-zoxide) - Use Zoxide inside vim
- [kevinhwang91/nvim-bqf](https://github.com/kevinhwang91/nvim-bqf) - much better quickfix window
- [nvim-pack/nvim-spectre](https://github.com/nvim-pack/nvim-spectre) - Search and replace like on other IDEs
- [wincent/ferret](https://github.com/wincent/ferret) - Search and replace for files in your project. To be used if Spectre doesn't work as expected (see LunarVim usage docs for details)
- [catpuccin/nvim](https://github.com/catppuccin/nvim) - Colorscheme

In LunarVIM there is an automatic LSP installer plugin - [Mason.nvim](https://github.com/williamboman/mason.nvim) which will install supported language servers and use them, when you open a specific filetype. This should work out of the box in most cases, however for Puppet I setup the LSP server manually, as it doesn't work with RVM by default. Also Ansible gets linter configuration override.

### Other software

- [ripgrep](https://github.com/BurntSushi/ripgrep) - much faster grep. Also used from within VIM to grep for text.
- [fd](https://github.com/sharkdp/fd) - faster `find` command
- [bat](https://github.com/sharkdp/bat) - prettier cat with syntax highlight, line numbers etc.
- [yq](https://mikefarah.gitbook.io/yq/) - YAML parser
- [htop](https://github.com/htop-dev/htop) - better top
- [jq](https://stedolan.github.io/jq/) - JSON parser

### Languages

#### Python

Python gets instaled with pretty recent version using [`pyenv`](https://github.com/pyenv/pyenv) version manager. This Python is set as default for ZSH shell and all PIP packages which get installed during ansible run are installed there.

Also, there is [`pyenv-virtualenv`](https://github.com/pyenv/pyenv-virtualenv) available to easily manage Python virtual environments.

For usage examples see [Usages.md](./Usages.md)

#### Ruby

For Ruby management, there is [Ruby Version Manager (RVM)](https://rvm.io/) installed. See available Ruby's with `rvm list`, use particular with `rvm use <ruby_version>`. There are some gems already preinstalled on Rubys available here (like `neovim` gem, or if Puppet is being installed, it installs `puppet` and `puppet-lint` gems).

**NOTE**: There might be some issues with installing/managing Ruby versions `< 3.1.x` on Ubuntu 22.04, but that might have been a random issue (to be confirmed)

#### JAVA/groovy

For multiple versions management for Java, groovy, gradle JDKs/SDKs, [SDKMAN!](https://sdkman.io/) manager is installed and some default JAVA and groovy versions.

#### Node

For Node, there is [NVM](https://github.com/nvm-sh/nvm) installed. See NPM versions with `nvm list`. By default there is latest LTS installed.

#### Puppet

`Puppet` and `puppet-lint` gems are installed on all configured rubys. Also, latest [PDK](https://puppet.com/try-puppet/puppet-development-kit/) is available.

There is Puppet LSP (language server protocol) called [Puppet Editor Services](https://github.com/puppetlabs/puppet-editor-services) installed in `~/.lsp/puppet-editor-services`.

**NOTE:** By default, Puppet gets installed **for all rubies**. If you choose to install latest puppet **AND** older rubies (like 2.4.x), there might be some dependencies errors. If you don't want to install Puppet for all rubies, set `puppet_rubies` in `vars/overrides.yml` to an array with rubies names. With latest 3.x.x ruby there shouldn't be a problem

#### Ansible

Ansible gets installed using PIP in designated `pyenv` Python environment. Also ansible-lint gets installed.

Also, there is an [Ansible Language Server](https://github.com/ansible/ansible-language-server) installed globally using default NPM, but LunarVIM uses it's own, auto-installed language server.

To configure linter diagnostics (enable/disable some checks) in LunarVIM for Ansible files, see: `ansible/roles/dev/files/.ansible-lint`

#### Rust

As LunarVIM requires it, [Rust](https://www.rust-lang.org/) is installed with [Cargo](https://github.com/rust-lang/cargo/) package manager.

## Releases

- `develop` branch - most of the software/plugins are set to `latest`. It contains all recent changes/features **and** sometimes in-progress testing features. Also documentation updates and so on.
- `master` branch contains rather stable updates from develop (documentation, new tested plugins, fixes), but all of the software versions are fixed.
- tagged releases are done from time to time whenever some useful functionality comes up (or critical fixes).

I recommend using `master` branch, with some of the software versions overwritten in `ansible/vars/overrides.yml` to be set to `latest`. See `.latest-versions.yml` to see what is set on `develop`.

## Requirements

When using either plain Ubuntu or WSL2:

- Any terminal using any iconic font (like [Nerd Fonts](https://www.nerdfonts.com/))

If using Windows with WSL2 Ubuntu also ensure:

- Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- WSL2 installed/enabled (version 0.67.6 and above)
- Ubuntu 22.04 installed
- `systemd` enabled for installed Ubuntu distribution

Verify you have correct Windows setup by going through [Windows manual setup](#manual) below

## Windows setup

Windows setup should be done manually, however there is an experimental automation for that (see [Automated](#automated) section)

### Manual

0. If you don't have WSL installed, you need to install it with: `wsl --install` executed from administrative `cmd` or `powershell` terminal. See [windows docs](https://learn.microsoft.com/en-us/windows/wsl/install#install-wsl-command)

1. Install Ubuntu 22.04, execute from Powershell (Administrator):

   ```shell
   wsl.exe --install -d 'Ubuntu-22.04'
   wsl.exe --set-default 'Ubuntu-22.04'
   ```

   For details, see [Microsoft WSL installation docs](https://docs.microsoft.com/en-us/windows/wsl/install)

2. Enable `systemd` in your distribution: Add these lines to `/etc/wsl.conf`:

   ```
   [boot]
   systemd=true
   ```

   Then restart WSL from Windows `cmd`: `wsl --shutdown`. After next login it should have systemd configured. For more information see (windows docs for systemd)[https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/]

3. (optionally) Install FiraCode nerd fonts (the ones I use are in `ansible/roles/windows/files/fonts`, if you need, download [all FiraCode Nerd fonts](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip) and use whichever you want) 
4. (optionally) Install [Microsoft Terminal](https://github.com/microsoft/terminal) and configure this Terminals Ubuntu profile with `FiraCode NF` nerd font (Settings -> Ubuntu-22.04 -> Appearance -> Font Face). You can check `ansible/roles/windows/templates/settings.json.j2` for settings reference with useful overrides.

In points #3 and #4 specific font+terminal duo is just a suggestion (I use them personally) - you can use any terminal of your choice and any font supporting iconic fonts (like [Nerd Fonts](https://www.nerdfonts.com/) - please note that not all fonts have the same amount of glyphs/icons. FiraCode has lots of them. Remember to configure you terminal to use your font!

Thats it, you can move to [Installation](#Installation)

### Automated

There is an initial automation for setting up Windows, which includes the steps above and some more things, like installing software I commonly use.

**NOTE**: This is just experimental feature, it is not tested thoroughly, use at your own risk (with some feedback if you do, please)

#### prepare-windows.ps1

There is a script `prepare-windows.ps1`, which will:

- Install WSL with Ubuntu 22.04.
- Enable WinRM protocol with CredSSP authentication transport (to be able to run Ansible from WSL2 to configure Windows)
- Install [Chocolatey](https://chocolatey.org/) package manager to install software

It must be run as Administrator.

#### prepare-ubuntu.sh

After `prepare-windows.ps1` is run, login to Ubuntu WSL and clone this repository.

Before running below script, ensure your WSL distro is using `systemd`. See [Requirements](#requirements)

From Ubuntu, run `sudo ./prepare-ubuntu.sh` - this will update the system and install required ansible packages.

#### setup-windows.yml

1. Create `ansible/vars/overrides.yml` and set `win_username` to your windows User. See `ansible/vars/README.md` for example
2. Investigate `ansible/roles/windows/tasks/main.yml` and review all other tasks in that directory to see what would be done
    1. `common.yml` will install common software packages, like 7Zip, Firefox, BitWarden etc.
    2. `dev.yml` will install GIT, Windows Terminal, IntelliJ, VSCode, Docker Desktop, Postman
    3. `context_menu.yml` will clean up context menu from things added by some of the packages above
    4. `terminal.yml` will install FiraCode font and apply custom settings for Windows Terminal
    5. `entertainment.yml` will install additional software, like Spotify, VLC, Discord etc.

You can switch off the whole sections from #2 by modifying `vars/overrides.yml`. For customization, just edit the yaml files.

After everything is prepared, you can run (from `ansible/` dir):

```shell
ansible-playbook -i inventory.yml setup-windows.yml -k
```

It will prompt for you Windows password. If the terminal hangs during an execution for more than couple minutes, just break it (`<C-c>`) and run again. This is because Chocolatey installations from WSL ansible can get clogged up sometimes (not sure why this happens).

## Installation

Assuming all the [requirements](#requirements) are met:

1. Clone this repository in Ubuntu if not yet already.
2. Create/update file `ansible/vars/overrides.yml` - set desired GIT config name and e-mail. See `ansible/vars/README.md` for more examples

   ```yaml
   git:
     name: James
     mail: james.doe@hell.no
   ```

3. Run `sudo ./prepare-ubuntu.sh` (if not already run during windows setup) to update the system and install required python packages and install ansible.
4. Run ansible (from `ansible/` dir):

    ```shell
    ansible-playbook -i inventory.yml setup-ubuntu.yml -K
    ```

## Roles overview

There are 2 essential roles:

- software - installs everything that needs to be installed
- config - configures everything that needs to be configured

Each role has their main configuration in `ansible/roles/<role>/vars/main.yml`. Also, their tasks are gathered in `ansible/roles/<role>/tasks/main.yml`. It is good idea to take a peek on all the .yml files in `tasks/` directories also. For detailed description of how do those things work together, see [Usages.md](./Usages.md). To override any variable(s), please use `ansible/vars/overrides.yml`.

There is also `common` role, to keep internal helper tasks.

### `software` role

This role will install all necessary things to have the terminal pretty and useful.

Various tools:

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
13. [TMUX](https://github.com/tmux/tmux) - terminal multiplexer
14. [LazyGIT](https://github.com/jesseduffield/lazygit) - GIT wrapper for both terminal and VIM
15. [keychain](https://www.funtoo.org/Funtoo:Keychain) - ssh-agent wrapper to keep SSH keys across terminal logins
16. [yq](https://mikefarah.gitbook.io/yq/) - awesome terminal YAML parser (also JSON, XML etc.)

Development-related software:

1. [Neovim](https://github.com/neovim/neovim) - more handsome VIM brother
2. [LunarVIM](https://github.com/LunarVim/LunarVim) - Neovim IDE-like extension with awesome plugins/configurations included out of the box
3. [RVM](https://rvm.io/) (Ruby enVironment Manager, installed using [rvm1-ansible-role](https://github.com/rvm/rvm1-ansible)), along with Ruby `3.1.3`
4. [PDK](https://puppet.com/try-puppet/puppet-development-kit/) (Puppet Development Kit)
5. [NVM](https://github.com/nvm-sh/nvm) (Node Version Manager) with latest LTS Node version (by default). Among all - dependency for LunarVIM installation
6. [SDKMAN](https://sdkman.io/) - Manage multiple versions of groovy/java and other JDKs/SDKs.
7. [pyenv](https://github.com/pyenv/pyenv) - Python version manager not to mess system python
8. [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv) - Python virtual environment manager to have separate environments with different packages for projects using same Python version

Also, common useful packages, like:

- mlocate (file search)
- tree (directory tree)
- jq (JSON/YAML parser)

In `ansible/roles/software/vars/main.yml` file, you can find everything that can be configured in terms of software. See [Configuration customizations](#configuration-customizations) for details.

To disable installation of anything, you can add and array in your overrides, for example:

```
software_tasks_exclude:
  - bat
  - keychain
```

Available software excludes:

- packages (default apt packages installation, including **dependencies**)
- git
- ripgrep
- fd
- lsg
- fzf
- diff-so-fancy
- git-fuzzy
- lazygit
- gita
- thefuck
- bat
- zoxide
- helm
- zsh
- w32yank
- tmux
- docker
- kubectl
- kind
- k9s
- rvm
- sdkman
- nvm
- rust
- ansible
- neovim
- lunarvim
- puppet

**PLEASE NOTE**: Do not disable `yq` installation, or ensure you have it installed and available in your path, as it is used to modify yaml files during ansible run.

### `config` role

This role is mostly configs management. It will apply configuration for:

- ZSH/powerlevel10k theme (`~/.zshrc` / `~/.p10k.zsh`)
- Tmux (`~/.tmux.conf`)
- GIT config (`~/.gitconfig`)
- thefuck (`~/.config/thefuck/settings.py`)
- LazyGIT (`~/.config/lazygit/config.yml`)
- ansible-lint (`~/.ansible-lint`)
- lunarvim (`~/.config/lvim/config.lua`)
- SDKMAN (~/.sdkman/etc/config)

If you want to exclude particular component configuration, you can add an array of sections, for example:

```yaml
config_tasks_exclude:
  - ansible-lint
  - tmux
```

Available configs excludes:

- zsh
- p10k
- tmux
- sdkman
- git
- lazygit
- lunarvim
- thefuck
- ansible

By default, all configuration files are backed up in `~/.configs_backup` on every ansible run, in form of `<filename>-<date>`.

To disable taking backups, set:

`config_files_backup: false`

See below for details on overriding variables.

## Configuration customizations

### Overriding variables

To override anything, you can set any variable you want in `ansible/vars/overrides.yml`.

Above file is added to .gitignore, so it won't be versioned.

See possible variables in:

- `ansible/roles/software/vars/main.yml`
- `ansible/roles/config/vars/main.yml`

### Versions management

After every ansible run, it prints all the versions which were installed/updated.

Also, it saves/updates them in `./current-versions.yml`. This file is added to .gitignore, so it is not versioned.

<details>
  <summary><b>Example:</b> Versions printed after run</summary>
  <div align="center">
    <img src="./resources/versions.gif">
  </div>
</details>


If you use `master` branch (which has all the versions set to `latest`), and you want stability for particular component, you can copy any of those outputs and add them to your `ansible/vars/overrides.yml` so this version will be used for any subsequent runs.

### Own config files

As described in [`config role`](#config-role) section, there are certain configuration files which are part of this automation. In order to keep your personal configuration in those files, there are two options:

1. (not recommended) Disable particular config file(s) management sections in `ansible/vars/overrides.yml` using `config_tasks_exclude: []`. This will prevent running config for it. For list of sections, see respective `ansible/roles/config/tasks/main.yml`.
2. (**recommended**) I personally suggest to checkout a local branch in this repository, modify any configuration file(s) in `ansible/roles/config/files` and/or `ansible/roles/config/templates` and commit them. When you want to update changes, just merge release tag (or `master`) to your branch when needed. That way, you can have both your own modifications to the file, and possible upcoming improvements/features which will come with those files. In case of confilcts, you can either choose your own piece of config, or the incoming one, or both.


### Excluding code

You can disable whole functionalities during ansible run using `--skip-tags`, for example:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --skip-tags "software" -K
```

See [ansible tags](#ansible-tags) below for full list.

To exclude certain parts of ansible code for subsequent runs, you can add to your `ansible/vars/overrides.yml` which sections you want to exclude:

```yaml
software_tasks_exclude:
  - bat    # do not install Bat
  - puppet # do not install Puppet
config_tasks_exclude:
  - zsh # do not configure ZSH
```

For full list of exclude options, see [software](#software-role) or [config](#config-role) role description.

### Run particular code

To run only particular parts of the code you can run ansible with `--tags` switch:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags "config" -K
```

See [tags](#ansible-Tags) below for full list.

### Ansible tags

See below list of available tags:

To include/exclude whole roles:

- config
- software

For information:

- versions

For particular functionality:

- ansible
- bat
- diff-so-fancy
- fd
- fzf
- git
- git-fuzzy
- gita
- helm
- k9s
- kind
- kubectl
- lazygit
- lsg
- lunarvim
- neovim
- nvm
- p10k
- puppet
- ripgrep
- rust
- rvm
- sdkman
- software_packages
- thefuck
- tmux
- w32yank
- yq
- zoxide
- zsh

## Troubleshooting

See below known issues and solutions.

### Github tasks issues

If you get an error when some task is trying to install software (or check version) from Github (so it returns `404 not found` with wrong URL or similar),  you probably reached maximum limit for guest API calls to Github (for non-logged users).

The solution would be to either wait (API calls pool is reset every 6 hours) or change your public IP (either by ISP, VPN, proxy or whatever).

### VPN connectivity issues

If you are using a VPN on Windows host and have WSL connectivity issues, please consider using [WSL VPNkit](https://github.com/sakai135/wsl-vpnkit).

After following setup instructions to import vpnkit WSL distro, execute `wsl.exe -d wsl-vpnkit --cd /app service wsl-vpnkit start` and network should work.

### Ruby GPG keys import failed

If that fails, check your firewall settings if hkp:// protocol is allowed, or try to force port 80 by adding to `ansible/vars/overrides.yml`:

```yaml
rvm1_gpg_key_server: 'hkp://keys.openpgp.org:80'

# The GPG alternative key servers
rvm1_gpg_key_servers:
  - '{{ rvm1_gpg_key_server }}'
  - hkp://pgp.mit.edu:80
  - hkp://keyserver.pgp.com:80
  - hkp://keyserver.ubuntu.com:80
```

### Unable to get https endpoints

If you are having problems with connecting to SSL sites (like `curl https://get.rvm.io` or `curl https://github.com`) with no Certificate Authority error, that means you are behind some proxy (corporate or ISP) and have external Certifitate Authority Chain. You would need to import this chain from Windows to WSL. See [this Github comment](https://github.com/microsoft/WSL/issues/3161#issuecomment-945384911) on how to import it.

## Contributing

If you want to help with this piece of software: fork it, create a branch, make changes, test it (preferably including Github workflow for Ubuntu 22.04) and open a Pull Request. You can see [TODO](./TODO.md) for ideas :)

Thanks in advance!

## Author

Eryk 'Ziwi' Kozakiewicz

## Mentions

- Windows setup was inspired and mostly based on [lholota/dev-setup](https://github.com/lholota/dev-setup) by [Lukas Holota](https://github.com/lholota)
- SDKMan! installation was deeply based on [Comcast/sdkman](https://github.com/Comcast/ansible-sdkman) by Elliot Weiser
