#!/bin/bash
#
# Generate the docs changelog page from the git history with git-cliff.
# Writes the same page to the develop docs and the stable versioned docs; both
# copies are gitignored. Extra arguments are passed to git-cliff.
#
# Usage: GIT_CLIFF=/path/to/git-cliff docs-web/changelog.sh [git-cliff args...]
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT=$(dirname -- "$SCRIPT_DIR")
GIT_CLIFF=${GIT_CLIFF:-git-cliff}

GIT_CLIFF__CHANGELOG__HEADER=$(cat <<'EOF'
---
sidebar_position: 11
title: Changelog
mdx: { format: md }
---

All notable changes to this project, generated from the git history by
[git-cliff](https://git-cliff.org). The same page is published for every docs version.
EOF
)
GIT_CLIFF__CHANGELOG__BODY=""
GIT_CLIFF__CHANGELOG__FOOTER=$(cat "$SCRIPT_DIR/changelog.md.tera")
export GIT_CLIFF__CHANGELOG__HEADER GIT_CLIFF__CHANGELOG__BODY GIT_CLIFF__CHANGELOG__FOOTER

page=$(mktemp)
trap 'rm -f "$page"' EXIT

"$GIT_CLIFF" --workdir "$REPO_ROOT" --config "$REPO_ROOT/cliff.toml" --output "$page" "$@"

for dest in docs/main/changelog.md versioned_docs/version-stable/main/changelog.md; do
  cp "$page" "$SCRIPT_DIR/$dest"
done
