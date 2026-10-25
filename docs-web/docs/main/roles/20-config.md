# `config`

This role lays down the configuration files. Each row is one task file in `ansible/roles/config/tasks/`; its name is the tag and the `config_tasks_exclude` name.

| Name | Files |
|---|---|
| `zsh` (required) | `~/.zshrc`, from `ansible/roles/config/templates/zshrc.j2`, and `~/.local/bin/ocs` ([opencode session browser](../../usage/20-terminal.md#browse-opencode-sessions-with-ocs)) |
| `p10k` | `~/.p10k.zsh` (powerlevel10k prompt) |
| `tmux` | `~/.tmux.conf`, the tmux plugins, `~/.local/bin/tmux-default-session-name`, `~/.local/bin/hunk-popup`, and `~/.tmuxp/default_session.yaml` when `~/.tmuxp` is empty |
| `git` | `~/.gitconfig`, from `ansible/roles/config/templates/gitconfig.j2` (uses the `git.name` and `git.mail` variables) |
| `lazygit` | `~/.config/lazygit/config.yml`, `lazygit-no-nerd-fonts.yml`, the AI commit scripts in `~/.config/lazygit/scripts/` and the `commit-msg`/`commit-split` agents in `~/.config/opencode/agents/`. See [AI commits in lazygit](../../usage/20-terminal.md#ai-commits-in-lazygit). |
| `neovim-config` | The Neovim config in `~/.config/<neovim_config_appname>` (default `~/.config/astronvim`), cloned from `neovim_config_url` or copied from a local directory. See [Own config files](../customization/30-config-files.md). |
| `ansible` | `~/.ansible-lint` |
| `sdkman` | `~/.sdkman/etc/config` |
| `ccmux` | `~/.config/ccmux/ccmux.json` and `~/.local/bin/ccmux-wsl-notify` |

`zsh` is required. The playbook stops at the start if `config_tasks_exclude` lists it.

To leave out the configuration of some components, list them in `ansible/vars/overrides.yml`:

```yaml
config_tasks_exclude:
  - ansible
  - tmux
```

See [Excluding code](../customization/40-excludes.md) for details.

## Backups

Before Proveasio changes a configuration file, it saves a copy in `~/.configs_backup`, named `<app>-<filename>-<date>`. Files that do not change are not backed up again.

To turn backups off, set:

```yaml
config_files_backup: false
```
