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
