# Changelog generation redesign

## Intent

The scheduled Build run on 2026-11-13 failed in "Generate CHANGELOG": `v5.2.0`, `master`
and `latest` pointed at the same commit, and `requarks/changelog-action` fails when there
are no commits. The setup is also wrong by design: `release.yml` never writes
`CHANGELOG.md`, `build.yml` drops and recreates a single `[latest]` section, so the file
never holds released sections, and the stable docs copy goes stale between releases.

## Goals

- `CHANGELOG.md`, GitHub releases, and the docs (develop and stable) contain all changes
  across all `v*` releases, plus an "Unreleased" section.
- The same changelog content in develop and stable docs.
- Docs: Unreleased and the newest release fully visible; everything older collapsed, one
  collapsible block per major version.
- A run with no new commits succeeds.
- `publish.sh` keeps working.

## Non-goals

- Changing release cadence, tagging, or the master/develop flow.
- Rewriting history or retro-fixing non-conventional commit subjects.

## Approaches

- **A. git-cliff, full regeneration from tags (chosen).** Deterministic, idempotent, empty
  Unreleased is valid, supports multiple templates (plain repo file, collapsible docs page),
  replaces requarks for release bodies too.
- B. Keep requarks and patch: skip on no commits, backfill old sections by hand. Fragile,
  cannot group by major. Rejected.
- C. Custom `git log` script. Reimplements git-cliff. Rejected.

Commit cadence for `CHANGELOG.md` (chosen: option 2): regenerate on release tags and the
weekly Build run only; the docs page is generated fresh at docs build time. Rejected:
committing on every push to develop (forces a pull after every push).

## Design

### Generator

- `cliff.toml` at repo root. `tag_pattern` matches `v[0-9]*` only; `latest` is ignored.
- Conventional commit groups (features, fixes, breaking changes, etc.), scope shown bold,
  short SHA linked to the commit on GitHub. No author credit.
- Skipped commits: `docs: Update CHANGELOG…`, `build: Release updated docs`, merge commits,
  dependabot bumps (`build(deps)`/`chore(deps)` from dependabot).
- Non-conventional commits go into an "Other" group (not dropped).
- `v0.9.0` is not an ancestor of `master`/`develop`; its commits fold into the next release.
  Accepted.

### `CHANGELOG.md` (committed)

- Plain markdown: `# Changelog`, `## Unreleased`, then `## vX.Y.Z - YYYY-MM-DD`, newest first.
- Generated from `develop` HEAD, so Unreleased = commits on develop not in any `v*` tag.
- Written and committed to `develop` (only when changed) by:
  - `release.yml`, on tag push;
  - `build.yml`, on its weekly/push/dispatch run.
- Pushes use `GITHUB_TOKEN`, so they do not trigger other workflows (no loop).

### GitHub releases

- `release.yml`: body from `git-cliff --latest --strip all` (the pushed tag's section).
- `build.yml` pre-release `latest`: body from `git-cliff --unreleased --strip all` computed
  on `master`. If empty, body is "No changes since vX.Y.Z" and the run succeeds.
- Remove `requarks/changelog-action` and the awk "drop `[latest]` section" step.

### Docs page (generated, not committed)

- `pages.yml` runs git-cliff with a second (docs) template before `npm run build`, writing
  the identical file to:
  - `docs-web/docs/main/changelog.md`
  - `docs-web/versioned_docs/version-stable/main/changelog.md`
- Front matter as today: `sidebar_position: 11`, `title: Changelog`, `format: md`
  (CommonMark keeps `<`/`{` in commit subjects safe; `<details>` works in md mode).
- Both paths added to `.gitignore`; the tracked copies are removed with `git rm --cached`.
- `release.yml` dispatches `pages.yml` (`gh workflow run pages.yml --ref develop`) so a new
  release appears right after tagging. `build.yml` no longer needs to dispatch it.
- Layout:

  ```
  ## Unreleased                         (open)
  ## v5.2.0 - 2026-11-11                (open, newest release)
  ## v5                                 <details>: 5.1.1, 5.1.0, 5.0.0
  ## v4                                 <details>
  ...
  ## v0                                 <details>
  ```

  Per-release headings inside `<details>` are raw HTML so the TOC lists only Unreleased,
  the newest release, and one entry per major.

### `publish.sh`

- Works unchanged (generated page is gitignored, `git add -A` respects it). Add
  `--exclude main/changelog.md` to the rsync so a stale local copy is never copied.

### Docs for maintainers

- Update the `CHANGELOG.md` paragraph in the project `AGENTS.md` (and the `ci-and-verification`
  Serena memory if it describes the old flow).

## Left to the builder

- Installation method of git-cliff in CI (action vs pinned binary) — pin a version.
- How the docs template computes major-version grouping (Tera `set_global`, or `--context`
  JSON + small renderer).
- Exact emoji/group naming.

## Verification

- Run git-cliff locally on the real tags for both outputs and inspect.
- `cd docs-web && npm run build` with the generated page in both locations.
- `actionlint` on changed workflows if available.
- Workflows themselves cannot run locally; unverified until CI runs.
