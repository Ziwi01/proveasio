# Run particular code

To run only particular parts of the code you can run ansible with `--tags` switch(es)

To include/exclude whole roles:

- config
- software

:::tip[Example: including only config]

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags "config" -K
```

Above will run only configuration part of the automation, it won't install/update any software
:::

:::tip[Example: Multiple tags at once]
You can run multiple multiple tags at once:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags "neovim,lunarvim,tmux" -K
```

:::

:::tip[Example: including particular software installation without config]

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags "zsh" --skip-tags "config" -K
```

Above will run only `software` role for ZSH, and will **not** run configuration for it.
:::

For particular functionality (`software` + `config`) below tags are available:

- ansible
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
- ~thefuck~ # temporarily disabled. See docs.
- tmux
- w32yank
- yq
- zoxide
- zsh
- gvm
- terraform
- terragrunt
- azurecli
- awscli
