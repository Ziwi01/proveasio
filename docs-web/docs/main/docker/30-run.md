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

Files you create in `/workspace` belong to UID 1000. If your own UID is
different, build with `USER_UID=$(id -u) USER_GID=$(id -g) docker buildx bake`.

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
