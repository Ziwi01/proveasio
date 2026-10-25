# Overriding variables

Set any variable in `ansible/vars/overrides.yml` to override its default. The file is in `.gitignore`, so it stays on your machine. Examples are in `ansible/vars/README.md`.

The variables and their defaults are in:

- `ansible/roles/software/vars/main.yml`
- `ansible/roles/config/vars/main.yml`

Do not change the defaults in those files; set the variable in `overrides.yml` instead. The roles load it with a higher precedence than their own `vars/main.yml`.

:::note[Merging]
A variable in `overrides.yml` replaces the default **completely**. The exceptions are the version catalogs `github_packages`, `pip_packages` and `docker_apt_packages`: they are merged key by key, so you only list the tools you pin. See [Versions management](./20-versions.md).

To add to a list such as `npm_default_packages` or `rvm1_rubies`, copy the default list and extend it.
:::

Commonly changed variables:

| Variable | Default | Effect |
|---|---|---|
| `git.name`, `git.mail` | | Your git identity in `~/.gitconfig` |
| `software_tasks_exclude`, `config_tasks_exclude` | `[]` | Tools and configs to leave out, see [Excluding code](./40-excludes.md) |
| `github_packages` | `latest` for all | Version pins, see [Versions management](./20-versions.md) |
| `github_api_token` | unset | Token for the GitHub API, see [GitHub API rate limits](./20-versions.md#github-api-rate-limits) |
| `nerd_fonts` | `true` | Icons in the prompt, tmux, Neovim, lazygit and `ls`, see below |
| `neovim_package` | `appimage` | `tarball` where FUSE is missing |
| `neovim_config_url`, `neovim_config_version` | Ziwi01/astronvim, `main` | Neovim config repository, see [Own config files](./30-config-files.md) |
| `opencode_config_url`, `opencode_config_version` | Ziwi01/opencode-config, `main` | Shared OpenCode config repository. The version is a branch name, the repository has no releases |
| `opencode_config_source`, `opencode_config_local_path` | `git`, unset | `local` runs `install.sh` from a working clone at `opencode_config_local_path`, see [Own config files](./30-config-files.md) |
| `opencode_config_path` | `~/.local/share/opencode-config` | Where the `git` source is cloned |
| `opencode_baseline` | `auto` | `auto` uses the `-baseline` OpenCode build only when the CPU of the machine running the playbook has no AVX2. `true` always downloads it on x64 (arm64 has no baseline build). The Docker images set `true`. OpenCode v2 currently publishes the same x64 binary under both names, so this mainly matters for v1 pins (separate builds) or if v2 splits them again. On an existing install or `update` image it takes effect with the next OpenCode version |
| `node_version` | `lts/jod` | Default Node version (nvm) |
| `go_versions`, `go_default` | `go1.26.1` | Go versions (gvm) |
| `rvm1_rubies` | `ruby-3.4.7` | Ruby versions (rvm) |
| `sdkman_install_packages`, `sdkman_defaults` | Java, Gradle, Groovy, Maven | SDKMAN candidates and their default versions |
| `cleanup_old_versions` | `true` | Remove old versions from `~/.local/opt`, see [Cleaning up old versions](./45-cleanup.md) |
| `config_files_backup` | `true` | Back up config files before changing them |

## No Nerd Font

The prompt, tmux status bar, Neovim, lazygit and `ls` (eza) show
[Nerd Fonts](https://www.nerdfonts.com/) icons. When your terminal has no such
font, set:

```yaml
nerd_fonts: false
```

This sets the default of the `PROVEASIO_NERD_FONTS` variable in `~/.zshrc`. With
`PROVEASIO_NERD_FONTS=0`, the prompt and Neovim use only ASCII, box drawing
characters (`─ │ ╭ ╮`) and `✓`. Fonts without Nerd Font icons often also lack
characters like `❯`, `✔` or `▏`, which show as squares.

- powerlevel10k uses its `ascii` icons, `>` as the prompt character, and no
  Powerline separators or `▓▒░` ends
- tmux2k shows no Powerline separators and text icons, and leaves out its git
  segment (it always prints a Nerd Font icon; the prompt shows the branch)
- lazygit reads `~/.config/lazygit/lazygit-no-nerd-fonts.yml` after
  `config.yml`, which turns its icons off
- eza runs without `--icons`
- the default Neovim config sets AstroNvim's `icons_enabled = false`, and
  replaces the glyphs that plugins hardcode: indent and scope lines, winbar
  separators, the status line scrollbar (hidden), picker, command line and
  `:Lazy` icons. A config from your own `neovim_config_url` has to read the
  variable itself
- lazygit's own `→ ○ ▐` and views of other Neovim plugins may still show
  squares

`PROVEASIO_NERD_FONTS` set in the environment wins over `nerd_fonts`, so you can
switch per terminal without running Ansible again:

```shell
PROVEASIO_NERD_FONTS=0 zsh
```

tmux reads it only when its server starts: run `tmux kill-server` first.

