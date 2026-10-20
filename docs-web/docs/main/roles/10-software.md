# `software`

This role will install all necessary things to have the terminal pretty and useful.

Various tools:

1. ZSH shell based on [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme, and some custom plugins.
2. [EZA](https://github.com/eza-community/eza) - modern replacement for `ls` with icons, colours, Git integration and ZSH completions. Aliased as `ls` and `ll`.
3. [LS with GIT status](https://github.com/gerph/ls-with-git-status) - list files/directories with GIT info
3. [FZF Fuzzy finder](https://github.com/junegunn/fzf) - insane speed fuzzy finder with milion usage scenarios
4. [Diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - alternate GIT DIFF presentation
5. [Git fuzzy](https://github.com/bigH/git-fuzzy.git) - managing GIT commands using FZF
6. [Gita](https://github.com/nosarthur/gita) - managing multiple GIT repositories at once (add groups, execute git or shell commands for those groups etc.)
7. [pay-respects](https://github.com/iffse/pay-respects) - corrects errors in previous console commands
8. [BAT](https://github.com/sharkdp/bat) - (much) better CAT
9. [Zoxide](https://github.com/ajeetdsouza/zoxide) - traverse directories with ease (also with FZF)
10. [Helm](https://github.com/helm/helm) - Kubernetes 'package manager'
11. [Ripgrep](https://github.com/BurntSushi/ripgrep) - `grep` on steroids. Blazing fast, easy to use
12. [fd](https://github.com/sharkdp/fd) - `find` alternative, much faster
13. [htop](https://htop.dev/) - process viewer, prettier `top` alternative
14. [TMUX](https://github.com/tmux/tmux) - terminal multiplexer
15. [LazyGIT](https://github.com/jesseduffield/lazygit) - GIT wrapper for both terminal and VIM
16. [keychain](https://www.funtoo.org/Funtoo:Keychain) - ssh-agent wrapper to keep SSH keys across terminal logins
17. [yq](https://mikefarah.gitbook.io/yq/) - awesome terminal YAML parser (also JSON, XML etc.)
18. [FX](https://github.com/antonmedv/fx) - terminal JSON viewer and processor
19. [hunk](https://github.com/modem-dev/hunk) - terminal-based code review and diff viewer with syntax highlighting
20. [opencode](https://github.com/anomalyco/opencode) - terminal-based AI coding agent. Installs v2 by default; pin a 1.x version to keep v1 (see [Versions management](../customization/20-versions.md#opencode-v1-and-v2))
21. [ccmux](https://github.com/epilande/ccmux) - run and track AI coding agents (opencode, Claude Code, Codex and more) in tmux, with live session states, a status sidebar and desktop notifications. Integrates with `opencode` out of the box and, on WSL, bridges notifications to Windows toasts via [wsl-notify-send](https://github.com/stuartleeks/wsl-notify-send)
22. [curlie](https://github.com/rs/curlie) - `curl` frontend with HTTPie-style output. Accepts all `curl` options

Development-related software:

1. [Neovim](https://github.com/neovim/neovim) - more handsome VIM brother
2. [AstroNvim](https://astronvim.com/) - Neovim IDE-like extension with awesome plugins/configurations included out of the box
3. [RVM](https://rvm.io/) (Ruby enVironment Manager, installed using [rvm1-ansible-role](https://github.com/rvm/rvm1-ansible)), along with Ruby `3.1.3`
4. [PDK](https://puppet.com/try-puppet/puppet-development-kit/) (Puppet Development Kit)
5. [NVM](https://github.com/nvm-sh/nvm) (Node Version Manager) with latest LTS Node version (by default). Among all - dependency for LunarVIM installation
6. [SDKMAN](https://sdkman.io/) - Manage multiple versions of groovy/java and other JDKs/SDKs.
7. [pyenv](https://github.com/pyenv/pyenv) - Python version manager not to mess system python
8. [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv) - Python virtual environment manager to have separate environments with different packages for projects using same Python version
9. [ShellCheck](https://github.com/koalaman/shellcheck) - static analysis for shell scripts (latest GitHub release, newer than the Ubuntu package)

Infrastructure and Kubernetes tools:

1. [OpenTofu](https://github.com/opentofu/opentofu) (`tofu`) - open source fork of Terraform
2. [kubeconform](https://github.com/yannh/kubeconform) - Kubernetes manifests validator
3. [dyff](https://github.com/homeport/dyff) - diff tool for YAML files, with Kubernetes-aware output
4. [helm-unittest](https://github.com/helm-unittest/helm-unittest) - unit tests for Helm charts (`helm unittest`). Installed as a Helm plugin, so it needs `helm`. The plugin is linked into `helm_plugins_dir` (default `~/.local/share/helm/plugins`). A `helm-unittest` plugin installed there by other means (for example `helm plugin install`) is removed and replaced.
5. [Argo CD CLI](https://github.com/argoproj/argo-cd) (`argocd`) - command line client for Argo CD, with ZSH completions
6. [Argonaut](https://github.com/darksworm/argonaut) - terminal UI for Argo CD. It uses the session saved by `argocd login`

Also, common useful packages, like `tree` (directory tree), `jq`/`yq` (JSON/YAML parser) and many others.

In `ansible/roles/software/vars/main.yml` file, you can find everything that can be configured in terms of software. See [Configuration customizations](../../category/customizations) for details.

To disable installation of anything, you can add an array in your overrides file, for example:

```
software_tasks_exclude:
  - azurecli
  - puppet
```

See [excluding code](../customization/excludes) for details.

`packages`, `yq` and `zsh` are required. The playbook stops at the start if
`software_tasks_exclude` lists one of them.

Available software excludes:

- fx
- git
- ripgrep
- fd
- eza
- lsg
- fzf
- diff-so-fancy
- git-fuzzy
- dry
- lazygit
- gita
- bottom
- pay-respects
- kubeswitch
- az-account-switcher
- zoxide
- helm
- helm-unittest
- w32yank
- tmux
- docker
- kubectl
- kubecolor
- kind
- k9s
- kubeconform
- dyff
- argocd
- argonaut
- rvm
- sdkman
- nvm
- rust
- gvm
- ansible
- neovim
- puppet
- terraform
- terragrunt
- tofu
- azurecli
- awscli
- uv
- opencode
- hunk
- curlie
- shellcheck
- wsl-notify-send
- ccmux
