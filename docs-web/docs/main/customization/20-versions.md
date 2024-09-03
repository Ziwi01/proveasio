# Versions management

:::warning[Latest defaults]
Please note that all software versions since 2.0.0 are set to 'latest', including `master` branch.

If you need to have particular software version static, add it to [overrides.yml](./10-variables)

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
