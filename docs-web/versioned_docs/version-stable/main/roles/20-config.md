# `config`

This role is mostly configs management. It will apply configuration for:

- ZSH/powerlevel10k theme (`~/.zshrc` / `~/.p10k.zsh`)
- Tmux (`~/.tmux.conf`)
- GIT config (`~/.gitconfig`)
- thefuck (`~/.config/thefuck/settings.py`)
- LazyGIT (`~/.config/lazygit/config.yml`)
- ansible-lint (`~/.ansible-lint`)
- SDKMAN (`~/.sdkman/etc/config`)

If you want to exclude particular component configuration, you can add an array of sections, for example:

```yaml
config_tasks_exclude:
  - ansible-lint
  - tmux
```

See [excluding code](../customization/excludes) for details.

Available configs excludes:

- zsh
- p10k
- tmux
- sdkman
- git
- lazygit
- neovim-config
- ansible

## Backups

By default, all configuration files are backed up in `~/.configs_backup` on every ansible run, in form of `<filename>-<date>`.

To disable taking backups, set:

`config_files_backup: false`
