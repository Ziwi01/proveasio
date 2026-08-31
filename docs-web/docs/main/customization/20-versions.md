# Versions management

:::warning[Latest defaults]
Please note that all software versions since 2.0.0 are set to 'latest'.

If you need to have particular software version static, add it to [overrides.yml](./variables)

This change ensure seamless support for both Ubuntu 22 and 24
:::

After every ansible run, it prints all the versions which were installed/updated.

Also, it saves/updates them in `./current-versions.yml`. This file is added to `.gitignore`, so it is not versioned.

<details>
  <summary><b>Example:</b> Versions output</summary>
  <div align="center">
    <img src="https://ziwi01.github.io/proveasio/assets/versions.png" />
  </div>
</details>
<br />

If you use `master` branch (which has all the versions set to `latest`), and you want stability for particular component, you can copy any of those outputs and add them to your `ansible/vars/overrides.yml` so this version will be used for any subsequent runs.

:::note[Overriding one version in a group]
For overriding only one package in a group (e.g `github_packages`), you need to set your desired version, but all the others need to be set to `latest`. In some cases `latest` can be something different (like `master` or `main`). You can find the reference in `latest-versions.yml`.

Please also note, that not every software version supports `latest`. Some need to be set explicitly. See `ansible/roles/software/vars/main.yml` for all static vars.
:::

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

