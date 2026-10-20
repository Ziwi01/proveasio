---
sidebar_position: 5
---

# Download

:::tip[Docker]
Instead of downloading the repository and running the installation, you can try the Docker version, see [Docker image](./docker/10-build.md).
:::

The easiest way to start is to clone the repository:

```shell
git clone https://github.com/Ziwi01/proveasio.git ~/proveasio
```

- `master` holds the tested changes from `develop`: documentation, new tools, fixes. All versions default to `latest`. CI runs the full installation on this branch every week.
- `develop` holds all recent changes, sometimes including features still being tested. Use it to try what is coming next.
- Tags match the [GitHub releases](https://github.com/Ziwi01/proveasio/releases). They were stable when released, but the `latest` versions they install change over time.

:::tip
Check out `master`, then create your own branch (`git checkout -b my-branch`).

Pin versions in `ansible/vars/overrides.yml`. The tools and their version keys are in `ansible/roles/software/vars/main.yml`, and `current-versions.yml` in the repository root lists the versions your last run installed.

A branch of your own also makes other [customizations](../category/customizations) easy to keep.
:::

## Releases

The project publishes [releases](https://github.com/Ziwi01/proveasio/releases) from time to time.

You can download a release and unpack it. You then lose the easy way to track your changes and to merge new updates, so cloning the repository is recommended.

## Updating

On `master` or `develop`, run `git pull` to get the latest changes. If you changed files locally, you may need to resolve conflicts.

On your own branch, run `git fetch` and merge `master` or `develop` into it (on your branch: `git merge origin/master`).

With a release tarball, you have to download the new version and move your changes into it by hand.

Then run the playbook again, see [Installation](./installation.md).
