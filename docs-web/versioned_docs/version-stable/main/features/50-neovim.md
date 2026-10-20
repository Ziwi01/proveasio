# Neovim

[Neovim](https://github.com/neovim/neovim) is installed in the latest stable version.

It is the default `EDITOR` and is aliased as `vim` and `vimdiff` (change this in `ansible/roles/config/templates/zshrc.j2`).

The default configuration is [Ziwi01/astronvim](https://github.com/Ziwi01/astronvim), based on [AstroNvim](https://astronvim.com/). It adds language servers for the languages Proveasio installs, Git tools (lazygit, Diffview, fugitive), search and replace, and AI assistants (opencode, CodeCompanion, Copilot). You can use your own config instead, see [Own config files](../customization/30-config-files.md).

To learn how to use it, see [Neovim usage](../../usage/40-vim.md).

Neovim is installed as an AppImage by default. AppImages need FUSE. Where FUSE is not available, install the release tarball instead by setting this in `ansible/vars/overrides.yml`:

```yaml
neovim_package: tarball
```
