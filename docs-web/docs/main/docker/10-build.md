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
docker buildx bake
```

`docker buildx bake` reads `docker-bake.hcl` in the repository root. It builds
the image, runs the smoke tests, and loads the result as `proveasio:local`.
If a test fails, the build fails and no image is loaded.

A build took about 15 minutes on a 16-core machine and produced an image of
about 8.5 GB. The first build also compiles Python and installs Ansible, which
adds about 5 minutes. Later builds reuse that layer.

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

## Pre-built image

:::note
The pre-built image is not published yet. Until it is, build the image
yourself as described above.
:::

The project also publishes the image to Docker Hub:

```shell
docker pull CHANGEME/proveasio:latest
```

| Tag | Content |
|---|---|
| `latest` | The newest build of `master`, rebuilt every week. |
| `YYYY-MM-DD` | The last build of that day. Use it when you want the same tool versions every time you pull. |
| `X.Y.Z` | The build of a Proveasio release. |
| `X.Y` | The build of the newest `X.Y.Z` release. |
| `sha-<short>` | The repository commit the image was built from. The same commit can be built again later with newer tool versions, so this tag does not give you a fixed set of versions. Use a dated tag for that. |

Each image contains the exact versions it was built with in
`~/proveasio/current-versions.yml`.
