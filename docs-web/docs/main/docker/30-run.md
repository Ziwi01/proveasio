# Run the image

The paths on this page assume the default user name `dev`. If you built with
another `USERNAME`, replace `/home/dev` with `/home/<USERNAME>`.

## The launcher

`proveasio` is a script for the host that starts the image in the current
directory. Your settings (image, SSH keys, tokens, the CA bundle and so on)
live in a config file, so the command stays short.

Install it from your clone of the repository (`~/proveasio`, see
[Download](../download)):

```shell
mkdir -p ~/.local/bin && ln -s ~/proveasio/docker/proveasio ~/.local/bin/proveasio
```

Or download only the script:

```shell
mkdir -p ~/.local/bin
curl -fsSLo ~/.local/bin/proveasio https://raw.githubusercontent.com/ziwi01/proveasio/master/docker/proveasio
chmod +x ~/.local/bin/proveasio
```

:::note
The script reaches `master` with the next release. Until then, take it from a
clone of the `develop` branch, or replace `master` with `develop` in the URL.
:::

`~/.local/bin` must be on your `PATH`. Then write a starter config and start
the container from a project directory:

```shell
proveasio init        # writes the config and prints its path
cd ~/projects/my-project
proveasio             # zsh in the container, with the project at /workspace
proveasio -- ansible --version   # run one command instead
proveasio --dry-run   # print the docker commands instead of running them
```

The launcher always adds `--rm`, mounts the current directory at `/workspace`,
and mounts the `proveasio-state` volume (see [Keeping state](#keeping-state)).
It refuses to start in your home directory or in `/`: that would give the
container your whole home directory, including keys and tokens the config did
not ask for.

To remove the volumes, images and config the launcher created, see
[Cleanup and uninstall](#cleanup-and-uninstall).

It runs on Linux and WSL with Docker Engine. It is not tested on macOS.

## Choosing the image

Set the image in the config:

```bash
PROVEASIO_IMAGE=proveasio:local   # your local build (the default of docker buildx bake)
PROVEASIO_PULL=missing            # missing, always or never
```

Or for one run: `proveasio --image ziwi/proveasio:latest-slim --pull always`.
An environment variable (`PROVEASIO_IMAGE=... proveasio`) overrides the config,
and the option overrides both.

Without a setting, the image is `ziwi/proveasio:latest`. The pull policy
defaults to `never` for names without a `/`, such as `proveasio:local`: Docker
would otherwise look for them on Docker Hub. When such an image does not
exist, the launcher tells you to build it. For all other names it defaults to
`missing`.

:::note
The pre-built image is not published yet. Until it is, build the image
([Build the image](./build)) and set `PROVEASIO_IMAGE=proveasio:local`.
:::

## Config files

The launcher reads `~/.config/proveasio/config`, then every
`~/.config/proveasio/conf.d/*.sh` in name order. Set `PROVEASIO_CONFIG_DIR`
to use another directory, for example one per project or customer.

The files are bash. Each setting adds arguments for `docker run` to
`PROVEASIO_ARGS`:

```bash
PROVEASIO_ARGS+=(-v "$HOME/.kube:/home/dev/.kube")
```

`proveasio init` writes every setting below into the config, commented out.
Remove the `# ` in front of the ones you want. You can also put a setting into
its own file in `conf.d/`.

Pass secrets by name only: `export NAME=...` and then `-e NAME`. A value on the
docker command line is visible to every user of the host in `ps`, and
`proveasio --dry-run` would print it.

## Settings

### SSH keys

```bash
PROVEASIO_ARGS+=(-v "$HOME/.ssh:/home/dev/.ssh")
```

This needs an image built with your UID (see [User ID](#user-id)). ssh
refuses to read private keys and `~/.ssh/config` that belong to another user.
The mount is writable, so ssh can add new hosts to `known_hosts`. With `:ro`
added it still works, but ssh warns that it cannot add new hosts. Paths in
`~/.ssh/config` that start with `/home/<you>` do not exist in the container;
write them as `~/.ssh/...` instead.

Instead of the key files, you can pass your ssh agent. The keys then stay on
the host:

```bash
PROVEASIO_ARGS+=(-v "$SSH_AUTH_SOCK:/run/ssh-agent.sock" -e SSH_AUTH_SOCK=/run/ssh-agent.sock)
```

The agent socket is readable only by its owner, so this also needs your UID.
This is for Docker Engine on Linux or WSL; Docker Desktop passes the agent
differently.

### Kubernetes

```bash
PROVEASIO_ARGS+=(-v "$HOME/.kube:/home/dev/.kube")
```

### Git identity

The image has the git identity from the build (the default is
`Proveasio <Proveasio@hell.no>`). Set yours in `docker/overrides.yml` before
building, or pass it when the container starts. `proveasio init` fills in the
values from your host's git config:

```bash
PROVEASIO_ARGS+=(-e GIT_AUTHOR_NAME=James -e GIT_AUTHOR_EMAIL=james.doe@hell.no)
PROVEASIO_ARGS+=(-e GIT_COMMITTER_NAME=James -e GIT_COMMITTER_EMAIL=james.doe@hell.no)
```

### No Nerd Font

The prompt, tmux, Neovim, lazygit and `ls` show
[Nerd Fonts](https://www.nerdfonts.com/) icons. When your terminal has no such
font, turn them off:

```bash
PROVEASIO_ARGS+=(-e PROVEASIO_NERD_FONTS=0)
```

To make it the image default, set `nerd_fonts: false` in `docker/overrides.yml`
before building. See [No Nerd Font](../customization/variables#no-nerd-font).

### Corporate CA bundle

If your network intercepts TLS, mount your host's CA bundle over the image's:

```bash
PROVEASIO_ARGS+=(-v /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:/etc/ssl/certs/ca-certificates.crt:ro)
```

The file must be a full bundle: the public root CAs plus your organization's.
The path above is the one on RHEL; on Debian and Ubuntu it is
`/etc/ssl/certs/ca-certificates.crt`. A file with only your organization's root
CA breaks TLS to every other site. If that is all you have, build the image
with it instead ([Corporate root CA](./build#corporate-root-ca)).

The image points `NODE_EXTRA_CA_CERTS` and `REQUESTS_CA_BUNDLE` at that file,
so Node.js and Python use the bundle too.

### Docker inside the container

The image has the Docker client, Compose and Buildx, but no engine. Mount the
host's socket to use the host engine, and add the socket's group so the user
`dev` can use it:

```bash
PROVEASIO_ARGS+=(-v /var/run/docker.sock:/var/run/docker.sock --group-add "$(stat -c %g /var/run/docker.sock)")
```

`dry` and `kind` then work against the host engine.
Containers you start this way run on the host, next to this one.

### Azure DevOps

To clone and push over HTTPS with a personal access token (PAT), create a PAT
in Azure DevOps with the narrowest scope that works: **Code (Read)** or
**Code (Read & Write)**, for one organization. Save it on the host:

```shell
install -m 600 /dev/null ~/.config/proveasio/ado-pat
$EDITOR ~/.config/proveasio/ado-pat
```

Then turn on the setting:

```bash
export ADO_PAT="$(<"$HOME/.config/proveasio/ado-pat")"
PROVEASIO_ARGS+=(-e ADO_PAT)
```

A git credential helper in the image gives the token to git for
`https://dev.azure.com` and `https://<org>.visualstudio.com`:

```shell
git clone https://dev.azure.com/<org>/<project>/_git/<repo>
```

When the PAT expires, replace the file. Nothing in the container needs to
change.

### GitHub

Create a token on GitHub, preferably a fine-grained one limited to the
repositories you need, and save it the same way:

```shell
install -m 600 /dev/null ~/.config/proveasio/github-token
$EDITOR ~/.config/proveasio/github-token
```

```bash
export GH_TOKEN="$(<"$HOME/.config/proveasio/github-token")"
PROVEASIO_ARGS+=(-e GH_TOKEN)
```

git uses it for `https://github.com`, and `gh` reads `GH_TOKEN` itself, so it
works without `gh auth login`:

```shell
git clone https://github.com/<owner>/<repo>.git
gh repo list
```

It also lifts the GitHub API rate limit when you run the playbook in the
container.

The token is visible to every program in the container, including the AI
agents. Give it, and the Azure DevOps PAT, only the scopes you need.

## Keeping state

Everything outside mounted directories is lost when the container stops. The
image keeps shell history (`HISTFILE`) and zoxide's data (`_ZO_DATA_DIR`) in
`/home/dev/.local/state/proveasio`, and the launcher mounts the
`proveasio-state` volume there. The state of other tools in `~/.local/state`
starts fresh in every container.

To keep another tool's state, add a volume for its directory. For Neovim (the
default config runs as `NVIM_APPNAME=astronvim`):

```bash
PROVEASIO_ARGS+=(-v proveasio-nvim-state:/home/dev/.local/state/astronvim)
```

The directory must exist in the image. If it does not, Docker creates the
volume owned by root and the tool cannot write to it.

## Cleanup and uninstall

The launcher creates the named volumes in your config itself, before
`docker run`, with the label `io.github.ziwi01.proveasio.launcher=1`.
`proveasio --dry-run` prints these `docker volume create` commands too.
`proveasio cleanup` finds the volumes by this label, so it also finds volumes
whose line you have since removed from the config.

```shell
proveasio cleanup --mounts --dry-run           # list, remove nothing
proveasio cleanup --mounts                     # every labeled volume
proveasio cleanup --mounts=proveasio-azure     # only these (comma-separated)
proveasio cleanup --mounts --exclude-mount proveasio-state
proveasio cleanup --images                     # the configured image
proveasio cleanup --images=all                 # every proveasio image, local builds too
proveasio cleanup --config                     # config, config.bak, conf.d/*.sh, the token files
proveasio uninstall                            # all of the above, and the launcher
```

Each command lists what it will remove and asks once. `--yes` removes without
asking; without a terminal, cleanup stops unless you pass `--yes`.

Docker cannot add a label to an existing volume. Volumes from before this
version, such as `proveasio-state`, and volumes you created by hand have no
label. Cleanup lists those that are named in the config or start with
`proveasio-` separately and asks whether to remove them as well;
`--include-unlabeled` removes them without asking. A volume you name in
`--mounts=` is removed with or without the label.

Cleanup never removes:

- bind mounts such as `~/.ssh` or `~/.kube`: those are your files on the host
- volumes and images a container still uses: they are listed as skipped
- other files in the config directory: they are listed as not removed, and
  the directory goes only when it is empty
- anything when the config directory is your home directory or contains it

`uninstall` removes every labeled volume, every image named `proveasio` or
`*/proveasio`, the config files, and the launcher. When the launcher is a
symlink, only the link goes; a launcher inside a git checkout, such as
`~/proveasio/docker/proveasio`, stays.

## User ID

Files in a mounted directory keep their owner's UID and GID from the host. The
user `dev` can only write to them when its UID matches yours. `dev` gets its
IDs when the image is built, from `USER_UID` and `USER_GID` (default 1000), so
build with yours:

```shell
USER_UID=$(id -u) USER_GID=$(id -g) docker buildx bake
```

When the working directory or `~/.ssh` belongs to another UID, the container
prints a warning with the command to rebuild. Set
`PROVEASIO_NO_UID_CHECK=1` (`-e PROVEASIO_NO_UID_CHECK=1`) to hide it.

The IDs cannot be changed when the container starts. That would need a
`chown` of the whole home directory, several GB, which Docker copies into the
container on every start. For the same reason `docker run --user` does not
work: the home directory would not be writable. A
[devcontainer](#devcontainer) with `updateRemoteUserUID` changes the IDs
once, in an extra image layer.

## Terminal colors

The image sets `TERM=xterm-256color`, because Docker would otherwise set
`xterm`, which has 8 colors, and the zsh prompt would lose its colors. If your
terminal needs another value, pass it with `-e TERM`.

## Without the launcher

The launcher only builds a `docker run` command. The minimal one, with the
state volume that keeps shell history and zoxide data, is:

```shell
docker run -it --rm -v "$PWD":/workspace -w /workspace \
  -v proveasio-state:/home/dev/.local/state/proveasio \
  proveasio:local
```

The state volume must be mounted at `~/.local/state/proveasio`: the image
keeps history and zoxide data there, not in `~/.zsh_history` or
`~/.local/share/zoxide`.

`proveasio --dry-run` prints the full command for your config, ready to copy.

## Devcontainer

A minimal `.devcontainer/devcontainer.json` for VS Code or DevPod:

```json
{
  "name": "proveasio",
  "image": "proveasio:local",
  "remoteUser": "dev",
  "updateRemoteUserUID": true,
  "runArgs": ["--group-add", "<gid>"],
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ]
}
```

Replace `<gid>` with the output of `stat -c %g /var/run/docker.sock` on the
host, so the user `dev` can use the socket.

`updateRemoteUserUID` changes the UID and GID of `dev` to yours on Linux, so
you do not need to rebuild with `USER_UID`.

## Running the tests

The smoke tests are in the image:

```shell
docker run --rm proveasio:local /home/dev/proveasio/docker/test.sh
docker run --rm proveasio:local /home/dev/proveasio/docker/test.sh --list
docker run --rm proveasio:local /home/dev/proveasio/docker/test.sh --only software/neovim
```

With the Docker socket mounted, the `software/docker` check also connects to
the engine.

The tests check that each tool runs and reports the version recorded in
`~/proveasio/current-versions.yml`, that zsh, tmux and Neovim start without
errors, and that the image defaults the launcher relies on are set
(`image/defaults`). They do not check that your configuration works the way
you want.

To get an image even when a test fails, for example to investigate the
failure, build the stage before the tests:

```shell
docker buildx bake --set image.target=build
```
