# Build the image

Instead of provisioning your machine, Proveasio can build a Docker image. The
build runs the same Ansible playbook inside `docker build`, so the image gets
the same tools and configuration as a native install. Every tool resolves to
its latest version unless you pin it.

## Requirements

- Docker Engine with the buildx plugin, or Docker Desktop. The build was
  tested with Docker Engine 29.8 and buildx 0.37. Older versions are untested.
  `docker buildx version` must work. Ubuntu's `docker.io` package does not
  include buildx. Install `docker-ce` and `docker-buildx-plugin` from
  [Docker's repository](https://docs.docker.com/engine/install/ubuntu/) instead.
- An x86_64 (amd64) machine. Many of the downloaded tools are amd64 builds.
- About 25 GB of free disk space for the image and the build cache.
- Network access to GitHub, the Ubuntu mirrors and the tools' download sites.

## Build

```shell
git clone https://github.com/Ziwi01/proveasio.git
cd proveasio
USER_UID=$(id -u) USER_GID=$(id -g) docker buildx bake
```

`docker buildx bake` reads `docker-bake.hcl` in the repository root. It builds
the image, runs the smoke tests, and loads the result as `proveasio:local`.
If a test fails, the build fails and no image is loaded.

:::warning[Build with your user ID]
The user `dev` inside the image gets the UID and GID from `USER_UID` and
`USER_GID`, which default to 1000. They cannot change after the build. If
they differ from yours, `dev` cannot write to the directories you mount, such
as your project at `/workspace`, and ssh cannot read a mounted `~/.ssh`. The
container prints a warning when it starts in that case. Pass your own IDs as
above to every build, including updates. Bake cannot read them itself, so
without them you get 1000. See [User ID](./run#user-id).
:::

A build took about 15 minutes on a 16-core machine and produced an image of
about 8.5 GB. The first build also compiles Python and installs Ansible, which
adds about 5 minutes. Later builds reuse that layer.

## Slim image

The slim image leaves out SDKMAN (Java, Gradle, Groovy, Maven), Azure CLI,
az-account-switcher, Rust, Puppet and AWS CLI:

```shell
PROFILE=slim USER_UID=$(id -u) USER_GID=$(id -g) docker buildx bake
```

It is loaded as `proveasio:slim` and is about 5.7 GB. It keeps nvm, gvm and
rvm, because the default Neovim config installs language servers with npm, Go
and gem, and Neovim would otherwise try to install them again on every start.
The Java language server is installed but does not start, because the image
has no Java.

To add one of the left-out tools, see
[Adding tools back](./customize#adding-tools-back). The list is in
`docker/profile-slim.yml`.

Build the images one at a time. Two builds at once need twice the memory.

## Getting the latest versions

Every build runs the playbook again and resolves `latest` again, because
`docker-bake.hcl` sets the `REFRESH` build argument to the current time. To
update your image, run `docker buildx bake` again.

When you change the build itself and do not want to wait for the playbook
each time, set a fixed value. The build then reuses the playbook layer from
the cache:

```shell
REFRESH=dev docker buildx bake
```

Some edits still run the playbook again, even with a fixed `REFRESH`. The
playbook step mounts the `docker/` directory and your local Neovim config, so
this happens when you edit any file in them, including `docker/overrides.yml`.
It also happens when you edit a file in `ansible/`.

## Updating tools in a built image

A full build runs the whole playbook again. To update only some tools in an
image you already have, use the `update` target with the tags of those tools:

```shell
ANSIBLE_TAGS=terraform docker buildx bake update
```

The update starts from `proveasio:local`, runs the playbook with
`--tags terraform`, runs all smoke tests again and loads the result as
`proveasio:local`. The tags are listed in
[Partial run](../customization/partial-run). For the slim image, add
`PROFILE=slim`. For any other image, set `BASE_IMAGE` to the image to start
from and `IMAGE` to the name of the result, and add `PROFILE=slim` when the
base is a slim image. The update reads the base image from the local image
store, which works with the default `docker` buildx driver. A
`docker-container` builder cannot see local images. To update a published
image, pull it first:

```shell
docker pull ziwi/proveasio:latest
BASE_IMAGE=ziwi/proveasio:latest IMAGE=proveasio:local \
  ANSIBLE_TAGS=neovim,neovim-config docker buildx bake update
```

An update:

- needs `ANSIBLE_TAGS`. To update everything, run a full build.
- needs `PROFILE` to match the profile of the base image. The default is
  `full`, so add `PROFILE=slim` for a slim image.
- reads `docker/overrides.yml` again, so version pins and other settings can
  change. Excludes can only get shorter. A tool you add back with
  `software_tasks_include` must also be in `ANSIBLE_TAGS`, so that the update
  installs it. A new exclude stops the build, because the tool would stay in
  the image. To remove a tool, run a full build.
- needs the same `NVIM_CONFIG` as the base build when it updates
  `neovim-config` in an image built from a local Neovim config.
- does not upgrade the Ubuntu packages.
- needs the `USERNAME`, `USER_UID` and `USER_GID` the base image was built with.
  If you built it with `USER_UID=$(id -u) USER_GID=$(id -g)`, pass them again.
- uses the `ansible/` and `docker/test.sh` of your checkout. A tool added to
  the checkout since the base build has to be in `ANSIBLE_TAGS`, or the update
  stops.

For example, to add Azure CLI to the slim image, put this in
`docker/overrides.yml`:

```yaml
software_tasks_include:
  - azurecli
  - az-account-switcher
```

and run:

```shell
PROFILE=slim ANSIBLE_TAGS=azurecli,az-account-switcher docker buildx bake update
```

Keep that `docker/overrides.yml` for later updates of the image. Without the
include, azurecli counts as a new exclude and the update stops. For updates,
`docker/overrides.yml` has to match the image you update, so keep one per
image.

Each update adds about four layers, and the files it replaces stay in the
layers below. The image grows by about the size of each tool you update. The
updates of an image are listed in `~/proveasio/docker/build-info.env`. A full
build starts from an empty image again.

## GitHub token

About 33 of the version lookups call the GitHub API. Without a token GitHub
allows 60 calls per hour per public IP address, so you can run about one full
build per hour. A failed build uses up quota too. With a token the limit is
5000 per hour.

The token is optional. The lookups read public data only, so the token needs
no permissions. Create a fine-grained token without adding any permissions,
or a classic token with no scopes selected. Pass it as an environment
variable:

```shell
export GITHUB_TOKEN=<token>
docker buildx bake
```

If you use the GitHub CLI, `GITHUB_TOKEN=$(gh auth token) docker buildx bake`
also works, but that token has every scope you granted the CLI.
The token reaches the build as a build secret and is not stored in the image.

Pinned versions skip the API call entirely. See
[Customize the build](./customize).

## Corporate root CA

If your network intercepts TLS (Zscaler and similar proxies), every HTTPS
fetch inside the build fails with a certificate error: the image's trust store
does not contain your organization's root CA. Export the root CA on the host
and pass it as the `CORP_CA` build secret:

```shell
# RHEL: find the installed anchor (adjust the subject to your proxy vendor)
for f in /etc/pki/ca-trust/source/anchors/*; do
  openssl x509 -in "$f" -noout -subject 2>/dev/null | grep -qi zscaler && echo "$f"
done
export CORP_CA="$(cat <anchor-file>)"
docker buildx bake
```

The secret reaches the build unstored in the image and is installed into the
system trust store only when `CORP_CA` is set. Builds without it are unchanged.
Keep it set for every build on that machine: the secret does not participate
in the build cache, so a build without it can reuse a cached layer that never
installed the CA.

## Pre-built image

:::note
The pre-built image is not published yet. Until it is, build the image
yourself as described above.
:::

The project also publishes the image to Docker Hub:

```shell
docker pull ziwi/proveasio:latest
docker pull ziwi/proveasio:slim
```

| Tag | Content |
|---|---|
| `latest` | The newest build of `master`, rebuilt every week. |
| `YYYY-MM-DD` | The last build of that day. Use it when you want the same tool versions every time you pull. |
| `X.Y.Z` | The build of a Proveasio release. |
| `X.Y` | The build of the newest `X.Y.Z` release. |
| `sha-<short>` | The repository commit the image was built from. The same commit can be built again later with newer tool versions, so this tag does not give you a fixed set of versions. Use a dated tag for that. |
| `slim` | The newest slim build of `master`, rebuilt every week. See [Slim image](#slim-image). |
| `YYYY-MM-DD-slim`, `X.Y.Z-slim`, `X.Y-slim`, `sha-<short>-slim` | The slim image for each tag above. |

Each image contains the exact versions it was built with in
`~/proveasio/current-versions.yml`.

The user `dev` in the pre-built images has UID and GID 1000, the default of
the first user on most Linux systems and in WSL. If `id -u` or `id -g` prints
something else, build the image yourself with your IDs, or use it through a
[devcontainer](./run#devcontainer), which can change the IDs for you. See
[User ID](./run#user-id).
