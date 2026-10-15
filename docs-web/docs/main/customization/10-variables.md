# Overriding variables

To override anything, you can set any variable you want in `ansible/vars/overrides.yml`.

Above file is added to `.gitignore`, so it won't be versioned.

See possible variables in:

- `ansible/roles/software/vars/main.yml`
- `ansible/roles/config/vars/main.yml`

## No Nerd Font

The prompt, tmux status bar, Neovim, lazygit and `ls` (eza) show
[Nerd Fonts](https://www.nerdfonts.com/) icons. When your terminal has no such
font, set:

```yaml
nerd_fonts: false
```

This sets the default of the `PROVEASIO_NERD_FONTS` variable in `~/.zshrc`. With
`PROVEASIO_NERD_FONTS=0`:

- powerlevel10k uses the `compatible` icons and no Powerline separators
- tmux2k shows no Powerline separators and text icons, and leaves out its git
  segment (it always prints a Nerd Font icon; the prompt shows the branch)
- lazygit reads `~/.config/lazygit/lazygit-no-nerd-fonts.yml` after
  `config.yml`, which turns its icons off
- eza runs without `--icons`
- the default Neovim config sets AstroNvim's `icons_enabled = false`, so
  Neo-tree, the status line and the other plugins use text. A config from your
  own `neovim_config_url` has to read the variable itself

`PROVEASIO_NERD_FONTS` set in the environment wins over `nerd_fonts`, so you can
switch per terminal without running Ansible again:

```shell
PROVEASIO_NERD_FONTS=0 zsh
```

tmux reads it only when its server starts: run `tmux kill-server` first.

