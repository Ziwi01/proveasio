#!/bin/bash

# Publish changes to master branch
#
# 1. Copy currently used versions from current-versions.yml to `ansible/roles/software/vars/main.yml`
# 2. (?) Generate changelog in Changes.md
# 3. Commit, push
# 4. Merge to master
# 5. Get back latest versions from `.latest-versions.yml` to software vars.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

yq -i eval-all '. as $item ireduce ({}; . * $item)' ${SCRIPT_DIR}/ansible/roles/software/vars/main.yml ${SCRIPT_DIR}/current-versions.yml

git add .
git commit -a -m 'release: Publish changes to master'
git push
git checkout master
git pull
git merge develop
git push
git checkout develop

yq -i eval-all '. as $item ireduce ({}; . * $item)' ${SCRIPT_DIR}/.latest-versions.yml ${SCRIPT_DIR}/ansible/roles/software/vars/main.yml

git add .
git commit -a -m 'release: Set latest version for development'
git push
