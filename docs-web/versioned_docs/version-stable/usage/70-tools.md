# Data and system tools

## JSON and YAML: jq, yq and fx

Uses: [jq](https://jqlang.org/), [yq](https://mikefarah.gitbook.io/yq/), [fx](https://fx.wtf/)

```shell
curl -s https://api.github.com/repos/Ziwi01/proveasio | jq '.stargazers_count'
kubectl get pods -o json | jq -r '.items[].metadata.name'
yq '.github_packages.neovim' ansible/roles/software/vars/main.yml
yq -i '.image.tag = "1.2.3"' values.yaml        # edit a YAML file in place
yq -o json values.yaml                          # YAML to JSON
```

To build a `jq` filter interactively, type a command that prints JSON and press <kbd>Alt</kbd>+<kbd>j</kbd> (from the [jq-zsh-plugin](https://github.com/reegnz/jq-zsh-plugin)). An fzf window shows the result of the filter as you type it; <kbd>Enter</kbd> puts `| jq '<filter>'` on the command line.

`fx` browses large JSON interactively: `fx data.json` or `... | fx`. Expand and collapse nodes with the arrow keys and search with `/`; `?` lists all keys. With an argument it works as a processor, like `jq`: `fx data.json .items`.

## HTTP: curlie

Uses: [curlie](https://curlie.io/)

`curlie` accepts every `curl` option, but prints headers and the formatted, colored body like HTTPie:

```shell
curlie https://api.github.com/repos/Ziwi01/proveasio
curlie post httpbin.org/post name=proveasio enabled:=true    # JSON body, HTTPie syntax
```

## Processes and resources: htop and bottom

`top` is aliased to [htop](https://htop.dev/). <kbd>F6</kbd> sorts, <kbd>F4</kbd> filters, <kbd>F5</kbd> shows the process tree, <kbd>F9</kbd> kills.

[bottom](https://github.com/ClementTsang/bottom) (`btm`) shows CPU, memory, network, disks, temperatures and processes in one screen with graphs. In the process list, `/` searches, `dd` kills and `t` toggles the tree view. `?` lists all keys.

## Disk usage: gdu

[gdu](https://github.com/dundee/gdu) scans a directory and shows what takes space:

```shell
gdu ~            # interactive; Enter to open a directory, d to delete, q to quit
gdu -n /var      # non-interactive summary
```

## Docker: dry

[dry](https://github.com/moncho/dry) is a terminal UI for Docker: containers, images, networks and their logs and stats. Run `dry`, move with the arrow keys, and press <kbd>Enter</kbd> on a container for its actions (logs, inspect, stop, remove). `?` lists all keys.

## Many repositories: gita

Uses: [gita](https://github.com/nosarthur/gita)

gita shows the status of many repositories side by side and runs Git commands on all of them, from any directory:

```shell
gita add ~/projects/*          # register repositories
gita ll                        # branch and status of each
gita fetch                     # fetch all
gita pull infra docs           # only some repositories
gita group add infra-repo1 infra-repo2 -n infra   # name a group
gita super infra checkout -b feature/x            # any git command on a group
gita shell infra 'ls'                             # any shell command on a group
```

## Code review: hunk

Uses: [hunk](https://github.com/modem-dev/hunk)

hunk shows diffs in a desktop-style viewer in the terminal: a file list, side-by-side or unified view, and syntax highlighting. It works well for reviewing changes made by an AI agent.

```shell
hunk diff                 # working tree changes
hunk diff --staged        # staged changes
hunk diff main            # against a branch
hunk show HEAD~1          # a commit
hunk log                  # browse history
```

In tmux, <kbd>Alt</kbd>+<kbd>h</kbd> opens hunk in a popup, and opencode can walk you through its changes in it. See [Review changes with an agent](./80-ai.md#review-changes-with-an-agent).

## Code review with notes for the agent: revdiff

Uses: [revdiff](https://github.com/umputun/revdiff)

revdiff shows a diff, a file or a plan, and lets you annotate any line. When you quit, it prints the annotations as Markdown (`## file:line (+)` and the comment), ready for an AI agent. In opencode, use `/revdiff` instead; see [Review changes with an agent](./80-ai.md#review-changes-with-an-agent).

```shell
revdiff                   # working tree changes
revdiff --staged          # staged changes
revdiff main              # against a branch
revdiff HEAD~1 HEAD       # a commit
revdiff --only=plan.md    # a single file, even outside git
revdiff -o review.md main # write the annotations to a file
```

In revdiff, <kbd>a</kbd> or <kbd>Enter</kbd> annotates the current line, <kbd>A</kbd> the whole file, <kbd>@</kbd> lists the annotations and <kbd>q</kbd> quits. <kbd>?</kbd> shows every key.

## Shell scripts: ShellCheck

[ShellCheck](https://www.shellcheck.net/) finds bugs in shell scripts: unquoted variables, wrong tests, unused variables and more.

```shell
shellcheck script.sh
shellcheck -x -S warning scripts/*.sh     # follow sourced files, skip notes and style hints
```

Neovim runs it automatically for shell files through the Bash language server.

## Python projects: uv

See [Python](./20-terminal.md#python).
