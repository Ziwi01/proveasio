# Manual

1. If WSL is not installed, install it from an administrator `cmd` or PowerShell with `wsl --install`. See the [Microsoft docs](https://learn.microsoft.com/en-us/windows/wsl/install#install-wsl-command).

2. Install Ubuntu 24.04 or 26.04. From PowerShell (as Administrator):

   ```powershell
   wsl.exe --list --online             # shows the exact distribution names
   wsl.exe --install -d Ubuntu-24.04   # or Ubuntu-26.04
   wsl.exe --set-default Ubuntu-24.04
   ```

3. Check that `systemd` runs in the distribution: `systemctl is-system-running` should print `running` or `degraded`. New Ubuntu installs enable it by default. If it does not, add these lines to `/etc/wsl.conf`:

   ```ini
   [boot]
   systemd=true
   ```

   Then restart WSL from Windows with `wsl --shutdown`. See [systemd support in WSL](https://learn.microsoft.com/en-us/windows/wsl/systemd).

4. (optional) Install a [Nerd Font](https://www.nerdfonts.com/font-downloads). The FiraCode Nerd Font I use is in `ansible/roles/windows/files/fonts`; the [latest FiraCode release](https://github.com/ryanoasis/nerd-fonts/releases/latest) has all variants.

5. (optional) Install [Windows Terminal](https://github.com/microsoft/terminal) and set the font of its Ubuntu profile to the Nerd Font (Settings → Ubuntu → Appearance → Font face). `ansible/roles/windows/templates/settings.json.j2` has my settings for reference.

Any terminal and any Nerd Font work; steps 4 and 5 are only my suggestion. Fonts differ in how many icons they include, and FiraCode has a lot. Without a Nerd Font, turn the icons off with [`nerd_fonts: false`](../customization/10-variables.md#no-nerd-font).

Then continue with [Installation](../installation.md).
