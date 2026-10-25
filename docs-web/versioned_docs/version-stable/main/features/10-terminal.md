# Terminal

Terminal is ZSH-based, configured with [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k):

<details>
  <summary><b>Example:</b> Terminal commandline</summary>

![terminal preview](/assets/terminal_preview.png)

</details>
<br />

The prompt uses [Nerd Fonts](https://www.nerdfonts.com/) icons. Without such a font, see [No Nerd Font](../customization/variables#no-nerd-font).

The plugins are listed in `ansible/roles/config/templates/zshrc.j2` (`omz_plugins` in `ansible/roles/software/vars/main.yml` lists the ones cloned from GitHub). They provide, for example:

- syntax highlighting
- commands autocompletion (based on history and/or completion scripts)
- [FZF](https://github.com/junegunn/fzf) integration (command history search, directory search, integration with `fd`)
- fuzzy search/go to directory
- aliases autosuggestions - tells you that you have an alias for particular commands
- easily traversing through **visited** directories (using [zoxide](https://github.com/ajeetdsouza/zoxide))
- correct your commands automatically with [pay-respects](https://github.com/iffse/pay-respects)
- finding files with FZF
- `cat` with syntax highlighting ([bat](https://github.com/sharkdp/bat)) and `ls` with icons and Git status ([eza](https://github.com/eza-community/eza))
- Windows clipboard support on WSL ([win32yank](https://github.com/equalsraf/win32yank)): text copied in Neovim lands in the Windows clipboard
- Windows browser on WSL: `.zshrc` sets `BROWSER` to `~/.local/bin/wsl-browser`, so `az login`, `gh auth login` and other commands that open a URL use the Windows default browser. Native Ubuntu keeps its own default browser.

See [Terminal usage](../../usage/20-terminal.md) for the commands and key bindings.
