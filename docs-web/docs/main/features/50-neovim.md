# Neovim

[Neovim](https://github.com/neovim/neovim) is installed in latest stable version.

It is set as default `EDITOR`, also aliased as `vim` (you can change it in `ansible/roles/config/templates/zshrc.j2`).

For details on how to navigate and power-use this IDE like a boss, see [Neovim usage](../../usage/vim)

Neovim is installed as an AppImage by default. AppImages need FUSE. Where FUSE is not available, install the release tarball instead by setting this in `ansible/vars/overrides.yml`:

```yaml
neovim_package: tarball
```
