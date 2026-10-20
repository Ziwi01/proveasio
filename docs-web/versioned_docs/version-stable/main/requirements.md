---
sidebar_position: 3
---

# Requirements

## Supported systems

| System | Status |
|---|---|
| Ubuntu 24.04, native or WSL2 | ✅ Supported. CI runs the full playbook on a clean 24.04 runner weekly and on every push to `master`. The Docker image is built on 24.04. |
| Ubuntu 26.04, native or WSL2 | ✅ Supported. CI runs the full playbook on a clean 26.04 runner (the `Build (26)` workflow, started manually). See the [sudo note](./installation.md#sudo-rs) below. |
| Other Ubuntu releases | ⚠️ Not tested. They may work, but nothing checks them. |
| Other distributions, macOS | ❌ Not supported. The roles use `apt` and Ubuntu packages. On those systems, use the [Docker image](./docker/10-build.md). |
| Windows host | ⚠️ Experimental. See [Windows setup](./windows/20-automated.md). |

Only x86_64 (amd64) is supported. Many tools are downloaded as amd64 builds.

## Terminal and font

Any terminal works. A font with [Nerd Fonts](https://www.nerdfonts.com/) icons is recommended. A sample font (FiraCode Nerd Font) is in `ansible/roles/windows/files/fonts`. Without such a font, turn the icons off with [`nerd_fonts`](./customization/10-variables.md#no-nerd-font).

## Network

The playbook downloads from GitHub, the Ubuntu mirrors and the tools' own sites. A full run makes about 33 GitHub API calls. Without a token, GitHub allows 60 per hour, so set up a token first (`gh auth login`, or `GITHUB_TOKEN`). See [GitHub API rate limits](./customization/20-versions.md#github-api-rate-limits).

Behind a TLS-intercepting proxy, see [Unable to get HTTPS endpoints](./troubleshooting.md#unable-to-get-https-endpoints).

## WSL2

When running Ubuntu on Windows with WSL2, also make sure you have:

- Windows 10 version 2004 or later (build 19041 or later), or Windows 11
- WSL2 installed and enabled (version 0.67.6 or later)
- Ubuntu 24.04 or 26.04 installed
- `systemd` enabled in the Ubuntu distribution (the default for new installs)

:::note
On WSL2, check your Windows setup by going through [Windows manual setup](./windows/10-manual.md).
:::
