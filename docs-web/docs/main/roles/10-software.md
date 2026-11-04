# `software`

This role installs the tools. Each row below is one task file in `ansible/roles/software/tasks/`. Its name is both the **tag** (`--tags <name>`, see [Run particular code](../customization/50-partial-run.md)) and the **exclude name** (`software_tasks_exclude`, see [Excluding code](../customization/40-excludes.md)).

Most tools are downloaded from their GitHub releases into `~/.local/opt/<tool>-<version>` and linked into `~/.local/bin`. Old versions are removed afterwards, see [Cleaning up old versions](../customization/45-cleanup.md).

## Required

These cannot be excluded. The playbook stops at the start if `software_tasks_exclude` lists one of them.

| Name | Installs |
|---|---|
| `packages` | Ubuntu packages from `default_apt_packages`: `tree`, `htop`, `jq`, `bat`, `gh`, `gdu`, `keychain`, `rsync`, `sqlite3`, build tools and more. Tag: `software_packages`. |
| `yq` | [yq](https://mikefarah.gitbook.io/yq/) - YAML, JSON and XML processor. The playbook itself uses it. |
| `zsh` | [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) plugins from `omz_plugins` and the [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme |

## Shell and terminal

| Name | Installs |
|---|---|
| `tmux` | [tmux](https://github.com/tmux/tmux), built from source, with the [tpm](https://github.com/tmux-plugins/tpm) plugin manager |
| `fzf` | [fzf](https://github.com/junegunn/fzf) - fuzzy finder |
| `zoxide` | [zoxide](https://github.com/ajeetdsouza/zoxide) - jump to visited directories |
| `eza` | [eza](https://github.com/eza-community/eza) - modern `ls`, aliased as `ls` and `ll`, with zsh completion |
| `ripgrep` | [ripgrep](https://github.com/BurntSushi/ripgrep) - fast recursive grep |
| `fd` | [fd](https://github.com/sharkdp/fd) - fast `find` alternative |
| `fx` | [fx](https://github.com/antonmedv/fx) - terminal JSON viewer |
| `pay-respects` | [pay-respects](https://github.com/iffse/pay-respects) - corrects the previous command |
| `bottom` | [bottom](https://github.com/ClementTsang/bottom) (`btm`) - system monitor |
| `curlie` | [curlie](https://github.com/rs/curlie) - `curl` frontend with HTTPie-style output; accepts all `curl` options |
| `shellcheck` | [ShellCheck](https://github.com/koalaman/shellcheck) - static analysis for shell scripts (latest release, newer than the Ubuntu package) |
| `w32yank` | [win32yank](https://github.com/equalsraf/win32yank) - Windows clipboard for Neovim on WSL |

## Git

| Name | Installs |
|---|---|
| `git` | Latest [Git](https://git-scm.com/) from the [git-core PPA](https://launchpad.net/~git-core/+archive/ubuntu/ppa) |
| `lazygit` | [lazygit](https://github.com/jesseduffield/lazygit) - terminal UI for Git |
| `diff-so-fancy` | [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - readable diffs |
| `git-fuzzy` | [git-fuzzy](https://github.com/bigH/git-fuzzy) - Git commands in fzf |
| `gita` | [Gita](https://github.com/nosarthur/gita) - run commands on groups of repositories |
| `lsg` | [ls-with-git-status](https://github.com/gerph/ls-with-git-status) - `ls` with Git status |
| `hunk` | [hunk](https://github.com/modem-dev/hunk) - terminal code review and diff viewer, with the hunk-review skill for opencode |
| `revdiff` | [revdiff](https://github.com/umputun/revdiff) - review diffs and plans with line annotations for AI agents, with its opencode plugin (`/revdiff`); sets `untracked = true` and `word-diff = true` in `~/.config/revdiff/config` |

## Editor

| Name | Installs |
|---|---|
| `neovim` | [Neovim](https://github.com/neovim/neovim), as an AppImage or a tarball (`neovim_package`). The config is installed by the [config role](./20-config.md). |

## Languages and version managers

| Name | Installs |
|---|---|
| `nvm` | [NVM](https://github.com/nvm-sh/nvm) with the latest LTS Node (`node_version`) and the npm packages from `npm_default_packages` |
| `gvm` | [GVM](https://github.com/moovweb/gvm) with the Go versions from `go_versions` |
| `rvm` | [RVM](https://rvm.io/) (with [rvm1-ansible](https://github.com/rvm/rvm1-ansible)) and the Rubies from `rvm1_rubies` (default `ruby-3.4.7`) |
| `sdkman` | [SDKMAN!](https://sdkman.io/) with Java, Gradle, Groovy and Maven (`sdkman_install_packages`) |
| `rust` | [Rust](https://www.rust-lang.org/) with `rustup` and Cargo |
| `uv` | [uv](https://github.com/astral-sh/uv) - Python package and project manager |
| `ansible` | Ansible and ansible-lint (pip), and the Ansible Language Server (npm, needs `nvm`) |
| `puppet` | `puppet` and `puppet-lint` gems for the Rubies in `puppet_rubies`, [PDK](https://www.puppet.com/docs/pdk/latest/pdk.html) and [Puppet Editor Services](https://github.com/puppetlabs/puppet-editor-services) (needs `rvm`) |

Python itself is installed by `prepare-ubuntu.sh` with [pyenv](https://github.com/pyenv/pyenv) and [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv), not by this role.

## Containers and Kubernetes

| Name | Installs |
|---|---|
| `docker` | [Docker](https://www.docker.com/) engine and the Compose plugin from Docker's APT repository (`docker_apt_packages`). With `docker_manage_service: false` and `docker-ce: absent` it installs only the client. |
| `dry` | [dry](https://github.com/moncho/dry) - terminal UI for Docker |
| `kubectl` | [kubectl](https://kubernetes.io/docs/reference/kubectl/), latest stable from `dl.k8s.io` |
| `kubecolor` | [kubecolor](https://github.com/kubecolor/kubecolor) - colorized `kubectl` (aliased as `kubectl`) |
| `kubeswitch` | [kubeswitch](https://github.com/danielfoehrKn/kubeswitch) (`switch`) - switch contexts and namespaces |
| `kind` | [kind](https://kind.sigs.k8s.io/) - local Kubernetes clusters in Docker |
| `k9s` | [k9s](https://github.com/derailed/k9s) - terminal UI for Kubernetes |
| `helm` | [Helm](https://github.com/helm/helm) - Kubernetes package manager |
| `helm-unittest` | [helm-unittest](https://github.com/helm-unittest/helm-unittest) - unit tests for Helm charts (`helm unittest`). A Helm plugin, so it needs `helm`. It is linked into `helm_plugins_dir` (default `~/.local/share/helm/plugins`); a `helm-unittest` plugin installed there by other means is replaced. |
| `kubeconform` | [kubeconform](https://github.com/yannh/kubeconform) - Kubernetes manifest validator |
| `dyff` | [dyff](https://github.com/homeport/dyff) - YAML diff with Kubernetes-aware output |
| `argocd` | [Argo CD CLI](https://github.com/argoproj/argo-cd) with zsh completion |
| `argonaut` | [Argonaut](https://github.com/darksworm/argonaut) - terminal UI for Argo CD; uses the session saved by `argocd login` |
| `stern` | [stern](https://github.com/stern/stern) - tail logs of many pods and containers at once, filtered by name regex or label |
| `crane` | [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md) - container registry CLI: list tags, copy images between registries, read digests and manifests without pulling |

## Infrastructure as code and cloud

| Name | Installs |
|---|---|
| `tenv` | [tenv](https://github.com/tofuutils/tenv) - version manager for Terraform, OpenTofu and Terragrunt. Links its proxies (`terraform`, `tofu`, `terragrunt`, `terramate`, `tf`, `atmos`) into `~/.local/bin`. The tasks below need it. |
| `terraform` | [Terraform](https://github.com/hashicorp/terraform), installed with tenv. The repository picks the version. See [Terraform, OpenTofu and Terragrunt versions](#terraform-opentofu-and-terragrunt-versions). |
| `tofu` | [OpenTofu](https://github.com/opentofu/opentofu), installed with tenv, like `terraform` |
| `terragrunt` | [Terragrunt](https://github.com/gruntwork-io/terragrunt), installed with tenv, like `terraform` |
| `tflint` | [TFLint](https://github.com/terraform-linters/tflint) - Terraform linter; provider rulesets are set per project in `.tflint.hcl` |
| `terraform-docs` | [terraform-docs](https://github.com/terraform-docs/terraform-docs) - generates the inputs and outputs documentation of a module |
| `spacectl` | [spacectl](https://github.com/spacelift-io/spacectl) - Spacelift CLI: runs, logs, local previews |
| `azurecli` | [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) and [kubelogin](https://github.com/Azure/kubelogin) |
| `az-account-switcher` | [az-account-switcher](https://github.com/abij/az-account-switcher) (`az-switch`) |
| `awscli` | [AWS CLI](https://github.com/aws/aws-cli) v2 |
| `granted` | [Granted](https://github.com/fwdcloudsec/granted) (`assume`) - switch AWS profiles and SSO roles in the current shell, open the console for a role |
| `session-manager-plugin` | [Session Manager plugin](https://github.com/aws/session-manager-plugin) - lets `aws ssm start-session` open shells and port forwards without SSH. Unpacked from AWS's `.deb`, no `sudo`. |
| `taws` | [taws](https://github.com/huseyinbabal/taws) - terminal UI for AWS resources, in the style of k9s |
| `eksctl` | [eksctl](https://github.com/eksctl-io/eksctl) - CLI for Amazon EKS clusters, node groups, add-ons and IAM service accounts |
| `eks-node-viewer` | [eks-node-viewer](https://github.com/awslabs/eks-node-viewer) - live node usage against requests, with cost per node |
| `steampipe` | [Steampipe](https://github.com/turbot/steampipe) - SQL queries against cloud APIs. Plugins are not installed: run `steampipe plugin install aws`. |

### Terraform, OpenTofu and Terragrunt versions

The repository decides the version. [tenv](https://tofuutils.github.io/tenv/)'s proxies look for it in this order, first match wins:

1. an environment variable (`TFENV_TERRAFORM_VERSION`, `TOFUENV_TOFU_VERSION`, `TG_VERSION`)
2. a version file in the directory or a parent: `.terraform-version` (or `.tfswitchrc`), `.opentofu-version`, `.terragrunt-version`, `.tool-versions`
3. a version constraint in `terragrunt.hcl` or `root.hcl`
4. the global default in `~/.tenv/<Terraform|OpenTofu|Terragrunt>/version`, written by `tenv tf use <version>`
5. the newest installed version that satisfies `required_version`

Proveasio installs the version from `github_packages` (`latest` by default) and does **not** write a global default: it would win over `required_version`. Outside a repository, the newest installed version runs. `.zshrc` sets `TENV_AUTO_INSTALL=true`, so a version a repository asks for is downloaded on first use. Proveasio never removes versions tenv installed; use `tenv tf uninstall <version>`.

Before tenv, Proveasio unpacked these tools into `~/.local/opt/<tool>-<version>`. The first run with tenv deletes those directories and points `~/.local/bin/terraform`, `tofu` and `terragrunt` at tenv's proxies. Pins in `github_packages` keep working.

Excluding `tofu` or `terragrunt` skips installing a version, but tenv's proxy for it stays on the `PATH`. With `TENV_AUTO_INSTALL`, calling it installs a version.

## AI coding agents

| Name | Installs |
|---|---|
| `opencode` | [opencode](https://github.com/anomalyco/opencode) - terminal AI coding agent. Installs v2 by default; pin a 1.x version to keep v1 (see [opencode v1 and v2](../customization/20-versions.md#opencode-v1-and-v2)). Can also install with a preinstalled Homebrew (`opencode_package: brew`, see [Install opencode with Homebrew](../customization/20-versions.md#install-opencode-with-homebrew)). |
| `ccmux` | [ccmux](https://github.com/epilande/ccmux) - run and track AI coding agents (opencode, Claude Code, Codex and more) in tmux, with live session states, a sidebar and desktop notifications |
| `wsl-notify-send` | [wsl-notify-send](https://github.com/stuartleeks/wsl-notify-send) - bridges ccmux notifications to Windows toasts on WSL |

## Bundles

A bundle groups the tools for one purpose. Its name works as a tag (`--tags terraform-tools`) and as an exclude name (`software_tasks_exclude: [terraform-tools]`). You can still leave out single tools of a selected bundle:

```shell
ansible-playbook -i inventory.yml setup-ubuntu.yml --tags terraform-tools --skip-tags tofu -K
```

```yaml
# ansible/vars/overrides.yml: everything AWS, except taws
software_tasks_exclude:
  - azure-tools
  - taws
```

| Bundle | Tools |
|---|---|
| `aws-tools` | `awscli`, `granted`, `session-manager-plugin`, `taws`, `eksctl`, `eks-node-viewer`, `steampipe` |
| `azure-tools` | `azurecli`, `az-account-switcher` |
| `kubernetes-tools` | `kubectl`, `kubecolor`, `kubeswitch`, `k9s`, `helm`, `helm-unittest`, `kubeconform`, `dyff`, `kind`, `stern`, `crane` |
| `terraform-tools` | `tenv`, `terraform`, `tofu`, `terragrunt`, `tflint`, `terraform-docs` |
| `argocd-tools` | `argocd`, `argonaut` |
| `spacelift-tools` | `spacectl` |

Bundles are defined in `software_bundles` in `ansible/roles/software/vars/main.yml`. Each member's include in `tasks/main.yml` carries the bundle tag; the playbook stops at the start if a member is not an include name.

## Dependencies

What a tool needs, and what it installs besides itself. A tool listed under "Needs" must be installed too, by the same run or an earlier one.

| Tool | Needs | Also installs |
|---|---|---|
| every GitHub tool | `packages` (`curl`, `jq`, `unzip`), `yq` (version receipt) | |
| `zsh` | `packages` | oh-my-zsh plugins, powerlevel10k |
| `ansible` | Python (`prepare-ubuntu.sh`), `nvm` | ansible-lint, Ansible Language Server (npm) |
| `neovim` config | `nvm`, `gvm`, `rvm` | language servers and tools through Mason (npm, go and gem packages) |
| `puppet` | `rvm` | puppet, puppet-lint, PDK, Puppet Editor Services |
| `helm-unittest` | `helm` | |
| `azurecli` | | kubelogin |
| `terraform`, `tofu`, `terragrunt` | `tenv` | |
| `tenv` | | proxies: `terraform`, `tofu`, `terragrunt`, `terramate`, `tf`, `atmos` |
| `granted` | | `assume`, `assumego` |
| `argonaut` | `argocd` login (`argocd login`) | |
| `session-manager-plugin` | `awscli` to be useful | |
| `ccmux` | `tmux` | |
| `wsl-notify-send` | WSL | |

## Configuration

Everything this role can configure is in `ansible/roles/software/vars/main.yml`. Override it in `ansible/vars/overrides.yml`, see [Customizations](../../category/customizations). For example, to skip some tools:

```yaml
software_tasks_exclude:
  - azurecli
  - puppet
```
