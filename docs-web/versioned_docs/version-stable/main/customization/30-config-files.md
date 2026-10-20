# Own config files

The [config role](../roles/20-config.md) manages several configuration files. To keep your own changes in them, there are two options:

1. **Recommended:** create your own branch of this repository (`git checkout -b my-branch`), change the files in `ansible/roles/config/files` and `ansible/roles/config/templates`, and commit them. To get updates, merge `master` (or a release tag) into your branch. You keep your changes and still receive improvements to the same files; on a conflict, pick your version, the incoming one, or both.
2. **Not recommended:** stop Proveasio from managing a file by listing its section in `config_tasks_exclude` in `ansible/vars/overrides.yml` (the names are in the [config role](../roles/20-config.md)). The file then never gets updates. `zsh` cannot be excluded, because it is required; to keep your own `.zshrc`, use option 1 and change `ansible/roles/config/templates/zshrc.j2`.

Whichever you choose, a file that Proveasio changes is first backed up to `~/.configs_backup`, see [Backups](../roles/20-config.md#backups).

:::note[Neovim config]
The Neovim config (based on AstroNvim) has its own repository. Fork it and change it, or use a different config entirely. For details see [Neovim usage](../../usage/40-vim.md).

To use your own repository, set `neovim_config_url` and `neovim_config_version` in `ansible/vars/overrides.yml`. To use a directory on your machine instead, set:

```yaml
neovim_config_source: local
neovim_config_local_path: /home/you/my-nvim
```

The directory is copied to `~/.config/<neovim_config_appname>` on every run. The copy adds and overwrites files but never deletes any in the target. If you switch from a git config to a local one, the files of the old clone stay there, including its `.git` directory. Delete the target directory before the run to start clean.
:::
