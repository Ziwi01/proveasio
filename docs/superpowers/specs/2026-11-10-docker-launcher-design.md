# Docker launcher and image defaults — design

## Intent

Starting the image takes a long `docker run` line: workspace, `~/.ssh`, `~/.kube`, two
state volumes, `HISTFILE`, git identity, a corporate CA bundle with two env vars, the font
switch, and now an Azure DevOps PAT. Typing it is tedious, and the docs
(`docs-web/docs/main/docker/30-run.md`) teach it as flags to paste.

Goals:

1. Universal flags become image defaults, so nobody passes them.
2. A `proveasio` launcher script starts the container in the current directory with a
   short command. Per-user settings live in a config file, not on the command line.
3. `proveasio init` writes a starter config with every optional setting commented out.
4. The docs show presets: config blocks to uncomment or drop in, one per need (ADO,
   GitHub, corporate CA, kube, ssh, Docker socket, fonts, git identity).
5. The config and a flag choose the image (published, local build or own tag) and the
   pull policy.
6. Cloning Azure DevOps and GitHub repositories over HTTPS with a token works from the
   config, with the token kept on the host.

Non-goals: Docker Compose; a PowerShell/Windows launcher; installing the launcher with the
native playbook; changing what the playbook installs.

Anti-goals:

- Mounting anything from the user's home directory that the config does not ask for. The
  image runs AI agents; access to `~/.ssh`, `~/.kube` or a PAT is opt-in.
- Secrets on the `docker` command line, where `ps` on the host shows them.
- A launcher that becomes required: plain `docker run` keeps working, and the docs keep
  showing how.

## Approaches

| Approach | Trade-off | Outcome |
|---|---|---|
| Compose file plus add-on files and an alias | Declarative and standard; cannot mount conditionally, read secrets from files or derive values; still needs an alias | Rejected |
| **Launcher script plus a bash config** | Flexible (derived values, secrets from files, `--dry-run`); a script to maintain and to get onto users' machines | **Chosen** |
| `--env-file` plus a shell function | Least work; env only, mounts stay on the command line | Rejected |

Distribution: users download the repository, or only the script, as the docs describe.

## 1. Image defaults

In `docker/Dockerfile`, in the `build` stage and again in the `update` stage (as `TERM`
is today, so updating an older image adds them):

| Default | Value | Why it is safe for everyone |
|---|---|---|
| `ENV HISTFILE` | `/home/${USERNAME}/.local/state/proveasio/zsh_history` | oh-my-zsh sets `HISTFILE` only when it is unset (`lib/history.zsh`). Without a volume the file is simply lost with the container, as today. |
| `ENV _ZO_DATA_DIR` | `/home/${USERNAME}/.local/state/proveasio/zoxide` | One volume then keeps history and zoxide data. |
| `ENV NODE_EXTRA_CA_CERTS`, `REQUESTS_CA_BUNDLE` | `/etc/ssl/certs/ca-certificates.crt` | That is the system bundle; without a mounted corporate bundle it changes nothing. With one, the CA preset only needs the mount. |
| ADO and GitHub credential helpers in `/etc/gitconfig` | see below | Each answers only for its host and only when its variable (`ADO_PAT`, `GH_TOKEN`) is set; otherwise git falls through to its normal prompt. |

The helper, written as root (`git config --system`, or `sudo` in the `update` stage, which
runs as the user):

```ini
[credential "https://dev.azure.com"]
	helper = "!f() { test \"$1\" = get && test -n \"$ADO_PAT\" && printf 'username=pat\\npassword=%s\\n' \"$ADO_PAT\"; }; f"
```

The same section is repeated for `https://*.visualstudio.com` (older organisation URLs;
git matches `*` in the host part of `credential.<url>`). ADO accepts any non-empty
username with a PAT.

A second helper does the same for GitHub, reading `GH_TOKEN`:

```ini
[credential "https://github.com"]
	helper = "!f() { test \"$1\" = get && test -n \"$GH_TOKEN\" && printf 'username=x-access-token\\npassword=%s\\n' \"$GH_TOKEN\"; }; f"
```

`GH_TOKEN` is the one variable for all three uses: git over HTTPS (this helper), `gh`
(in the image, reads `GH_TOKEN` itself) and the playbook's GitHub API calls during
`proveasio -- ...` runs of Ansible (`common/tasks/github_version.yml` reads `GITHUB_TOKEN`
or `GH_TOKEN`). A self-contained helper, rather than `gh auth git-credential`, keeps both
helpers the same shape and does not depend on gh's login state. GitHub Enterprise hosts
are out of scope; a user adds a section in their own config.

The image has no `/etc/gitconfig` today
(checked in `ziwi/proveasio:lor`), so nothing is overwritten; the native `.gitconfig`
template (`ansible/roles/config/templates/gitconfig.j2`) is not touched.

Not baked: `-w /workspace` (a container without the mount would open in an empty
directory). The launcher sets it.

**The state volume covers only `~/.local/state/proveasio/`** (decided with the user). The
whole of `~/.local/state` also holds opencode's `service.json` and `locks/` and
AstroNvim's `lazy/pkg-cache.lua`; a volume over all of it would hide newer copies from an
updated image and share locks between concurrent containers. The image creates
`~/.local/state/proveasio/` (and `zoxide/` inside it), owned by the user, in both the
`build` and `update` stages, so a fresh named volume is seeded with the right owner. Other
tools' state stays in the container; a user who wants it kept adds a volume for that
directory in the config (the docs show one example, noting the directory must exist in the
image or the volume is root-owned).

Existing users' volumes: their `proveasio-state` (whole directory) and `proveasio-zoxide`
are no longer read at the old paths. The docs give a one-time migration: copy
`zsh_history` from the old state volume and `db.zo` from the zoxide volume into the new
layout, then remove the old volumes. Because the volume name stays `proveasio-state` but
now mounts at a different path, the old contents would appear under
`~/.local/state/proveasio/`; the builder either renames the volume (for example
`proveasio-home-state`) or makes the migration move the files within it. Builder's call;
the docs must match.

Builder: verify that zoxide uses `_ZO_DATA_DIR` as is. Add a check to `docker/test.sh` for the new defaults if
its structure has a place for checks that are not tied to an include; otherwise say so.

## 2. The launcher

File: `docker/proveasio`, bash, executable. Hosts: Linux and WSL. macOS untested (the docs
say so).

### Command line

```
proveasio [--image IMAGE] [--pull POLICY] [--dry-run] [--] [COMMAND...]
proveasio init [--force]
proveasio --help
```

- No `COMMAND`: the image's default (`zsh -l`). With `COMMAND`, it replaces CMD; the
  entrypoint still runs.
- `--dry-run` prints the full `docker run` command, one argument per line or shell-quoted
  (builder's call), and exits. The docs use it to show what the launcher does, and people
  without the launcher copy its output.
- `--` ends launcher options.

### What it always passes

`--rm`, `-i`, `-t` when stdin and stdout are a TTY (so `proveasio -- cmd | less` works),
`-v "$PWD":/workspace -w /workspace`, `-v <state volume>:<home>/.local/state/proveasio`, then
`PROVEASIO_ARGS` from the config, `--pull`, the image, and the command.

`<home>` is `PROVEASIO_USER_HOME`, default `/home/dev`, for images built with another
`USERNAME`. Settable in the config.

The launcher refuses to start when `$PWD` is `$HOME` or `/`: mounting the whole home
directory would hand `~/.ssh`, `~/.kube` and the PAT file to the container without the
config asking for them. The message says to `cd` into a project. (Design call.)

Older images lack the defaults of section 1, so history, the CA preset and the ADO and GitHub presets
would silently not work. Before running, the launcher reads the image's `Config.Env`
(`docker image inspect`, only when the image is present) and warns once when `HISTFILE` is
missing, naming the fix (pull or rebuild). It does not pass the values itself. (Design
call.) The docs state that the launcher needs an image built after this change.

### Config

`${PROVEASIO_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/proveasio}/config` is sourced,
then every `conf.d/*.sh` in that directory in name order. Both are plain bash. Missing
files are not an error; with no config at all the launcher runs with the defaults and
prints one line to stderr pointing at `proveasio init`.

Variables:

| Variable | Default | Meaning |
|---|---|---|
| `PROVEASIO_IMAGE` | `ziwi/proveasio:latest` | Image to run |
| `PROVEASIO_PULL` | `missing`; `never` when the image name has no registry and no `/` (for example `proveasio:local`) | Passed to `docker run --pull` (`missing`, `always`, `never`) |
| `PROVEASIO_ARGS` | `()` | Extra `docker run` arguments, appended with `+=` |
| `PROVEASIO_USER_HOME` | `/home/dev` | Home of the image user |

Precedence for image and pull policy: flag, then environment, then config, then default.
The environment value must survive sourcing the config (read it before sourcing, apply it
after).

When `--pull never` is in effect and the image is not present, the launcher stops with a
message that names the image and says how to build it (`docker buildx bake`) or pull it,
instead of Docker's error.

### Secrets

Presets that need a secret export it into the launcher's environment and pass only the
name: `export ADO_PAT="$(<file)"` and `PROVEASIO_ARGS+=(-e ADO_PAT)`. `-e NAME` without a
value takes it from the environment, so the value is not in the `docker` process's
arguments. `--dry-run` therefore never prints a secret.

### `proveasio init`

Writes `<config dir>/config` (creates the directory). Refuses when the file exists, unless
`--force`; with `--force` it keeps a `config.bak`. Contents:

- `PROVEASIO_IMAGE` and `PROVEASIO_PULL`, commented, with the values the user can choose.
- Commented preset blocks (section 3), each with a one-line explanation.
- The git identity block filled in from the host's `git config user.name` and
  `user.email`, but still commented. If those are empty, placeholders.

The template lives inside the script (heredoc), so downloading only the script is enough.

## 3. Presets

Each preset is a few lines that add to `PROVEASIO_ARGS`. The same text appears commented
in `init`'s output and in the docs.

| Preset | Lines (sketch) |
|---|---|
| SSH keys | `PROVEASIO_ARGS+=(-v "$HOME/.ssh:$PROVEASIO_USER_HOME/.ssh")` |
| SSH agent | `PROVEASIO_ARGS+=(-v "$SSH_AUTH_SOCK:/run/ssh-agent.sock" -e SSH_AUTH_SOCK=/run/ssh-agent.sock)` |
| Kubernetes | `PROVEASIO_ARGS+=(-v "$HOME/.kube:$PROVEASIO_USER_HOME/.kube")` |
| Git identity | `-e GIT_AUTHOR_NAME=... -e GIT_AUTHOR_EMAIL=... -e GIT_COMMITTER_NAME=... -e GIT_COMMITTER_EMAIL=...` |
| No Nerd Font | `PROVEASIO_ARGS+=(-e PROVEASIO_NERD_FONTS=0)` |
| Corporate CA bundle | `PROVEASIO_ARGS+=(-v /path/to/bundle.pem:/etc/ssl/certs/ca-certificates.crt:ro)` (the env vars are image defaults now) |
| Docker socket | `PROVEASIO_ARGS+=(-v /var/run/docker.sock:/var/run/docker.sock --group-add "$(stat -c %g /var/run/docker.sock)")` |
| Azure DevOps | `export ADO_PAT="$(<"$HOME/.config/proveasio/ado-pat")"`, `PROVEASIO_ARGS+=(-e ADO_PAT)`; the docs say to create the PAT file with mode 600 and the narrowest PAT scope |
| GitHub | `export GH_TOKEN="$(<"$HOME/.config/proveasio/github-token")"`, `PROVEASIO_ARGS+=(-e GH_TOKEN)`; same file rules; the docs recommend a fine-grained token limited to the needed repositories, and note that it also lifts the playbook's API rate limit |

The corporate CA preset mounts a **full** bundle (public roots plus the corporate root, such
as RHEL's `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`); a file with only the
corporate root would break TLS to every public site. The docs say so. A user with only the
root certificate uses the `CORP_CA` build secret instead. (Design call.) The existing `CORP_CA`
build secret stays as it is; the docs point out the difference (baked at build time vs
mounted per run).

## 4. Docs

- `docs-web/docs/main/docker/30-run.md`: lead with the launcher: download (clone, or
  `curl` the single script from raw.githubusercontent.com into `~/.local/bin`). The docs
  deploy from `develop` as "next" while the script reaches `master` only at release, so
  the "next" docs download from `develop` and the released docs from `master`; the builder
  checks how `publish.sh` regenerates the stable copy and whether a branch in the URL needs
  a manual note there), `proveasio init`, `proveasio`. Then image choice, then the presets,
  replacing the current long `docker run` blocks. Keep a "Without the launcher" section
  with the plain `docker run` form and a pointer to `--dry-run`. Keep the User ID and
  Devcontainer sections; update the "Keeping state" section for the single volume and the
  zoxide migration.
- `docs-web/docs/main/docker/10-build.md`: where it says how to run a pulled or built
  image, point at the launcher and `PROVEASIO_IMAGE`.
- `README.md`: one line for the launcher if the Docker section lists how to start it.
- A usage example for cloning from Azure DevOps and from GitHub (the preset plus a
  `git clone` URL, and `gh` working without `gh auth login`).

Edit `docs-web/docs/` only, as always.

## 5. Verification

- `cd docs-web && npm install && npm run build` (broken links fail it).
- `cd ansible && ansible-lint` only if anything under `ansible/` changes (not planned).
- `bash -n docker/proveasio`; `shellcheck` if it is installed (not a project gate).
- `docker buildx bake --print`, then the smoke build and the smoke update from
  `AGENTS.md`; check the new ENV and `/etc/gitconfig` in the result.
- Launcher against the smoke image: `--dry-run` with and without a config, `init` (and its
  refusal), `PROVEASIO_IMAGE=proveasio:smoke proveasio -- zsh -lc 'echo $HISTFILE'`, a
  missing local image with `never`, and a non-TTY run.
- ADO and GitHub: `git credential fill` inside the container with `ADO_PAT`/`GH_TOKEN`
  set and unset, for `dev.azure.com`, an `*.visualstudio.com` host and `github.com`. A real
  clone needs the user's PAT and is theirs to run.

## Left to the builder

Script internals, `--dry-run` output format, exact `init` wording and template layout,
whether `test.sh` gets a defaults check (section 1), and the order of the docs sections
beyond "launcher first".
