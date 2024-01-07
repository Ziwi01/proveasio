# Terminal

## Traverse directories with `Zoxide`

Uses: [Zoxide](https://github.com/ajeetdsouza/zoxide)

After you've visited any directory (with plain `cd <dir>`, or just `<dir>`) you can easily go back to any directory using `z <pattern>`.

For example:

To go back to `/home/user/projects/ansible`, use something like `z ansible` or `z ans` or similar

`z` will go to first directory matching the pattern. If there are more directories with `ansible` and you want to go to some other one, use `z <pattern> <TAB>`, which will open a fuzzy finder. See example below.

<details>
  <summary><b>Example:</b> Zoxide fuzzy find</summary>
  <div align="center">
    <img src="./resources/zoxide-ff.gif" />
  </div>
</details>

## Find and open files with `fd` and `fzf`

Uses: 

- [fd](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)

Replace your `find` command with that

Easily find files with preview using `bfind` alias (uses `fzf`):

<details>
  <summary><b>Example:</b> Search file with `bfind`</summary>
  <div align="center">
    <img src="./resources/bfind.png" />
  </div>
</details>
<br />

You can scroll the file preview using `SHIFT+up` and `SHIFT+down`

To find files the same way as above and then edit them with VIM, use `vimfind`

To go into a directory using fuzzy search, try `<Alt>+t` or `cd **<TAB>`

## Browse command history

Just use good old `CTRL+r`. You will be presented with fuzzy finder to look for a command.

You can also start typing something and then hit `CTRL+r`, then it will search for the text already put.

## View files with `bat`

`cat` is an alias to `bat` and by default shows line numbers, has syntax highlight and pipes long outputs through a pager.

If you need plain output (for copying purposes for example), use `cat -p <file>`. To also disable paging, use `cat -pp <file>`

See `man bat` if you want more options.

If you want to use old unaliased cat, use `\cat`

## Better tail

There is an alias `btail <file>`, which will use BAT as tail command. This gives better output format and some syntax highlighting.

<details>
  <summary><b>Example:</b> Tail with `btail`</summary>
  <div align="center">
    <img src="./resources/btail.png" />
  </div>
</details>

## Correct commands with `thefuck`

Uses: [thefuck](https://github.com/nvbn/thefuck)

Misspelling a command is a real pain in the ass. Here comes the solution. When you misspell a command, try hitting `ESC ESC` or just type `fuck` and hit enter.

`thefuck` will try to correct this command for you. This is handy especially in git commands, for example if you want to push new branch to the remote:

<details>
  <summary><b>Example:</b> Correct new branch push with `thefuck`</summary>
  <div align="center">
    <img src="./resources/thefuck.png" />
  </div>
</details>

There are lots of rules - see [rules list](https://github.com/nvbn/thefuck/tree/master/thefuck/rules) (you can also add you own rules in `~/.config/thefuck/rules/`)

## Docker/Kubernetes

Docker is installed and available for use. Confirm it with `systemctl status docker` :)

For Kubernetes management from CLI there is a [`kubectl`](https://kubernetes.io/docs/reference/kubectl/kubectl/). For GUI management use [`k9s`](https://k9scli.io/) 

To setup a local kubernetes cluster for development purposes you can use [`kind create cluster`](https://kind.sigs.k8s.io/) which will quickly provision new cluster in Docker.

## Keychain ssh-agent

When using SSH keys with a password we can either input the password every time the key is used (pull, push, fetch etc.) or use `ssh-agent` to persist password for this session.

To go further, [`keychain`](https://www.funtoo.org/Funtoo:Keychain) lets you persist the password accross terminal logins until the machine is restarted.

Use:

```ssh
eval `keychain --eval --agents ssh <key1> <keyN>`
```

If you only have `id_rsa`, you can ommit passing key(s). Keychain will prompt you for all the passwords for those keys and will persist them across logins (you still need to run above command on new terminal, but it won't prompt you for password). To always call it, add it to `~/.zshrc`

## Grep with ripgrep

Uses: [ripgrep](https://github.com/BurntSushi/ripgrep)

Instead of `grep`, use `rg`. Its super fast and easy to use.

The search will be recursive by default, can use regex and lots more. See its [GUIDE.md](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md) if you need more advanced usage.

## List directories/files with git status

There are two commands to use for this:

`k`: Looks like `ls -la`, but gives indication on which files/directories have beed modified from Git perspective.

<details>
  <summary><b>Example:</b> List files with `k`</summary>
  <div align="center">
    <img src="./resources/terminal-k.png" />
  </div>
</details>
<br />

`lsg`: Gives simple, yet more verbose information about what changed (both directory-wise and file-wise)

<details>
  <summary><b>Example:</b> List files with `lsg`</summary>
  <div align="center">
    <img src="./resources/terminal-lsg.png" />
  </div>
</details>

## Git related

Git used from terminal has some tweaks, including aliases, new commands/functions for branch checkout and git status.

For lots of git commands there are aliases. If you use a command which is aliased, the terminal will remind you that you can use an alias instead.

Aliases below are just helpers in case something needs to be done from terminal directly. Personally I don't use them very often, instead I use LazyGit (invoked from Vim) - see [Lazygit](#lazygit).

### Checkout branches

`gco` - function alias for `git checkout`. Will show a list of available branches in a fuzzy search so you can pick it from the list. You can also use `gco <branch>` to checkout to specific branch without fuzzing :)

<details>
  <summary><b>Example:</b> Checkout new branch</summary>
  <div align="center">
    <img src="./resources/git-checkout.png" />
  </div>
</details>

### Status

`gst` - function alias for `git status` - browse through changed files (with preview). From this view you can also stage/unstage files for commit, edit and run a commit.

<details>
  <summary><b>Example:</b> Checking git status</summary>
  <div align="center">
    <img src="./resources/git-status.png" />
  </div>
</details>

### Log

`glo` - function alias for `git log`. Runs fuzzy search to browse a commit list, with a preview window of this commit on the right side. You can scroll the preview with `Shift+up/down`.

### Clone

`gcl <remote_url>` - plain alias for `git clone <remote_url>`

### Origin

- `grrm <origin_name>` - `git remote remove <origin_name>`
- `gra <origin_name> <origin_url>` - `git remote add <origin_name> <origin_url>`
- `grv` - `git remote -v`

### LazyGit

All above commands and aliases can be run through [`lazygit`](https://github.com/jesseduffield/lazygit) GUI for managing Git. It has lots of features, which makes Git interactions a breeze, even the painful, complicated ones. You can run it from terminal, but most of my usage comes from within Vim - see [Vim section](./vim).

<details>
  <summary><b>Example:</b> Lazy Git interface</summary>
  <div align="center">
    <img src="./resources/lazygit.png" />
  </div>
</details>

## Languages

### Python

By default, Python gets installed using [`pyenv`](https://github.com/pyenv/pyenv) manager for mulitple Python versions. It gets pretty recent version (check with `pyenv versions`). All PIP packages, which get installed during ansible run are installed in that default Python environment, so system Python is intact.

:::tip
You can install new Python versions with `pyenv install <python_version>`. List available versions with `pyenv install -l`.
:::

To change running version:

- for current shell session: `pyenv shell <version>`
- to change default: `pyenv global <version>`
- to change version whenever you are in current directory, use `pyenv local <version>`

### Go

Automatic installation of Go is done using [`GVM`](https://github.com/moovweb/gvm) - Go Version Manager. By default `go1.20.4` gets installed (at the time of writing).

:::tip
You can install more Go versions either manually (`gvm install <version>`) or you can add/set your prefered version(s) in `ansible/vars/overrides.yml` (and run the automation):
:::

```yaml
go_versions:
  - go1.20.4
go_default: go1.20.4
```

Note that `go_default` value must be in `go_versions` :)

- list installed Go versions: `gvm list`
- list all available Go versions: `gvm listall`
- install: `gvm install <version>`
- uninstall: `gvm uninstall <version>`
- switch to different version: `gvm use <version>`
- switch and set default: `gvm use <version> --default`

### Ruby

Ruby is managed through [`rvm`](https://github.com/rvm/rvm) (Ruby enVironment Manager). By default, fairly recent version of Ruby is installed (check with `rvm list`).

:::tip
You can install new Rubies with `rvm install <ruby_version>` (if no version is passed, latest available will be installed), get the list of all available versions with `rvm list known`

To switch used version, run `rvm use <version>`. To make it default for your shell, add `--default` switch.
:::

### Java/Gradle/Groovy

All those three languages (and more) are managed by [SDKMAN!](https://sdkman.io/) manager.

- list installation candidates: `sdk list` or simply `list`.
- list available versions for candidate: `sdk list <candidate>`. Candidate can be for example: java, groovy, gradle.
- install candidate version: `sdk install <candidate> <version>`
- use particular version: `sdk use <candidate> <version>`
- check currently used candidate version: `sdk current <candidate>`
- to have automatic version change whenever you enter a directory, you need to place there `.sdkmanrc` file. You can do that by running `sdk env init` inside a directory, and it will create `.sdkmanrc` file with current java used. You can add more `key=value` pairs, for each SDK candidate (e.g `groovy=<my_version>` or other)
