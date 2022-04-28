#!/bin/sh

apt update
apt upgrade -y
apt install ansible aptitude python3-dev python3-pip python3-setuptools -y