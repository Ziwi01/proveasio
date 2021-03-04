#!/bin/bash

# Script for initializing working environment. Designed for Ubuntu 20.04 on WSL2.

# TODO: Whole setup (python3+venv, RVM, NPM, directory structure etc.)

### Shell environment
# config files
cp $(realpath $0)/bash/* ~/

### TMUX
# install

# config
cp $(realpath $0)/tmux/* ~/

### VIM
# apply ide.vim
mkdir -p ~/.vim/bundle/
cp -r $(realpath $0)/vim.ide ~/.vim/bundle/

### GIT config

### Python 3 setup

### RVM / Ruby + gems

### NPM

### Gradle / Groovy

### Ansible

### Needed tools (tree, mlocate)