# Limitations

## Size and build time

The image is about 8.5 GB. A build takes about 15 minutes on a 16-core
machine, or about 20 minutes the first time. The build already removes about
2.9 GB of caches and build leftovers. Most of the rest is the tools
themselves. The largest parts, measured in an image built with the defaults:

| Path | Size | Remove with |
|---|---|---|
| `~/.local/share/astronvim` | 2.1 GB, of which 1.6 GB is Mason packages | `neovim-config` |
| `/usr` | 1.0 GB | |
| `~/.sdkman` | 0.9 GB | `sdkman` |
| `/opt/az` | 0.6 GB | `azurecli` |
| `~/.rustup` | 0.6 GB | `rust` |
| `~/.local/lib` | 0.5 GB | |
| `/opt/puppetlabs` | 0.4 GB | `puppet` |
| `~/.local/opt/nvm` | 0.4 GB | `nvm` and `ansible` |
| `~/.gvm` | 0.3 GB | `gvm` |
| `~/.local/opt/aws-cli` | 0.3 GB | `awscli` |

The names in the last column go in `software_tasks_exclude`, except
`neovim-config`, which goes in `config_tasks_exclude`. An empty cell means no
single exclude removes the path. `/usr` holds the Ubuntu packages, and
`~/.local/lib` holds the Ansible that runs the build.

To make the image smaller, exclude what you do not need. See
[Turning tools off](./customize#turning-tools-off). The slim image leaves out
the largest tools that nothing else needs and is about 5.7 GB. See
[Slim image](./build#slim-image).

## Other limitations

- **amd64 only.** On arm64 machines, such as Apple Silicon Macs, the image
  runs under emulation, which is slow and may not work for every tool.
- **Updates make the image grow.** Each `docker buildx bake update` adds about
  four layers, and the files it replaces stay in the layers below. After about
  25 updates the image reaches Docker's limit of 127 layers. A full build
  starts from an empty image again.
- **Versions change between builds.** Two builds a day apart can contain
  different versions. Pin versions in `docker/overrides.yml`, or use a dated
  tag of the pre-built image.
- **No man pages.** The Ubuntu base image is minimized. To restore them, run
  `sudo apt-get update && sudo unminimize` inside a container. It takes a few
  minutes and adds several hundred MB.
- **No systemd.** Nothing runs as a service inside the container, including
  the Docker engine.
- **The user ID is fixed at build time.** The user `dev` can only write to
  mounted directories when its UID matches yours, and the pre-built images
  use 1000. See [User ID](./run#user-id).
- **ccmux notifications do nothing.** They are sent to Windows through the WSL
  bridge, which does not exist in a container.
- **opencode and older CPUs.** The build picks the opencode binary for the
  CPU of the machine that builds the image. The pre-built image uses the AVX2
  build and can crash on CPUs without AVX2. Build the image on your own
  machine in that case.
