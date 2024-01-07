# Versions management

After every ansible run, it prints all the versions which were installed/updated.

Also, it saves/updates them in `./current-versions.yml`. This file is added to `.gitignore`, so it is not versioned.

<details>
  <summary><b>Example:</b> Versions output</summary>
  <div align="center">
    <img src="/versions.png" />
  </div>
</details>
<br />

If you use `master` branch (which has all the versions set to `latest`), and you want stability for particular component, you can copy any of those outputs and add them to your `ansible/vars/overrides.yml` so this version will be used for any subsequent runs.

