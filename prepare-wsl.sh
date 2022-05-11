#!/bin/sh

echo "Updating apt..."
apt update
echo "Upgrading system..."
apt upgrade -y
echo "Installing ansible, python3 and required PIP modules..."
apt install ansible aptitude python3-dev python3-pip python3-setuptools -y
python3 -m pip install "pywinrm>=0.3.0"
python3 -m pip install "pywinrm[credssp]"
python3 -m pip install "pywinrm[kerberos]"