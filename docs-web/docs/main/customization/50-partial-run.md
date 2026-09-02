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
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags "neovim,neovim-config,tmux" -K
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
- awscli
- az-account-switcher
- azurecli
- bottom
- ccmux
- diff-so-fancy
- docker
- dry
- eza
- fd
- fx
- fzf
- git
- git-fuzzy
- gita
- gvm
- helm
- hunk
- k9s
- kind
- kubecolor
- kubectl
- kubeswitch
- lazygit
- lsg
- neovim
- neovim-config
- nvm
- opencode
- p10k
- pay-respects
- puppet
- ripgrep
- rust
- rvm
- sdkman
- software_packages
- terraform
- terragrunt
- tmux
- uv
- w32yank
- wsl-notify-send
- yq
- zoxide
- zsh

There is also `versions`, which re-resolves every tool version and prunes old
installation directories.

## Skip-only tags

A few tags exist purely so you can **exclude** things with `--skip-tags`. They
cannot be used with `--tags`, because the tasks they mark depend on version
resolution that happens earlier in the same task file:

- `cleanup` — the removal of old versions from `~/.local/opt`. Use
  `--skip-tags cleanup` to keep old versions around. To *run* the cleanup, use
  `--tags versions`.
- `sdkman_privilege` — the SDKMAN tasks that need `sudo` (fixing permissions on
  `SDKMAN_DIR` and updating alternatives). Use `--skip-tags sdkman_privilege` to
  run the SDKMAN part unprivileged.

:::tip[Listing the tags yourself]

The list above can always be regenerated from the playbook:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tags
```

:::

:::note[Windows]

`setup-windows.yml` has **no** tags at all. To run only parts of it, use the
`bundle_include` variables instead — see [Windows automation](../windows/automated).

:::
