#!/bin/sh

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo "Updating apt..."
apt update
echo "Upgrading system..."
apt upgrade -y
echo "Installing ansible, python3 and required PIP modules..."
apt install ansible aptitude python3-dev python3-pip python3-setuptools -y
python3 -m pip install "pywinrm>=0.3.0"