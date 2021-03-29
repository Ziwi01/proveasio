#!/bin/bash

# Script for initializing working environment. Designed for Ubuntu 20.04 on WSL2.
# TODO: make proper documentation and requirements/usage

USER_HOME=$(eval echo ~${SUDO_USER})
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

check_status() {
  [[ $1 == 0 ]] && printf "${GREEN}OK${NORMAL}\n\n" || printf "${RED}FAILED${NORMAL}\n\n"
}

configure_dotfiles() {
  cp -rT ${BASE_DIR}/dotfiles ${USER_HOME} || return 1
  chown ${SUDO_USER}: ${USER_HOME}/{.bashrc,.profile,.vimrc,.tmux.conf} || return 1
}

configure_vim() {
  mkdir -p ${USER_HOME}/.vim/bundle/ || return 1
  cp -r ${BASE_DIR}/vim.ide ${USER_HOME}/.vim/bundle/ || return 1
  chown -R ${SUDO_USER}: ${USER_HOME}/.vim || return 1
  vim +'PlugInstall --sync' +qa
}

printf '\nEnvironment initializer for Ubuntu 20.04 on WSL2. PLEASE SEE README.\n\n' # TODO: make help function with usage and prompt with accept

### Shell environment
printf 'Copying dotfiles... '
configure_dotfiles
check_status $?

### VIM
printf 'Configuring VIM... '
configure_vim
check_status $?

### GIT config

### Python 3 setup

### RVM / Ruby + gems

### NPM

### Gradle / Groovy

### Ansible

### Needed tools (tree, mlocate)