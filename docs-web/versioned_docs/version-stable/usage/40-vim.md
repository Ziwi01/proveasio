# Neovim

Neovim is the default editor (`EDITOR`), aliased as `vim`. The default config is [Ziwi01/astronvim](https://github.com/Ziwi01/astronvim), built on the [AstroNvim](https://docs.astronvim.com) distribution. This page describes that config.

## Changing the Neovim config

You can use your own config, either a completely different one or a fork of the default. These variables select it:

```yaml
neovim_config_url: https://github.com/Ziwi01/astronvim.git
neovim_config_version: main
neovim_config_appname: astronvim
```

The config is cloned into `~/.config/<neovim_config_appname>`, and `NVIM_APPNAME` is set to the same name, so it does not collide with a config in `~/.config/nvim`. To use a local directory instead of a repository, see [Own config files](../main/customization/30-config-files.md).

## Basics

The leader key is <kbd>Space</kbd>, written `<Space>` below. Most shortcuts start with it.

Press `<Space>` (or any other key that starts a mapping) and wait: [which-key](https://github.com/folke/which-key.nvim) shows every mapping that continues from there. Search all mappings with `<Space>fk`.

Language support (language servers, formatters, linters, Treesitter parsers) comes from AstroNvim's language packs for Ansible, Bash, Docker, Go, Helm, Java, JSON, Lua, Markdown, Python, Ruby, Terraform and YAML. [Mason](https://github.com/mason-org/mason.nvim) installs the servers on the first start; check them with `:Mason`.

### Plugins

The full list is in [community.lua](https://github.com/Ziwi01/astronvim/blob/main/lua/community.lua) (plugins from the [AstroNvim community repository](https://github.com/AstroNvim/astrocommunity)) and the [plugins directory](https://github.com/Ziwi01/astronvim/tree/main/lua/plugins). Some of the most useful:

| Plugin | What it does |
|---|---|
| [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) | File browser (`<Space>e`) |
| [snacks.nvim](https://github.com/folke/snacks.nvim) picker | Find files, text, buffers, keymaps (`<Space>f…`) |
| [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim), [vim-fugitive](https://github.com/tpope/vim-fugitive), [diffview.nvim](https://github.com/sindrets/diffview.nvim), [gv.vim](https://github.com/junegunn/gv.vim), [git-blame.nvim](https://github.com/f-person/git-blame.nvim) | Git, see [Git](#git) |
| [codediff.nvim](https://github.com/esmuellert/codediff.nvim), [vim-dirdiff](https://github.com/will133/vim-dirdiff) | Diff files and directories |
| [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim), [ferret](https://github.com/wincent/ferret) | Search and replace across files |
| [leap.nvim](https://github.com/ggandor/leap.nvim) | Jump anywhere on the screen (`s`, `S`) |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Move between Neovim splits and tmux panes with <kbd>Alt</kbd>+arrows |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | Diagnostics, references and quickfix lists (`<Space>x…`) |
| [nvim-bqf](https://github.com/kevinhwang91/nvim-bqf) | Better quickfix window with previews |
| [goto-preview](https://github.com/rmagatti/goto-preview) | Show a definition in a floating window (`gpd`) instead of jumping to it |
| [vim-easy-align](https://github.com/junegunn/vim-easy-align) | Align text on a character |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | Saves files automatically |
| [vim-illuminate](https://github.com/RRethy/vim-illuminate) | Highlights other uses of the word under the cursor |
| [telescope-zoxide](https://github.com/jvgrootveld/telescope-zoxide) | Jump to a zoxide directory (`<Space>z`) |
| [opencode.nvim](https://github.com/NickvanDyke/opencode.nvim), [CodeCompanion](https://github.com/olimorris/codecompanion.nvim), [copilot.lua](https://github.com/zbirenbaum/copilot.lua) | AI assistants, see [AI agents](./80-ai.md#ai-in-neovim) |

## Files and buffers

### File browser

Uses: [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim)

Toggle the file browser with `<Space>e`. Its root is the project of the current file (the nearest parent directory with `.git`, `node_modules` and similar).

Move the focus between the tree and the file with <kbd>Alt</kbd>+arrows.

Useful keys:

- `?`: help
- <kbd>Enter</kbd>: open a file, expand or collapse a directory
- `.`: make the directory under the cursor the root
- <kbd>Backspace</kbd>: go up one directory
- `P`: preview the file without focusing it
- `z`: collapse all nodes
- `H`: show or hide hidden files
- `a`, `d`, `r`, `c`, `m`: add, delete, rename, copy, move
- `s`: open the file in a vertical split. To compare two files, open the second one in a split, close the tree (`<Space>e`) and run `:windo diffthis`
- `gm`: mark the directory under the cursor as the diff source (press again to unmark). See [Diff directories](#diff-directories)
- `gd`: diff the directory under the cursor against the marked source

### Find files and text

- `<Space>ff`: find files in the project
- `<Space>fF`: find files, including hidden and ignored ones
- `<Space>fw`: search text in the project (live grep with ripgrep); `<Space>fW` includes hidden files
- `<Space>fo`: recently opened files
- `<Space>fb`: open buffers
- `<Space>fk`: keymaps
- `<Space>z`: jump to a directory known to [zoxide](./20-terminal.md#traverse-directories-with-zoxide)

In a picker, <kbd>Ctrl</kbd>+<kbd>v</kbd> opens the selection in a vertical split and <kbd>Ctrl</kbd>+<kbd>s</kbd> in a horizontal one.

### Switch buffers

Open files are shown as tabs at the top. Move between them with `H` (left) and `L` (right), or pick one with `<Space>fb`.

<kbd>Ctrl</kbd>+<kbd>6</kbd> jumps back to the previous buffer.

### Close buffers

- `<Space>c`: close the current buffer
- `<Space>bc`: close all buffers except the current one
- `<Space>bl` / `<Space>br`: close all buffers to the left / right
- `<Space>bD`: pick a buffer to close (the tabs show letters; press one)

### Splits

Move between splits, and on to tmux panes, with <kbd>Alt</kbd>+arrows. Resize splits with <kbd>Ctrl</kbd>+arrows.

## Diffs

### Diff an open buffer with the current file

1. `<Space>fb`: find the other buffer.
1. <kbd>Ctrl</kbd>+<kbd>v</kbd>: open it in a vertical split.
1. Close neo-tree if it is open (`<Space>e`).
1. `:windo diffthis`: start the diff.

`:diffoff` stops the diff; closing either buffer (`<Space>c`) also ends it.

In the diff:

- `]c` / `[c`: next / previous change
- `:diffput` / `:diffget`: put this change into the other window / get it from there

### Diff directories

There are two ways to diff two directories: from the [file browser](#file-browser) with CodeDiff (recommended), or with DirDiff.

#### From neo-tree (CodeDiff)

Uses: [CodeDiff](https://github.com/esmuellert/codediff.nvim)

1. Open neo-tree (`<Space>e`) and go to the first directory.
1. With the cursor on it, press `gm` to mark it as the **diff source**. A dimmed `(diff source)` tag appears next to it, like the `(copied)`/`(cut)` markers.
1. Move to the second directory and press `gd`.

A CodeDiff explorer lists every file that differs between the two directories. Press <kbd>Enter</kbd> on a file to open its side-by-side diff.

- `gm` toggles the mark: press it again on the marked directory to unmark it.
- `gd` clears the mark after opening the diff.
- Both work only on directories. On a file, or `gd` with no source marked, they show a warning.

#### With DirDiff

Uses: [DirDiff](https://github.com/will133/vim-dirdiff)

Outside the neo-tree window, run `:DirDiff <dir1> <dir2>`.

<details>
  <summary><b>Example:</b> Diff directories</summary>

![vim dirdiff](/assets/vim-dirdiff.png)

</details>
<br />

In the DirDiff view:

- `x`: exclude files matching a pattern (for example `.git`), then `u` to update the diff
- <kbd>Enter</kbd>: open the diff of a file
- `s`: sync the changes; DirDiff asks which side to keep (`A` or `B`)
- to sync several files at once, select them with `V`, then press `s`

## Search and replace

### In the current file

Use Neovim's substitute command:

```vim
:%s/<pattern>/<replacement>/gc
```

`g` replaces every match in a line, `c` asks before each one (`y`/`n`/`a`/`q`). Select lines with `V` first and press `:` to limit it to the selection. The pattern is a Vim regex: escape `(`, `)`, `{` and `+` to use them as groups and quantifiers, or start the pattern with `\v` to make them special without escaping.

### In the project: grug-far

Uses: [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim)

grug-far opens a buffer with fields for the search, the replacement, file filters and flags, and shows the matches live below them (it uses ripgrep).

- `<Space>ss`: search and replace in the whole project
- `<Space>sf`: in the current file
- `<Space>se`: in files with the current file's extension
- `<Space>sw`: replace the word under the cursor
- `<Space>s` in visual mode: search for the selection

Edit the fields like normal text. In the results, delete lines (`dd`) to leave those matches out. Press `,r` (`<localleader>r`) to replace and `g?` to see all keys. Close the buffer with `:q`.

### In the project: Ferret

Uses: [Ferret](https://github.com/wincent/ferret)

Ferret works on the quickfix list, which makes it handy when you want to review every match first, and for multiline replacements.

1. `<Space>sa`: search (`:Ack`). The matches go to the quickfix window, with a preview.
1. Remove the matches you want to keep unchanged with `dd`.
1. `<Space>sr`: replace in the remaining matches (`:Acks`).

`<Space>sA` searches for the word under the cursor. Ferret shows no preview of the result before replacing.

<details>
  <summary><b>Example:</b> Ferret search</summary>

![vim ferret](/assets/vim-ferret.png)

</details>
<br />

#### Multiline replace

With Ferret, `\r` in the replacement inserts a line break. For example, to turn:

```yaml
text:
  replace: under
```

into:

```yaml
text:
  replace: under
  newkey:
    newkey2: value
```

1. Search with `<Space>sa` for `(.*)(replace:\ under)`. The parentheses are regex groups; the space must be escaped.
2. Check the results and remove the ones you want to keep with `dd`.
3. Replace with `<Space>sr` and the replacement `\1\2\r\1newkey:\r\1  newkey2: value`. `\1` is the indentation (first group), `\2` the old key, and `\r` a line break.

## Moving around

### Jumping

Uses: [leap.nvim](https://github.com/ggandor/leap.nvim)

Press `s` (forward) or `S` (backward), then the first two characters of the place you want to go. Leap labels the matches; press the label to jump there.

For example, to jump to the word `Preview` further down, press `s`, `Pr` and the label shown there.

This works from insert mode too: press <kbd>Ctrl</kbd>+<kbd>o</kbd>, then `s` or `S`.

### Markdown

Uses: [mkdx](https://github.com/SidOfc/mkdx), [vim-table-mode](https://github.com/dhruvasagar/vim-table-mode), [markdown-plus.nvim](https://github.com/yousefhadder/markdown-plus.nvim)

- `]]` / `[[`: next / previous heading
- `:TableModeToggle`: format Markdown tables as you type
- the rendered view ([markview.nvim](https://github.com/OXY2DEV/markview.nvim)) shows headings, lists and tables formatted in the buffer

### Align text

Uses: [EasyAlign](https://github.com/junegunn/vim-easy-align)

Select the lines (for example with `V`) and run `:EasyAlign <char>`, for example `:EasyAlign =` or `:EasyAlign :`. More examples are in the [EasyAlign demo](https://github.com/junegunn/vim-easy-align?tab=readme-ov-file#demo).

### Run commands in tmux with Vimux

Uses: [Vimux](https://github.com/preservim/vimux)

Vimux runs shell commands in a tmux pane next to Neovim, for example tests or linters, without leaving the editor:

```vim
:VimuxRunCommand "ansible-lint"
:VimuxRunLastCommand
:VimuxCloseRunner
```

## Plugins and updates

Uses: [lazy.nvim](https://github.com/folke/lazy.nvim)

`:Lazy` opens the plugin manager. From there you can list, debug and update the plugins (`U` updates, `S` syncs). Update them from time to time.

The playbook updates the config and the plugins too. To update everything:

```shell
cd ~/proveasio/ansible
ansible-playbook -i inventory.yml setup-ubuntu.yml -K
```

or only Neovim and its config:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml -K --tags 'neovim,neovim-config'
```

Inside Neovim:

- `:AstroUpdate`: update AstroNvim and its plugins
- `:TSUpdate`: update the Treesitter parsers
- `:MasonUpdate`, then `:Mason` and `U`: update the language servers and tools

## Git

Uses:

- [tpope/fugitive](https://github.com/tpope/vim-fugitive)
- [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim)
- [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim)
- [f-person/git-blame.nvim](https://github.com/f-person/git-blame.nvim)
- [junegunn/gv](https://github.com/junegunn/gv.vim)

Git operations from inside Neovim:

### Diff current changes

To quickly preview current GIT changes, use fugitives `:Gvdiff` or `<Space>gd`. This will open a vertical split with all the local modifications.

On the left hand side (in the gutter column), there are indications if the chunk of code was added/removed/modified (+/-/!). You can preview those changes with `<Space>gp`

See more options by invoking whichkey for git operations: `<Space>g`

Those include:

- checkout branch/commit
- see git blame for this line
- go to next/previous hunk (change)
- reset hunk/buffer
- stage hunk

Diffview opens in separate tab, you can switch the tab(s) with `gt` (next tab) and `gT` (previous tab).

To close it, use `:DiffviewClose` or simply `:tabc`

### Diff another branch

To open a nice diff between your local and other branch, run `:DiffviewOpen <branch_name>`. You can hit `<TAB>` before entering branch name so it will list available branches.

In the diffview you can cycle through the diffs or apply a left-hand side for the selection with `X`.

See all options with `g?`

With diffview you can also browse a file history `:DiffviewFileHistory`.

To get changes only for this file, compared to another branch, you can use `:Gvdiff <branch>`

<details>
  <summary><b>Example:</b> Diffview another branch</summary>

![vim diffview](/assets/vim-diffview.png)

</details>

### Diff current file with different file on another branch

Sometimes you need to diff a file you're working on, with different branch, but on different branch the file has either different name, or is located elsewhere.

To do this, run:

`:Gvdiff <branch_name>:<relative_file_path>`

### Conflicts resolve

If you get any conflicts after the merge, you can run `:DiffviewOpen`, which will show conflicts at the top, and it will use a 3-way diff (3 windows split: with current branch changes, final output and with incoming branch changes).

For simple conflict resolve you can also use Lazygit (see [lazygit from Vim](#lazygit-from-vim))

### Checkout branch

Quickly checkout any branch with `<Space>gb`. Checkout to specific commit with `<Space>gc`. Checkout specific commit for current file with `<Space>gC`

Alternatively you can also checkout with `:G checkout <branch>`

### Git blame

Basically git blame shows as a 'shadowed' text when you cycle through lines in normal mode.

To see the blame for current line more visibly, you can use `<Space>gl`

To toggle git blame panel for all lines (so you can easily go to specified commit), use `:G blame`

From this view, you can run `g?` to show help of what you can do, like:

- `<Enter>`: close blame and jump to patch that added line
- `o`: jump to patch in horizontal split
- `O`: jump to patch in new tab
- `p`: jump to patch in preview window
- `-`: reblame at commit

### File history

To get all files history, enter `:DiffviewFileHistory`

To get history for currently opened file: `:DiffviewFileHistory %`

From this view you can:

- `<Enter>`: Open the diff
- `y`: copy the commit hash under the cursor
- `zR`: expand all folds (for all files view)
- `L`: show commit details

Diffview opens in separate tab, you can switch the tab(s) with `gt` (next tab) and `gT` (previous tab).

To close it, use `:DiffviewClose` or simply `:tabc`

Alternatively, you can use `:GV` to browse all commits (`<Enter>` to preview this commit in split). `:GV!` to list only commits affecting current file. Also, you can select lines in visual mode and run `:GV` to show only selected lines changes.

<details>
  <summary><b>Example:</b> File history with Diffview</summary>

![vim diffview history](/assets/vim-diffview-history.png)

</details>
<br />
<details>
  <summary><b>Example:</b> File history with GV</summary>

![vim gv](/assets/vim-gv.png)

</details>

### Reload file after checkout

Sometimes when you have a file opened in a buffer and you checkout to another branch (e.g from lazygit), the file does not get reloaded automatically. There are some indications that changes occurred (in left gutter panel in form of `|` sign).

To reload checked out changes, type `:e`.

### Lazygit from Vim

Uses: [Lazygit](https://github.com/jesseduffield/lazygit)

Basically this is a user interface for GIT. It makes complicated things very simple (like cherry-picking commits, interactive rebasing, creating patches, moving commits between branches and much more). Please see its documentation and a video for what it can do really.

Basic usage:

- invoke Lazygit from vim with `<Space>gg`.
- quit it with `q`
- browse through windows (Status/Files/Branches/Commits) with left and right arrows
- browse through tabs in particular window with `[` and `]` (like for branches windows it would cycle through Local Branches, Remotes, Tags)
- whenever you are in any view, hit `x` to get the available shortcuts/commands for current context. You can just `<Enter>` to execute them
- (branches view) `<Space>` to checkout branch
- (branches view) `p` to pull, `P` to push, `f` on particular branch to fetch it.
- (files view) `a` to stage all, `<Space>` to stage selected, `c` to commit, `A` to amend previous commit

Lazygit supports conflicts resolving: when there is a conflict, you can browse through conflicted hunks, `<Enter>` them and select which version you want with up/down arrow keys. Then `<Space>` to select either hunk.

I really suggest to go through Lazygit docs/[tutorial video](https://youtu.be/VDXvbHZYeKY) to get to know this tool.

If there is something Lazygit can't do, you can invoke custom command by hitting `:` and running anything (like `git pull <remote> <branch> --no-ff --no-commit` or anything else)
