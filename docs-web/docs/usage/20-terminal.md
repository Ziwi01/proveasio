# Terminal

## Traverse directories with `Zoxide`

Uses: [Zoxide](https://github.com/ajeetdsouza/zoxide)

After you visit a directory (with `cd <dir>`, or just `<dir>`), you can jump back to it from anywhere with `z <pattern>`.

For example:

To go back to `/home/user/projects/ansible`, use `z ansible`, `z ans` or similar.

`z` goes to the best match (zoxide ranks directories by how often and how recently you visited them). When several directories match and you want another one, type `z <pattern> <TAB>` to pick from a fuzzy finder, or run `zi` for an interactive search.

<details>
  <summary><b>Example:</b> Zoxide fuzzy find</summary>

![zoxide ff](/assets/zoxide-ff.gif)

</details>

## Find and open files with `fd` and `fzf`

Uses:

- [fd](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)

Use `fd <pattern>` instead of `find . -name '*<pattern>*'`. It is faster, ignores files listed in `.gitignore`, and has simpler syntax (`fd -e yml` finds YAML files, `fd -H` includes hidden files).

To find files with a preview, use the `bfind` alias (fzf with a `bat` preview):

<details>
  <summary><b>Example:</b> Search file with `bfind`</summary>

![bfind](/assets/bfind.png)

</details>
<br />

Scroll the preview with <kbd>Shift</kbd>+<kbd>↑</kbd> and <kbd>Shift</kbd>+<kbd>↓</kbd>.

To find a file the same way and open it in Neovim, use `vimfind`.

The fzf key bindings work in any command line:

- <kbd>Ctrl</kbd>+<kbd>t</kbd> - insert the path of a file picked with fzf
- <kbd>Alt</kbd>+<kbd>c</kbd> - `cd` into a directory picked with fzf
- `cd **<TAB>`, `vim **<TAB>` - fuzzy completion for the argument; with `fzf-tab`, plain <kbd>Tab</kbd> completion also opens in fzf

## Browse command history

Press <kbd>Ctrl</kbd>+<kbd>r</kbd> to search your command history with fzf. If you already typed part of a command, the search starts with that text.

While you type, `zsh-autosuggestions` shows the last matching command in grey; press <kbd>→</kbd> to accept it.

## View files with `bat`

`cat` is an alias for `bat` (`batcat` on Ubuntu). It shows line numbers, highlights the syntax and pages long output.

For plain output (for example to copy it), use `cat -p <file>`. To also turn paging off, use `cat -pp <file>`. `man` pages are also shown through `bat`.

See `man batcat` for more options. To run the real `cat`, use `\cat`.

## Better tail

`btail <file>` follows a file like `tail -f` and highlights it as a log with `bat`.

<details>
  <summary><b>Example:</b> Tail with `btail`</summary>

![btail](/assets/btail.png)

</details>

## Browse opencode sessions with `ocs`

Uses:

- [opencode](https://github.com/anomalyco/opencode)
- [fzf](https://github.com/junegunn/fzf)

An opencode session is tied to the directory it was started from. Running `opencode` in `~/projects/proveasio` and then in `~/projects/proveasio/ansible` gives you two separate session lists, and the built-in `/sessions` picker only ever shows the ones belonging to the current directory. Sessions started from a subdirectory effectively disappear.

`ocs` reads opencode's database directly and shows **every** session from **every** directory in one fuzzy-searchable list, sorted newest first. Pick one and it re-attaches to that session, switching to the right directory on the way. The preview pane shows the first message of the session, so you can tell apart the six sessions you named "New session".

- Type to filter across date, path and title at once
- `CTRL+/` toggles the preview pane
- `ESC` aborts without launching anything

:::note[Where the data comes from]
Sessions live in `~/.local/share/opencode/opencode.db`. `ocs` only reads it — it never writes. Archived sessions are hidden. It reads the v2 tables when they exist (v2 migrates v1 sessions into them) and the v1 tables otherwise, so it works with both versions.
:::

<details>
  <summary><b>Example:</b> Browse sessions with `ocs` with a preview</summary>

```text
╭───────────────────────────── opencode sessions ──────────────────────────────╮
│   session                                                            242/242 │
│ ──────────────────────────────────────────────────────────────────────────── │
│ ▌ 2026-09-03 01:31  ~                            Organizing opencode sessions│
│ ▌ 2026-09-03 01:14  ~/.config/astronvim          Reviewing community.lua     │
│ ▌ 2026-09-02 18:56  ~/github/awx-helm SAML Azure Entra setup guide           │
│ ▌ 2026-09-02 16:38  ~/github/devops              Nexus Helm chart update     │
│ ▌ 2026-09-02 12:11  ~/projects/proveasio         Ansible FZF clone task fails│
│ ──────────────────────────────────────────────────────────────────────────── │
│ When running ansible, I get error for FZF:                                   │
│                                                                              │
│ TASK [software : [fzf] Clone/checkout version 0.74.3] ********************** │
│ [ERROR]: Task failed: Module failed: Failed to download remote objects       │
╰──────────────────────────────────────────────────────────────────────────────╯
```

</details>
<br />

## Correct commands with `pay-respects`

Uses: [pay-respects](https://github.com/iffse/pay-respects)

When a command fails because of a typo or a missing option, type `f` and press <kbd>Enter</kbd>. `pay-respects` suggests the corrected command. This is handy with git, for example after `git push` on a new branch that has no upstream yet.

You can add your own rules in a TOML file, see the [pay-respects repository](https://github.com/iffse/pay-respects).

## Docker and Kubernetes

The Docker engine runs as a systemd service. Check it with `systemctl status docker`. (In the [Docker image](../main/docker/30-run.md#docker-inside-the-container) there is no engine; mount the host's socket instead.)

For `kubectl`, `k9s`, `kind`, Helm and the other Kubernetes tools, see [Kubernetes](./50-kubernetes.md).

## Keychain ssh-agent

With a passphrase-protected SSH key, you either type the passphrase every time the key is used (pull, push, fetch) or load the key into `ssh-agent` for the session.

[`keychain`](https://www.funtoo.org/Funtoo:Keychain) goes further: it keeps one agent running across terminal logins until the machine (or WSL) restarts.

```shell
eval "$(keychain --eval --agents ssh id_ed25519)"
```

List the key files from `~/.ssh` you want to load (for example `id_ed25519 id_rsa`). The first time, keychain asks for the passphrases. In later terminals the same command reuses the running agent without asking. To load the keys in every terminal, add the line to `~/.zshrc` (note that the config role manages that file, see [Own config files](../main/customization/30-config-files.md)).

## Grep with ripgrep

Uses: [ripgrep](https://github.com/BurntSushi/ripgrep)

Use `rg <pattern>` instead of `grep -r`. It searches recursively by default, skips files in `.gitignore`, and is much faster.

```shell
rg 'github_packages' ansible/        # search a directory
rg -t yaml 'become: true'            # only YAML files
rg -l TODO                           # list matching files only
rg -uu 'secret'                      # include hidden and ignored files
```

See the [ripgrep guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md) for more.

## List directories/files with git status

There are two commands to use for this:

`ls` (eza) shows the Git status of each file in its own column.

`k` looks like `ls -la`, but marks the files and directories that Git sees as modified.

<details>
  <summary><b>Example:</b> List files with `k`</summary>

![terminal k](/assets/terminal-k.png)

</details>
<br />

`lsg` gives simple, but more verbose information about what changed, for directories and files.

<details>
  <summary><b>Example:</b> List files with `lsg`</summary>

![terminal lsg](/assets/terminal-lsg.png)

</details>

## Git related

The shell has the aliases of the oh-my-zsh `git` plugin (`gst`, `gco`, `gp` and many more) and a few functions of its own. When you type a command that has an alias, `you-should-use` reminds you of it.

The aliases help when you work from the terminal directly. For most Git work I use lazygit from Neovim, see [lazygit](#lazygit).

### Checkout branches

`gco` picks a branch (local or remote, newest first, with a log preview) in fzf and checks it out. A remote branch gets a local tracking branch. `gco <branch>` checks out without searching. `gb` shows the same picker and prints the branch name, for use in other commands: `git diff $(gb)`.

<details>
  <summary><b>Example:</b> Checkout new branch</summary>

![git checkout](/assets/git-checkout.png)

</details>

### Status

`gst` runs `git-fuzzy status`: browse the changed files with a diff preview. From this view you can also stage and unstage files, edit them and commit.

<details>
  <summary><b>Example:</b> Checking git status</summary>

![git status](/assets/git-status.png)

</details>

### Log

`glo` runs `git-fuzzy log`: search the commit list, with a preview of the selected commit on the right. Scroll the preview with <kbd>Shift</kbd>+<kbd>↑</kbd>/<kbd>↓</kbd>.

`gd` runs `git-fuzzy diff` the same way for the working tree changes (or `gd <branch>` against a branch).

### Clone

`gcl <remote_url>` - plain alias for `git clone <remote_url>`

### Remotes

- `grrm <origin_name>` - `git remote remove <origin_name>`
- `gra <origin_name> <origin_url>` - `git remote add <origin_name> <origin_url>`
- `grv` - `git remote -v`

### LazyGit

[lazygit](https://github.com/jesseduffield/lazygit) is a terminal UI for Git that makes even complicated operations (interactive rebase, cherry-picks, partial staging) easy. Run `lazygit` in a repository, or open it from Neovim, see [lazygit from Neovim](./40-vim.md#lazygit-from-vim).

<details>
  <summary><b>Example:</b> Lazy Git interface</summary>

![lazygit](/assets/lazygit.png)

</details>

#### AI commits in Lazygit

The `lazygit` config adds shortcuts that use [OpenCode](https://opencode.ai) to write commit messages. They need `opencode` (logged in to a provider), `jq` and `python3`. Every OpenCode session they create is deleted afterwards.

| View | Key | Action |
| --- | --- | --- |
| Files | `Ctrl+A` | Generate a commit message (subject and body) for the staged changes into the commit draft. Press `c` to review, edit and commit it. |
| Files | `Alt+A` | Same, subject only. |
| Files | `Alt+S` | Split changes into commits by functionality: the staged changes if anything is staged, otherwise all changes including untracked files. Shows the plan first: `y` creates the commits, `v` opens the proposed commits in Neovim's [Diffview](https://github.com/sindrets/diffview.nvim) (commit list, files, side-by-side diffs; close it with `:DiffviewClose` to return; falls back to `git log -p` when Diffview is missing), `e` edits the plan in your editor, `r` regenerates it, `n` aborts. If a commit fails, HEAD and the index are restored. |
| Commits | `Ctrl+A` | Reword the selected commit with a generated subject and body. Press `r` to adjust it, `z` to undo. |
| Commits | `Alt+A` | Reword only the subject and keep the existing body. |

Models can be changed with environment variables: `AI_COMMIT_MODEL` (messages, default `github-copilot/claude-haiku-4.5`) and `AI_COMMIT_SPLIT_MODEL` (splitting, default `github-copilot/claude-sonnet-5.5`).

To keep large change sets within the model's limits, `Alt+S` sends a condensed diff: generated files (lockfiles such as `package-lock.json`, minified assets, and files marked `linguist-generated` in `.gitattributes`) appear as a one-line summary and stay whole in a single commit, and hunks are cut off after `AI_COMMIT_SPLIT_MAX_HUNK_LINES` lines (default `60`, `0` disables it). The commits themselves always contain the full changes. If the condensed diff is still larger than `AI_COMMIT_SPLIT_MAX_DIFF_BYTES` (default `400000`), stage a subset first.

## Languages

### Python

Python is installed with the [`pyenv`](https://github.com/pyenv/pyenv) version manager, in a recent version (check with `pyenv versions`). The pip packages from the playbook are installed into that Python, so the system Python stays untouched.

:::tip
You can install new Python versions with `pyenv install <python_version>`. List available versions with `pyenv install -l`.
:::

To change the Python version:

- for the current shell: `pyenv shell <version>`
- as the default: `pyenv global <version>`
- for a directory (writes `.python-version`): `pyenv local <version>`

Virtual environments with `pyenv-virtualenv`:

```shell
pyenv virtualenv 3.14.0 myproject   # create
pyenv local myproject               # activate it whenever you are in this directory
```

For projects, [uv](https://docs.astral.sh/uv/) is often faster and simpler. It creates the virtual environment and the lock file for you:

```shell
uv init myproject && cd myproject
uv add requests           # add a dependency to pyproject.toml and .venv
uv run python main.py     # run inside the project environment
uvx ruff check .          # run a tool without installing it
```

### Go

Go is installed with [GVM](https://github.com/moovweb/gvm) (Go Version Manager). The default version is set by `go_default` in `ansible/roles/software/vars/main.yml`.

:::tip
Install more Go versions by hand (`gvm install <version>`), or list them in `ansible/vars/overrides.yml` and run the playbook with `--tags gvm`:

```yaml
go_versions:
  - go1.26.1
  # - <another version from `gvm listall`>
go_default: go1.26.1
```

`go_default` must be one of `go_versions`.
:::

- list installed Go versions: `gvm list`
- list all available Go versions: `gvm listall`
- install: `gvm install <version>`
- uninstall: `gvm uninstall <version>`
- switch to different version: `gvm use <version>`
- switch and set default: `gvm use <version> --default`

### Ruby

Ruby is managed by [`rvm`](https://github.com/rvm/rvm) (Ruby enVironment Manager). The Rubies in `rvm1_rubies` are installed (check with `rvm list`).

:::tip
Install more Rubies with `rvm install <ruby_version>`; list the available versions with `rvm list known`.

To switch the version, run `rvm use <version>`. To make it the default, add `--default`.
:::

### Node

Node is managed by [nvm](https://github.com/nvm-sh/nvm). nvm loads on its first use, so the shell starts fast; the default Node is on the `PATH` right away.

- list installed versions: `nvm list`
- install a version: `nvm install 24` or `nvm install --lts`
- switch: `nvm use <version>`; make it the default: `nvm alias default <version>`
- per project: put the version in `.nvmrc` and run `nvm use`

The global npm packages from `npm_default_packages` are installed for the default Node.

### Rust

Rust is installed with `rustup`:

- update the toolchain: `rustup update`
- install a tool from crates.io: `cargo install <crate>`
- new project: `cargo new myproject`

### Java/Gradle/Groovy

Java, Gradle, Groovy, Maven and many other JVM tools are managed by [SDKMAN!](https://sdkman.io/).

- list installation candidates: `sdk list`
- list available versions for candidate: `sdk list <candidate>`. Candidate can be for example: java, groovy, gradle.
- install candidate version: `sdk install <candidate> <version>`
- use particular version: `sdk use <candidate> <version>`
- check currently used candidate version: `sdk current <candidate>`
- to pin versions per project, run `sdk env init` in the project directory. It creates `.sdkmanrc` with the current Java; add a `key=value` line for each other candidate (for example `groovy=<version>`). Run `sdk env` there to switch to those versions.
