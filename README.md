# Windows-WSL2 Power Environment

THIS IS A WORK IN PROGRESS

## Contents

Script will set up WSL2 with:

- ZSH environment
  - oh-my-zsh
  - powerlevel10k
  - custom aliases
- Tmux
- VIM
- GIT config
- Fuzzy-finder (https://github.com/junegunn/fzf)
- Diff-so-Fancy (https://github.com/so-fancy/diff-so-fancy)
- git-fuzzy (https://github.com/bigH/git-fuzzy.git)
- thefuck (https://github.com/nvbn/thefuck)
- bat (https://github.com/sharkdp/bat)
- Zoxide (https://github.com/ajeetdsouza/zoxide)
- Version manager(s):
  - ruby
  - nodejs

Please detailed description for all customizations and added functionality please see below sections


## Manual actions

- Generate SSH keys and put them into `~/.ssh`
- Generate GPG keys and use them in `~/.git/config`

## Author

Eryk 'Ziwi' Kozakiewicz

## Mentions

- `ide.vim` configuration/setup is based on old (modified) version of [run2cmd/ide.vim](https://github.com/run2cmd/ide.vim) by Piotr Bugała <piotr.bugala@gmail.com>
- Windows setup was inspired and mostly based on https://github.com/lholota/dev-setup