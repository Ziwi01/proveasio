#!/bin/bash

#
# Publish changes to master branch
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# echo "Replace software/vars/main.yml versions with .current-versions.yml"
# yq -i eval-all '. as $item ireduce ({}; . * $item)' ${SCRIPT_DIR}/ansible/roles/software/vars/main.yml ${SCRIPT_DIR}/current-versions.yml

# echo 'git add'
# git add .
#
# echo 'git commit updated versions'
# git commit -a -m 'build: Release updated versions'

echo 'Update docs'
rsync -avrE ${SCRIPT_DIR}/docs-web/docs/ ${SCRIPT_DIR}/docs-web/versioned_docs/version-stable/

echo 'git commit updated docs'
git commit -a -m 'build: Release updated docs'

echo 'git push'
git push

echo 'git checkout master'
git checkout master

echo 'git pull'
git pull

echo 'git rebase develop'
git rebase develop

echo 'git push'
git push

echo 'git checkout develop'
git checkout develop

# echo 'Replace software/vars/main.yml with .latest-versions.yml'
# yq -i eval-all '. as $item ireduce ({}; . * $item)' ${SCRIPT_DIR}/ansible/roles/software/vars/main.yml ${SCRIPT_DIR}/.latest-versions.yml
#
# echo 'git add'
# git add .
#
# echo 'git commit'
# git commit -a -m 'build: Set latest versions for development'
#
# echo 'git push'
# git push
