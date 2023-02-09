```text
 _ _ _ _____ __       _____                      _____
| | | |   __|  |     |  _  |___ _ _ _ ___ ___   |   __|___ _ _ 
| | | |__   |  |__   |   __| . | | | | -_|  _|  |   __|   | | |
|_____|_____|_____|  |__|  |___|_____|___|_|    |_____|_|_|\_/ 
```

![WSL build](https://github.com/Ziwi01/wsl-power-env/actions/workflows/ci.yml/badge.svg?branch=master)
![license](https://img.shields.io/github/license/Ziwi01/wsl-power-env)
![last commit](https://img.shields.io/github/last-commit/Ziwi01/wsl-power-env)

## TL;DR

Repository containing bunch of automation scripts (mostly Ansible tasks) to install, configure and maintain Windows WSL2 environment based on Ubuntu 20.04/22.04, including set of very useful dev tools and customizations to ease out and speed up terminal usage during day-to-day work and bump up productivity.

## About

The idea is to:

- have something consistent when trying to configure new Windows machine with WSL2 mainly for automation development purposes (like DevOps/SysAdmin thingy), but for general usage also.
- be able to be run repeatably to also update installed tools and customizations to latest versions (or stay on particular versions for stability)
- be easily extendable and configurable to suit personal needs.
- have all the features and usages described so they are easily assimilated for someone new to this

In the process of making, I figured out that this can be beneficial for all the people who want to learn how to use Linux as their development base. By documenting the tools and usage scenarios, this repository can be used by tech-savvy wannabies to get a grip of some advanced workflows and tools, with a little less effort than figuring it out themselves from scratch.

**NOTE**: Below project is an opinionated set of tools which I use for my everyday work, but I hope someone will find it useful after tailoring it to ones needs. All the tools/customizations I use will be listed, described and if there are any customizations, they will be shown. If you have some new ideas/functionalities/fixes, feel free to create a Pull Request, it will be very much appreciated!

Please read below README carefully and go through the scripts to see whats going on there before using on existing Windows/WSL.

## TODO

- ~feat: support both Ubuntu 20.04 and 22.04 LTS~
- feat: install docker, kubectl, k9s, kind
- feat: AWS cli installation/setup
- docs: add usage descriptions with videos and images
- feat(vim): Install neovim-ruby-host for all rubies


## Table of contents

* [TL;DR](#tl;dr)
* [About](#about)
* [TODO](#todo)
* [Table of contents](#table-of-contents)
* [Requirements](#requirements)
* [Windows setup](#windows-setup)
  * [Manual](#manual)
  * [Automated](#automated)
    * [prepare-windows.ps1](#prepare-windows.ps1)
    * [prepare-wsl.sh](#prepare-wsl.sh)
    * [setup-windows.yml](#setup-windows.yml)
* [WSL2 setup](#wsl2-setup)
* [Roles overview](#roles-overview)
  * [`software` role](#`software`-role)
  * [`dev` role](#`dev`-role)
  * [`config` role](#`config`-role)
* [Releases](#releases)
* [Configuration customizations](#configuration-customizations)
  * [Tags](#tags)
  * [Excluding code](#excluding-code)
  * [Run particular code](#run-particular-code)
* [Features](#features)
  * [Terminal](#terminal)
  * [Tmux](#tmux)
  * [Git](#git)
  * [Neovim with LunarVIM](#neovim-with-lunarvim)
  * [Helm](#helm)
  * [Languages](#languages)
    * [Ruby](#ruby)
    * [Node](#node)
    * [Puppet](#puppet)
    * [Ansible](#ansible)
    * [Rust](#rust)
* [Author](#author)
* [Mentions](#mentions)


## Requirements

- (obviously) Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- WSL2 configured
- Ubuntu 20.04 or 22.04 installed
- Any terminal using any iconic font (like [Nerd Fonts](https://www.nerdfonts.com/) - see windows setup for details)

Please verify you have correct Windows setup by going through Windows manual setup below, or try experimental Windows automation even more below (feedback welcome!)

## Windows setup

Windows setup should be done manually, however there is an experimental automation for that (see [Automated](#automated) section)

### Manual

1. Install Ubuntu 20.04/22.04, execute from Powershell (Administrator):

    ```shell
    wsl.exe --install -d 'Ubuntu-22.04'
    wsl.exe --set-default 'Ubuntu-22.04'
    ```

    For details, see [Microsoft WSL installation docs](https://docs.microsoft.com/en-us/windows/wsl/install)

    **NOTE:** ~For Ubuntu 22.04 LTS you need to install it through Microsoft Store - there is no image available through `wsl` command.~ Now it is available as `wsl --install -d Ubuntu-22.04`

2. Install DejaVuSans fonts (it can be found in this repo in `ansible/roles/windows/files/fonts`)
3. Install [Microsoft Terminal](https://github.com/microsoft/terminal) and configure this Terminals Ubuntu profile with DejaVuSans font. You can check `ansible/roles/windows/templates/settings.json.j2` for settings reference with useful overrides.

In points #2 and #3 specific font+terminal duo is just a suggestion (I use them personally) - you can use any terminal of your choice and any font supporting iconic fonts (like [Nerd Fonts](https://www.nerdfonts.com/) - please note that not all fonts have the same amount of glyphs/icons. DejaVu has lots of them. Remember to configure you terminal to use this font!

Thats it, you can move to [WSL2 setup](#wsl2-setup)

### Automated

There is an initial automation for setting up Windows, which includes the steps above and some more things, like installing software I commonly use.

#### prepare-windows.ps1

There is a script `prepare-windows.ps1`, which will:

- Install WSL with Ubuntu 22.04.
- Enable WinRM protocol with CredSSP authentication transport (to be able to run Ansible from WSL2 to configure Windows)
- Install [Chocolatey](https://chocolatey.org/) package manager to install software

It must be run as Administrator.

#### prepare-wsl.sh

After `prepare-windows.ps1` is run, login to Ubuntu WSL and clone this repository.

From Ubuntu, run `sudo ./prepare-wsl.sh` - this will update the system and install required ansible packages.

#### setup-windows.yml

1. Create `ansible/vars/overrides.yml` and set `win_username` to your windows User. See `ansible/vars/README.md` for example
2. Investigate `ansible/roles/windows/tasks/main.yml` and review all other tasks in that directory to see what would be done
    1. `common.yml` will install common software packages, like 7Zip, Firefox, BitWarden etc.
    2. `dev.yml` will install GIT, Windows Terminal, IntelliJ, VSCode, Docker Desktop, Postman
    3. `context_menu.yml` will clean up context menu from things added by some of the packages above
    4. `terminal.yml` will install DejaVu font and apply custom settings for Windows Terminal
    5. `entertainment.yml` will install additional software, like Spotify, VLC, Discord etc.

You can switch off the whole sections from #2 by modifying `vars/overrides.yml`. For customization, just edit the yaml files.

After everything is prepared, you can run (from `ansible/` dir):

```shell
ansible-playbook -i inventory.yml setup-windows.yaml -k
```

It will prompt for you Windows password. If the terminal hangs during an execution for more than couple minutes, just break it (`<C-c>`) and run again. This is because Chocolatey installations from WSL ansible can get clogged up sometimes (not sure why this happens).

## WSL2 setup

Now for the main part :).

You might want to go through [very basic config](#roles-overview) before running the installation. This will install everything - see [usages](#usages) for details. Most of the software packages are installed directly from Github repositories and are placed in `${HOME}/.local/` directory, however others are installed either from PIP, direct links or other things.

Assuming all the [requirements](#requirements) are met (Windows manual or automatic setup is done):

1. Create/update file `ansible/vars/overrides.yml` - set desired GIT config name and e-mail. See `ansible/vars/README.md` for examples
2. Clone this repository in WSL Ubuntu if not yet already.
3. Run `sudo ./prepare-wsl.sh` (if not already run during windows setup) to update the system and install required ansible packages.
4. Run ansible (from `ansible/` dir):

    ```shell
    ansible-playbook -i inventory.yml setup-wsl.yaml -K
    ```

## Roles overview

All of the roles have their main configuration in `ansible/roles/<role>/vars/main.yml`. Also, their tasks are gathered in `ansible/roles/<role>/tasks/main.yml`. It is good idea to take a peek on all the .yml files in `tasks/` directories also. For detailed description of how do those things work together, see [Usages](#usages) section below. To override any variable, please use `ansible/vars/overrides.yml`. 

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
10. [Ripgrep](https://github.com/BurntSushi/ripgrep) - `grep` on steroids. Blazing fast, easy to use. Command: `rg <query>`
11. [fd](https://github.com/sharkdp/fd) - `find` alternative, much faster. Command: `fdfind`
12. [htop](https://htop.dev/) - process viewer, prettier `top` alternative
13. [TMUX](https://github.com/tmux/tmux) - terminal multiplexer
14. [LazyGIT](https://github.com/jesseduffield/lazygit) - GIT wrapper for both terminal and VIM. Commands: `lazygit` (from terminal), `<Leader>gg` (from VIM)

Also, common useful packages, like:

- mlocate (file search)
- tree (directory tree)
- jq (JSON/YAML parser)

More useful packages will be installed in `dev` role.

In `ansible/roles/software/vars/main.yml` file, you can find configuration for:

- particular versions of software in `versions` key - by default they are set to `latest`, so that they will get updated when re-running the `setup-wsl.yml` playbook
- list of packages that will get installed from apt repository (like git, tree, htop etc.)
- Oh-My-ZSH plugin list

To override anything, set the variables you want in `ansible/vars/overrides.yml`

### `dev` role

This role installs programming-related tools which I currently use in my work.

Essential:
 - [Neovim](https://github.com/neovim/neovim) - more handsome VIM brother
 - [LunarVIM](https://github.com/LunarVim/LunarVim) - Neovim IDE-like extension with awesome plugins/configurations included out of the box

Programming:
- [RVM](https://rvm.io/) (Ruby enVironment Manager, installed using [rvm1-ansible-role](https://github.com/rvm/rvm1-ansible)), along with Ruby `3.1.3`
- [PDK](https://puppet.com/try-puppet/puppet-development-kit/) (Puppet Development Kit)
- [NVM](https://github.com/nvm-sh/nvm) (Node Version Manager) with latest LTS Node version (by default). Among all - dependency for LunarVIM installation
- [SDKMAN](https://sdkman.io/) - Manage multiple versions of groovy/java and other JDKs/SDKs.

In `ansible/vars/overrides.yml` you can specify Neovim/LunarVIM and RVM/PDK/NVM versions (see `ansible/roles/dev/vars/main.yml` for key reference).

### `config` role

This role is mostly configs management. It will apply configuration for:

- ZSH/powerlevel10k theme (`.zshrc` / `.p10k.zsh`)
- Tmux (`.tmux.conf`)
- GIT config (`.gitconfig`)

If you already have any of those files, you can either turn off overwrites, or back them up before overwriting, by setting appropriate option in `ansible/vars/overrides.yml`:

- `dotfiles_overwrite` (default: true)
- `dotfiles_backup` (default: false)

You can also granulize this on per-component basis - see `ansible/roles/config/vars/main.yml` for reference.

Additionally, configs for below apps will be updated (disable overwrite in `ansible/vars/overrides.yml` if needed)

- thefuck (`~/.config/thefuck/settings.py`)
- LazyGIT (`~/.config/lazygit/config.yml`)
- ansible-lint (`~/.ansible-lint`)
- lunarvim (`~/.config/lvim/config.lua`)

## Releases

Using `master` branch comes with certain amount of danger, as most of the tools used are set to `latest` version. This can cause issues, when those underlying tools introduce a breaking change. Moreover, as I personally try very hard not to make any breaking changes, it can always happen. If you want more stability, please checkout to a release tag before applying the changes - it will have fixed versions of (almost) all used tools.

I will try push new releases with updated (tested) software versions once in a while (even when there is no change to the automation itself), but you can set them yourself:

1. After automation is run (either with `latest` or fixed versions set), it will print out all used versions and save them in `current-versions.yaml` file (this file is added to `.gitignore`)
2. You can copy-paste those versions into `ansible/vars/overrides.yml` so they will be used for future runs.

## Configuration customizations

As described in [`config role`](#config-role) section, there are certain configuration files which are part of this automation. In order to keep your personal configuration in those files, there are two options:

1. (not recommended) Disable particular config file(s) management in `ansible/vars/overrides.yml` using variables like `dotfiles_overwrite: false` or similar. This will prevent any updates of those config files in the future. For list of possible variables, see respective `ansible/roles/<role>/vars/main.yml`.
2. (**recommended**) I personally suggest to checkout a local branch, modify any configuration file(s) there and commit them. When updating, just merge upstream changes to your branch (either from master or tag) when needed. That way, you can have both your own modifications to the file, and possible upcoming improvements/features which will come with those files. In case of confilcts, you can either choose your own piece of config, or the incoming one.

### Tags

See below list of available tags:

For roles overall:

- config
- software
- dev

For functionality:

- ansible
- bat
- diff-so-fancy
- fd
- fzf
- git
- git-fuzzy
- gita
- helm
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
- zoxide
- zsh

### Excluding code

You can disable whole functionalities during ansible run using tags, for example:

```shell
ansible-playbook -i inventory.yml setup-wsl.yaml --skip-tags "dev,software" -K
```

See [tags](#Tags) above for full list.

To exclude certain parts of ansible code for subsequent runs, you can add to your `ansible/vars/overrides.yml` which sections you want to exclude:

```yaml
software_tasks_exclude:
  - bat # do not install BAT
dev_tasks_exclude:
  - puppet # do not install Puppet
config_tasks_exclude:
  - zsh # do not configure ZSH
```

For full list of exclude options, see `ansible/roles/[dev|software|config]/tasks/main.yml`

### Run particular code

To run only particular parts of the code you can run ansible with `--tags` switch:

```shell
ansible-playbook -i inventory.yml setup-wsl.yaml --tags "config" -K
```

See [tags](#Tags) above for full list.

## Features

Below you can find some useful commands/shortcuts/tips on how to use all of this fancy software. For more details for each tool, see the [software](#software-role) and [dev](#dev-role) roles section and take a look at the links there. Below you will find most common scenarios I use and custom added things (configs, modifications, functions).

### Terminal

Terminal is ZSH-based, configured with [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k):

<details>
  <summary><b>Example:</b> Terminal commandline</summary>
  ![terminal](/resources/terminal_preview.png?raw=true)
</details>

There are couple of useful plugins installed there (you can find them in `ansible/roles/config/files/.zshrc`), like:

- syntax highlighting
- commands autocompletion (based on history and/or completion scripts)
- [`FZF`](https://github.com/junegunn/fzf) integration (fuzzy search command history with `<C-r>` and lots other places - try using TAB or `**TAB` here and there)
- fuzzy search/go to directory with `ALT+c`
- traversing directories back and forth (and parent/child) with `ALT+<left|right|up|down>`
- aliases autosuggestions - tells you that you have an alias for particular commands
- easily traversing through **visited** directories (using [`zoxide`](https://github.com/ajeetdsouza/zoxide))
- correct your commands with `fuck` or `ESC ESC`
- finding files with FZF using custom `bfind` alias - with preview and all. Can be used with vim to search file and edit selected (`vim $(bfind)`). Similar functionality (but without file preview) can be achieved with `vim **<TAB>`.
- prettier cat (with [`bat`](https://github.com/sharkdp/bat)) with syntax highlight and all

### Tmux

For TMUX overall usage, please see its documentation with `man tmux`.

Basic usage (@TODO: move to `Usage.md`):

- start with `tmux new`
- `<C-b>c` - new window
- `<C-b>%` - split window vertically
- `<C-b>"` - split window horizontally
- `<C-b><arrows>` - move between panes
- `<C-b><C+<arrows>>` - resize panes
- `<C-b>xy` - kill pane
- `<C-b>n` - next window
- `<C-b>l` - last window
- `<C-b>p` - previous window (in order)
- `<C-b><C-s>` - save session (windows/panes/directories)
- `<C-b><C-r>` - load saved session
- `<C-b><C-f>` - search back TMUX buffer with FZF

Custom modifications in `roles/config/files/.tmux.conf` include:

- custom theme
- session management (`<C-b><C-s>` to save session, `<C-b><C-r>` to restore)
- ability to search back tmux buffer with FZF (`<C-b><C-f>`)
- ability to extract text from tmux buffer with FZF (`<C-b><TAB>`)
- enabled mouse support
- prevent deselect+auto scroll on mouse selection copy (very annoying..)

### Git

For smooth GIT experience there are some tools configured:

- [LazyGIT](https://github.com/jesseduffield/lazygit) - great GUI terminal GIT wrapper. Command: `lazygit`. See docs for usages. Also available from LunarVIM (see Neovim/LunarVIM section)
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - better looking diffs.
- [git-fuzzy](https://github.com/bigH/git-fuzzy) - GIT on FZF steroids. I use LazyGIT now instead, but maybe useful for simpler checkups. Commands:
    - `git-fuzzy`
    - `git-fuzzy status` (alias: `gst`)
    - `git-fuzzy log` (alias: `glo`)
- **truly** useful: `gco` alias for searching and checking out branch with FZF. You can also use it to checkout without searching (`gco branch_name`)
- [Gita](https://github.com/nosarthur/gita) - gather your GIT repositories in groups and execute command on them at once (either GIT command or shell commands)
- [LS with GIT status](https://github.com/gerph/ls-with-git-status) and `k` ohmyzsh plugin - list directories/files and show their GIT status. Command:
    - `lsg` - list directories
    - `k` - list files

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
- [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) - Preview your markdown files in the browser (with dynamic scroll and refresh)
- [godlygeek/tabular](https://github.com/godlygeek/tabular) - easily line up text (like align with equal sign etc.)
- [junegunn/fzf](https://github.com/junegunn/fzf) and [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim) - FZF integration in VIM
- GIT integration plugins:
    - [tpope/fugitive](https://github.com/tpope/vim-fugitive) - Git wrapper, execute any Git command from VIM
    - [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) - Neovim integration with awesome GIT wrapper (LazyGIT). See `software` role description for details.
    - [mhinz/vim-signify](https://github.com/mhinz/vim-signify) - shows GIT info about modified/added/removed lines
    - [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) - great GIT diff plugin for comparing file tree with particular revision(s) or browse file/selection history
    - [f-person/git-blame.nvim](https://github.com/f-person/git-blame.nvim) - show Git blame in-line virtual text.
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

In LunarVIM there is an automatic [LSP installer plugin - Mason](https://github.com/williamboman/mason.nvim) which will install supported language servers and use them, when you open a specific filetype. This should work out of the box in most cases, however for Puppet I setup the LSP server manually, as it doesn't work with RVM by default. Also Ansible gets linter configuration override.

For all configuration overrides, see `ansible/roles/dev/files/lvim-config.lua` in this repo or `~/.config/lvim/config.lua` on the filesystem.

If you have problems with plugins, try to execute `:Lazy` and run Sync or Update.

For detailed usage examples, shortcuts and basic workflow videos, please see [`Usages.md`](./Usages.md)

### Helm

[Helm](https://github.com/helm/helm) gets installed with latest 3.x version.

### Languages

#### Ruby

For Ruby management, there is [Ruby Version Manager (RVM)](https://rvm.io/) installed. See available Ruby's with `rvm list`, use particular with `rvm use <ruby_version>`. There are some gems alredy preinstalled on Rubys available here (mostly for Puppet support).

**NOTE**: There are different ruby versions installed depending if you are using Ubuntu 22.04 or 20.04 - for 20.04 beside latest `3.1.x`, there is `2.4.x` and `2.7.x` installed.

**NOTE 2**: There might be some issues with installing/managing Ruby versions `< 3.1.x` on Ubuntu 22.04 (that's why there is only latest 3.1 version listed for this OS).

#### Node

For Node, there is [NVM](https://github.com/nvm-sh/nvm) installed. See NPM versions with `nvm list`. By default there is latest LTS installed.

#### Puppet

`Puppet` and `puppet-lint` gems are installed on all configured rubys. Also, latest [PDK](https://puppet.com/try-puppet/puppet-development-kit/) is available.

There is Puppet LSP (language server protocol) called [Puppet Editor Services](https://github.com/puppetlabs/puppet-editor-services) installed in `~/.lsp/puppet-editor-services`.

**NOTE:** For Ubuntu-20.04, by default, Puppet gets installed in version 5.5.22 **for all rubies**. If you choose to install latest puppet, there might be some dependencies errors for lower ruby versions (for example 2.4.10, which is included by default). If you don't want to install Puppet for all rubies, set `puppet_rubies` in `vars/overrides.yml` to an array with rubies names. Alternatively, you can override (`vars/overrides.yml`) ruby versions to list only 3.1.x Ruby (`rvm1_rubies` key) - that way you can use latest Puppet/puppet-lint gems - `puppet_version`/`puppet_lint_version`

#### Ansible

Ansible gets installed using both APT (during first step in `setup-wsl.sh`, for further installation) and then the playbooks install PIP3 Ansible in latest available version, along with ansible-lint.

Also, there is an [Ansible Language Server](https://github.com/ansible/ansible-language-server) installed globally using default NPM, but LunarVIM uses it's own, auto-installed language server.

To configure linter diagnostics (enable/disable some checks) in LunarVIM for Ansible files, see: `ansible/roles/dev/files/.ansible-lint`

#### Rust

As LunarVIM requires it, [Rust](https://www.rust-lang.org/) is installed with [Cargo](https://github.com/rust-lang/cargo/) package manager.

## Author

Eryk 'Ziwi' Kozakiewicz

## Mentions

- Windows setup was inspired and mostly based on [lholota/dev-setup](https://github.com/lholota/dev-setup) by [Lukas Holota](https://github.com/lholota)
- SDKMan! installation was deeply based on [Comcast/sdkman](https://github.com/Comcast/ansible-sdkman) by Elliot Weiser
