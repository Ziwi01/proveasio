# Tmux

[Tmux](https://github.com/tmux/tmux) is a terminal multiplexer, which helps working with mulitple terminals, using panes (splits) and windows. Because it is running on top of the terminal itself, there some neat features which will work even during remote sessions (ssh), like buffer text extract (see below).

TMUX prefix is set to `<C-b>` (ctrl+b) - everything after that is a tmux shortcut/command.

## Basic commands

- `tmux new` - start new TMUX session. Tip: Start with this command whenever you start new terminal :)
- `<C-b>?` - help, list all available shortcuts
- `<C-b>c` - new window
- `<C-b>%` - split window vertically
- `<C-b>"` - split window horizontally
- `<C-b><arrows>` - move between panes. *Easier alternative*: `<Alt>+<arrows>` (includes moving between Vim splits)
- `<C-b><C+<arrows>>` - resize panes
- `<C-b>xy` - kill pane
- `<C-b>n` - next window
- `<C-b>l` - last window
- `<C-b>p` - previous window (in order)

<details>
  <summary><b>Example:</b> Tmux window</summary>
  <div align="center">
    <img src="https://ziwi01.github.io/proveasio/assets/tmux-overview.png" />
  </div>
</details>

## Manage sessions

Uses: 
- [tmuxp](https://github.com/tmux-python/tmuxp)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)

There are two ways to manage you session(s):

- simple save/restore session
- user-defined multiple sessions with own layouts, commands, etc.

For the first option - you can simply save your current session (opened windows, splits, Vim instances) using `<C-b><C-s>`. To restore it, run `<C-b><C-r>`. Vim instances are persistent only until system restart (or WSL shutdown).

You can also have multiple sessions, configured in YAML format, where you define open windows, panes, commands etc. You can define one for each project and easily switch/attach to them.

Sessions are stored in `${HOME}/.tmuxp` directory in a `*.yaml` file. See [`tmuxp`](https://github.com/tmux-python/tmuxp) how to define session.

After you define you session(s), you can run `lp` from shell, which will invoke a picker for your sessions. You can either attach it to our current session or create a new one.

To jump between sessions, use `<C-b>s`.

## Copy mode

You can enter a copy mode from Tmux buffer using `<C-b><C-]>` - move around with arrow keys.

In copy mode you can select text with `v` (or `<Space>`) and copy selected text with `y` (or `<Enter>`). It will be copied to your clipboard, so you can paste it normally with `<C-v>` or directly from Tmux buffer using `<C-b><C-]>` (that way you can copy something else to the actual clipboard instead).

:::tip
To select a block of text (vertical selection), before (or after) selecting text with `<v>` just hit `<Alt>v`.
:::

## Search back buffer

Uses: [tmux-fuzzback](https://github.com/roosta/tmux-fuzzback)

During Tmux session, it saves a pretty big buffer (max 14k lines) for everything that was printed to terminal.

You can go back somewhere in the buffer with `<C-b><C-f>`, which will pop up a window with fuzzy finder, where you can search for text. After you go back, you can either examine the contents, or copy anything - see copy mode above.

## Extract from buffer

Uses: [extrakto](https://github.com/laktak/extrakto)

There is this awesome plugin, which can directly extract information from Tmux buffer.

Running `<C-b><TAB>` will open a fuzzy search to extract something.

This can be VERY useful, as the buffer includes also remote SSH sessions. It comes in handy to fill out commands, get the IP, hostname, or any other information, which you would need to copy with mouse or write down.

It has three modes (you can change them with `<C-f>`):

- `word`: will divide the search in a single words
- `all`: will show common types if found (urls, paths, quotes)
- `line`: will show the whole line(s)

After selecting what you want to get, you can either directly put it into terminal with `<TAB>` or just copy it to clipboard with `<Enter>`

## Switching panes

By default, you can move around panes with `<C-b><arrows>`. There is a maximum delay for this to work (between hitting `<C-b>` and arrow key), so after moving to the pane, arrows will work normally after a second (not switching between panes anymore).

**However!** You can use a very handy `<Alt>+<arrows>` (without `<C-b>` prefix) to jump between panes **and** Vim windows/splits.

## Synchronize panes

Sometimes you need to enter the same commands in all you panes (like after logging to two ssh servers, need to run the same things).

You can turn on panes synchronizations with: `<C-b>:` and writing `setw synchronize-panes on`

