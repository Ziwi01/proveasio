---
sidebar_position: 4
---

# Requirements

When using either plain Ubuntu or WSL2:

- Any terminal using any iconic font (like [Nerd Fonts](https://www.nerdfonts.com/)) - there is a sample font (FiraCode Nerd Font) in this repository in `ansible/roles/windows/files/fonts`

If using Windows with WSL2 Ubuntu also ensure:

- Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- WSL2 installed/enabled (version 0.67.6 and above)
- Ubuntu 22.04 installed
- `systemd` enabled for installed Ubuntu distribution

:::note
If running on WSL2, verify you have correct Windows setup by going through [Windows manual setup](./windows/manual)
:::
