---
sidebar_position: 3
---

# Download

Easiest way to start is to clone the repository:

```
git clone https://github.com/Ziwi01/proveasio.git ~/proveasio
```

- `master` branch contains rather stable updates from develop (documentation, new tested plugins, fixes). By default, versions are set to `latest`. This branch is tested weekly to ensure the installation works as expected.
- `develop` branch. It contains all recent changes/features **and** sometimes in-progress testing features. Also documentation updates and so on. Use it if you want to see what's cookin.
- tags are equivalent of the releases published in Github. They should be stable, but there is no guarantee after some time.

:::tip
I recommend checking out `master` branch, then create your own branch (`git checkout -b my-branch`).

You can then override some versions in `ansible/vars/overrides.yml` and set them to `latest` if you want to keep some of the software fresh. See `.latest-versions.yml` to see all available versions to override.

Also, this approach makes it easy to do other [customizations](../category/customizations)
:::

## Releases

This project publishes [releases](https://github.com/Ziwi01/proveasio/releases) (sometimes).

You can download newest release, unpack it and use it. However, you loose the ability to track your changes and easily update/merge new incoming updates so it is recommended to use git repository/own branch.

I personally recommend cloning the repository instead of downloading the release.

## Updating

If you use `master` or `develop` branch, just run `git pull` to have the latest changes. Be aware that your local changes might conflict, so you will need t o resolve that

If you use your own branch, run `git fetch` and then merge `master` or `develop` to your branch (beeing on our branch: `git merge master`)

If using the release tarball, you need to download/checkout new version and migrate your previous changes to new structure. Not fun.
