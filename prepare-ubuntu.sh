#!/bin/bash

PYTHON_VERSION='3.14.0'

# Formatting helpers for visible output
if [ -t 1 ]; then
  RESET="\033[0m"
  BOLD="\033[1m"
  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  MAGENTA="\033[35m"
  CYAN="\033[36m"
else
  RESET=""
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  CYAN=""
fi

hr() { printf "%b\n" "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
section() {
  hr
  printf "%b\n" "${BOLD}${CYAN}$1${RESET}"
  hr
}

if [ "$EUID" -ne 0 ]; then
  printf "%b\n" "${BOLD}${RED}Please run this script using 'sudo'${RESET}"
  exit
fi

section "Updating apt"
apt-get update

section "Upgrading system"
apt-get upgrade -y

section "Installing base requirements"
apt-get install -y curl wget

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

section "Install uv"
curl -LsSf https://astral.sh/uv/install.sh | sh

section "Set up .bashrc for uv (temporarily)"
grep -qxF 'export PATH="\$HOME/.local/bin:\$PATH"' ~/.bashrc || echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> ~/.bashrc

export PATH="\$HOME/.local/bin:\$PATH"

section "Install Python ${PYTHON_VERSION} with uv"
uv python install ${PYTHON_VERSION}

section "Create Python venv with uv"
uv venv --python ${PYTHON_VERSION} "\$HOME/.venv"

# Activate venv for all subsequent steps in this script
source "\$HOME/.venv/bin/activate"

# Also persist venv activation in .bashrc
grep -qxF 'source "\$HOME/.venv/bin/activate"' ~/.bashrc || echo 'source "\$HOME/.venv/bin/activate"' >> ~/.bashrc

section "Upgrade PIP"
uv pip install --upgrade pip

section "Install ansible with uv pip"
uv pip install ${ANSIBLE_PIP_INSTALL}

section "Install setuptools"
uv pip install setuptools

section "Install pywinrm with uv pip for potential Windows support"
uv pip install "pywinrm>=0.3.0"
uv pip install "pywinrm[credssp]"
uv pip install "pywinrm[kerberos]"
_
