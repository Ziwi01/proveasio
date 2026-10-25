# Automated

:::danger
This is experimental and not tested thoroughly. Use it at your own risk, and please report how it went.
:::

This automates the [Windows manual setup](./10-manual.md) and installs Windows software I commonly use. Ansible runs from WSL and configures Windows over WinRM. It finds Windows by itself with either WSL networking mode: at `127.0.0.1` with mirrored networking, and at the default gateway with NAT (the default).

## prepare-windows.ps1

Download this repository somewhere on Windows. The script `prepare-windows.ps1`:

- installs WSL with Ubuntu 24.04,
- enables WinRM with CredSSP authentication, so Ansible in WSL can configure Windows,
- installs the [Chocolatey](https://chocolatey.org/) package manager.

Run it as Administrator from `cmd` or PowerShell.

## prepare-ubuntu.sh

Then open Ubuntu and [download](../download.md) the repository there as well.

Check that the distribution runs `systemd`, see [Requirements](../requirements.md#wsl2).

In the repository root, run `sudo ./prepare-ubuntu.sh`. It updates the system and installs Python and Ansible.

## setup-windows.yml

This playbook sets up Windows.

1. Note your Windows user name. You pass it as `win_username` when you run the playbook (see below).
2. Read `ansible/roles/windows/tasks/main.yml` and the other task files in that directory to see what they change:
    1. `common.yml` installs common software, like 7-Zip, Firefox and Bitwarden.
    2. `dev.yml` installs Git, Windows Terminal, IntelliJ, VS Code, Docker Desktop and Postman.
    3. `context_menu.yml` removes the context menu entries some of these packages add.
    4. `terminal.yml` installs the FiraCode font and applies settings to Windows Terminal.
    5. `entertainment.yml` installs Spotify, VLC, Discord and similar.

To skip whole sections, set them to `false` in `bundle_include`. Because of the problem described below, pass it with `-e` as JSON, for example `-e '{"bundle_include": {"common": true, "dev": true, "terminal": true, "entertainment": false, "context_menu": true}}'`. The defaults are:

```yaml
bundle_include:
  common: true
  dev: true
  terminal: true
  entertainment: true
  context_menu: true
```

:::tip
To skip single packages instead of a whole section, remove them from the task file in your own branch (for example `ansible/roles/windows/tasks/entertainment.yml`).
:::

Then run, from the `ansible/` directory:

```shell
ansible-playbook -i inventory.yml setup-windows.yml -k -e win_username=<your-windows-user>
```

`-k` asks for your Windows password.

:::warning[`win_username` in overrides.yml has no effect]
`setup-windows.yml` loads `ansible/vars/overrides.yml` with a lower precedence than the role's own variables, so a `win_username` set there is ignored and the default (`Jimmy`) is used. Pass it with `-e` as above until this is fixed. The same applies to every other `windows` role variable, including `bundle_include`.
:::

If the run hangs for more than a few minutes, stop it with <kbd>Ctrl</kbd>+<kbd>c</kbd> and run it again. Chocolatey installations started from Ansible in WSL sometimes get stuck.

