# Versions management

:::info[Latest by default]
Since Proveasio 2.0.0, every tool version defaults to `latest`. To keep a tool on a particular version, pin it in [overrides.yml](./10-variables.md).
:::

After every ansible run, it prints all the versions which were installed/updated.

It also writes them to `current-versions.yml` in the repository root. The file is in `.gitignore`. It is a record of what was installed on this machine; the playbook never reads it, and it keeps keys of tools you no longer install. Do not edit it.

<details>
  <summary><b>Example:</b> Versions output</summary>

![versions](/assets/versions.png)

</details>
<br />

To keep a component stable, copy its version from that output into `ansible/vars/overrides.yml`. Later runs then install that version. Copy only the versions you want to pin, not the whole file.

::::note[Overriding one version in a group]
You only need to set the packages you actually want to pin. Version catalogs
(`github_packages`, `pip_packages`, `docker_apt_packages`) in your
`ansible/vars/overrides.yml` are **merged on top of the defaults**, so any
package you don't mention keeps its default (usually `latest`). For example:

```yaml
github_packages:
  tmux: "3.7c"
  neovim: "0.12.5"
```

This pins only `tmux` and `neovim`; every other tool — including ones added by
newer Proveasio releases (e.g. `hunk`, `ccmux`) — still resolves normally. You
no longer need to copy the whole catalog and set everything else to `latest`.

:::tip[Upgrading from older Proveasio]
Earlier versions replaced the whole catalog, so an `overrides.yml` copied from
an old `current-versions.yml` could break newer runs with errors like
`object of type 'dict' has no attribute 'hunk'`. With merging this no longer
happens; you can safely trim your `overrides.yml` down to just the pins you care
about.
:::

Not every tool supports `latest`. SDKMAN candidates, Ruby gems and a few others need an explicit version. See `ansible/roles/software/vars/main.yml`.
::::

## opencode v1 and v2

`latest` installs **opencode v2**. v2 is not published as GitHub releases, so
its version comes from the opencode.ai update service and the binary from
`opencode.ai/files/bin` (this needs no GitHub API call). Pinning a v2 version
works the same way.

To stay on **v1**, pin a 1.x version. It is then downloaded from GitHub releases:

```yaml
github_packages:
  opencode: "1.18.34"
```

v2 reads and migrates the v1 sessions in `~/.local/share/opencode/opencode.db`.
[`ocs`](../../usage/20-terminal.md#browse-opencode-sessions-with-ocs) works with
both.

## GitHub API rate limits

With versions set to `latest`, each run queries the GitHub API to resolve the newest release for ~30+ tools. **Unauthenticated** GitHub API requests are limited to **60 per hour** (shared across everyone on your public IP), so running the playbook a few times in a row can exhaust it and fail with:

```
Target version for `<app>` is empty. The GitHub API call returned nothing,
most likely because the unauthenticated rate limit (60 requests/hour ...) was exceeded.
```

Authenticating raises the limit to **5000 requests/hour**. Proveasio picks up a token automatically from the first of these that is set:

1. the `github_api_token` variable (e.g. in `ansible/vars/overrides.yml`)
2. the `GITHUB_TOKEN` or `GH_TOKEN` environment variable
3. `gh auth token` — i.e. after a one-time [`gh auth login`](https://cli.github.com/manual/gh_auth_login)

The easiest option (since `gh` is installed by Proveasio) is:

```shell
gh auth login
```

Alternatively, pass a [personal access token](https://github.com/settings/tokens) (a classic token with **no scopes**, or a fine-grained token with **public read** access, is enough — resolving public release versions needs no permissions):

```shell
# one-off, for a single run
GITHUB_TOKEN=ghp_xxx ansible-playbook -i inventory.yml setup-ubuntu.yml -K
```

or persist it in `ansible/vars/overrides.yml`:

```yaml
github_api_token: ghp_xxx
```

:::note
Authentication is entirely optional — with no token found, the queries run unauthenticated exactly as before. You can check your current limit any time with `curl -s https://api.github.com/rate_limit`.
:::

