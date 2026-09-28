# Docker image implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Proveasio as a Docker image by running the existing Ubuntu playbook inside `docker build`, with the same override format as native, a local or git Neovim config, in-build smoke tests, and a GitHub workflow that publishes to Docker Hub.

**Architecture:** `docker-bake.hcl` at the repo root drives `docker/Dockerfile`. Stages: `nvim-config` (empty, replaceable named context), `build` (root bootstrap, then `prepare-ubuntu.sh`, then the playbook with merged overrides and cleanup), `test` (runs `docker/test.sh`), `receipt` (exports `current-versions.yml`), `final` (depends on `test`). Role changes add opt-in variables only.

**Tech stack:** Docker BuildKit and Bake (buildx 0.37), Dockerfile syntax 1 with heredocs, Ansible (existing roles), bash, yq v4, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-24-docker-image-design.md`

## Global constraints

- Base image `ubuntu:${UBUNTU_VERSION}`, default `24.04`. Platform `linux/amd64` only.
- Container user `dev`, UID 1000, GID 1000 by default, passwordless sudo. `CMD ["zsh", "-l"]`, no `ENTRYPOINT`.
- Every new Ansible variable defaults to today's behaviour: `neovim_package: appimage`, `docker_manage_service: true`, `neovim_config_source: git`, `neovim_config_local_path: ""`.
- `cd ansible && ansible-lint` must print `Passed: 0 failure(s)` after every task that touches `ansible/`.
- Ansible conventions: task names start with `"[Tool] ..."`; every `shell:` task sets `args.executable: /bin/bash` and starts with `set -e -o pipefail`; silence lint findings with an inline `# noqa: <rule>` plus a reason.
- The GitHub token reaches the build only as the BuildKit secret `id=GITHUB_TOKEN,env=GITHUB_TOKEN` (string form; the HCL object form fails when the variable is unset).
- Registry placeholders: image `docker.io/CHANGEME/proveasio`, `vars.DOCKERHUB_USERNAME`, `secrets.DOCKERHUB_TOKEN`.
- Action majors (latest releases checked 2026-09-24 with `gh api repos/<r>/releases/latest`): `actions/checkout@v7`, `docker/setup-buildx-action@v4`, `docker/metadata-action@v6`, `docker/login-action@v4`, `docker/bake-action@v7`, `actions/upload-artifact@v7`.
- User docs go in `docs-web/docs/` only, never `docs-web/versioned_docs/`. Nothing in user docs describes the pipeline; maintainer notes go in workflow comments.
- Docs prose follows the unslop rules: sentence-case headings, no em dashes, plain words.
- Never run `ansible-playbook setup-ubuntu.yml` on the host. The playbook only runs inside `docker buildx bake`.
- Never commit, push, branch or tag. Each task ends with a checkpoint that shows the diff; the maintainer decides when to commit. Suggested commit subjects are given for that moment (Conventional Commits, capitalized subject).
- Throwaway files go in `/tmp/opencode/`.

## Facts established while planning

Probed on this machine (WSL Ubuntu 24.04, Docker 29.8.1, buildx 0.37.0, yq 4.52.2) against the native install:

- Bind-mounting the empty `FROM scratch` stage works (0 entries). A `--build-context nvim-config=<dir>` replaces it. The env secret is empty when not passed.
- `yq eval-all '. as $i ireduce ({}; . *+ $i)' a.yml b.yml` appends lists, merges maps, and works when `b.yml` is empty or only comments.
- A metadata-action Bake file redefining `target "docker-metadata-action"` overrides the local `tags`. `--set image.output=type=cacheonly` works.
- Bake does not expand `~`; `regex_replace(NVIM_CONFIG, "^~", HOME)` with `variable "HOME" { default = null }` does.
- `timestamp()` is evaluated per Bake invocation, so CI must pin `REFRESH` for the whole job.
- Interactive zsh without a terminal prints `can't change option: zle` and p10k's `gitstatus failed to initialize`. Under `script -qec 'zsh -i -c exit' /dev/null` the output is empty.
- oh-my-zsh enables `EXTENDED_GLOB`, so checks must run in bash. The PATH of an interactive zsh can be captured with `script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null | tr -d '\r' | tail -n 1`.
- `/usr/bin/script` comes from `bsdutils`, which is essential in Ubuntu.
- `nvim-linux-x86_64.tar.gz` exists for v0.12.5 and unpacks to `nvim-linux-x86_64/bin/nvim`.
- The receipt version appears verbatim in each tool's version output, with these exceptions handled in `test.sh`: apt versions (`1:2.55.0-0ppa1~ubuntu24.04.2` needs epoch and revision stripped), `pdk` (receipt `3.4.0.1-1focal`, binary prints `3.4.0`), `diff-so-fancy` (prints no version; the script contains `my $VERSION = "1.4.12";`), `puppet` (8.4.0 is installed next to 8.8.1, check `gem list --exact puppet`), `gita`/`az-account-switcher`/`ansible` (use `pip3 show` or `--version` as listed in Task 6).
- On native, SDKMAN is not initialized by `.zshrc` (`sdk` and `java` are not on the interactive PATH), and `nvm --version` is 0.40.0 while the receipt says 0.40.8 (`nvm.yml` has `creates:` so it never upgrades). Both are native issues; `test.sh` sources the SDKMAN and nvm init scripts explicitly.
- `.zshrc` has more unguarded tool integrations than the spec listed: `pay-respects` (`zshrc.j2:154`), `switcher` (`:157-159`), `kubectl`/`kubecolor` (`:162-164`), `fzf` (`:172`, `:307`), the omz `fzf` and `zoxide` plugins (which print warnings when the tool is missing), and `{{ eza_version }}` (`:120`), which fails to render when eza was not installed.
- The native astronvim install has 40 Mason packages and 113 lazy plugins. The config uses `mason-tool-installer.nvim`.

## Spec deltas

These refine the approved spec; Task 12 writes them back into the spec file.

1. The zshrc fix covers every tool integration listed above, not only `.cargo/env` and gvm (Task 3).
2. The playbook `RUN` also runs a Mason/treesitter sync (no-op when the commands do not exist) and warms zsh once so p10k's `gitstatusd` is in the image (Task 7).
3. `test.sh` runs checks in bash with the zsh PATH, and has `--list`, `--only` and `--coverage` (Task 6).
4. The `receipt` stage copies from `build`, not `final`, so `final` stays the last stage and a plain `docker build -f docker/Dockerfile .` produces the image.
5. CI uses a small `plan` job to path-filter `develop` pushes, because `on.push.paths` would also filter `master`.
6. `.gitignore` also gets `/out/` (the local receipt output).

## File map

| File | Responsibility |
|---|---|
| `ansible/roles/software/vars/main.yml` | Add `neovim_package`, `docker_manage_service`. |
| `ansible/roles/software/tasks/neovim.yml` | Tarball install branch next to the AppImage branch. |
| `ansible/roles/software/tasks/docker.yml` | Gate the service start; skip `absent` packages in the version read-back. |
| `ansible/roles/config/vars/main.yml` | Add `neovim_config_source`, `neovim_config_local_path`. |
| `ansible/roles/config/tasks/neovim-config.yml` | Validate the source; git clone or local copy. |
| `ansible/roles/config/templates/zshrc.j2` | Load tool integrations only when the tool exists. |
| `.dockerignore` | Allowlist of the build context. |
| `.gitignore` | Ignore `docker/overrides.yml` and `/out/`. |
| `docker/profile.yml` | Container defaults in overrides format. |
| `docker/render-overrides.sh` | Merge profile and user overrides; write `build-info.env`. |
| `docker/cleanup.sh` | Remove build leftovers in the playbook layer. |
| `docker/test.sh` | Select and run smoke checks. |
| `docker/Dockerfile` | Stages described above. |
| `docker-bake.hcl` | Variables, targets `image` and `receipt`. |
| `.github/workflows/docker.yml` | Build, test, publish, receipt. |
| `docs-web/docs/main/docker/*` | User docs: build, customize, run, limitations. |
| `docs-web/docs/main/customization/30-config-files.md`, `features/50-neovim.md`, `installation.md`, `README.md` | Pointers and the two new native options. |
| `AGENTS.md`, `TODO.md` | Maintainer notes and found bugs. |

---

### Task 1: Software role options (Neovim tarball, Docker service gate)

**Files:**
- Modify: `ansible/roles/software/vars/main.yml` (after the `github_packages` block, before `# Kubectl version`; after the `docker_apt_packages` block)
- Modify: `ansible/roles/software/tasks/neovim.yml`
- Modify: `ansible/roles/software/tasks/docker.yml:62-97`

**Interfaces:**
- Produces: variables `neovim_package` (`appimage` | `tarball`) and `docker_manage_service` (bool). Task 4's `docker/profile.yml` sets `neovim_package: tarball`, `docker_manage_service: false`, and `docker_apt_packages` entries with value `absent`.
- Produces: with `tarball`, `~/.local/bin/nvim` links to `~/.local/opt/neovim-<ver>/nvim-linux-x86_64/bin/nvim`. Task 7 checks this path.

- [ ] **Step 0: Record the tag baseline**

Before any change under `ansible/`:

```bash
mkdir -p /tmp/opencode
cd /home/ziwi/projects/proveasio/ansible
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tags 2>/dev/null > /tmp/opencode/tags-before.txt
wc -l < /tmp/opencode/tags-before.txt
```

Expected: a non-zero line count. Task 13 compares against this file.

- [ ] **Step 1: Write the failing structural test**

```bash
cd /home/ziwi/projects/proveasio/ansible
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --tags neovim,docker 2>/dev/null \
  | grep -E 'Unpack Neovim release tarball|Validate neovim_package' || echo "FAIL: tarball tasks missing"
```

Expected now: `FAIL: tarball tasks missing`.

- [ ] **Step 2: Add the variables**

In `ansible/roles/software/vars/main.yml`, insert before the line `# Kubectl version`:

```yaml
# How Neovim is installed: `appimage` (default) or `tarball`.
# The AppImage needs FUSE. Use `tarball` where FUSE is not available,
# for example in containers.
neovim_package: appimage
```

Insert after the `docker_apt_packages:` block (after `  containerd.io: latest`):

```yaml
# Start and enable the Docker engine service after installing it.
# Set to false where there is no init system (containers). To install only the
# client there, set `docker-ce: absent`, `containerd.io: absent` and
# `docker-ce-cli: latest` in `docker_apt_packages`.
docker_manage_service: true
```

- [ ] **Step 3: Add the Neovim tarball branch**

In `ansible/roles/software/tasks/neovim.yml`:

Insert as the first task after `---`:

```yaml
- name: "[Neovim] Validate neovim_package"
  ansible.builtin.assert:
    that:
      - neovim_package in ['appimage', 'tarball']
    fail_msg: "neovim_package must be 'appimage' or 'tarball', got '{{ neovim_package }}'"
    quiet: true
```

Change both `github_uri` lines:

```yaml
    github_uri: "v{{ neovim_version }}/nvim-linux-x86_64.{{ 'tar.gz' if neovim_package == 'tarball' else 'appimage' }}"
```

```yaml
    github_uri: "nightly/nvim-linux-x86_64.{{ 'tar.gz' if neovim_package == 'tarball' else 'appimage' }}"
```

Add `and neovim_package == 'appimage'` to the `when:` of the four AppImage tasks inside the `Installation` block:

```yaml
      when: github_packages['neovim'] != 'nightly' and neovim_package == 'appimage'
```

(for `[Neovim] Download Neovim release` and `[Neovim] Link Neovim release appimage`) and

```yaml
      when: github_packages['neovim'] == 'nightly' and neovim_package == 'appimage'
```

(for `[Neovim] Download Neovim nightly` and `[Neovim] Link Neovim nightly appimage`).

Append these tasks at the end of the `Installation` block (same indentation as the AppImage tasks, before `- name: "[Neovim] Save used version"`):

```yaml
    - name: "[Neovim] Unpack Neovim release tarball"
      ansible.builtin.unarchive:
        src: "{{ neovim_url }}"
        dest: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-{{ neovim_version }}"
        remote_src: true
        creates: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-{{ neovim_version }}/nvim-linux-x86_64/bin/nvim"
      when: github_packages['neovim'] != 'nightly' and neovim_package == 'tarball'

    - name: "[Neovim] Link Neovim release binary"
      ansible.builtin.file:
        src: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-{{ neovim_version }}/nvim-linux-x86_64/bin/nvim"
        dest: "{{ ansible_facts['env']['HOME'] }}/.local/bin/nvim"
        state: link
        force: true
      when: github_packages['neovim'] != 'nightly' and neovim_package == 'tarball'

    - name: "[Neovim] Create nightly tarball directory"
      ansible.builtin.file:
        path: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-nightly/nvim-{{ neovim_version_exact.stdout }}"
        state: directory
        mode: '0755'
      when: github_packages['neovim'] == 'nightly' and neovim_package == 'tarball'

    - name: "[Neovim] Unpack Neovim nightly tarball"
      ansible.builtin.unarchive:
        src: "{{ neovim_url }}"
        dest: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-nightly/nvim-{{ neovim_version_exact.stdout }}"
        remote_src: true
        creates: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-nightly/nvim-{{ neovim_version_exact.stdout }}/nvim-linux-x86_64/bin/nvim"
      when: github_packages['neovim'] == 'nightly' and neovim_package == 'tarball'

    - name: "[Neovim] Link Neovim nightly binary"
      ansible.builtin.file:
        src: "{{ ansible_facts['env']['HOME'] }}/.local/opt/neovim-nightly/nvim-{{ neovim_version_exact.stdout }}/nvim-linux-x86_64/bin/nvim"
        dest: "{{ ansible_facts['env']['HOME'] }}/.local/bin/nvim"
        state: link
        force: true
      when: github_packages['neovim'] == 'nightly' and neovim_package == 'tarball'
```

The release and nightly directory tasks at the top of the block stay unconditional on `neovim_package`; both branches need them.

- [ ] **Step 4: Gate the Docker service and skip `absent` packages**

In `ansible/roles/software/tasks/docker.yml`, change the loop of `[Docker] Get installed packages versions`:

```yaml
  loop: "{{ docker_apt_packages | dict2items | rejectattr('value', 'equalto', 'absent') | list }}"
```

Add `when:` to `[Docker] Start docker daemon`, keeping the existing `# noqa: args[module]`:

```yaml
- name: '[Docker] Start docker daemon' # noqa: args[module]
  become: true
  ansible.builtin.service:
    name: docker
    state: started
    enabled: true
    use: "{{ service_manager }}"
  when: docker_manage_service | bool
```

- [ ] **Step 5: Run the structural test and the gates**

```bash
cd /home/ziwi/projects/proveasio/ansible
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --tags neovim,docker 2>/dev/null \
  | grep -cE 'Unpack Neovim (release|nightly) tarball|Validate neovim_package|Link Neovim (release|nightly) binary'
ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check
ansible-lint
```

Expected: the count prints `5`; syntax check prints `playbook: setup-ubuntu.yml`; ansible-lint prints `Passed: 0 failure(s)`. If ansible-lint flags `risky-file-permissions` on the `unarchive` tasks, add `mode: '0755'` to them and re-run. Functional proof comes in Task 7 (the smoke build installs Neovim with `tarball`).

- [ ] **Step 6: Checkpoint**

```bash
cd /home/ziwi/projects/proveasio && git status --short && git diff --stat
```

Suggested commit when the maintainer asks: `feat(neovim): Add tarball install option and Docker service gate`.

---

### Task 2: Local Neovim config source

**Files:**
- Modify: `ansible/roles/config/vars/main.yml` (after `neovim_config_path`)
- Modify: `ansible/roles/config/tasks/neovim-config.yml` (whole file)

**Interfaces:**
- Produces: `neovim_config_source` (`git` | `local`) and `neovim_config_local_path` (string). Task 4's `render-overrides.sh` sets `neovim_config_source: local` and `neovim_config_local_path: /tmp/nvim-config`.
- Produces: receipt key `neovim_config_version` is `local` for local sources.

- [ ] **Step 1: Write the failing structural test**

```bash
cd /home/ziwi/projects/proveasio/ansible
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --tags neovim-config 2>/dev/null \
  | grep -E 'Copy local config|Validate config source' || echo "FAIL: local source tasks missing"
```

Expected now: `FAIL: local source tasks missing`.

- [ ] **Step 2: Add the variables**

Append to `ansible/roles/config/vars/main.yml`:

```yaml
# Where the Neovim config comes from:
#   git   - clone neovim_config_url at neovim_config_version (default)
#   local - copy the directory neovim_config_local_path into neovim_config_path
neovim_config_source: git
neovim_config_local_path: ""
```

- [ ] **Step 3: Rewrite `neovim-config.yml`**

Replace the whole file with:

```yaml
# Install neovim custom config
---
- name: "[Neovim config] Validate config source"
  ansible.builtin.assert:
    that:
      - neovim_config_source in ['git', 'local']
      - neovim_config_source == 'git' or neovim_config_local_path | length > 0
    fail_msg: >-
      neovim_config_source must be 'git' or 'local', and 'local' needs
      neovim_config_local_path (got source '{{ neovim_config_source }}',
      path '{{ neovim_config_local_path }}')
    quiet: true

- name: "[Neovim config] Clone/update config version {{ neovim_config_version }}"
  ansible.builtin.git:
    repo: "{{ neovim_config_url }}"
    dest: "{{ neovim_config_path }}"
    update: true
    version: "{{ neovim_config_version }}"
  when: neovim_config_source == 'git'

- name: "[Neovim config] Copy local config from {{ neovim_config_local_path }}"
  ansible.builtin.copy:
    src: "{{ neovim_config_local_path }}/"
    dest: "{{ neovim_config_path }}/"
    mode: preserve
  when: neovim_config_source == 'local'

# Runs on every play by design: the headless launch drives lazy.nvim/Mason
# plugin + LSP sync. There is no reliable "already up to date" signal to gate
# on, so this is an accepted always-run task (changed_when:false keeps it from
# reporting a spurious change on every run).
- name: "[Neovim config] Update Neovim config"
  ansible.builtin.command: "nvim --headless +q"
  changed_when: false
  failed_when: false
  environment:
    PATH: "{{ ansible_facts['env']['HOME'] }}/.local/bin/:{{ ansible_facts['env']['PATH'] }}"
    NVIM_APPNAME: "{{ neovim_config_appname }}"

- name: "[Neovim config] Save used version"
  vars:
    app: neovim-config
    neovim_config_saved_version: "{{ neovim_config_version if neovim_config_source == 'git' else 'local' }}"
    target_version:
      neovim_config_version: "{{ neovim_config_saved_version }}"
    yq_query: '.neovim_config_version = "{{ neovim_config_saved_version }}"'
  ansible.builtin.include_role:
    name: common
    tasks_from: save_version.yml
    apply:
      tags:
        - versions
  tags:
    - versions
```

- [ ] **Step 4: Run the structural test and the gates**

```bash
cd /home/ziwi/projects/proveasio/ansible
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tasks --tags neovim-config 2>/dev/null \
  | grep -cE 'Copy local config|Validate config source'
ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check
ansible-lint
```

Expected: `2`, the syntax-check line, `Passed: 0 failure(s)`. Functional proof in Task 9 (build with `NVIM_CONFIG`).

- [ ] **Step 5: Checkpoint**

`git status --short && git diff --stat`. Suggested commit: `feat(neovim-config): Support a local config directory`.

---

### Task 3: Exclude-safe zshrc

**Files:**
- Modify: `ansible/roles/config/templates/zshrc.j2` lines 88-121, 153-172, 306-307, 341-345

**Interfaces:**
- Produces: a `.zshrc` whose interactive start prints nothing when any subset of tools is missing. Task 6's `check_config_zsh` asserts this; Task 7's smoke build exercises it with most tools absent.

- [ ] **Step 1: Write the failing render test**

```bash
cd /home/ziwi/projects/proveasio/ansible
ansible localhost -c local -m ansible.builtin.template \
  -a "src=roles/config/templates/zshrc.j2 dest=/tmp/opencode/zshrc.rendered mode=0644" \
  -e '{"actual_node_version": {"stdout": ""}, "neovim_config_appname": "astronvim"}' 2>&1 | tail -3
```

Expected now: FAILED with `'eza_version' is undefined`.

- [ ] **Step 2: Guard the plugin list and the eza FPATH**

Replace lines 88-121 (from `plugins=(` through the eza `fi`) with:

```zsh
# Plugins that need a tool are added only when the tool is installed, so a
# tool listed in software_tasks_exclude does not make the shell print errors.
# The order below is the original order; fzf-tab must load before
# zsh-autosuggestions and zsh-syntax-highlighting.
plugins=(
    zsh-lazyload
    git
    docker
    colorize
    helm
    rvm
    dotenv
    colored-man-pages
    dirhistory
)
if [[ -d "${HOME}/.fzf" ]]; then
  plugins+=(fzf fzf-tab fzf-tab-source)
fi
plugins+=(
    zsh-autosuggestions
    zsh-sdkman
    zsh-syntax-highlighting
    you-should-use
    k
)
if (( $+commands[zoxide] )); then
  plugins+=(zoxide)
fi
plugins+=(
    pyenv-lazy
    jq
    kubectl
    aws
    azure
    terraform
{% if actual_node_version.stdout | regex_search('^v[0-9]*\.[0-9]*\.[0-9]*') %}
    zsh-snv
{% endif %}
)

{% if eza_version is defined %}
# EZA - must be set before oh-my-zsh sources compinit
if command -v eza &>/dev/null; then
  export FPATH="${HOME}/.local/opt/eza-{{ eza_version }}:$FPATH"
fi
{% endif %}
```

- [ ] **Step 3: Guard the tool integrations**

Replace lines 153-172 (from `### Pay Respects` through `source <(fzf --zsh)`) with:

```zsh
### Pay Respects
if command -v pay-respects &>/dev/null; then
  eval "$(pay-respects zsh --alias)"
fi

### Kubectl context switch
if command -v switcher &>/dev/null; then
  source <(switcher init zsh)
  source <(alias s=switch)
  source <(switch completion zsh)
fi

### kubecolor
if command -v kubectl &>/dev/null; then
  source <(command kubectl completion zsh)
  if command -v kubecolor &>/dev/null; then
    alias kubectl=kubecolor
    compdef kubecolor=kubectl
  fi
fi

### Fuzzy Finder

# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}${HOME}/.fzf/bin"
fi
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi
```

Replace the fzf-tab `source` line (currently `source $HOME/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh`) with:

```zsh
if [[ -d "${HOME}/.fzf" ]]; then
  source $HOME/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh
fi
```

Replace the Cargo and gvm lines (currently `. "$HOME/.cargo/env"` and `. "${HOME}/.gvm/scripts/gvm"`) with:

```zsh
# Cargo
[[ -s "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Go version manager
[[ -s "${HOME}/.gvm/scripts/gvm" ]] && . "${HOME}/.gvm/scripts/gvm"
```

- [ ] **Step 4: Run the render test twice and syntax-check the output**

```bash
cd /home/ziwi/projects/proveasio/ansible
ansible localhost -c local -m ansible.builtin.template \
  -a "src=roles/config/templates/zshrc.j2 dest=/tmp/opencode/zshrc.rendered mode=0644" \
  -e '{"actual_node_version": {"stdout": ""}, "neovim_config_appname": "astronvim"}' | head -1
zsh -n /tmp/opencode/zshrc.rendered && echo "zsh -n ok"
grep -c 'eza-' /tmp/opencode/zshrc.rendered
ansible localhost -c local -m ansible.builtin.template \
  -a "src=roles/config/templates/zshrc.j2 dest=/tmp/opencode/zshrc.rendered2 mode=0644" \
  -e '{"actual_node_version": {"stdout": "v22.23.2"}, "neovim_config_appname": "astronvim", "eza_version": "0.23.5"}' | head -1
zsh -n /tmp/opencode/zshrc.rendered2 && grep -c -e 'eza-0.23.5' -e 'zsh-snv' /tmp/opencode/zshrc.rendered2
cd /home/ziwi/projects/proveasio/ansible && ansible-lint
```

Expected: both renders report `CHANGED` (or `SUCCESS`), `zsh -n ok`, `0` for the first grep, `2` for the second, `Passed: 0 failure(s)`. The runtime proof (clean interactive start with tools missing) is Task 7.

- [ ] **Step 5: Checkpoint**

`git status --short && git diff --stat`. Suggested commit: `fix(zsh): Load tool integrations only when the tool is installed`.

---

### Task 4: Build inputs (`.dockerignore`, profile, override merge)

**Files:**
- Create: `.dockerignore`, `docker/profile.yml`, `docker/render-overrides.sh` (mode 0755)
- Modify: `.gitignore`

**Interfaces:**
- Consumes: variables from Tasks 1 and 2.
- Produces: `render-overrides.sh` reads env `PROVEASIO_HOME` (default `$HOME/proveasio`), `DOCKER_DIR` (default `/tmp/proveasio-docker`), `NVIM_CONFIG_DIR` (default `/tmp/nvim-config`), `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `REFRESH`. It writes `$PROVEASIO_HOME/ansible/vars/overrides.yml` and `$PROVEASIO_HOME/docker/build-info.env` (bash-sourceable `KEY=value` lines for `ANSIBLE_TAGS`, `ANSIBLE_SKIP_TAGS`, `REFRESH`, `BUILD_DATE`). Tasks 6 and 7 rely on both files.

- [ ] **Step 1: Write the failing context test**

```bash
cd /home/ziwi/projects/proveasio
docker buildx build --progress=plain --no-cache -f - . 2>&1 <<'EOF' | grep -E 'CTX' | sort -u > /tmp/opencode/ctx.txt
FROM busybox
COPY . /ctx
RUN cd /ctx && find . -maxdepth 2 | sed 's/^/CTX /'
EOF
grep -E 'CTX \./(docs-web|current-versions.yml|ansible/vars/overrides.yml|\.git)$' /tmp/opencode/ctx.txt && echo "FAIL: context leaks"
```

Expected now: lines for `docs-web`, `.git`, `current-versions.yml` and `FAIL: context leaks`. (`ansible/vars/overrides.yml` is at depth 3, so also check it in Step 5.)

- [ ] **Step 2: Create `.dockerignore`**

```
# Allowlist: the image build reads only these paths.
*
!ansible/
!prepare-ubuntu.sh
!docker/
# Machine-local and generated files must never reach a build.
ansible/vars/overrides.yml
ansible/.ansible/
```

- [ ] **Step 3: Update `.gitignore`**

Append:

```
docker/overrides.yml
/out/
```

- [ ] **Step 4: Create `docker/profile.yml`**

```yaml
# Container defaults for Docker image builds, in the same format as
# ansible/vars/overrides.yml. docker/render-overrides.sh merges this file with
# the optional, gitignored docker/overrides.yml: maps merge recursively and
# lists are appended, so a user override cannot drop an entry from here.

# Windows-only tools. win32yank.exe would also make Neovim configs that look
# for it use it as the clipboard, which fails in a Linux container.
software_tasks_exclude:
  - w32yank
  - wsl-notify-send

# The AppImage needs FUSE, which containers do not have.
neovim_package: tarball

# No init system in a container. The image ships the Docker client and
# plugins only; containers use the host engine through a mounted
# /var/run/docker.sock.
docker_manage_service: false
docker_apt_packages:
  docker-ce: absent
  containerd.io: absent
  docker-ce-cli: latest
  docker-buildx-plugin: latest

# A fresh image has no earlier config files worth backing up.
config_files_backup: false
```

- [ ] **Step 5: Re-run the context test**

Run the Step 1 command again, then:

```bash
grep -E 'CTX \./(ansible|docker|prepare-ubuntu.sh)$' /tmp/opencode/ctx.txt
docker buildx build --progress=plain --no-cache -f - . 2>&1 <<'EOF' | grep -cE ' LEAK_FOUND$'
FROM busybox
COPY . /ctx
RUN if test -e /ctx/ansible/vars/overrides.yml; then echo LEAK_FOUND; fi
EOF
```

Expected: no `FAIL` line; the three allowed paths are listed; the leak count is `0`. (The pattern is anchored at line end so the echoed `RUN` line in the build log does not match.)

- [ ] **Step 6: Write the failing merge test**

Create `/tmp/opencode/render-test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo=/home/ziwi/projects/proveasio
t="$(mktemp -d)"
mkdir -p "$t/docker" "$t/home/proveasio" "$t/nvim"
cp "$repo/docker/profile.yml" "$t/docker/"
cat > "$t/docker/overrides.yml" <<'EOF'
software_tasks_exclude: [rvm]
github_packages:
  eza: "0.20.0"
github_api_token: ghp_should_never_appear
git:
  name: Test User
  mail: test@example.com
EOF
o="$t/home/proveasio/ansible/vars/overrides.yml"
info="$t/home/proveasio/docker/build-info.env"
run() { PROVEASIO_HOME="$t/home/proveasio" DOCKER_DIR="$t/docker" NVIM_CONFIG_DIR="$t/nvim" "$@" bash "$repo/docker/render-overrides.sh"; }

# Case 1: user overrides with a token, no local Neovim config.
log="$(run env ANSIBLE_SKIP_TAGS=rvm REFRESH=r1 2>&1)"
! grep -q ghp_should_never_appear <<<"$log"
test "$(yq -o=json -I=0 '.software_tasks_exclude' "$o")" = '["w32yank","wsl-notify-send","rvm"]'
test "$(yq '.github_packages.eza' "$o")" = "0.20.0"
test "$(yq 'has("github_api_token")' "$o")" = false
test "$(yq '.neovim_package' "$o")" = tarball
test "$(yq '.git.name' "$o")" = "Test User"
test "$(yq 'has("neovim_config_source")' "$o")" = false
grep -qx 'ANSIBLE_SKIP_TAGS=rvm' "$info"
grep -qx 'REFRESH=r1' "$info"
( source "$info"; test -z "$ANSIBLE_TAGS" )

# Case 2: no user overrides, local Neovim config present.
rm "$t/docker/overrides.yml"
echo 'vim.o.number = true' > "$t/nvim/init.lua"
run env >/dev/null
test "$(yq '.neovim_config_source' "$o")" = local
test "$(yq '.neovim_config_local_path' "$o")" = "$t/nvim"
test "$(yq -o=json -I=0 '.software_tasks_exclude' "$o")" = '["w32yank","wsl-notify-send"]'

# Case 3: empty user overrides file.
: > "$t/docker/overrides.yml"
run env >/dev/null
test "$(yq '.neovim_package' "$o")" = tarball
echo "render-overrides: all assertions passed"
```

Run: `bash /tmp/opencode/render-test.sh`. Expected now: fails because `docker/render-overrides.sh` does not exist.

- [ ] **Step 7: Create `docker/render-overrides.sh`**

```bash
#!/usr/bin/env bash
# Build the effective ansible/vars/overrides.yml for a Docker image build.
#
# Runs in the playbook RUN step of docker/Dockerfile. Inputs are the committed
# docker/profile.yml and the optional, gitignored docker/overrides.yml (both
# bind-mounted at DOCKER_DIR), plus the nvim-config build context at
# NVIM_CONFIG_DIR. Maps merge recursively and lists are appended. The roles
# then merge github_packages, pip_packages and docker_apt_packages with their
# defaults per key; every other variable replaces the role default.
set -euo pipefail

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
DOCKER_DIR="${DOCKER_DIR:-/tmp/proveasio-docker}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-/tmp/nvim-config}"

profile="$DOCKER_DIR/profile.yml"
user_overrides="$DOCKER_DIR/overrides.yml"
target="$PROVEASIO_HOME/ansible/vars/overrides.yml"
build_info="$PROVEASIO_HOME/docker/build-info.env"

if [ ! -f "$profile" ]; then
  echo "render-overrides: missing $profile" >&2
  exit 1
fi

inputs=("$profile")
if [ -f "$user_overrides" ]; then
  inputs+=("$user_overrides")
  echo "render-overrides: merging docker/overrides.yml into the profile"
else
  echo "render-overrides: no docker/overrides.yml, using docker/profile.yml only"
fi

merged="$(yq eval-all '. as $i ireduce ({}; . *+ $i)' "${inputs[@]}")"

# The merged file stays in the image, so a token must never be written to it.
if [ "$(yq 'has("github_api_token")' <<<"$merged")" = true ]; then
  echo "render-overrides: WARNING: removed github_api_token. Pass the token as the GITHUB_TOKEN build secret instead." >&2
  merged="$(yq 'del(.github_api_token)' <<<"$merged")"
fi

if [ -d "$NVIM_CONFIG_DIR" ] && [ -n "$(ls -A "$NVIM_CONFIG_DIR")" ]; then
  echo "render-overrides: using the local Neovim config from the nvim-config build context"
  merged="$(NVIM_CONFIG_DIR="$NVIM_CONFIG_DIR" yq '.neovim_config_source = "local" | .neovim_config_local_path = strenv(NVIM_CONFIG_DIR)' <<<"$merged")"
fi

mkdir -p "$(dirname "$target")" "$(dirname "$build_info")"
printf '%s\n' "$merged" > "$target"

{
  printf 'ANSIBLE_TAGS=%q\n' "${ANSIBLE_TAGS:-}"
  printf 'ANSIBLE_SKIP_TAGS=%q\n' "${ANSIBLE_SKIP_TAGS:-}"
  printf 'REFRESH=%q\n' "${REFRESH:-}"
  printf 'BUILD_DATE=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$build_info"

echo "render-overrides: effective overrides ($target):"
sed 's/^/  /' "$target"
```

`chmod 0755 docker/render-overrides.sh`

- [ ] **Step 8: Run the merge test**

`bash /tmp/opencode/render-test.sh`. Expected: `render-overrides: all assertions passed`. Note: `printf %q ''` writes `''`, so `ANSIBLE_TAGS=''` sources as empty.

- [ ] **Step 9: Checkpoint**

`git status --short && git diff --stat`. Suggested commit: `feat(docker): Add build context allowlist, container profile and override merge`.

---

### Task 5: Cleanup script

**Files:**
- Create: `docker/cleanup.sh` (mode 0755)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `bash docker/cleanup.sh`, env `CLEANUP_SYSTEM` (default `1`; `0` skips apt and `/tmp`). Prints `cleanup: <KiB> KiB  <path>` per removal and `cleanup: <n> MiB removed in total`. Task 7 calls it at the end of the playbook `RUN`; Task 8 reads its log lines.

- [ ] **Step 1: Write the failing test**

Create `/tmp/opencode/cleanup-test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo=/home/ziwi/projects/proveasio
t="$(mktemp -d)"; H="$t/home"
mkdir -p "$H"/.cache/pip/x "$H"/.cache/uv "$H"/.npm/_cacache "$H"/.rvm/src/ruby-3.4.7 "$H"/.rvm/archives \
  "$H"/.gvm/archive/go "$H"/.gvm/environments "$H"/.sdkman/archives "$H"/.sdkman/tmp \
  "$H"/.local/opt/awscli-install "$H"/.local/opt/tmux-3.7c "$H"/.local/opt/aws-cli/v2
head -c 1048576 /dev/zero > "$H/.cache/pip/x/blob"
touch "$H/.rvm/src/ruby-3.4.7/Makefile" "$H/.rvm/archives/ruby.tar.bz2" "$H/.gvm/archive/go/README" \
  "$H/.gvm/environments/go1.26.1" "$H/.local/opt/awscliv2.zip" "$H/.sdkman/tmp/t" "$H/.sdkman/archives/a.zip"
HOME="$H" CLEANUP_SYSTEM=0 bash "$repo/docker/cleanup.sh" | tee "$t/log"
for p in .cache/pip .cache/uv .npm/_cacache .local/opt/awscli-install .local/opt/awscliv2.zip; do
  test ! -e "$H/$p" || { echo "not removed: $p"; exit 1; }
done
for d in .rvm/src .rvm/archives .gvm/archive .sdkman/archives .sdkman/tmp; do
  test -d "$H/$d" && test -z "$(ls -A "$H/$d")" || { echo "not emptied or deleted: $d"; exit 1; }
done
test -e "$H/.gvm/environments/go1.26.1" && test -d "$H/.local/opt/tmux-3.7c" && test -d "$H/.local/opt/aws-cli/v2"
grep -q 'KiB  .*/.cache/pip$' "$t/log"
grep -q 'MiB removed in total' "$t/log"
echo "cleanup: all assertions passed"
```

Run: `bash /tmp/opencode/cleanup-test.sh`. Expected now: fails, script missing.

- [ ] **Step 2: Create `docker/cleanup.sh`**

```bash
#!/usr/bin/env bash
# Remove build leftovers from a Proveasio image.
#
# Runs at the end of the playbook RUN step in docker/Dockerfile. It has to run
# in that same step: files deleted in a later layer still take space in the
# image. It never deletes a path the roles use to detect an existing install
# (for example ~/.local/opt/<tool>-<version>, ~/.gvm/environments/<version>,
# ~/.local/opt/nvm/nvm.sh), so the playbook can still be re-run in a container.
#
# CLEANUP_SYSTEM=0 skips the parts that need sudo (apt lists, /tmp). It is used
# to test the script outside an image.
set -euo pipefail

CLEANUP_SYSTEM="${CLEANUP_SYSTEM:-1}"
total_kib=0

log_size() {
  total_kib=$((total_kib + $1))
  printf 'cleanup: %8s KiB  %s\n' "$1" "$2"
}

# remove_paths [sudo] <path>...: delete each existing path, logging its size.
remove_paths() {
  local sudo=() path
  if [ "${1:-}" = sudo ]; then sudo=(sudo); shift; fi
  for path in "$@"; do
    [ -e "$path" ] || continue
    log_size "$("${sudo[@]}" du -sk "$path" | cut -f1)" "$path"
    "${sudo[@]}" rm -rf -- "$path"
  done
}

# remove_contents [sudo] <dir>...: empty directories that their tool expects to exist.
remove_contents() {
  local sudo=() dir
  if [ "${1:-}" = sudo ]; then sudo=(sudo); shift; fi
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    log_size "$("${sudo[@]}" du -sk "$dir" | cut -f1)" "$dir/*"
    "${sudo[@]}" find "$dir" -mindepth 1 -delete
  done
}

# Package manager caches.
remove_paths "$HOME/.cache/pip" "$HOME/.cache/uv" "$HOME/.cache/go-build" \
  "$HOME/.npm/_cacache" "$HOME/.cache/gem" "$HOME/.cargo/registry/cache"

# rvm: Ruby sources and build trees, downloaded archives.
remove_contents "$HOME/.rvm/src" "$HOME/.rvm/archives"

# Rust offline documentation (`rustup doc`). The toolchain stays.
if [ -x "$HOME/.cargo/bin/rustup" ]; then
  docs_kib="$(du -sck "$HOME"/.rustup/toolchains/*/share/doc 2>/dev/null | tail -n 1 | cut -f1)"
  if "$HOME/.cargo/bin/rustup" component remove rust-docs >/dev/null 2>&1; then
    log_size "${docs_kib:-0}" "rust-docs component"
  fi
fi

# AWS CLI installer copy. awscli.yml downloads and unpacks it on every run and
# checks ~/.local/opt/aws-cli/v2/current instead.
remove_paths "$HOME/.local/opt/awscli-install" "$HOME/.local/opt/awscliv2.zip"

# gvm download archive. gvm.yml checks ~/.gvm and ~/.gvm/environments/<version>.
remove_contents "$HOME/.gvm/archive"

# SDKMAN download archives and temporary files.
remove_contents "$HOME/.sdkman/archives" "$HOME/.sdkman/tmp"

if [ "$CLEANUP_SYSTEM" = 1 ]; then
  sudo apt-get clean
  remove_contents sudo /var/lib/apt/lists
  # /tmp, except the bind mounts of the running build step.
  while IFS= read -r -d '' path; do
    remove_paths sudo "$path"
  done < <(find /tmp -mindepth 1 -maxdepth 1 ! -name proveasio-docker ! -name nvim-config -print0)
fi

printf 'cleanup: %d MiB removed in total\n' $((total_kib / 1024))
```

`chmod 0755 docker/cleanup.sh`

- [ ] **Step 3: Run the test**

`bash /tmp/opencode/cleanup-test.sh`. Expected: `cleanup: all assertions passed`.

- [ ] **Step 4: Checkpoint**

Suggested commit: `feat(docker): Add image cleanup script`.

---

### Task 6: Smoke test harness and checks

**Files:**
- Create: `docker/test.sh` (mode 0755)

**Interfaces:**
- Consumes: `build-info.env` and the merged `overrides.yml` from Task 4; `current-versions.yml` written by the playbook.
- Produces: `docker/test.sh [--list] [--coverage] [--only <role>/<name>]...`, env `PROVEASIO_HOME` (default `$HOME/proveasio`). Output lines `ok <role>/<name> (<detail>)` / `not ok <role>/<name>: <reason>`, then `# <n> selected, <p> passed, <f> failed`. Exit 0 only when nothing failed. Check functions are named `check_<role>_<name>` with dashes replaced by underscores.

- [ ] **Step 1: Write the harness without checks**

Create `docker/test.sh` with this content (the check functions are added in Step 3, between the markers):

```bash
#!/usr/bin/env bash
# Smoke tests for a Proveasio Docker image.
#
# Runs in the `test` stage of docker/Dockerfile on every build (the `final`
# stage depends on it) and by hand in a container:
#   ~/proveasio/docker/test.sh                      run every selected check
#   ~/proveasio/docker/test.sh --list               print the selected checks
#   ~/proveasio/docker/test.sh --only config/zsh    run one check (repeatable)
#   ~/proveasio/docker/test.sh --coverage           fail if an include has no check
#
# Selection comes from the real inputs: every include in
# roles/{software,config}/tasks/main.yml, minus the excludes in the effective
# ansible/vars/overrides.yml, filtered by the tags in docker/build-info.env.
# Each selected include needs a check_<role>_<name> function below (dashes
# become underscores). A missing function counts as a failure.
set -uo pipefail

PROVEASIO_HOME="${PROVEASIO_HOME:-$HOME/proveasio}"
ANSIBLE_DIR="$PROVEASIO_HOME/ansible"
OVERRIDES="$ANSIBLE_DIR/vars/overrides.yml"
RECEIPT="$PROVEASIO_HOME/current-versions.yml"
BUILD_INFO="$PROVEASIO_HOME/docker/build-info.env"
ROLES=(software config)

if [ -z "${TERM:-}" ] || [ "$TERM" = dumb ]; then export TERM=xterm-256color; fi
export AZURE_CORE_COLLECT_TELEMETRY=no

OUT=""
REASON=""
DETAIL=""

# ------------------------------------------------------------------ helpers

fail() { REASON="$*"; return 1; }

# effective <key> <role> [yq filter]: the value Ansible uses for a top-level
# variable. include_vars replaces whole variables, so the overrides file wins
# when it has the key. Do not use it for github_packages, pip_packages or
# docker_apt_packages (merged per key); read the receipt for those.
effective() {
  local key="$1" role="$2" filter="${3:-.}" file="$ANSIBLE_DIR/roles/$2/vars/main.yml"
  if [ -f "$OVERRIDES" ] && [ "$(yq "has(\"$key\")" "$OVERRIDES" 2>/dev/null)" = true ]; then
    file="$OVERRIDES"
  fi
  yq -r ".[\"$key\"] | $filter" "$file"
}

# receipt <yq path>: a value from current-versions.yml, empty when absent.
receipt() {
  [ -f "$RECEIPT" ] || return 0
  local v
  v="$(yq -r "$1" "$RECEIPT" 2>/dev/null)"
  [ "$v" = null ] && v=""
  printf '%s' "$v"
}

# deb_upstream <apt version>: 1:2.55.0-0ppa1~ubuntu24.04.2 -> 2.55.0
deb_upstream() {
  local v="${1#*:}"
  printf '%s' "${v%%-*}"
}

# run_cmd <cmd...>: run with a timeout; combined output goes to OUT.
run_cmd() {
  local rc
  OUT="$(timeout 300 "$@" 2>&1)"
  rc=$?
  [ "$rc" -eq 0 ] || fail "'$*' exited $rc: $(head -c 300 <<<"$OUT")"
}

# run_sh <script>: run_cmd for commands that need `source` or pipes.
run_sh() { run_cmd bash -c "$1"; }

# expect_out <text>: OUT must contain text.
expect_out() {
  [ -n "$1" ] || fail "expected text is empty" || return 1
  grep -qF -- "$1" <<<"$OUT" || fail "expected '$1' in: $(head -c 200 <<<"$OUT")"
}

# expect_receipt <yq path> [deb]: the receipt version must appear in OUT.
expect_receipt() {
  local v
  v="$(receipt "$1")"
  [ -n "$v" ] || fail "no $1 in current-versions.yml" || return 1
  if [ "${2:-}" = deb ]; then v="$(deb_upstream "$v")"; fi
  DETAIL="$v"
  expect_out "$v"
}

expect_file() { [ -e "$1" ] || fail "missing $1"; }
expect_exec() { [ -x "$1" ] || fail "missing or not executable: $1"; }
expect_nonempty_dir() { [ -n "$(ls -A "$1" 2>/dev/null)" ] || fail "missing or empty directory: $1"; }

# ------------------------------------------------------------------ checks
# (check functions go here, Step 3)
# ------------------------------------------------------------- end of checks

# includes <role>: "<name> <comma-separated outer tags>" for each include.
includes() {
  yq -r '.[] | select(has("ansible.builtin.include_tasks"))
    | (.["ansible.builtin.include_tasks"].file | sub("\.yml$"; "")) + " " + ((.tags // []) | join(","))' \
    "$ANSIBLE_DIR/roles/$1/tasks/main.yml"
}

excluded() { effective "${1}_tasks_exclude" "$1" '.[]' | grep -qxF -- "$2"; }

# tags_select <outer tags>: mirrors --tags / --skip-tags on the include.
tags_select() {
  local t hit=0
  if [ -n "${ANSIBLE_TAGS:-}" ]; then
    for t in ${ANSIBLE_TAGS//,/ }; do
      if [[ ",$1," == *",$t,"* ]]; then hit=1; fi
    done
    [ "$hit" -eq 1 ] || return 1
  fi
  if [ -n "${ANSIBLE_SKIP_TAGS:-}" ]; then
    for t in ${ANSIBLE_SKIP_TAGS//,/ }; do
      if [[ ",$1," == *",$t,"* ]]; then return 1; fi
    done
  fi
  return 0
}

check_fn() {
  local n="check_$1_$2"
  printf '%s' "${n//-/_}"
}

coverage() {
  local role name tags fn missing=0 total=0
  for role in "${ROLES[@]}"; do
    while read -r name tags; do
      [ -n "$name" ] || continue
      total=$((total + 1))
      fn="$(check_fn "$role" "$name")"
      if ! declare -F "$fn" >/dev/null; then
        echo "missing $fn for $role/$name"
        missing=$((missing + 1))
      fi
    done < <(includes "$role")
  done
  echo "# $total includes, $missing without a check"
  [ "$missing" -eq 0 ]
}

# Checks run in bash, with the PATH an interactive zsh would have, so they see
# what a user sees. zsh needs a terminal for a clean start; `script` gives it one.
use_zsh_path() {
  if [ ! -f "$HOME/.zshrc" ] || ! command -v zsh >/dev/null || ! command -v script >/dev/null; then
    return 0
  fi
  local p
  p="$(script -qec 'zsh -i -c "print -r -- \$PATH"' /dev/null 2>/dev/null | tr -d '\r' | tail -n 1)"
  case "$p" in
    */usr/bin*) export PATH="$p" ;;
    *) echo "# warning: could not read PATH from zsh, keeping the current PATH" ;;
  esac
}

usage() {
  cat <<'EOF'
Usage: docker/test.sh [--list] [--coverage] [--only <role>/<name>]...
  --list      print the checks selected for this image and exit
  --coverage  exit non-zero if any include in the roles has no check function
  --only      run only the given check; repeatable
EOF
}

main() {
  local list_only=0 do_coverage=0 only=() selected=() role name tags item fn o
  while [ $# -gt 0 ]; do
    case "$1" in
      --list) list_only=1 ;;
      --coverage) do_coverage=1 ;;
      --only)
        [ $# -ge 2 ] || { echo "--only needs a value" >&2; exit 2; }
        only+=("$2"); shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done

  if [ "$do_coverage" -eq 1 ]; then coverage; exit $?; fi

  ANSIBLE_TAGS=""
  ANSIBLE_SKIP_TAGS=""
  # shellcheck source=/dev/null
  if [ -f "$BUILD_INFO" ]; then source "$BUILD_INFO"; fi

  for role in "${ROLES[@]}"; do
    while read -r name tags; do
      [ -n "$name" ] || continue
      excluded "$role" "$name" && continue
      tags_select "$tags" || continue
      selected+=("$role/$name")
    done < <(includes "$role")
  done

  if [ ${#only[@]} -gt 0 ]; then
    for o in "${only[@]}"; do
      printf '%s\n' "${selected[@]}" | grep -qxF -- "$o" || { echo "not selected in this image: $o" >&2; exit 2; }
    done
    selected=("${only[@]}")
  fi

  if [ "$list_only" -eq 1 ]; then printf '%s\n' "${selected[@]}"; exit 0; fi

  use_zsh_path
  local pass=0 failed=0
  for item in "${selected[@]}"; do
    fn="$(check_fn "${item%%/*}" "${item#*/}")"
    OUT=""; REASON=""; DETAIL=""
    if ! declare -F "$fn" >/dev/null; then
      echo "not ok $item: no $fn in docker/test.sh"
      failed=$((failed + 1))
    elif "$fn"; then
      echo "ok $item${DETAIL:+ ($DETAIL)}"
      pass=$((pass + 1))
    else
      echo "not ok $item: ${REASON:-check failed}"
      failed=$((failed + 1))
    fi
  done
  echo "# ${#selected[@]} selected, $pass passed, $failed failed"
  [ "$failed" -eq 0 ]
}

main "$@"
```

`chmod 0755 docker/test.sh`

- [ ] **Step 2: Run coverage to see it fail**

```bash
cd /home/ziwi/projects/proveasio
bash -n docker/test.sh && PROVEASIO_HOME="$PWD" bash docker/test.sh --coverage | tail -2
```

Expected: `# 54 includes, 54 without a check` and exit 1 (45 software + 9 config includes).

- [ ] **Step 3: Add the check functions**

Replace the line `# (check functions go here, Step 3)` with:

```bash
check_software_packages() {
  local installed p missing=()
  # Names and virtual names (Provides) of installed packages, so renamed or
  # virtual entries such as libfuse2 (libfuse2t64) or ncurses-dev match.
  installed="$(dpkg-query -W -f '${db:Status-Abbrev} ${Package} ${Provides}\n' \
    | awk '$1 == "ii" { $1 = ""; print }' | sed -E 's/\([^)]*\)//g; s/,/ /g' \
    | tr ' ' '\n' | sed '/^$/d' | sort -u)"
  while read -r p; do
    [ -n "$p" ] || continue
    grep -qxF -- "$p" <<<"$installed" || missing+=("$p")
  done < <(effective default_apt_packages software '.[]')
  [ ${#missing[@]} -eq 0 ] || fail "not installed: ${missing[*]}" || return 1
  DETAIL="$(effective default_apt_packages software 'length') packages"
}

check_software_yq()        { run_cmd yq --version && expect_receipt .github_packages.yq; }
check_software_fx()        { run_cmd fx --version && expect_receipt .github_packages.fx; }
check_software_git()       { run_cmd git --version && expect_receipt .git_apt_version deb; }
check_software_ripgrep()   { run_cmd rg --version && expect_receipt .github_packages.ripgrep; }
check_software_fd()        { run_cmd fd --version && expect_receipt .github_packages.fd; }
check_software_eza()       { run_cmd eza --version && expect_receipt .github_packages.eza; }
check_software_lsg()       { expect_exec "$HOME/.local/bin/lsg" && run_cmd bash -n "$HOME/.local/bin/lsg"; }
check_software_fzf()       { run_cmd fzf --version && expect_receipt .github_packages.fzf; }

check_software_diff_so_fancy() {
  local bin
  bin="$(command -v diff-so-fancy)" || fail "diff-so-fancy is not on PATH" || return 1
  run_sh 'printf "" | diff-so-fancy' || return 1
  # diff-so-fancy prints no version; the script defines `my $VERSION = "x";`.
  OUT="$(<"$bin")"
  expect_receipt .github_packages.diff_so_fancy
}

check_software_git_fuzzy() { expect_exec "$HOME/.local/opt/git-fuzzy/bin/git-fuzzy"; }
check_software_dry()       { run_cmd dry --version && expect_receipt .github_packages.dry; }
check_software_lazygit()   { run_cmd lazygit --version && expect_receipt .github_packages.lazygit; }
check_software_gita()      { run_cmd gita --version && expect_receipt .pip_packages.gita; }
check_software_bottom()    { run_cmd btm --version && expect_receipt .github_packages.bottom; }
check_software_pay_respects() { run_cmd pay-respects --version && expect_receipt .github_packages.pay_respects; }
check_software_kubeswitch() { run_cmd switcher --version && expect_receipt .github_packages.kubeswitch; }

check_software_az_account_switcher() {
  command -v az-account-switcher >/dev/null || fail "az-account-switcher is not on PATH" || return 1
  run_cmd "$HOME/.pyenv/shims/pip3" show az-account-switcher && expect_receipt .pip_packages.az_account_switcher
}

check_software_zoxide()    { run_cmd zoxide --version && expect_receipt .github_packages.zoxide; }
check_software_helm()      { run_cmd helm version --short && expect_receipt .github_packages.helm; }

check_software_zsh() {
  local p
  run_cmd zsh --version || return 1
  expect_nonempty_dir "$HOME/.oh-my-zsh" || return 1
  for p in $(effective omz_plugins software 'keys | .[]'); do
    expect_nonempty_dir "$HOME/.oh-my-zsh/custom/plugins/$p" || return 1
  done
  run_cmd git -C "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" describe --tags \
    && expect_receipt .github_packages.p10k
}

check_software_w32yank()   { expect_exec "$HOME/.local/bin/win32yank.exe"; }
check_software_wsl_notify_send() { expect_exec "$HOME/.local/bin/wsl-notify-send.exe"; }

check_software_tmux() {
  local sock="proveasio-test-$$"
  run_cmd tmux -V && expect_receipt .github_packages.tmux || return 1
  run_cmd tmuxp --version && expect_receipt .pip_packages.tmuxp || return 1
  expect_file "$HOME/.tmux/plugins/tpm/tpm" || return 1
  run_cmd tmux -L "$sock" new-session -d -s proveasio-test || return 1
  run_cmd tmux -L "$sock" kill-server
  DETAIL="$(receipt .github_packages.tmux)"
}

check_software_docker() {
  local detail
  run_cmd docker --version || return 1
  if [ -n "$(receipt '.docker_apt_packages["docker-ce-cli"]')" ]; then
    expect_receipt '.docker_apt_packages["docker-ce-cli"]' deb || return 1
  fi
  detail="$DETAIL"
  run_cmd docker compose version && expect_receipt '.docker_apt_packages["docker-compose-plugin"]' deb || return 1
  if [ -n "$(receipt '.docker_apt_packages["docker-buildx-plugin"]')" ]; then
    run_cmd docker buildx version && expect_receipt '.docker_apt_packages["docker-buildx-plugin"]' deb || return 1
  fi
  DETAIL="cli ${detail:-?}"
  # Only when the host engine socket is mounted (never during the build).
  if [ -S /var/run/docker.sock ]; then
    run_cmd docker info --format '{{.ServerVersion}}' || return 1
    DETAIL+=", engine $(head -n 1 <<<"$OUT")"
  fi
}

check_software_kubectl()   { run_cmd kubectl version --client && expect_receipt .kubectl_version; }
check_software_kubecolor() { run_cmd kubecolor --kubecolor-version && expect_receipt .github_packages.kubecolor; }
check_software_kind()      { run_cmd kind version && expect_receipt .github_packages.kind; }
check_software_k9s()       { run_cmd k9s version -s && expect_receipt .github_packages.k9s; }

check_software_rvm() {
  local rvm='source "$HOME/.rvm/scripts/rvm"' ruby
  run_sh "$rvm && rvm --version" || return 1
  for ruby in $(effective rvm1_rubies software '.[]'); do
    run_sh "$rvm && rvm $ruby do ruby -v" && expect_out "${ruby#ruby-}" || return 1
  done
  DETAIL="$(effective rvm1_rubies software 'join(" ")')"
}

check_software_sdkman() {
  local init='source "$HOME/.sdkman/bin/sdkman-init.sh"' cand ver cmd
  for cand in $(effective sdkman_defaults software 'keys | .[]'); do
    ver="$(effective sdkman_defaults software ".[\"$cand\"]")"
    case "$cand" in
      java) cmd="java -version" ;;
      maven) cmd="mvn --version" ;;
      *) cmd="$cand --version" ;;
    esac
    # SDKMAN candidate versions carry a vendor suffix: 25.0.2-open -> 25.0.2
    run_sh "$init && $cmd" && expect_out "${ver%%-*}" || return 1
  done
  DETAIL="$(effective sdkman_defaults software 'to_entries | map(.key + " " + .value) | join(", ")')"
}

check_software_nvm() {
  local init='source "$HOME/.local/opt/nvm/nvm.sh"' pkg
  run_sh "$init && nvm --version" && expect_receipt .github_packages.nvm || return 1
  run_cmd node --version || return 1
  DETAIL="nvm $(receipt .github_packages.nvm), node $(head -n 1 <<<"$OUT")"
  for pkg in $(effective npm_default_packages software '.[]'); do
    run_sh "$init && npm ls -g --depth=0 $pkg" && expect_out "$pkg@" || return 1
  done
}

check_software_rust()      { run_cmd rustc --version && run_cmd cargo --version; }

check_software_gvm() {
  local go
  go="$(effective go_default software)"
  run_cmd go version && expect_out "$go " && DETAIL="$go"
}

check_software_ansible() {
  run_cmd "$HOME/.pyenv/shims/pip3" show ansible && expect_receipt .ansible_pip_version || return 1
  run_cmd ansible-playbook --version || return 1
  run_cmd ansible-lint --version && expect_receipt .ansible_lint_pip_version
}

check_software_neovim() {
  run_cmd nvim --version || return 1
  if [ "$(receipt .github_packages.neovim)" = nightly ]; then DETAIL=nightly; return 0; fi
  expect_receipt .github_packages.neovim
}

check_software_puppet() {
  local rvm='source "$HOME/.rvm/scripts/rvm"' pdk
  run_sh "$rvm && rvm all do gem list --exact puppet" \
    && expect_out "$(effective puppet_version software)" || return 1
  run_sh "$rvm && rvm all do gem list --exact puppet-lint" \
    && expect_out "$(effective puppet_lint_version software)" || return 1
  # apt 3.4.0.1-1focal is PDK 3.4.0 (the fourth number is the package build).
  pdk="$(deb_upstream "$(receipt .puppet_pdk_version)" | cut -d. -f1-3)"
  run_cmd pdk --version && expect_out "$pdk" || return 1
  expect_nonempty_dir "$HOME/.lsp/puppet-editor-services" || return 1
  DETAIL="puppet $(effective puppet_version software), pdk $pdk"
}

check_software_terraform()  { run_cmd terraform version && expect_receipt .github_packages.terraform; }
check_software_terragrunt() { run_cmd terragrunt --version && expect_receipt .github_packages.terragrunt; }
check_software_azurecli()   { run_cmd az version && expect_receipt .azurecli_apt_version deb; }
check_software_awscli()     { run_cmd aws --version && expect_out "aws-cli/" && DETAIL="$(cut -d' ' -f1 <<<"$OUT")"; }
check_software_uv()         { run_cmd uv --version && expect_receipt .github_packages.uv; }
check_software_opencode()   { run_cmd opencode --version && expect_receipt .github_packages.opencode; }
check_software_hunk()       { run_cmd hunk --version && expect_receipt .github_packages.hunk; }
check_software_ccmux()      { run_cmd ccmux --version && expect_receipt .github_packages.ccmux; }

check_config_zsh() {
  local rc
  expect_file "$HOME/.zshrc" || return 1
  OUT="$(script -qec 'zsh -i -c exit' /dev/null 2>&1)"
  rc=$?
  OUT="$(tr -d '\r' <<<"$OUT")"
  [ "$rc" -eq 0 ] || fail "interactive zsh exited $rc: $(head -c 300 <<<"$OUT")" || return 1
  [ -z "$(tr -d '[:space:]' <<<"$OUT")" ] || fail "interactive zsh printed: $(head -c 300 <<<"$OUT")"
}

check_config_p10k()     { expect_file "$HOME/.p10k.zsh"; }

check_config_tmux() {
  local n
  expect_file "$HOME/.tmux.conf" || return 1
  expect_exec "$HOME/.local/bin/tmux-default-session-name" || return 1
  expect_file "$HOME/.tmuxp/default_session.yaml" || return 1
  n="$(find "$HOME/.tmux/plugins" -mindepth 1 -maxdepth 1 -type d ! -name tpm 2>/dev/null | wc -l)"
  [ "$n" -gt 0 ] || fail "no TPM plugins in ~/.tmux/plugins" || return 1
  DETAIL="$n TPM plugins"
}

check_config_ccmux()    { expect_file "$HOME/.config/ccmux/ccmux.json"; }

check_config_neovim_config() {
  local app lazy mason
  app="$(effective neovim_config_appname config)"
  expect_nonempty_dir "$HOME/.config/$app" || return 1
  expect_nonempty_dir "$HOME/.local/share/$app" || return 1
  run_cmd env NVIM_APPNAME="$app" nvim --headless +qa || return 1
  if grep -qE 'E[0-9]+: |Error' <<<"$OUT"; then
    fail "nvim reported errors: $(head -c 300 <<<"$OUT")"
    return 1
  fi
  lazy="$HOME/.local/share/$app/lazy"
  mason="$HOME/.local/share/$app/mason/packages"
  DETAIL="$app"
  if [ -d "$lazy" ]; then DETAIL+=", $(find "$lazy" -mindepth 1 -maxdepth 1 | wc -l) lazy plugins"; fi
  if [ -d "$mason" ]; then DETAIL+=", $(find "$mason" -mindepth 1 -maxdepth 1 | wc -l) mason packages"; fi
  return 0
}

check_config_sdkman()   { expect_file "$HOME/.sdkman/etc/config"; }
check_config_git()      { run_cmd git config --global user.name && expect_out "$(effective git config '.name')"; }
check_config_lazygit()  { expect_file "$HOME/.config/lazygit/config.yml"; }
check_config_ansible()  { expect_file "$HOME/.ansible-lint"; }
```

- [ ] **Step 4: Run coverage and list on the native checkout**

```bash
cd /home/ziwi/projects/proveasio
bash -n docker/test.sh
PROVEASIO_HOME="$PWD" bash docker/test.sh --coverage | tail -1
PROVEASIO_HOME="$PWD" bash docker/test.sh --list | wc -l
```

Expected: `# 54 includes, 0 without a check`; list count `53` (your native `ansible/vars/overrides.yml` excludes config `git`).

- [ ] **Step 5: Run a native subset to exercise the helpers**

These checks only read state or start short-lived processes. Do not run the full set on the host.

```bash
cd /home/ziwi/projects/proveasio
PROVEASIO_HOME="$PWD" bash docker/test.sh \
  --only software/packages --only software/eza --only software/yq --only software/tmux \
  --only software/docker --only software/diff-so-fancy --only software/puppet \
  --only software/sdkman --only software/gvm --only software/nvm --only config/zsh
```

Expected from the probes: `ok` for packages, eza (0.23.5), tmux (3.7c), docker (compose 5.5.1, engine 29.8.1), diff-so-fancy (1.4.12), puppet, sdkman, gvm (go1.26.1), config/zsh. `not ok software/yq` (receipt 4.53.6, the zsh PATH finds `/usr/bin/yq` 4.52.2 first) and `not ok software/nvm` (receipt 0.40.8, installed 0.40.0): both are real native mismatches, which shows the failure path works. Any other `not ok` is a harness bug unless you can show the native state is wrong; fix harness bugs before continuing. Exit code is 1 because of the two expected failures.

- [ ] **Step 6: Checkpoint**

Suggested commit: `test(docker): Add image smoke test harness`.

---

### Task 7: Dockerfile, Bake file, smoke build

**Files:**
- Create: `docker/Dockerfile`, `docker-bake.hcl`

**Interfaces:**
- Consumes: `docker/render-overrides.sh`, `docker/cleanup.sh`, `docker/test.sh`, `docker/profile.yml` (Tasks 4-6); role options (Tasks 1-3).
- Produces: Bake targets `image` (stage `final`, output `type=docker`, tag from `docker-metadata-action`) and `receipt` (stage `receipt`, output `./out/current-versions.yml`); Bake variables `REFRESH UBUNTU_VERSION USERNAME USER_UID USER_GID ANSIBLE_TAGS ANSIBLE_SKIP_TAGS NVIM_CONFIG IMAGE HOME`; build secret `GITHUB_TOKEN`. Task 10 uses the targets and the `docker-metadata-action` target name.

- [ ] **Step 1: Create `docker/Dockerfile`**

```dockerfile
# syntax=docker/dockerfile:1

# Proveasio developer workstation image.
# Build from the repository root with `docker buildx bake` (docker-bake.hcl).
# The playbook runs at build time. The `final` stage exists only when
# docker/test.sh passed in the `test` stage.

ARG UBUNTU_VERSION=24.04
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Local Neovim config. Empty unless the build passes a named context called
# `nvim-config`, which replaces this stage (Bake does that when NVIM_CONFIG is set).
FROM scratch AS nvim-config

FROM ubuntu:${UBUNTU_VERSION} AS build
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 \
    TZ=Etc/UTC \
    USER=${USERNAME}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Root bootstrap: what the minimized base lacks, the locale, and the user.
# Recommends are off for every apt install, including Ansible's apt tasks.
# pkgconf and python3-packaging are listed because native Ubuntu gets them
# only through recommended packages.
RUN <<'EOF'
set -euo pipefail
printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' > /etc/apt/apt.conf.d/99-proveasio
apt-get update
apt-get install -y sudo git python3 python3-apt python3-packaging locales tzdata \
  ca-certificates curl wget pkgconf
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
locale-gen en_US.UTF-8
if id ubuntu >/dev/null 2>&1; then userdel --remove ubuntu; fi
groupadd --gid "${USER_GID}" "${USERNAME}"
useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"
printf '%s ALL=(ALL) NOPASSWD:ALL\nDefaults env_keep += "DEBIAN_FRONTEND"\n' "${USERNAME}" > /etc/sudoers.d/proveasio
chmod 0440 /etc/sudoers.d/proveasio
visudo -cf /etc/sudoers.d/proveasio
rm -rf /var/lib/apt/lists/*
EOF

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/.pyenv/shims:/home/${USERNAME}/.pyenv/bin:${PATH}

# prepare-ubuntu.sh reads ansible_pip_version from this vars file. Copying only
# these two files keeps the slow layer below cached when other Ansible files change.
COPY --chown=${USER_UID}:${USER_GID} prepare-ubuntu.sh /home/${USERNAME}/proveasio/prepare-ubuntu.sh
COPY --chown=${USER_UID}:${USER_GID} ansible/roles/software/vars/main.yml /home/${USERNAME}/proveasio/ansible/roles/software/vars/main.yml

# Python (compiled by pyenv), Ansible and yq. prepare-ubuntu.sh has no `set -e`
# and exits 0 when it is not root, so its results are checked here.
# This layer stays cached across REFRESH builds.
RUN <<'EOF'
set -euo pipefail
sudo bash "$HOME/proveasio/prepare-ubuntu.sh"
expected="$(sed -n "s/^PYTHON_VERSION='\(.*\)'$/\1/p" "$HOME/proveasio/prepare-ubuntu.sh")"
actual="$(python --version 2>&1)"
if [ "$actual" != "Python ${expected}" ]; then
  echo "prepare-ubuntu.sh did not install Python ${expected} (got: ${actual})" >&2
  exit 1
fi
ansible-playbook --version
yq --version
# llvm is needed only to build Python. The CPython test suite and caches are unused.
sudo apt-get purge -y --auto-remove llvm
rm -rf "$HOME"/.pyenv/versions/*/lib/python*/test "$HOME/.cache/pip" "$HOME/.pyenv/cache"
sudo rm -rf /var/lib/apt/lists/*
EOF

COPY --chown=${USER_UID}:${USER_GID} ansible /home/${USERNAME}/proveasio/ansible

# Everything below re-runs when REFRESH changes. docker-bake.hcl sets it to the
# current time by default, so every build resolves `latest` again.
ARG REFRESH=manual
ARG ANSIBLE_TAGS=""
ARG ANSIBLE_SKIP_TAGS=""

RUN --mount=type=bind,source=docker,target=/tmp/proveasio-docker \
    --mount=type=bind,from=nvim-config,target=/tmp/nvim-config \
    --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
    <<'EOF'
set -euo pipefail
echo "Proveasio build: REFRESH=${REFRESH} ANSIBLE_TAGS=${ANSIBLE_TAGS} ANSIBLE_SKIP_TAGS=${ANSIBLE_SKIP_TAGS}"
sudo apt-get update
sudo apt-get -y upgrade
bash /tmp/proveasio-docker/render-overrides.sh

args=()
if [ -n "${ANSIBLE_TAGS}" ]; then args+=(--tags "${ANSIBLE_TAGS}"); fi
if [ -n "${ANSIBLE_SKIP_TAGS}" ]; then args+=(--skip-tags "${ANSIBLE_SKIP_TAGS}"); fi
cd "$HOME/proveasio/ansible"
ansible-playbook -i inventory.yml setup-ubuntu.yml "${args[@]}"

# Mason and treesitter install in the background, so the role's headless
# `nvim +q` can exit before they finish. Both commands are no-ops for configs
# that do not define them.
app="$(yq -r '.neovim_config_appname // ""' vars/overrides.yml)"
if [ -z "$app" ]; then app="$(yq -r '.neovim_config_appname' roles/config/vars/main.yml)"; fi
if command -v nvim >/dev/null 2>&1 && [ -d "$HOME/.config/$app" ]; then
  NVIM_APPNAME="$app" timeout 1800 nvim --headless \
    -c 'if exists(":MasonToolsInstallSync") == 2 | MasonToolsInstallSync | endif' \
    -c 'if exists(":TSUpdateSync") == 2 | TSUpdateSync | endif' \
    -c 'qa'
fi

bash /tmp/proveasio-docker/cleanup.sh

# The first interactive zsh start downloads gitstatusd for p10k and builds
# caches. Doing it here lets containers start without network access.
if [ -f "$HOME/.zshrc" ]; then script -qec 'zsh -i -c exit' /dev/null; fi
EOF

COPY --chown=${USER_UID}:${USER_GID} --chmod=0755 docker/test.sh /home/${USERNAME}/proveasio/docker/test.sh
CMD ["zsh", "-l"]

FROM build AS test
RUN "$HOME/proveasio/docker/test.sh" | tee "$HOME/proveasio/docker/tests-passed"

# Version receipt for CI. Copies from `build` so that `final` stays the last
# stage and a plain `docker build` produces the image.
FROM scratch AS receipt
ARG USERNAME
COPY --from=build /home/${USERNAME}/proveasio/current-versions.yml /current-versions.yml

FROM build AS final
ARG USERNAME
ARG USER_UID
ARG USER_GID
COPY --from=test --chown=${USER_UID}:${USER_GID} /home/${USERNAME}/proveasio/docker/tests-passed /home/${USERNAME}/proveasio/docker/tests-passed
```

- [ ] **Step 2: Create `docker-bake.hcl`**

```hcl
# Build definition for the Proveasio Docker image, used by local builds and CI.
#
#   docker buildx bake                          build, test and load proveasio:local
#   GITHUB_TOKEN=... docker buildx bake         authenticate GitHub API version lookups
#   REFRESH=dev docker buildx bake              keep the cached playbook layer
#   NVIM_CONFIG=~/my-nvim docker buildx bake    use a local Neovim config
#   docker buildx bake receipt                  write ./out/current-versions.yml
#
# Every variable can be set from the environment. User docs are in
# docs-web/docs/main/docker/.

# A new value re-runs the playbook, so `latest` versions are resolved again.
variable "REFRESH" {
  default = timestamp()
}
variable "UBUNTU_VERSION" {
  default = "24.04"
}
variable "USERNAME" {
  default = "dev"
}
variable "USER_UID" {
  default = "1000"
}
variable "USER_GID" {
  default = "1000"
}
variable "ANSIBLE_TAGS" {
  default = ""
}
variable "ANSIBLE_SKIP_TAGS" {
  default = ""
}
# Directory with a local Neovim config. Empty means neovim_config_url is cloned.
variable "NVIM_CONFIG" {
  default = ""
}
variable "IMAGE" {
  default = "proveasio:local"
}
# Read from the environment; used to expand `~` in NVIM_CONFIG.
variable "HOME" {
  default = null
}

# CI replaces this target with the tags and labels from docker/metadata-action.
target "docker-metadata-action" {
  tags = [IMAGE]
}

target "_common" {
  context    = "."
  dockerfile = "docker/Dockerfile"
  platforms  = ["linux/amd64"]
  pull       = true
  args = {
    REFRESH           = REFRESH
    UBUNTU_VERSION    = UBUNTU_VERSION
    USERNAME          = USERNAME
    USER_UID          = USER_UID
    USER_GID          = USER_GID
    ANSIBLE_TAGS      = ANSIBLE_TAGS
    ANSIBLE_SKIP_TAGS = ANSIBLE_SKIP_TAGS
  }
  contexts = NVIM_CONFIG == "" ? {} : {
    nvim-config = regex_replace(NVIM_CONFIG, "^~", HOME)
  }
  # Optional: without it the version lookups run unauthenticated.
  secret = ["id=GITHUB_TOKEN,env=GITHUB_TOKEN"]
}

target "image" {
  inherits = ["_common", "docker-metadata-action"]
  target   = "final"
  output   = ["type=docker"]
}

target "receipt" {
  inherits = ["_common"]
  target   = "receipt"
  output   = ["type=local,dest=out"]
}

group "default" {
  targets = ["image"]
}
```

- [ ] **Step 3: Check the resolved definition**

```bash
cd /home/ziwi/projects/proveasio
docker buildx bake --print image | yq -p json '.target.image | {"target": .target, "tags": .tags, "contexts": .contexts, "output": .output, "args": .args}'
NVIM_CONFIG='~/x' docker buildx bake --print image | yq -p json '.target.image.contexts'
```

Expected: target `final`, tags `[proveasio:local]`, contexts null, output `type=docker`, `REFRESH` is a timestamp. Second command prints `nvim-config: /home/ziwi/x`.

- [ ] **Step 4: Run the smoke build**

The tag set installs few tools, so it exercises every "tool is missing" path in the zshrc, plus the Neovim tarball, the Docker client-only setup and the test stage. Expected time 20-40 minutes (Python compile included). This runs the playbook only inside the build container.

```bash
cd /home/ziwi/projects/proveasio
export GITHUB_TOKEN="$(gh auth token)"
time ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke \
  docker buildx bake --progress=plain 2>&1 | tee /tmp/opencode/build-smoke.log | tail -40
grep -E ' (ok|not ok) (software|config)/|# [0-9]+ selected' /tmp/opencode/build-smoke.log
```

Expected test output: `ok` for `software/packages`, `software/yq`, `software/eza`, `software/zsh`, `software/docker`, `software/neovim`, `config/zsh`, `config/p10k`, `config/neovim-config`, then `# 9 selected, 9 passed, 0 failed`.

If the build fails, use superpowers:systematic-debugging. Likely causes and the fix to apply:
- `userdel` or `groupadd` exit code: adjust the bootstrap commands in the root `RUN`.
- A tool or Python module that native Ubuntu gets through recommends: add the package to the bootstrap `apt-get install` line and re-run. If a failure cannot be fixed with an explicit package, stop and report; the spec says no-recommends is dropped in that case.
- `config/zsh` prints output: find the plugin or line with `docker run --rm -t proveasio:smoke script -qec 'zsh -i -x -c exit' /dev/null 2>&1 | tail -40`, then guard it in `zshrc.j2` with the Task 3 pattern (`if command -v <tool> &>/dev/null; then ... fi`, or `(( $+commands[<tool>] )) && plugins+=(<plugin>)` for plugins), re-run Task 3 Step 4 and this step.
- Record each fix and its cause for the Task 8 report.

- [ ] **Step 5: Verify the role options in the smoke image**

```bash
docker run --rm proveasio:smoke bash -c 'readlink -f ~/.local/bin/nvim'
docker run --rm proveasio:smoke yq -o=json -I=0 '.docker_apt_packages | keys' /home/dev/proveasio/current-versions.yml
docker run --rm proveasio:smoke bash -c 'dpkg-query -W -f "\${db:Status-Abbrev}\n" docker-ce 2>&1 | head -1; apt-config dump | grep Install-Recommends'
docker run --rm proveasio:smoke /home/dev/proveasio/docker/test.sh --list
docker run --rm proveasio:smoke bash -c 'id; getent passwd dev | cut -d: -f7; locale | head -1'
```

Expected: a path ending in `/nvim-linux-x86_64/bin/nvim`; keys `["docker-buildx-plugin","docker-ce-cli","docker-compose-plugin"]`; docker-ce `un` or `no packages found`, and `APT::Install-Recommends "false";`; the 9 checks; `uid=1000(dev) gid=1000(dev)`, `/bin/zsh` (set by `chsh` in the role), `LANG=en_US.UTF-8`.

If `config/neovim-config` failed in Step 4 only because Mason packages need tools this tag set leaves out (node/npm, cargo, pip), that is expected for the smoke image: note it and confirm the check passes in Task 8's full build. Any other failure must be fixed here.

- [ ] **Step 6: Checkpoint**

`git status --short && git diff --stat`. Suggested commit: `feat(docker): Add Dockerfile and Bake definition`.

---

### Task 8: Full build and size measurement

**Files:**
- Modify: whatever the fixes from this build require (record them)
- Create: `/tmp/opencode/proveasio-measurements.md` (throwaway; Task 11 copies numbers from it)

**Interfaces:**
- Consumes: Task 7 files.
- Produces: measured image size, build time, cleanup total, largest directories, lazy/Mason counts. Task 11 uses them in `10-build.md` and `40-limitations.md`.

- [ ] **Step 1: Run the full build**

The bootstrap layer is cached from Task 7. Expected time 45-90 minutes.

```bash
cd /home/ziwi/projects/proveasio
export GITHUB_TOKEN="$(gh auth token)"
time docker buildx bake --progress=plain 2>&1 | tee /tmp/opencode/build-full.log | tail -80
grep -E ' (ok|not ok) (software|config)/|# [0-9]+ selected' /tmp/opencode/build-full.log
```

Expected: `# 52 selected, 52 passed, 0 failed` (54 includes minus `w32yank` and `wsl-notify-send`). Fix failures with superpowers:systematic-debugging, using the same rules as Task 7 Step 4. If a check fails because the check is wrong (the tool works, the check expectation does not match its output), fix the check in `docker/test.sh` and rebuild with `REFRESH=dev` twice in a row (first run populates the cache for that value, second confirms). Do not weaken a check to hide a real defect; report real defects instead.

- [ ] **Step 2: Check the Mason result against native**

```bash
docker run --rm proveasio:local bash -c 'ls ~/.local/share/astronvim/mason/packages | wc -l; ls ~/.local/share/astronvim/lazy | wc -l'
```

Native has 40 Mason packages and 113 lazy plugins. If the image has clearly fewer Mason packages, add this line as the first `-c` argument of the Mason/treesitter `nvim --headless` command in the Dockerfile, so lazy-loaded tool installers get loaded first:

```dockerfile
    -c 'if exists(":Lazy") == 2 | Lazy! load all | endif' \
```

Rebuild with a new `REFRESH` and compare again. If the count is still lower, report both numbers instead of adding more config-specific logic.

- [ ] **Step 3: Record measurements**

```bash
{
  echo "# Proveasio image measurements ($(date -u +%F))"
  echo; echo "## Image"; docker image ls proveasio:local --format '{{.Repository}}:{{.Tag}} {{.Size}}'
  echo; echo "## Build time"; grep -E '^real' /tmp/opencode/build-full.log || echo "(see time output in the terminal)"
  echo; echo "## Layers"; docker history --format '{{.Size}}\t{{.CreatedBy}}' proveasio:local | head -15 | cut -c1-140
  echo; echo "## Cleanup"; grep -oE 'cleanup: .*' /tmp/opencode/build-full.log | sort -u
  echo; echo "## Largest directories"
  docker run --rm proveasio:local bash -c 'du -sh ~/.[!.]* ~/.local/opt/* ~/.local/share/* /usr /opt/* 2>/dev/null | sort -h | tail -25'
  echo; echo "## Neovim"
  docker run --rm proveasio:local bash -c 'echo "mason: $(ls ~/.local/share/astronvim/mason/packages | wc -l)"; echo "lazy: $(ls ~/.local/share/astronvim/lazy | wc -l)"'
} > /tmp/opencode/proveasio-measurements.md
cat /tmp/opencode/proveasio-measurements.md
```

Note the `time` output from Step 1 in the file if `tee` did not capture it.

- [ ] **Step 4: Checkpoint**

Report the measurements and every fix made during Tasks 7-8. Suggested commit for any fixes: `fix(docker): <what was fixed>`.

---

### Task 9: Customization build and runtime checks

**Files:**
- Create then delete: `docker/overrides.yml` (gitignored test input)
- Create: `/tmp/opencode/nvim-local/` (throwaway clone)

**Interfaces:**
- Consumes: everything from Tasks 1-8.
- Produces: evidence that pins, excludes, git identity, the local Neovim config and the host Docker socket work.

- [ ] **Step 1: Prepare inputs**

```bash
cd /home/ziwi/projects/proveasio
prev_eza="$(gh api repos/eza-community/eza/releases -q '.[1].tag_name' | sed 's/^v//')"
echo "pinning eza to $prev_eza"
cat > docker/overrides.yml <<EOF
github_packages:
  eza: "$prev_eza"
software_tasks_exclude:
  - rust
git:
  name: Plan Test
  mail: plan-test@example.com
EOF
rm -rf /tmp/opencode/nvim-local
git clone -q https://github.com/Ziwi01/astronvim.git /tmp/opencode/nvim-local
echo '-- proveasio local config marker' >> /tmp/opencode/nvim-local/init.lua
```

- [ ] **Step 2: Build**

```bash
export GITHUB_TOKEN="$(gh auth token)"
time NVIM_CONFIG=/tmp/opencode/nvim-local IMAGE=proveasio:custom \
  docker buildx bake --progress=plain 2>&1 | tee /tmp/opencode/build-custom.log | tail -40
grep -E ' (ok|not ok) (software|config)/|# [0-9]+ selected' /tmp/opencode/build-custom.log
```

Expected: `# 51 selected, 51 passed, 0 failed` (rust excluded) and the build log shows `render-overrides: using the local Neovim config`.

- [ ] **Step 3: Verify each customization**

```bash
docker run --rm proveasio:custom bash -c '
  yq .github_packages.eza ~/proveasio/current-versions.yml
  ~/proveasio/docker/test.sh --list | grep -c "^software/rust$"
  git config --global user.name
  grep -c "proveasio local config marker" ~/.config/astronvim/init.lua
  yq .neovim_config_version ~/proveasio/current-versions.yml
  test -e ~/.cargo && echo "cargo present" || echo "cargo absent"'
```

Expected: the pinned eza version, `0`, `Plan Test`, `1`, `local`, `cargo absent`.

- [ ] **Step 4: Runtime checks with the host engine**

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  proveasio:local /home/dev/proveasio/docker/test.sh --only software/docker
docker run --rm -t proveasio:local zsh -i -c 'print -r -- zsh $ZSH_VERSION; tmux -V; nvim --version | head -1'
docker run --rm --network none proveasio:local /home/dev/proveasio/docker/test.sh --only config/zsh
```

Expected: `ok software/docker (cli <ver>, engine 29.8.1)`; a zsh version, a tmux version and an NVIM version with no error lines; `ok config/zsh` without network (proves gitstatusd is in the image). The devcontainer example in the docs is not tested here; say so in the Task 13 report.

- [ ] **Step 5: Clean up the test inputs**

```bash
cd /home/ziwi/projects/proveasio
rm docker/overrides.yml
docker image rm proveasio:custom proveasio:smoke
git status --short
```

Expected: `docker/overrides.yml` is gone and `git status` shows no new untracked test files.

---

### Task 10: CI workflow

**Files:**
- Create: `.github/workflows/docker.yml`

**Interfaces:**
- Consumes: Bake targets `image`, `receipt`, target `docker-metadata-action`, variable `REFRESH`, secret `GITHUB_TOKEN` (Task 7).

- [ ] **Step 1: Write the workflow**

```yaml
# Docker image: build, test and publish docker.io/CHANGEME/proveasio.
#
# - The image comes from docker-bake.hcl and docker/Dockerfile, the same files
#   users build locally. docker/test.sh runs inside the build (`final` depends
#   on `test`), so nothing is pushed unless every check passes.
# - Pushes to master, the weekly schedule and manual runs on master publish
#   `latest`, `YYYY-MM-DD` and `sha-<short>`. `v*` tags publish `X.Y.Z`, `X.Y`
#   and `sha-<short>` and leave `latest` alone. Everything else only builds
#   and tests.
# - Scheduled runs start on the default branch (develop), so the image job
#   checks out master for them.
# - Repository settings: variable DOCKERHUB_USERNAME, secret DOCKERHUB_TOKEN
#   (Docker Hub access token, Read & Write), and IMAGE_NAME below.
# - secrets.GITHUB_TOKEN reaches the build as the GITHUB_TOKEN build secret
#   for the GitHub API version lookups (1000 requests/hour per repository).
name: "Docker image"

on:
  push:
    branches: ["master", "develop"]
    tags: ["v*"]
  pull_request:
    paths:
      - "docker/**"
      - "docker-bake.hcl"
      - ".dockerignore"
      - "ansible/**"
      - "prepare-ubuntu.sh"
      - ".github/workflows/docker.yml"
  schedule:
    - cron: "0 6 * * 5"
  workflow_dispatch:

env:
  IMAGE_NAME: docker.io/CHANGEME/proveasio

permissions:
  contents: read

concurrency:
  group: docker-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  # `on.push.paths` would also filter master, so develop pushes are filtered
  # here instead. Pull requests use `paths:` above.
  plan:
    name: "Decide what to run"
    runs-on: ubuntu-latest
    outputs:
      build: ${{ steps.decide.outputs.build }}
      publish: ${{ steps.decide.outputs.publish }}
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0

      - name: Decide
        id: decide
        env:
          EVENT: ${{ github.event_name }}
          REF: ${{ github.ref }}
          BEFORE: ${{ github.event.before }}
          SHA: ${{ github.sha }}
        run: |
          set -euo pipefail
          build=true
          publish=false
          if [ "$EVENT" = push ]; then
            case "$REF" in
              refs/heads/master|refs/tags/v*) publish=true ;;
              refs/heads/develop)
                if [[ "$BEFORE" =~ ^0+$ ]] || ! git cat-file -e "${BEFORE}^{commit}" 2>/dev/null; then
                  build=true
                elif git diff --name-only "$BEFORE" "$SHA" \
                    | grep -qE '^(docker/|docker-bake\.hcl$|\.dockerignore$|ansible/|prepare-ubuntu\.sh$|\.github/workflows/docker\.yml$)'; then
                  build=true
                else
                  build=false
                fi
                ;;
            esac
          elif [ "$EVENT" = schedule ]; then
            publish=true
          elif [ "$EVENT" = workflow_dispatch ] && [ "$REF" = refs/heads/master ]; then
            publish=true
          fi
          echo "build=$build publish=$publish"
          echo "build=$build" >> "$GITHUB_OUTPUT"
          echo "publish=$publish" >> "$GITHUB_OUTPUT"

  image:
    name: "Build, test and publish"
    needs: plan
    if: needs.plan.outputs.build == 'true'
    runs-on: ubuntu-24.04
    timeout-minutes: 240
    env:
      # timestamp() in docker-bake.hcl changes per call; one value per run
      # keeps the receipt step on the cached build.
      REFRESH: ${{ github.run_id }}-${{ github.run_attempt }}
    steps:
      - uses: actions/checkout@v7
        with:
          ref: ${{ github.event_name == 'schedule' && 'master' || '' }}

      # The image is 10 GB or more. A standard runner has no room for it and
      # the build cache without this.
      - name: Free disk space
        run: |
          df -h /
          sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
          sudo docker image prune --all --force
          df -h /

      - uses: docker/setup-buildx-action@v4

      - name: Image metadata
        id: meta
        uses: docker/metadata-action@v6
        with:
          images: ${{ env.IMAGE_NAME }}
          # `git` reads the commit of the checkout (master on scheduled runs);
          # `workflow` would report the develop commit that triggered the run.
          context: ${{ github.event_name == 'schedule' && 'git' || 'workflow' }}
          flavor: |
            latest=false
          tags: |
            type=raw,value=latest,enable=${{ needs.plan.outputs.publish == 'true' && !startsWith(github.ref, 'refs/tags/') }}
            type=raw,value={{date 'YYYY-MM-DD'}},enable=${{ needs.plan.outputs.publish == 'true' && !startsWith(github.ref, 'refs/tags/') }}
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=sha-,format=short

      - name: Log in to Docker Hub
        if: needs.plan.outputs.publish == 'true'
        uses: docker/login-action@v4
        with:
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # Tests run inside this build. Non-publishing runs keep the result in
      # the builder cache only.
      - name: Build, test and push
        uses: docker/bake-action@v7
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          source: .
          files: |
            ./docker-bake.hcl
            cwd://${{ steps.meta.outputs.bake-file-tags }}
            cwd://${{ steps.meta.outputs.bake-file-labels }}
          targets: image
          set: |
            image.output=${{ needs.plan.outputs.publish == 'true' && 'type=registry' || 'type=cacheonly' }}

      - name: Export version receipt
        uses: docker/bake-action@v7
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          source: .
          files: ./docker-bake.hcl
          targets: receipt

      - name: Version receipt summary
        run: |
          {
            echo "### Versions in this image"
            echo
            echo '```yaml'
            cat out/current-versions.yml
            echo '```'
          } >> "$GITHUB_STEP_SUMMARY"

      - uses: actions/upload-artifact@v7
        with:
          name: current-versions
          path: out/current-versions.yml
```

- [ ] **Step 2: Lint the workflow**

```bash
cd /home/ziwi/projects/proveasio
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -color .github/workflows/docker.yml
```

Expected: no output, exit 0. Fix any finding (actionlint also runs shellcheck on `run:` blocks).

- [ ] **Step 3: Check the Bake inputs the workflow uses**

```bash
cd /home/ziwi/projects/proveasio
printf '{"target":{"docker-metadata-action":{"tags":["docker.io/CHANGEME/proveasio:latest"],"labels":{"org.opencontainers.image.revision":"x"}}}}' > /tmp/opencode/meta.json
REFRESH=ci docker buildx bake -f docker-bake.hcl -f /tmp/opencode/meta.json --set image.output=type=cacheonly --print image \
  | yq -p json '.target.image | {"tags": .tags, "output": .output, "labels": .labels, "refresh": .args.REFRESH}'
REFRESH=ci docker buildx bake -f docker-bake.hcl --print receipt | yq -p json '.target.receipt.output'
```

Expected: the CHANGEME tag, `type=cacheonly`, the revision label, `refresh: ci`; the receipt output is `type=local,dest=out`.

- [ ] **Step 4: State what is unverified**

The workflow cannot be run without pushing to GitHub, which needs the maintainer's go-ahead. Record in the Task 13 report: the workflow is linted and its Bake inputs resolve, but it has not run; runner disk space, Docker Hub push time and the scheduled-run checkout are unverified.

- [ ] **Step 5: Checkpoint**

Suggested commit: `ci(docker): Build, test and publish the Docker image`.

---

### Task 11: User documentation

**Files:**
- Create: `docs-web/docs/main/docker/_category_.yml`, `10-build.md`, `20-customize.md`, `30-run.md`, `40-limitations.md`
- Modify: `docs-web/docs/main/customization/30-config-files.md`, `docs-web/docs/main/features/50-neovim.md`, `docs-web/docs/main/installation.md`, `README.md`

**Interfaces:**
- Consumes: `/tmp/opencode/proveasio-measurements.md` from Task 8. In the text below, replace `IMAGE_SIZE` with the size from its `## Image` line (rounded to 0.5 GB), `BUILD_TIME` with the Task 8 Step 1 `real` time rounded to 5 minutes, `CLEANUP_TOTAL` with the `MiB removed in total` value converted to GB, and fill the size table in `40-limitations.md` from `## Largest directories`. These are measured values, so they cannot be written before Task 8 runs.

- [ ] **Step 1: Confirm the docs build before changes**

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm install && npm run build 2>&1 | tail -3
```

Expected: `[SUCCESS] Generated static files in "build".`

- [ ] **Step 2: Create `docs-web/docs/main/docker/_category_.yml`**

```yaml
position: 7.5
label: 'Docker image'
collapsible: true
className: red
link:
  type: generated-index
  title: Docker image
  description: Build Proveasio as a Docker image, customize the build, and run it as a dev shell or devcontainer.
```

- [ ] **Step 3: Create `10-build.md`**

````markdown
# Build the image

Instead of provisioning your machine, Proveasio can build a Docker image. The
build runs the same Ansible playbook inside `docker build`, so the image gets
the same tools and configuration as a native install. Every tool resolves to
its latest version unless you pin it.

## Requirements

- Docker Engine 23 or newer with the buildx plugin, or Docker Desktop.
  `docker buildx version` must work. Ubuntu's `docker.io` package does not
  include buildx. Install `docker-ce` and `docker-buildx-plugin` from
  [Docker's repository](https://docs.docker.com/engine/install/ubuntu/) instead.
- An x86_64 (amd64) machine. Many of the downloaded tools are amd64 builds.
- About 25 GB of free disk space for the image and the build cache.
- Network access to GitHub, the Ubuntu mirrors and the tools' download sites.

## Build

```shell
git clone https://github.com/Ziwi01/proveasio.git
cd proveasio
docker buildx bake
```

`docker buildx bake` reads `docker-bake.hcl` in the repository root. It builds
the image, runs the smoke tests, and loads the result as `proveasio:local`.
If a test fails, the build fails and no image is loaded.

A full build took BUILD_TIME on a 16-core machine and produced an image of
IMAGE_SIZE. The first build also compiles Python, which adds about 10 minutes.

## Getting the latest versions

Every build runs the playbook again and resolves `latest` again, because
`docker-bake.hcl` sets the `REFRESH` build argument to the current time. To
update your image, run `docker buildx bake` again.

When you change the build itself and do not want to wait for the playbook
each time, set a fixed value. The playbook layer is then reused from the
cache as long as its inputs did not change:

```shell
REFRESH=dev docker buildx bake
```

Editing `docker/overrides.yml` or your local Neovim config still triggers a
new playbook run, because both are part of the build cache key.

## GitHub token

About 33 of the version lookups call the GitHub API. Without a token GitHub
allows 60 calls per hour per public IP address, so you can run about one full
build per hour. A failed build uses up quota too. With a token the limit is
5000 per hour.

The token is optional. Pass one as an environment variable:

```shell
export GITHUB_TOKEN=<token>
docker buildx bake
```

Any token works, including a classic token with no scopes. If you use the
GitHub CLI, `GITHUB_TOKEN=$(gh auth token) docker buildx bake` does the same.
The token reaches the build as a build secret and is not stored in the image.

Pinned versions skip the API call entirely. See
[Customize the build](./customize).

## Pre-built image

The project also publishes the image to Docker Hub:

```shell
docker pull CHANGEME/proveasio:latest
```

| Tag | Content |
|---|---|
| `latest` | The newest build of `master`, rebuilt every week. |
| `YYYY-MM-DD` | The build of that day. Use it when you want the same tool versions every time you pull. |
| `X.Y.Z` | The build of a Proveasio release. |

Each image contains the exact versions it was built with in
`~/proveasio/current-versions.yml`.
````

- [ ] **Step 4: Create `20-customize.md`**

````markdown
# Customize the build

## Overrides file

Create `docker/overrides.yml`. It uses the same format as the native
`ansible/vars/overrides.yml`, so everything in the
[Customizations](../customization/variables) section applies: version pins,
excludes, the git identity, and any other role variable.

```yaml
git:
  name: James
  mail: james.doe@hell.no

github_packages:
  neovim: "0.12.5"

software_tasks_exclude:
  - puppet
  - azurecli
```

The file is in `.gitignore`. The native `ansible/vars/overrides.yml` is never
used for Docker builds, so settings for your own machine do not end up in the
image. To reuse it, copy it to `docker/overrides.yml`. A symlink does not
work.

Do not put `github_api_token` in this file. The build removes it and prints a
warning. Use the `GITHUB_TOKEN` environment variable described in
[Build the image](./build#github-token).

## Container defaults

`docker/profile.yml` holds the settings every Docker build needs. The build
merges it with your `docker/overrides.yml`:

- Lists are appended. Your `software_tasks_exclude` adds to the profile's list.
- Maps are merged key by key.
- The roles then merge `github_packages`, `pip_packages` and
  `docker_apt_packages` with their defaults key by key. Every other variable
  replaces the role default completely, as in a native run.

The profile:

- excludes `w32yank` and `wsl-notify-send`, which are Windows tools,
- installs Neovim from the release tarball, because the AppImage needs FUSE,
- installs the Docker client, Compose and Buildx plugins, but not the engine
  (see [Run the image](./run#docker-inside-the-container)),
- turns off config file backups.

To change one of these for every build, edit `docker/profile.yml`.

## Turning tools off

Use `software_tasks_exclude` and `config_tasks_exclude`. The names are listed
in [Excluding code](../customization/excludes).

When you exclude a software task that has a config task with the same name
(`zsh`, `tmux`, `ccmux`, `sdkman`, `lazygit`, `ansible`), exclude the config
task too. For `neovim`, exclude `neovim-config`.

The smoke tests read the same lists and skip what you excluded.

## Tags

`ANSIBLE_TAGS` and `ANSIBLE_SKIP_TAGS` are passed to the playbook as `--tags`
and `--skip-tags`:

```shell
ANSIBLE_SKIP_TAGS=puppet,rvm docker buildx bake
```

`--skip-tags` is safe. `--tags` builds an image from scratch with only the
selected tasks, so it has to include what those tasks depend on. For example,
`ANSIBLE_TAGS=neovim` alone fails, because the version lookups need `curl`
and `jq` from `software_packages`. Excludes are the better way to leave tools
out. The tag list is in [Partial run](../customization/partial-run).

## Neovim config

By default the build clones `neovim_config_url` at `neovim_config_version`.
Change both in `docker/overrides.yml` to use your own repository:

```yaml
neovim_config_url: https://github.com/you/nvim-config.git
neovim_config_version: main
```

To use a directory on your machine instead, set `NVIM_CONFIG`:

```shell
NVIM_CONFIG="$HOME/my-nvim" docker buildx bake
```

The directory is copied as it is, including uncommitted changes, and its
plugins are installed during the build. `neovim_config_appname` decides where
it goes (`~/.config/<appname>`).

## Build variables

Set these as environment variables when you run `docker buildx bake`.

| Variable | Default | Effect |
|---|---|---|
| `REFRESH` | current time | Any new value runs the playbook again. A fixed value reuses the cache. |
| `GITHUB_TOKEN` | unset | Token for the GitHub API version lookups. |
| `NVIM_CONFIG` | empty | Directory with a local Neovim config. |
| `ANSIBLE_TAGS` | empty | Passed as `--tags`. |
| `ANSIBLE_SKIP_TAGS` | empty | Passed as `--skip-tags`. |
| `UBUNTU_VERSION` | `24.04` | Tag of the `ubuntu` base image. |
| `USERNAME` | `dev` | User inside the image. |
| `USER_UID` / `USER_GID` | `1000` / `1000` | IDs of that user. Set them to yours (`id -u`, `id -g`) if you bind-mount files. |
| `IMAGE` | `proveasio:local` | Name of the loaded image. |

To see the resolved build definition without building, run
`docker buildx bake --print`.
````

- [ ] **Step 5: Create `30-run.md`**

````markdown
# Run the image

## Interactive shell

```shell
docker run -it --rm -v "$PWD":/workspace -w /workspace proveasio:local
```

This starts zsh with tmux, Neovim and the rest of the tools, as the user `dev`
with passwordless sudo. Your current directory is mounted at `/workspace`.

Files you create in `/workspace` belong to UID 1000. If your own UID is
different, build with `USER_UID=$(id -u) USER_GID=$(id -g) docker buildx bake`.

## Keeping state

Everything outside mounted directories is lost when the container stops. To
keep shell history and zoxide data, mount named volumes and point zsh's
history file into one of them:

```shell
docker run -it --rm \
  -v "$PWD":/workspace -w /workspace \
  -v proveasio-state:/home/dev/.local/state \
  -v proveasio-zoxide:/home/dev/.local/share/zoxide \
  -e HISTFILE=/home/dev/.local/state/zsh_history \
  proveasio:local
```

## Git identity

The image has the git identity from the build (the default is
`Proveasio <Proveasio@hell.no>`). Set yours in `docker/overrides.yml` before
building, or pass it when you start a container:

```shell
docker run -it --rm \
  -e GIT_AUTHOR_NAME="James" -e GIT_AUTHOR_EMAIL="james.doe@hell.no" \
  -e GIT_COMMITTER_NAME="James" -e GIT_COMMITTER_EMAIL="james.doe@hell.no" \
  proveasio:local
```

## Docker inside the container

The image has the Docker client, Compose and Buildx, but no engine. Mount the
host's socket to use the host engine, and add the socket's group so the user
`dev` can use it:

```shell
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  proveasio:local
```

`dry` and `kind` then work against the host engine.
Containers you start this way run on the host, next to this one.

## Devcontainer

A minimal `.devcontainer/devcontainer.json` for VS Code or DevPod:

```json
{
  "name": "proveasio",
  "image": "proveasio:local",
  "remoteUser": "dev",
  "updateRemoteUserUID": true,
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ]
}
```

`updateRemoteUserUID` changes the UID of `dev` to yours on Linux, so you do
not need to rebuild with `USER_UID`.

## Running the tests

The smoke tests are in the image:

```shell
docker run --rm proveasio:local /home/dev/proveasio/docker/test.sh
docker run --rm proveasio:local /home/dev/proveasio/docker/test.sh --list
docker run --rm proveasio:local /home/dev/proveasio/docker/test.sh --only software/neovim
```

With the Docker socket mounted, the `software/docker` check also connects to
the engine.

The tests check that each tool runs and reports the version recorded in
`~/proveasio/current-versions.yml`, and that zsh, tmux and Neovim start
without errors. They do not check that your configuration works the way you
want.

To get an image even when a test fails, for example to investigate the
failure, build the stage before the tests:

```shell
docker buildx bake --set image.target=build
```
````

- [ ] **Step 6: Create `40-limitations.md`**

Fill the table from `## Largest directories` in the measurements file (the ten largest entries, in GB with one decimal).

````markdown
# Limitations

## Size and build time

The image is about IMAGE_SIZE and a full build takes about BUILD_TIME. The
build already removes about CLEANUP_TOTAL of caches and build leftovers.
Most of the rest is the tools themselves. The largest parts, measured in an
image built with the defaults:

| Path | Size | Remove with |
|---|---|---|
| (from the measurements) | | |

To make the image smaller, exclude what you do not need. See
[Turning tools off](./customize#turning-tools-off).

## Other limitations

- **amd64 only.** On arm64 machines, such as Apple Silicon Macs, the image
  runs under emulation, which is slow and may not work for every tool.
- **Versions change between builds.** Two builds a day apart can contain
  different versions. Pin versions in `docker/overrides.yml`, or use a dated
  tag of the pre-built image.
- **No man pages.** The Ubuntu base image is minimized. Run `sudo unminimize`
  inside a container to restore them; it takes a few minutes and adds several
  hundred MB.
- **No systemd.** Nothing runs as a service inside the container, including
  the Docker engine.
- **ccmux notifications do nothing.** They are sent to Windows through the WSL
  bridge, which does not exist in a container.
- **opencode and older CPUs.** The build picks the opencode binary for the
  CPU of the machine that builds the image. The pre-built image uses the AVX2
  build and can crash on CPUs without AVX2. Build the image on your own
  machine in that case.
- **SDKMAN is not loaded by the shell.** As in a native install, run
  `source ~/.sdkman/bin/sdkman-init.sh` before using `java`, `gradle`,
  `groovy` or `mvn`.
````

The table's `Remove with` column names the exclude that removes each path (for example `sdkman` for `~/.sdkman`, `rvm` and `puppet` for `~/.rvm`, `neovim-config` for `~/.local/share/astronvim`). Leave it empty for paths no exclude removes. Replace the `(from the measurements)` row with real rows.

- [ ] **Step 7: Update existing pages**

`docs-web/docs/main/customization/30-config-files.md`: replace the `:::note[Neovim config]` block with:

```markdown
:::note[Neovim config]
Neovim config (based on AstroNvim) has its own repository. You can fork it and modify it, or use your own config entirely. For details see [Neovim usage section](../../usage/vim).

To use your own repository, set `neovim_config_url` and `neovim_config_version` in `ansible/vars/overrides.yml`. To use a directory on your machine instead, set:

```yaml
neovim_config_source: local
neovim_config_local_path: /home/you/my-nvim
```

The directory is copied to `~/.config/<neovim_config_appname>` on every run.
:::
```

`docs-web/docs/main/features/50-neovim.md`: append:

```markdown

Neovim is installed as an AppImage by default. AppImages need FUSE. Where FUSE is not available, install the release tarball instead by setting this in `ansible/vars/overrides.yml`:

```yaml
neovim_package: tarball
```
```

`docs-web/docs/main/installation.md`: append:

```markdown

:::tip[Docker]
To build Proveasio as a Docker image instead of installing it on this machine, see [Docker image](./docker/build).
:::
```

`README.md`: in `## Installation and usage`, after the documentation link line, add:

```markdown

To build it as a Docker image instead, see [Docker image](https://ziwi01.github.io/proveasio/main/docker/build).
```

- [ ] **Step 8: Build the docs and check links**

```bash
cd /home/ziwi/projects/proveasio/docs-web && npm run build 2>&1 | tail -5
ls build/main/docker/
grep -rn '—' docs/main/docker/ || echo "no em dashes"
grep -rn -e 'IMAGE_SIZE' -e 'BUILD_TIME' -e 'CLEANUP_TOTAL' -e '(from the measurements)' docs/main/docker/ ../README.md || echo "no leftovers"
```

Expected: `[SUCCESS]`, the directories `build`, `customize`, `run`, `limitations`, `no em dashes` and `no leftovers`. `onBrokenLinks: 'throw'` fails the build on any broken internal link; fix the link, do not change the setting.

- [ ] **Step 9: Checkpoint**

Suggested commit: `docs(docker): Document building, customizing and running the image`.

---

### Task 12: Maintainer notes, found bugs, spec sync

**Files:**
- Modify: `AGENTS.md`, `TODO.md`, `docs/superpowers/specs/2026-09-24-docker-image-design.md`
- Serena memory: create `docker-image`

- [ ] **Step 1: Update `AGENTS.md`**

Replace the heading `## Adding software — four edits minimum` and its numbered list items 1-4 with:

```markdown
## Adding software: five edits minimum

1. `roles/software/tasks/<tool>.yml`: copy `hunk.yml` or `eza.yml`; they are the canonical shape.
2. Register in `roles/software/tasks/main.yml` with
   `when: "'<tool>' not in software_tasks_exclude"` and `tags: [software, versions, <tool>]`.
3. Add the key to `github_packages` in `roles/software/vars/main.yml`. **Required**:
   `common/tasks/github_version.yml` looks up `github_packages[app]`.
4. Add `check_software_<tool>` (dashes become underscores) to `docker/test.sh`. **Required**:
   the Docker build fails for any selected include without a check.
   `docker/test.sh --coverage` lists missing checks without building.
5. Update the docs (see below).
```

Add a new section before `## Tags: what actually works`:

```markdown
## Docker image

`docker buildx bake` (repo root) builds `docker/Dockerfile` from `docker-bake.hcl`. The playbook
runs inside the build; `.github/workflows/docker.yml` publishes it.

- Inputs: `docker/profile.yml` (committed container defaults) merged with the gitignored
  `docker/overrides.yml` by `docker/render-overrides.sh` (`yq *+`: maps merge, lists append).
  The native `ansible/vars/overrides.yml` is excluded by `.dockerignore`.
- `docker/test.sh` runs in the `test` stage; `final` depends on it. It selects checks from the
  includes in `software`/`config` `tasks/main.yml`, the effective excludes and the build tags.
- `docker/cleanup.sh` runs in the playbook layer. It must not delete paths the roles use as
  "already installed" gates.
- `REFRESH` defaults to `timestamp()`, so every local build re-resolves `latest`. CI pins it per run.
- Verify Docker changes with `docker buildx bake --print` and a smoke build:
  `ANSIBLE_TAGS=software_packages,yq,eza,zsh,neovim,neovim-config,docker IMAGE=proveasio:smoke docker buildx bake`.
```

- [ ] **Step 2: Update `TODO.md`**

Append:

```markdown
- [ ] fix(neovim): `software/tasks/neovim.yml:4-11` passes a pipe to `ansible.builtin.command`, so the installed-version check never works and Neovim is reinstalled on every run
- [ ] fix(nvm): `software/tasks/nvm.yml` installs with `creates:`, so nvm is never upgraded while `current-versions.yml` records the newly resolved version (native: installed 0.40.0, receipt 0.40.8)
- [ ] fix(opencode): `software/tasks/opencode.yml:20` picks the AVX2 build from the build host's `/proc/cpuinfo`; the published Docker image can crash with SIGILL on CPUs without AVX2
- [ ] fix(sdkman): `.zshrc` does not load SDKMAN, so `sdk`, `java`, `gradle`, `groovy`, `mvn` are not on the interactive PATH
- [ ] chore(ci): `build.yml`'s weekly cron runs on the default branch `develop`, not `master`; confirm whether that is intended
```

- [ ] **Step 3: Sync the spec**

In `docs/superpowers/specs/2026-09-24-docker-image-design.md`:
- Replace role change item 4 with: "`zshrc.j2`: load every tool integration only when the tool exists (plugins `fzf`, `fzf-tab`, `fzf-tab-source`, `zoxide`; `pay-respects`, `switcher`, `kubectl`/`kubecolor`, `fzf --zsh`, the fzf-tab source line, `.cargo/env`, gvm) and render the eza FPATH block only when `eza_version` is defined."
- In "Stage `receipt`", change "from `final`" to "from `build`, so `final` stays the last stage".
- In the playbook `RUN` command list, add after the playbook: "Mason/treesitter sync (`MasonToolsInstallSync`, `TSUpdateSync`, no-ops when undefined)" and after cleanup: "warm zsh once under `script` so p10k's gitstatusd is in the image".
- In "Tests", add: "Checks run in bash with the PATH of an interactive zsh captured through `script`. Flags: `--list`, `--only`, `--coverage`."
- In "CI workflow", add: "A `plan` job decides `build` and `publish`; it path-filters `develop` pushes because `on.push.paths` would also filter `master`. `REFRESH` is pinned per run so the receipt step hits the cache."
- In "Files", add `/out/` to the `.gitignore` line.

- [ ] **Step 4: Write the Serena memory**

Use `serena_write_memory` with name `docker-image` and content summarizing: the file list, the merge rule, the five-edit rule, the smoke-build command, `REFRESH` behaviour, the `script`-based zsh PATH capture and why (`EXTENDED_GLOB`, zle errors without a TTY), the measured image size and build time from Task 8, and the unverified CI items.

- [ ] **Step 5: Checkpoint**

Suggested commit: `chore: Document the Docker image for maintainers and record found bugs`.

---

### Task 13: Final verification

- [ ] **Step 1: Run every gate**

```bash
cd /home/ziwi/projects/proveasio/ansible && ansible-lint 2>&1 | tail -1
ansible-playbook -i inventory.yml setup-ubuntu.yml --syntax-check
ansible-playbook -i inventory.yml setup-ubuntu.yml --list-tags 2>/dev/null > /tmp/opencode/tags-after.txt
cd /home/ziwi/projects/proveasio && PROVEASIO_HOME="$PWD" bash docker/test.sh --coverage | tail -1
bash /tmp/opencode/render-test.sh
bash /tmp/opencode/cleanup-test.sh
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -color
cd docs-web && npm run build 2>&1 | tail -1
```

Expected: `Passed: 0 failure(s)`; `playbook: setup-ubuntu.yml`; `# 54 includes, 0 without a check`; both script tests pass; actionlint silent; `[SUCCESS]`.

- [ ] **Step 2: Confirm the tag list did not change**

Compare with the baseline recorded in Task 1 Step 0 (no `git stash`, so uncommitted work is never touched):

```bash
diff /tmp/opencode/tags-before.txt /tmp/opencode/tags-after.txt && echo "tags unchanged"
```

Expected: `tags unchanged` (no new outer tags, so `50-partial-run.md` needs no edit).

- [ ] **Step 3: Review the change set**

```bash
cd /home/ziwi/projects/proveasio
git status --short
git diff --stat
git status --short --ignored docker/ | grep overrides || echo "no docker/overrides.yml"
```

Expected: only the files in the File map, plus the spec and plan documents. No `docker/overrides.yml`, no `out/`, no `current-versions.yml` changes.

- [ ] **Step 4: Report**

Report to the maintainer, with the command output behind each claim:
- gate results from Step 1,
- the three build results (smoke, full, custom) with their test summaries,
- measured image size, build time and cleanup total,
- every fix made during Tasks 7-9 and why,
- unverified items: the workflow has not run on GitHub (disk space, push time, scheduled checkout), the devcontainer example, native AppImage path (unchanged code, not re-run on this machine),
- the TODO items added in Task 12,
- a proposed commit split using the suggested subjects above, for the maintainer to approve.

---

## Self-review

Spec coverage, section by section:

| Spec section | Task |
|---|---|
| Decisions (usage, Docker CLI, tarball, contents, Bake, token, local config, CI, credentials, base image) | 1, 2, 4, 7, 10 |
| Files | File map; 1-12 |
| Build context | 4 |
| Dockerfile stages and steps | 7 |
| Configuration: override layers, profile, tags, Neovim config, Bake file | 4, 7 |
| Role changes 1-4 | 1, 2, 3 |
| Size reduction (cleanup rules, llvm, test suite, no-recommends, measurement) | 5, 7, 8 |
| Tests | 6, 7, 8, 9 |
| CI workflow | 10 |
| Documentation (new category, updates, AGENTS.md) | 11, 12 |
| Caveats | 11 (`40-limitations.md`), 13 report |
| Found, not fixed | 12 (`TODO.md`) |
| Verification 1-9 | 1-3, 7, 8, 9, 10, 11, 13 |

Placeholder scan: `IMAGE_SIZE`, `BUILD_TIME`, `CLEANUP_TOTAL` and the size table rows in Task 11 are measured values produced by Task 8; Task 11 Step 8 fails if any remain. `CHANGEME` is the placeholder the maintainer asked for.

Name consistency: `render-overrides.sh` env names (`PROVEASIO_HOME`, `DOCKER_DIR`, `NVIM_CONFIG_DIR`) match Task 7's mounts (`/tmp/proveasio-docker`, `/tmp/nvim-config`); `build-info.env` keys match `test.sh`; Bake targets `image`, `receipt`, `docker-metadata-action` and variable `REFRESH` match Task 10; check function naming (`check_<role>_<name>`, dashes to underscores) matches `check_fn`.
