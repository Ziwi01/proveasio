# Git

Git comes from the [git-core PPA](https://launchpad.net/~git-core/+archive/ubuntu/ppa), so it is newer than the Ubuntu package. These tools make working with it easier:

- [lazygit](https://github.com/jesseduffield/lazygit) - terminal UI for Git, also opened from Neovim. Its config adds [AI-generated commit messages and commit splitting](../../usage/20-terminal.md#ai-commits-in-lazygit) with opencode.
- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - more readable `git diff` output.
- [git-fuzzy](https://github.com/bigH/git-fuzzy) - Git status, log and diff in fzf (`gst`, `glo`, `gd`).
- `gco` / `gb` - pick a branch with fzf and check it out (`gco`) or print it (`gb`). `gco <branch>` checks out without searching.
- [hunk](https://github.com/modem-dev/hunk) - review diffs in a desktop-like terminal viewer.
- [Gita](https://github.com/nosarthur/gita) - group your repositories and run Git or shell commands on a whole group at once.
- [ls with git status](https://github.com/gerph/ls-with-git-status) (`lsg`), the `k` oh-my-zsh plugin and `eza --git` - list files with their Git status.
- [GitHub CLI](https://cli.github.com/) (`gh`) - pull requests, issues and releases from the terminal. Proveasio also uses its login for the GitHub API.

See [Git usage](../../usage/20-terminal.md#git-related) for examples.
