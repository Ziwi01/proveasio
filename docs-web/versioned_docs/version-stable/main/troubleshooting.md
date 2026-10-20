---
sidebar_position: 10
---

# Troubleshooting

Known problems and their solutions.

## GitHub API rate limit

If a task that looks up a version on GitHub fails with:

```text
Target version for `<app>` is empty. The GitHub API call returned nothing,
most likely because the unauthenticated rate limit (60 requests/hour ...) was exceeded.
```

you used up the 60 unauthenticated GitHub API calls per hour for your public IP address. A full run needs about 33.

Log in with `gh auth login`, or set `GITHUB_TOKEN`, and run again. The limit is then 5000 per hour. See [GitHub API rate limits](./customization/20-versions.md#github-api-rate-limits). Without a token, wait for the hourly reset. `curl -s https://api.github.com/rate_limit` shows when it happens.

## `-K` fails with the correct password

On Ubuntu 26.04, `sudo` is `sudo-rs`, and Ansible does not recognize its password prompt. Install the classic sudo with `sudo apt install sudo`; Proveasio then uses `/usr/bin/sudo.ws`. See [sudo-rs](./installation.md#sudo-rs).

Also check that you run `ansible-playbook` from the `ansible/` directory. From anywhere else, Ansible does not read the project's `ansible.cfg`.

## Neovim does not start: FUSE / AppImage errors

Neovim is installed as an AppImage, which needs FUSE. Where FUSE is missing (containers, some WSL setups), install the release tarball instead. Add to `ansible/vars/overrides.yml`:

```yaml
neovim_package: tarball
```

and run `--tags neovim`.

## Squares instead of icons

Your terminal font has no [Nerd Fonts](https://www.nerdfonts.com/) icons. Set the terminal font to a Nerd Font (for example FiraCode Nerd Font), or turn the icons off with [`nerd_fonts: false`](./customization/10-variables.md#no-nerd-font). To try it without running Ansible: `PROVEASIO_NERD_FONTS=0 zsh`.

## Mason packages fail to install in Neovim

The default Neovim config installs language servers and tools with npm, Go and gem. If you excluded `nvm`, `gvm` or `rvm`, the packages that need them fail, and Neovim retries them on every start. Keep those tools, or remove the language packs from your Neovim config.

## My `.zshrc` (or another config file) was replaced

The `config` role manages `~/.zshrc`, `~/.tmux.conf`, `~/.gitconfig` and the other files listed in the [config role](./roles/20-config.md). Before it changes a file, it saves a copy in `~/.configs_backup/<app>-<filename>-<date>`. To keep your own version, see [Own config files](./customization/30-config-files.md).

## Ruby GPG keys import failed

Check that your firewall allows the `hkp://` protocol, or force port 80. Add to `ansible/vars/overrides.yml`:

```yaml
rvm1_gpg_key_server: 'hkp://keys.openpgp.org:80'

# The GPG alternative key servers
rvm1_gpg_key_servers:
  - '{{ rvm1_gpg_key_server }}'
  - hkp://pgp.mit.edu:80
  - hkp://keyserver.pgp.com:80
  - hkp://keyserver.ubuntu.com:80
```

## Unable to get HTTPS endpoints

If connections to HTTPS sites (like `curl https://get.rvm.io` or `curl https://github.com`) fail with a certificate authority error, a proxy (corporate or ISP) intercepts TLS with its own certificate chain. Import that chain from Windows into WSL. See [this GitHub comment](https://github.com/microsoft/WSL/issues/3161#issuecomment-945384911) for how. For Docker builds, see [Corporate root CA](./docker/10-build.md#corporate-root-ca).

## VPN connectivity issues

If you use a VPN on the Windows host and WSL loses its network connection, try [WSL VPNkit](https://github.com/sakai135/wsl-vpnkit).

After importing the vpnkit WSL distribution as its setup describes, run `wsl.exe -d wsl-vpnkit --cd /app service wsl-vpnkit start`.

## WSL shuts down during a Docker build

A full image build can push WSL to its memory limit. If Windows itself runs short of memory, it shuts WSL down. Before a build, check that the Windows host has at least 10 GB of free physical memory and 10 GB of free commit (values in KB):

```shell
powershell.exe -Command "Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory,FreeVirtualMemory"
```

Build one image at a time. After a build, WSL may keep the memory as page cache for a while.
