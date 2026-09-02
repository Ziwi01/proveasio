# `config`

This role is mostly configs management. It will apply configuration for:

- ZSH/powerlevel10k theme (`~/.zshrc` / `~/.p10k.zsh`)
- Tmux (`~/.tmux.conf`)
- GIT config (`~/.gitconfig`)
- thefuck (`~/.config/thefuck/settings.py`)
- LazyGIT (`~/.config/lazygit/config.yml`)
- ansible-lint (`~/.ansible-lint`)
- SDKMAN (`~/.sdkman/etc/config`)
- ccmux (`~/.config/ccmux/ccmux.json`)

If you want to exclude particular component configuration, you can add an array of sections, for example:

```yaml
config_tasks_exclude:
  - ansible
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
- ccmux

## Backups

By default, a configuration file is backed up in `~/.configs_backup`, in form of `<app>-<filename>-<date>`, whenever Proveasio actually changes it (unchanged files are not re-backed up).

To disable taking backups, set:

`config_files_backup: false`
