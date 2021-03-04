# Environment init

THIS IS A WORK IN PROGRESS

This repository contains personal stuff for initializing WSL2 Ubuntu (20.04) environment with basic stuff to get working.

## Script

`initialize.sh` script will include:

- Bash environment setup
- Development directory tree (see: [Directory tree](#directory-tree))
- Tmux installation/config
- VIM configuration as IDE (plugins, config etc.)
- GIT config
- Python 3 setup with virtual env
- RVM/Ruby setup
- Gradle/Groovy setup
- NPM setup
- Ansible setup
- Basic tools installation (tree, mlocate, etc.)

The script needs to be run from user where we want to set those things up with `SUDO NOPASSWD` permissions (for tools installation)

## Additional files

Optional files to be put manually where they belong

- Windows Terminal settings file
- PowerShell PS1 file

## Directory tree

Created directory tree

## Manual actions

- Generate SSH keys and put them into `~/.ssh`
- Generate GPG keys and use them in `~/.git/config`

## Author

Ziwi <ziwi01@gmail.com>

## Contributors

`ide.vim` configuration/setup is based on old version of [run2cmd/ide.vim](https://github.com/run2cmd/ide.vim) by Piotr Bugała <piotr.bugala@gmail.com>
