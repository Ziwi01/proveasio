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
echo "Installing ansible, python3 and required PIP modules..."
apt-get install -y libkrb5-dev
apt-get install -y ansible aptitude python3-dev python3-pip python3-setuptools python3-venv

echo "Installing pyenv requirements..."
apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

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

echo "Install ansible with PIP"
pip install --user ansible

echo "Install pywinrm with PIP for potential Windows support"
pip install --user "pywinrm>=0.3.0"
pip install --user "pywinrm[credssp]"
pip install --user "pywinrm[kerberos]"
_
