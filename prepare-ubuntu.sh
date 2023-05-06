#!/bin/bash

PYTHON_VERSION='3.11.2'

if [ "$EUID" -ne 0 ]
  then echo "Please run this script using 'sudo'"
  exit
fi

echo "Updating apt..."
apt-get update
echo "Upgrading system..."
apt-get upgrade -y

echo "Installing pyenv requirements..."
apt-get install -y make build-essential libkrb5-dev libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

echo "Install yq requirement"
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ANSIBLE_VERSION=$(yq '.ansible_pip_version' ${SCRIPT_DIR}/ansible/roles/software/vars/main.yml)

if [ ${ANSIBLE_VERSION} != 'latest' ]; then
  ANSIBLE_PIP_INSTALL="ansible==${ANSIBLE_VERSION}"
else
  ANSIBLE_PIP_INSTALL='ansible'
fi

sudo -u ${SUDO_USER} bash <<_
echo "Install pyenv"
curl https://pyenv.run | bash

echo "Set up .bashrc (temporarily)"
grep -qxF 'export PYENV_ROOT="\$HOME/.pyenv"' ~/.bashrc || echo 'export PYENV_ROOT="\$HOME/.pyenv"' >> ~/.bashrc
grep -qxF 'command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"' ~/.bashrc || echo 'command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"' >> ~/.bashrc
grep -qxF 'eval "\$(pyenv init -)"' ~/.bashrc || echo 'eval "\$(pyenv init -)"' >> ~/.bashrc
grep -qxF 'eval "\$(pyenv virtualenv-init -)"' ~/.bashrc || echo 'eval "\$(pyenv virtualenv-init -)"' >> ~/.bashrc

export PYENV_ROOT="\$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"

echo "Install Python ${PYTHON_VERSION}"
pyenv install ${PYTHON_VERSION}
pyenv global ${PYTHON_VERSION}

echo "Upgrade PIP"
pip install --upgrade pip

echo "Install ansible with PIP"
pip install --user ${ANSIBLE_PIP_INSTALL}

echo "Install pywinrm with PIP for potential Windows support"
pip install --user "pywinrm>=0.3.0"
pip install --user "pywinrm[credssp]"
pip install --user "pywinrm[kerberos]"
_
