# Tmux

[TMUX](https://github.com/tmux/tmux) is a terminal multiplexer. It enables a number of terminals to be created, accessed, and controlled from a single screen. tmux may be detached from a screen and continue running in the background, then later reattached. Basic usage is described in [TMUX usage section](../../usage/tmux)

<details>
  <summary><b>Example:</b> TMUX splits</summary>
  <div align="center">
    <img src="https://ziwi01.github.io/proveasio/assets/tmux-overview.png" />
  </div>
</details>

Custom modifications in `roles/config/files/tmux.conf` include:

- custom theme
- declarative sessions (alternatively: save/restore session)
- search back tmux buffer with FZF
- extract text from tmux buffer with FZF
- mouse support
- prevent deselect+auto scroll on mouse selection copy (very annoying..)
- seamless navigation between TMUX splits and VIM splits
