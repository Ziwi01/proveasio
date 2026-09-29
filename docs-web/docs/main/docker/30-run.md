# Run the image

The paths on this page assume the default user name `dev`. If you built with
another `USERNAME`, replace `/home/dev` with `/home/<USERNAME>`.

## Interactive shell

```shell
docker run -it --rm -v "$PWD":/workspace -w /workspace proveasio:local
```

This starts zsh, with tmux, Neovim and the other tools installed, as the user
`dev` with passwordless sudo. Your current directory is mounted at
`/workspace`.

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

## SSH keys

To use your own keys, mount your `~/.ssh`:

```shell
docker run -it --rm \
  -v "$PWD":/workspace -w /workspace \
  -v "$HOME/.ssh":/home/dev/.ssh \
  proveasio:local
```

This needs an image built with your UID (see [User ID](#user-id)). ssh
refuses to read private keys and `~/.ssh/config` that belong to another user.
The mount is writable, so ssh can add new hosts to `known_hosts`. With `:ro`
added it still works, but ssh warns that it cannot add new hosts. Paths in
`~/.ssh/config` that start with `/home/<you>` do not exist in the container;
write them as `~/.ssh/...` instead.

Instead of the key files, you can pass your ssh agent. The keys then stay on
the host:

```shell
docker run -it --rm \
  -v "$SSH_AUTH_SOCK":/run/ssh-agent.sock -e SSH_AUTH_SOCK=/run/ssh-agent.sock \
  proveasio:local
```

The agent socket is readable only by its owner, so this also needs your UID.
This is for Docker Engine on Linux or WSL; Docker Desktop passes the agent
differently.

## Terminal colors

The image sets `TERM=xterm-256color`, because Docker would otherwise set
`xterm`, which has 8 colors, and the zsh prompt would lose its colors. If your
terminal needs another value, pass it with `-e TERM`.

## Keeping state

Everything outside mounted directories is lost when the container stops. To
keep shell history and zoxide data, mount named volumes and point zsh's
history file into one of them:

```shell
docker run -it --rm \
  -v "$PWD":/workspace -w /workspace \
  -v proveasio-state:/home/dev/.local/state \
  -v proveasio-zoxide:/home/dev/.local/share/zoxide \
  -e HISTFILE=/home/dev/.local/state/zsh_history \
  proveasio:local
```

## Git identity

The image has the git identity from the build (the default is
`Proveasio <Proveasio@hell.no>`). Set yours in `docker/overrides.yml` before
building, or pass it when you start a container:

```shell
docker run -it --rm \
  -e GIT_AUTHOR_NAME="James" -e GIT_AUTHOR_EMAIL="james.doe@hell.no" \
  -e GIT_COMMITTER_NAME="James" -e GIT_COMMITTER_EMAIL="james.doe@hell.no" \
  proveasio:local
```

## Docker inside the container

The image has the Docker client, Compose and Buildx, but no engine. Mount the
host's socket to use the host engine, and add the socket's group so the user
`dev` can use it:

```shell
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  proveasio:local
```

`dry` and `kind` then work against the host engine.
Containers you start this way run on the host, next to this one.

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
`~/proveasio/current-versions.yml`, and that zsh, tmux and Neovim start
without errors. They do not check that your configuration works the way you
want.

To get an image even when a test fails, for example to investigate the
failure, build the stage before the tests:

```shell
docker buildx bake --set image.target=build
```
