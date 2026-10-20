# Tmux

[Tmux](https://github.com/tmux/tmux) is a terminal multiplexer: it runs several terminals in panes (splits) and windows, and keeps them running when you detach. Because it runs on top of the terminal, some features work on remote (SSH) sessions too, like extracting text from the buffer (see below).

The tmux prefix is <kbd>Ctrl</kbd>+<kbd>b</kbd>, written `<C-b>` below. Press it, release it, then press the key of the command.

## Basic commands

- `tmux new` - start a new session (auto-numbered sessions are named `Default`, `Default-1`, ...). `tmux new -s <name>` names it, `tmux attach` reattaches.
- `<C-b>d` - detach; the session keeps running
- `<C-b>?` - help, list all available shortcuts
- `<C-b>c` - new window
- `<C-b>%` - split side by side (the new pane opens in the current directory)
- `<C-b>"` - split top and bottom
- `<C-b><arrows>` - move between panes. *Easier alternative*: `<Alt>+<arrows>` (includes moving between Vim splits)
- `<C-b>` then <kbd>Ctrl</kbd>+arrows - resize panes
- `<C-b>z` - zoom the current pane in and out
- `<C-b>x`, then `y` - kill pane
- `<C-b>n` - next window
- `<C-b>p` - previous window
- `<C-b>l` - last used window
- `<C-b>,` - rename the window

<details>
  <summary><b>Example:</b> Tmux window</summary>

![tmux overview](/assets/tmux-overview.png)

</details>

## Manage sessions

Uses:

- [tmuxp](https://github.com/tmux-python/tmuxp)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)

There are two ways to manage your sessions:

- simple save/restore session
- user-defined multiple sessions with own layouts, commands, etc.

To save your sessions (windows, splits, running Neovim instances), press `<C-b><C-s>`. To restore them, for example after a reboot, press `<C-b><C-r>`. Neovim sessions are restored only until the system restarts (or WSL shuts down).

You can also define sessions in YAML: windows, panes, start directories and commands. Define one per project and load it when you need it.

Session files are `*.yaml` files in `~/.tmuxp`. When that directory is empty, Proveasio creates `default_session.yaml` there as an example. Once you add files of your own (or delete the example), it is not created again.

```yaml title="~/.tmuxp/myproject.yaml"
session_name: myproject
start_directory: ~/projects/myproject
windows:
  - window_name: code
    panes:
      - nvim
  - window_name: shell
    layout: even-horizontal
    panes:
      - git status
      - null
```

See [`tmuxp`](https://github.com/tmux-python/tmuxp) for details on how to define sessions with multiple windows, panes etc.

Run `lp` (load project) in the shell to pick a session file with fzf and load it. `tmuxp load <file>` does the same without the picker.

To switch between running sessions, press `<C-b>s`.

## Copy mode

Enter copy mode with `<C-b>[` and move around with the arrow keys or vi keys (scrolling up with the mouse wheel also enters it). Copy mode uses vi bindings: `/` and `?` search.

Select text with `v` (or <kbd>Space</kbd>) and copy it with `y` (or <kbd>Enter</kbd>). Selecting with the mouse copies too. Paste the last copied text with `<C-b>]`.

:::tip
To select a rectangular block, press <kbd>Ctrl</kbd>+<kbd>v</kbd> before or after starting the selection with `v`.
:::

## Search back buffer

Uses: [tmux-fuzzback](https://github.com/roosta/tmux-fuzzback)

tmux keeps the last 50,000 lines of each pane.

Press `<C-b><C-f>` to search that history in an fzf popup. Picking a line jumps there in copy mode, so you can read around it or copy it (see above).

## Extract from buffer

Uses: [extrakto](https://github.com/laktak/extrakto)

extrakto picks words, paths, URLs or lines from the pane's text with fzf. Press `<C-b><Tab>` to open it.

The pane can be a remote SSH session, so this is a quick way to grab an IP address, a hostname or a path without the mouse.

It has several modes; switch between them with <kbd>Ctrl</kbd>+<kbd>f</kbd>:

- `word`: will divide the search in a single words
- `all`: will show common types if found (urls, paths, quotes)
- `line`: will show the whole line(s)

Insert the selection into the command line with <kbd>Tab</kbd>, or copy it to the clipboard with <kbd>Enter</kbd>.

## Switching panes

`<C-b>` and an arrow key moves between panes. For a short time after that, arrow keys keep switching panes without the prefix; after it, they work normally again.

The easier way: <kbd>Alt</kbd>+arrows (no prefix) moves between tmux panes **and** Neovim splits, as if they were one layout.

## Synchronize panes

To type the same commands into all panes of a window (for example on several SSH servers at once), press `<C-b>:` and enter `setw synchronize-panes on`. Turn it off with `setw synchronize-panes off`.

## Track AI coding agents (ccmux)

Uses: [ccmux](https://github.com/epilande/ccmux)

When you run multiple AI coding agents (`opencode`, Claude Code, Codex and others) across tmux panes, it gets hard to track which one is idle, working, or waiting for you. [ccmux](https://github.com/epilande/ccmux) discovers the agents already running in your panes and shows their live state, so you can jump straight to the one that needs attention.

It works with your existing workflow - you don't change how you launch agents. `opencode` integration is set up automatically (`ccmux setup --agent opencode` installs a plugin under `~/.config/opencode/plugins/`; check it with `ccmux setup --status`), so its sessions report their state out of the box.

The ccmux daemon tracks the agents and sends notifications. It is started together with the tmux server (and again on every `tmux source-file ~/.tmux.conf`), so it runs as soon as tmux does. Check it with `ccmux daemon status`.

The following keybindings are configured:

- `<C-b><C-p>` - open the ccmux **picker** in a centered popup (closes and drops you into the selected agent's pane)
- `<Alt>p` - open the ccmux picker from any pane (no prefix)
- `<C-b><C-o>` - toggle the ccmux **sidebar** (an always-visible agent status rail) in every window
- `<Alt>o` - toggle the ccmux sidebar from any pane (no prefix)
- `<C-b><C-i>` - open the picker in persistent **dashboard** mode (stays open after switching)

:::tip[Desktop notifications]
Notifications are enabled by default and fire when an agent starts waiting for you or finishes. On WSL they are bridged to native Windows toast notifications through [wsl-notify-send](https://github.com/stuartleeks/wsl-notify-send). You can tweak or disable them in `~/.config/ccmux/ccmux.json` (see the [config role](../main/roles/config)), or test the setup with `ccmux notify`.
:::

You can list all commands with `ccmux --help` and see the full feature set in the [ccmux README](https://github.com/epilande/ccmux).

