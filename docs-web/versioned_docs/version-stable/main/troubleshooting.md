---
sidebar_position: 8
---

# Troubleshooting

See below known issues and solutions.

## Github tasks issues

If you get an error when some task is trying to install software (or check version) from Github (so it returns `404 not found` with wrong URL or similar),  you probably reached maximum limit for guest API calls to Github (for non-logged users).

The solution would be to either wait (API calls pool is reset every 6 hours) or change your public IP (either by ISP, VPN, proxy or whatever).

## VPN connectivity issues

If you are using a VPN on Windows host and have WSL connectivity issues, please consider using [WSL VPNkit](https://github.com/sakai135/wsl-vpnkit).

After following setup instructions to import vpnkit WSL distro, execute `wsl.exe -d wsl-vpnkit --cd /app service wsl-vpnkit start` and network should work.

## Ruby GPG keys import failed

If that fails, check your firewall settings if hkp:// protocol is allowed, or try to force port 80 by adding to `ansible/vars/overrides.yml`:

```yaml
rvm1_gpg_key_server: 'hkp://keys.openpgp.org:80'

# The GPG alternative key servers
rvm1_gpg_key_servers:
  - '{{ rvm1_gpg_key_server }}'
  - hkp://pgp.mit.edu:80
  - hkp://keyserver.pgp.com:80
  - hkp://keyserver.ubuntu.com:80
```

## Unable to get https endpoints

If you are having problems with connecting to SSL sites (like `curl https://get.rvm.io` or `curl https://github.com`) with no Certificate Authority error, that means you are behind some proxy (corporate or ISP) and have external Certifitate Authority Chain. You would need to import this chain from Windows to WSL. See [this Github comment](https://github.com/microsoft/WSL/issues/3161#issuecomment-945384911) on how to import it.
