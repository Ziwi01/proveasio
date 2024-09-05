# Terminal

Terminal is ZSH-based, configured with [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k):

<details>
  <summary><b>Example:</b> Terminal commandline</summary>
  <div align="center">
    <img src="https://ziwi01.github.io/proveasio/assets/terminal_preview.png" />
  </div>
</details>
<br />

There are couple of useful plugins installed there (you can find them in `ansible/roles/config/templates/zshrc.j2`), which provide for example:

- syntax highlighting
- commands autocompletion (based on history and/or completion scripts)
- [FZF](https://github.com/junegunn/fzf) integration (command history search, directory search, integration with `fd`)
- fuzzy search/go to directory
- aliases autosuggestions - tells you that you have an alias for particular commands
- easily traversing through **visited** directories (using [zoxide](https://github.com/ajeetdsouza/zoxide))
- (turned off temporarily) ~correct your commands automatically with [thefuck](https://github.com/nvbn/thefuck)~
- finding files with FZF
- Windows clipboard support - also works from VIM (copying in VIM makes it available in Windows clipboard)
