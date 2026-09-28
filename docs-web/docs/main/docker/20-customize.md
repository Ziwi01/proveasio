# Customize the build

## Overrides file

Create `docker/overrides.yml`. It uses the same format as the native
`ansible/vars/overrides.yml`, so everything in the
[Customizations](../customization/variables) section applies: version pins,
excludes, the git identity, and any other role variable.

```yaml
git:
  name: James
  mail: james.doe@hell.no

github_packages:
  neovim: "0.12.5"

software_tasks_exclude:
  - puppet
  - azurecli
```

The file is in `.gitignore`. The native `ansible/vars/overrides.yml` is never
used for Docker builds, so settings for your own machine do not end up in the
image. To reuse it, copy it to `docker/overrides.yml`. A symlink does not
work.

Do not put `github_api_token` in this file. The build removes it and prints a
warning. Use the `GITHUB_TOKEN` environment variable described in
[Build the image](./build#github-token).

## Container defaults

`docker/profile.yml` holds the settings every Docker build needs. The build
merges it with your `docker/overrides.yml`:

- Lists are appended. Your `software_tasks_exclude` adds to the profile's list.
- Maps are merged key by key.
- The roles then merge `github_packages`, `pip_packages` and
  `docker_apt_packages` with their defaults key by key. Every other variable
  replaces the role default completely, as in a native run.

The profile:

- excludes `w32yank` and `wsl-notify-send`, which are Windows tools,
- installs Neovim from the release tarball, because the AppImage needs FUSE,
- installs the Docker client, Compose and Buildx plugins, but not the engine
  (see [Run the image](./run#docker-inside-the-container)),
- turns off config file backups.

To change one of these for every build, edit `docker/profile.yml`.

## Turning tools off

Use `software_tasks_exclude` and `config_tasks_exclude`. The names are listed
in [Excluding code](../customization/excludes).

When you exclude a software task that has a config task with the same name
(`tmux`, `ccmux`, `sdkman`, `lazygit`, `ansible`), exclude the config task
too. For `neovim`, exclude `neovim-config`.

`packages`, `yq` and `zsh` cannot be excluded, as on a native run. The build
stops before the playbook runs when `docker/overrides.yml` excludes one.

The smoke tests read the same lists and skip what you excluded.

Do not empty a list or map to turn a tool off. A value such as
`npm_default_packages: []` or `omz_plugins: {}` in `docker/overrides.yml`
replaces the role default, and the smoke tests fail because they find nothing
to check. Exclude the tool instead.

## Tags

`ANSIBLE_TAGS` and `ANSIBLE_SKIP_TAGS` are passed to the playbook as `--tags`
and `--skip-tags`:

```shell
ANSIBLE_SKIP_TAGS=puppet,rvm docker buildx bake
```

`--skip-tags` leaves out the tasks with those tags, and the smoke tests skip
them too.

`--tags` builds an image from scratch with only the selected tasks. A new
image needs the package, yq and zsh tasks, including the zsh configuration.
The build stops before the playbook runs when the tags leave one of them out,
and names the missing tasks. For example, `ANSIBLE_TAGS=neovim` stops, and so
does `ANSIBLE_SKIP_TAGS=config`, because it also skips the zsh configuration.
Excludes are the better way to leave tools out. The tag list is in
[Partial run](../customization/partial-run).

## Neovim config

By default the build clones `neovim_config_url` at `neovim_config_version`.
Change both in `docker/overrides.yml` to use your own repository:

```yaml
neovim_config_url: https://github.com/you/nvim-config.git
neovim_config_version: main
```

To use a directory on your machine instead, set `NVIM_CONFIG`. For a
directory outside the repository, also grant Bake read access to it with
`--allow`:

```shell
NVIM_CONFIG="$HOME/my-nvim" docker buildx bake --allow fs.read="$HOME/my-nvim"
```

Without `--allow`, Bake stops with `ERROR: additional privileges requested`
and prints the flag it needs. A directory inside the repository needs no
`--allow`.

The build copies the whole directory as it is, including uncommitted changes,
its `.git` directory and other hidden files, and installs its plugins.
`neovim_config_appname` decides where it goes (`~/.config/<appname>`). The
copy is part of the image, so a later change to the directory needs a new
build.

To run the playbook again inside a container built with `NVIM_CONFIG`, first
add `neovim-config` to `config_tasks_exclude` in
`~/proveasio/ansible/vars/overrides.yml`. The directory the build copied from
does not exist in the container, and the exclude leaves the copied config as
it is:

```yaml
config_tasks_exclude:
  - neovim-config
```

## Build variables

Set these as environment variables when you run `docker buildx bake`.

| Variable | Default | Effect |
|---|---|---|
| `REFRESH` | current time | Any new value runs the playbook again. A fixed value reuses the cache. |
| `GITHUB_TOKEN` | unset | Token for the GitHub API version lookups. |
| `NVIM_CONFIG` | empty | Directory with a local Neovim config. Outside the repository it also needs `--allow fs.read=<directory>`, see [Neovim config](#neovim-config). |
| `ANSIBLE_TAGS` | empty | Passed as `--tags`. |
| `ANSIBLE_SKIP_TAGS` | empty | Passed as `--skip-tags`. |
| `UBUNTU_VERSION` | `24.04` | Tag of the `ubuntu` base image. |
| `USERNAME` | `dev` | User inside the image. |
| `USER_UID` / `USER_GID` | `1000` / `1000` | IDs of that user. Set them to yours (`id -u`, `id -g`) if you bind-mount files. |
| `IMAGE` | `proveasio:local` | Name of the loaded image. |

To see the resolved build definition without building, run
`docker buildx bake --print`.
