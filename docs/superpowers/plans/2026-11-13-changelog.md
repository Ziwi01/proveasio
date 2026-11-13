# Changelog Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace requarks/changelog-action with git-cliff so `CHANGELOG.md`, GitHub releases and both docs versions hold the full release history plus an Unreleased section, and a run with no new commits passes.

**Architecture:** One `cliff.toml` at the repo root defines commit parsing and the plain `CHANGELOG.md` template. The docs page reuses it with header/body/footer overridden through `GIT_CLIFF__CHANGELOG__*` env vars from `docs-web/changelog.md.tera`, rendered by `docs-web/changelog.sh` at docs build time into two gitignored files. Workflows install a pinned git-cliff and call these.

**Tech Stack:** git-cliff 2.14.2 (Tera templates), GitHub Actions, Docusaurus 3 (`format: md`), bash, jq.

**Spec:** `docs/superpowers/specs/2026-11-13-changelog-design.md`

## Global Constraints

- git-cliff pinned to `2.14.2`, installed in CI with `taiki-e/install-action@v2` (`tool: git-cliff@2.14.2`).
- Tags: only `^v[0-9]` count; `latest` never appears as a release.
- Skipped commits: `^Merge`, `^docs: Update CHANGELOG`, `^build: Release updated (docs|versions)`, `^build: Set latest versions for development`, `^build\(deps\)` (dependabot). Breaking commits are protected (`protect_breaking_commits = true`).
- Non-conventional commits: kept, group "Other" (`filter_unconventional = false`).
- No author credit. Each entry: optional bold scope, subject, short SHA linked to `https://github.com/Ziwi01/proveasio/commit/<full sha>`.
- `<` and `>` in commit subjects are emitted as `&lt;` / `&gt;` in both outputs.
- Empty Unreleased renders the line `No unreleased changes.`
- Docs front matter exactly: `sidebar_position: 11`, `title: Changelog`, `format: md`.
- All `shell`/`run` scripts start with `set -euo pipefail`.
- Never commit, push or tag. `git rm --cached` (Task 2) only stages; the user commits.
- Edit `docs-web/docs/` and workflow/script files only; never `docs-web/versioned_docs/` by hand except the `git rm --cached` in Task 2.

## Review Focus

1. Commit subject containing `<details>` or `{x}` → shows literally in docs, does not break `npm run build` or open a stray HTML element. Test in Task 1 and Task 2 via `--with-commit`.
2. No commits since the last tag (the failure that started this) → pre-release body "No changes since vX.Y.Z", CHANGELOG step commits nothing, run is green. Test in Task 4/5 via range `v5.2.0..v5.2.0` / `--context` count.
3. `latest` tag present and pointing at a release commit → never shows as a version heading. Test in Task 1.
4. Breaking change with a skipped type (e.g. `build(deps)!:`) → still listed. Test in Task 1 via `--with-commit`.
5. Docs TOC → lists only Unreleased, newest release, one entry per major (headings inside `<details>` are raw HTML). Test in Task 2 by grepping the generated file for Markdown headings.

---

### Task 1: `cliff.toml` and regenerated `CHANGELOG.md`

**Files:**
- Create: `cliff.toml`
- Modify: `CHANGELOG.md` (fully regenerated)

**Interfaces:**
- Produces: `cliff.toml` usable as `git cliff -c cliff.toml [-o CHANGELOG.md | --latest --strip all | --unreleased --strip all | --context]`. Groups, in this order (ordered with `<!-- N -->` prefixes, removed in templates with `striptags`): Features, Bug Fixes, Performance, Refactor, Documentation, Build, CI, Tests, Chores, Reverts, Other. Breaking commits stay in their group with a `**BREAKING**` prefix. Task 2's template reuses `commit.group` and the same entry format.

- [ ] **Step 1: Write the checks (they fail now: no `cliff.toml`)**

Run from repo root with `GC=/path/to/git-cliff` (2.14.2):

```bash
$GC -c cliff.toml -o /tmp/opencode/CL.md
grep -c '^## v' /tmp/opencode/CL.md                     # expect 16 (v0.9.0 folds into v0.9.1)
grep -c '^## Unreleased' /tmp/opencode/CL.md            # expect 1
grep -cE '^## \[?latest' /tmp/opencode/CL.md            # expect 0
grep -cE 'Update CHANGELOG|Release updated|bump ' /tmp/opencode/CL.md   # expect 0
$GC -c cliff.toml --unreleased --strip all --with-commit 'fix(x): Handle <details> and {x}' --with-commit 'build(deps)!: Drop node 18' \
  | grep -cE '&lt;details&gt; and \{x\}|Drop node 18'   # expect 2
$GC -c cliff.toml v5.2.0..v5.2.0 --strip all | grep -c 'No unreleased changes.'   # expect 1
```

- [ ] **Step 2: Run them, confirm failure** (`cliff.toml` not found).

- [ ] **Step 3: Write `cliff.toml`**

`[changelog]`: header `# Changelog` + one-line description; body renders `## Unreleased` or `## vX.Y.Z - YYYY-MM-DD` (`timestamp | date(format="%Y-%m-%d")`), then `### <group>` and entries per Global Constraints; footer empty; `trim = true`. `[git]`: `conventional_commits = true`, `filter_unconventional = false`, `protect_breaking_commits = true`, `tag_pattern = "^v[0-9]"`, `sort_commits = "newest"`, commit_parsers per Global Constraints, ending with `{ message = ".*", group = "Other" }`.

- [ ] **Step 4: Run Step 1 checks, all match expectations.** Write the real file: `$GC -c cliff.toml -o CHANGELOG.md` and skim it.

- [ ] **Step 5: Stop for user review (no commit).**

### Task 2: Docs changelog page

**Files:**
- Create: `docs-web/changelog.md.tera`, `docs-web/changelog.sh` (executable)
- Modify: `.gitignore`, `publish.sh` (rsync line)
- Untrack: `docs-web/docs/main/changelog.md`, `docs-web/versioned_docs/version-stable/main/changelog.md` (`git rm --cached`)

**Interfaces:**
- Consumes: `cliff.toml` from Task 1.
- Produces: `docs-web/changelog.sh [extra git-cliff args...]` — extra args are passed through to git-cliff (used for `--with-commit` checks); uses `${GIT_CLIFF:-git-cliff}`; must run from anywhere (resolves repo root from its own path); writes both docs paths identically; exits non-zero if git-cliff fails.

- [ ] **Step 1: Write the checks**

```bash
GIT_CLIFF=$GC docs-web/changelog.sh
F=docs-web/docs/main/changelog.md
cmp $F docs-web/versioned_docs/version-stable/main/changelog.md     # identical
head -5 $F    # ---, sidebar_position: 11, title: Changelog, format: md, ---
grep -E '^#{1,6} ' $F          # expect exactly: ## Unreleased, ## v5.2.0 - 2026-11-11, ## v5, ## v4, ## v3, ## v2, ## v1, ## v0
grep -c '<details>' $F         # expect 6 (v5 older, v4..v0)
git check-ignore -q $F && echo ignored
```

- [ ] **Step 2: Run them, confirm failure** (script missing).

- [ ] **Step 3: Write `docs-web/changelog.md.tera` and `docs-web/changelog.sh`**

Template is used as the footer (`releases` array is only available there); script sets `GIT_CLIFF__CHANGELOG__HEADER` (front matter + intro), `GIT_CLIFF__CHANGELOG__BODY=""`, `GIT_CLIFF__CHANGELOG__FOOTER="$(cat changelog.md.tera)"`. Layout: iterate `releases` newest first; unreleased and the first versioned release as `##` Markdown sections; for each further release compute major (`version | split(pat=".") | first`), and when it changes close the previous `</details>`, emit `## vN` and `<details><summary>vN releases</summary>` (for the newest major: `Earlier vN releases`); inside, per release `<h3>vX.Y.Z - date</h3>` and groups as `<h4>`, blank lines around Markdown lists. Track state with `set_global`. Same entry format and escaping as Task 1.

`.gitignore`: add both docs paths. `publish.sh`: add `--exclude main/changelog.md` to the rsync. Then `git rm --cached` both paths.

- [ ] **Step 4: Run Step 1 checks, plus the escaping check:**

```bash
GIT_CLIFF=$GC docs-web/changelog.sh --with-commit 'fix(x): Handle <details> and {x}'
cd docs-web && npm install && npm run build      # expect success, no broken links
grep -o 'Handle &lt;details&gt; and {x}' build/main/changelog/index.html   # or rendered equivalent; literal text, not an element
```

Open `build/main/changelog/index.html` (or `npm run serve`) and check Unreleased and v5.2.0 are open, the rest collapsed. Regenerate without the injected commit afterwards.

- [ ] **Step 5: Stop for user review.**

### Task 3: `pages.yml` generates the page

**Files:** Modify: `.github/workflows/pages.yml`

**Interfaces:** Consumes `docs-web/changelog.sh` (Task 2).

- [ ] **Step 1:** Add after Checkout: `taiki-e/install-action@v2` with `tool: git-cliff@2.14.2`; then a step "Generate changelog page" running `docs-web/changelog.sh`. Checkout already has `fetch-depth: 0` (tags included).
- [ ] **Step 2: Verify:** `actionlint .github/workflows/pages.yml` if installed (else say it was not run); `yq '.jobs.build-docs.steps[].name' .github/workflows/pages.yml` shows the step before "Build Docusaurus".
- [ ] **Step 3: Stop for user review.**

### Task 4: `release.yml`

**Files:** Modify: `.github/workflows/release.yml`

**Interfaces:** Consumes `cliff.toml`.

- [ ] **Step 1:** Checkout `develop` (`fetch-depth: 0`) instead of `master`; install git-cliff; drop "Get previous tag" and requarks. Steps:
  1. Release body: `git cliff -c cliff.toml --latest --strip all > "$RUNNER_TEMP/body.md"`; `ncipollo/release-action` uses `bodyFile`.
  2. `git cliff -c cliff.toml -o CHANGELOG.md`; commit `docs: Update CHANGELOG for ${{ github.ref_name }}` and push to `develop` only if `git diff --quiet CHANGELOG.md` fails.
  3. Keep "Delete pre-releases".
  4. `gh workflow run pages.yml --ref develop` (env `GH_TOKEN: ${{ github.token }}`), always (the new tag changes the docs even if the commit was a no-op).
  - Add `permissions: contents: write, actions: write` at job level.
- [ ] **Step 2: Verify locally** the body command against the real tag: `git checkout --detach v5.2.0 && $GC -c cliff.toml --latest --strip all | head` shows v5.2.0 entries, not Unreleased; return to `develop`. `actionlint` if available.
- [ ] **Step 3: Stop for user review.**

### Task 5: `build.yml`

**Files:** Modify: `.github/workflows/build.yml` (steps from "Get previous tag" to the end)

**Interfaces:** Consumes `cliff.toml`.

- [ ] **Step 1:** Remove "Get previous tag", the awk "Drop the previous `latest` section" step, requarks, "Render CHANGELOG as a docs page" and "Deploy the documentation". Install git-cliff. Then:
  1. "Pre-release notes" on the `master` checkout: `n=$(git cliff -c cliff.toml --unreleased --context | jq '[.[].commits[]] | length')`; if `0`, body is `No changes since $(git describe --tags --abbrev=0 --match 'v[0-9]*').`; else `git cliff -c cliff.toml --unreleased --strip all`. Write to `$RUNNER_TEMP/body.md`; release-action uses `bodyFile`.
  2. "Commit CHANGELOG to develop": `git fetch origin develop && git checkout -f -B develop origin/develop`, `git cliff -c cliff.toml -o CHANGELOG.md`, commit/push only if changed (message `docs: Update CHANGELOG`).
  Keep the `BUILD_BRANCH` env and its comment, adjusted to the new steps.
- [ ] **Step 2: Verify locally:** on `master` (== `v5.2.0`) the jq count prints `0` and the `git describe` prints `v5.2.0`; with `--with-commit 'fix: x'` the count is `1`. `actionlint` if available.
- [ ] **Step 3: Stop for user review.**

### Task 6: Maintainer docs

**Files:** Modify: `AGENTS.md` (CHANGELOG paragraph under "Commits and branches"); Serena memory `ci-and-verification` if it describes requarks or the `[latest]` section.

- [ ] **Step 1:** Replace the CHANGELOG sentence with: generated by git-cliff from `cliff.toml`; committed to `develop` by `release.yml` and the weekly Build; docs page generated at docs build time by `docs-web/changelog.sh` and gitignored in both docs versions; never hand-edit. Mention local preview: `GIT_CLIFF=<path> docs-web/changelog.sh`.
- [ ] **Step 2: Verify:** `grep -n requarks -r AGENTS.md .github` prints nothing.
- [ ] **Step 3: Final gates:** `cd docs-web && npm run build` passes; Task 1 and 2 checks rerun green. `ansible-lint` not required (no `ansible/` change). Workflows remain unverified until CI runs — say so.
