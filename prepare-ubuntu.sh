#!/bin/bash

PYTHON_VERSION='3.14.0'

# Formatting helpers for visible output
if [ -t 1 ]; then
  RESET="\033[0m"; BOLD="\033[1m"; RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; MAGENTA="\033[35m"; CYAN="\033[36m"
else
  RESET=""; BOLD=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""
fi

hr() { printf "%b\n" "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
section() { hr; printf "%b\n" "${BOLD}${CYAN}$1${RESET}"; hr; }

if [ "$EUID" -ne 0 ]; then
  printf "%b\n" "${BOLD}${RED}Please run this script using 'sudo'${RESET}"
  exit
fi

section "Updating apt"
apt-get update

section "Upgrading system"
apt-get upgrade -y

section "Installing pyenv requirements"
apt-get install -y make build-essential libkrb5-dev libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

section "Install yq requirement"
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ANSIBLE_VERSION=$(yq '.ansible_pip_version' "${SCRIPT_DIR}"/ansible/roles/software/vars/main.yml)

if [ "${ANSIBLE_VERSION}" != 'latest' ]; then
  ANSIBLE_PIP_INSTALL="ansible==${ANSIBLE_VERSION}"
else
  ANSIBLE_PIP_INSTALL='ansible'
fi

sudo -u "${SUDO_USER}" bash <<_
# Formatting helpers for visible output (user context)
if [ -t 1 ]; then
  RESET="\033[0m"; BOLD="\033[1m"; RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; MAGENTA="\033[35m"; CYAN="\033[36m"
else
  RESET=""; BOLD=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""
fi

hr() { printf "%b\n" "\${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${RESET}"; }
section() { hr; printf "%b\n" "\${BOLD}\${CYAN}\$1\${RESET}"; hr; }

section "Install pyenv"
curl https://pyenv.run | bash

section "Set up .bashrc (temporarily)"
grep -qxF 'export PYENV_ROOT="\$HOME/.pyenv"' ~/.bashrc || echo 'export PYENV_ROOT="\$HOME/.pyenv"' >> ~/.bashrc
grep -qxF 'command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"' ~/.bashrc || echo 'command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"' >> ~/.bashrc
grep -qxF 'eval "\$(pyenv init -)"' ~/.bashrc || echo 'eval "\$(pyenv init -)"' >> ~/.bashrc
grep -qxF 'eval "\$(pyenv virtualenv-init -)"' ~/.bashrc || echo 'eval "\$(pyenv virtualenv-init -)"' >> ~/.bashrc

export PYENV_ROOT="\$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"

section "Install pyenv update plugin"
git clone https://github.com/pyenv/pyenv-update.git "\$PYENV_ROOT/plugins/pyenv-update"

section "Run pyenv update"
pyenv update

section "Install Python ${PYTHON_VERSION}"
pyenv install ${PYTHON_VERSION}
pyenv global ${PYTHON_VERSION}

section "Upgrade PIP"
pip install --upgrade pip

section "Install ansible with PIP"
pip install --user ${ANSIBLE_PIP_INSTALL}

section "Install setuptools"
pip install --user setuptools

section "Install pywinrm with PIP for potential Windows support"
pip install --user "pywinrm>=0.3.0"
pip install --user "pywinrm[credssp]"
pip install --user "pywinrm[kerberos]"
_
