# Usages

This document describes all the tools and features which I find useful for everyday work including usage scenarios and workflows.

## Table of contents

* [Table of contents](#table-of-contents)
* [Terminal](#terminal)
  * [Find files](#find-files)
  * [Traverse directories](#traverse-directories)
  * [GIT](#git)
    * [Checkout branches](#checkout-branches)
    * [Status](#status)
* [Tmux](#tmux)
  * [Basic commands](#basic-commands)
  * [Manage sessions](#manage-sessions)
  * [Search back buffer](#search-back-buffer)
  * [Extract from buffer](#extract-from-buffer)
* [Neovim/LunarVIM](#neovim/lunarvim)
  * [File browser](#file-browser)
  * [Switch to opened buffer](#switch-to-opened-buffer)
  * [Jump to last opened buffer](#jump-to-last-opened-buffer)
  * [Close opened buffers](#close-opened-buffers)
  * [Diff opened buffer to current file](#diff-opened-buffer-to-current-file)
  * [Diff directories](#diff-directories)
  * [Search and replace](#search-and-replace)
    * [Spectre](#spectre)
    * [Ferret](#ferret)
  * [Open recent file](#open-recent-file)
  * [Find text](#find-text)
  * [Find files](#find-files)
  * [Markdown](#markdown)
    * [Table of Contents](#table-of-contents)
    * [Preview](#preview)
  * [Updates](#updates)
  * [Resize/pick splits](#resize/pick-splits)
  * [Align text](#align-text)
  * [Commands with Vimux](#commands-with-vimux)
  * [Plugin management](#plugin-management)
  * [LSP integration](#lsp-integration)
  * [GIT](#git)
    * [Lazygit](#lazygit)
    * [Diff current changes](#diff-current-changes)
    * [Diff another branch](#diff-another-branch)
    * [Preview hunk](#preview-hunk)
    * [Git blame](#git-blame)
    * [File history](#file-history)

## Terminal

### Traverse directories with `Zoxide`

### Find and open files with `fd` and `fzf`

- finding files with FZF using custom `bfind` alias - with preview. Can be used with vim to search file and edit selected (`vim $(bfind)`). Similar functionality (but without file preview) can be achieved with `vim **<TAB>`.

### Browse command history

### View files with BAT

### Git

#### Checkout branches

#### Status

#### Clone

#### Origin

### Correct commands with thefuck

### Docker/Kubernetes

### Keychain ssh-agent

### Grep with ripgrep

## Tmux

### Basic commands

- start with `tmux new`
- `<C-b>c` - new window
- `<C-b>%` - split window vertically
- `<C-b>"` - split window horizontally
- `<C-b><arrows>` - move between panes
- `<C-b><C+<arrows>>` - resize panes
- `<C-b>xy` - kill pane
- `<C-b>n` - next window
- `<C-b>l` - last window
- `<C-b>p` - previous window (in order)

### Manage sessions

- session management (`<C-b><C-s>` to save session, `<C-b><C-r>` to restore)

### Search back buffer

- ability to search back tmux buffer with FZF (`<C-b><C-f>`)

### Extract from buffer

- ability to extract text from tmux buffer with FZF (`<C-b><TAB>`)

## Neovim/LunarVIM

For all configuration overrides, see `ansible/roles/dev/files/lvim-config.lua` in this repo or `~/.config/lvim/config.lua` on the filesystem.

### File browser

### Switch to opened buffer

### Jump to last opened buffer

### Close opened buffers

### Diff opened buffer to current file

### Diff directories

### Search and replace

#### Spectre

#### Ferret

### Open recent file

### Find text

### Find files

### Markdown

#### Table of Contents

#### Preview

### Updates

### Resize/pick splits

### Align text

### Commands with Vimux

### Plugin management

### LSP integration

### GIT

#### Lazygit

#### Diff current changes

#### Diff another branch

#### Preview hunk

#### Git blame

#### File history

#### Reload file after checkout
