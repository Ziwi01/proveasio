#!/bin/sh

echo "Updating apt..."
apt update
echo "Upgrading system..."
apt upgrade -y
echo "Installing ansible, python3 and required PIP modules..."
apt install -y libkrb5-dev
apt install -y ansible aptitude python3-dev python3-pip python3-setuptools python3-venv
python -m pip install --user "pywinrm>=0.3.0"
python -m pip install --user "pywinrm[credssp]"
python -m pip install --user "pywinrm[kerberos]"
