# Manual

0. If you don't have WSL installed, you need to install it with: `wsl --install` executed from administrative `cmd` or `powershell` terminal. See [windows docs](https://learn.microsoft.com/en-us/windows/wsl/install#install-wsl-command)

1. Install Ubuntu 22.04, execute from Powershell (Administrator):

   ```shell
   wsl.exe --install -d 'Ubuntu-22.04'
   wsl.exe --set-default 'Ubuntu-22.04'
   ```

   For details, see [Microsoft WSL installation docs](https://docs.microsoft.com/en-us/windows/wsl/install)

2. Enable `systemd` in your distribution: Add these lines to `/etc/wsl.conf`:

   ```
   [boot]
   systemd=true
   ```

   Then restart WSL from Windows `cmd`: `wsl --shutdown`. After next login it should have systemd configured. For more information see [windows docs for systemd](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/)

3. (optionally) Install FiraCode nerd fonts (the ones I use are in `ansible/roles/windows/files/fonts`, if you need, download [all FiraCode Nerd fonts](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip) and use whichever you want) 
4. (optionally) Install [Microsoft Terminal](https://github.com/microsoft/terminal) and configure this Terminals Ubuntu profile with `FiraCode NF` nerd font (Settings -> Ubuntu-22.04 -> Appearance -> Font Face). You can check `ansible/roles/windows/templates/settings.json.j2` for settings reference with useful overrides.

In points #3 and #4 specific font+terminal duo is just a suggestion (I use them personally) - you can use any terminal of your choice and any font supporting iconic fonts (like [Nerd Fonts](https://www.nerdfonts.com/) - please note that not all fonts have the same amount of glyphs/icons. FiraCode has lots of them. Remember to configure you terminal to use your font!

Thats it, you can move to [Installation](../installation)

