# Languages and toolchains

Every language comes with a version manager, so you can install more versions next to the default one and switch between them. Usage examples are in [Terminal usage](../../usage/20-terminal.md#languages).

## Python

Python is installed with the [`pyenv`](https://github.com/pyenv/pyenv) version manager, in a recent version (`prepare-ubuntu.sh` sets it). It is the default Python in zsh, and every pip package the playbook installs goes there, so the system Python stays untouched.

[`pyenv-virtualenv`](https://github.com/pyenv/pyenv-virtualenv) manages virtual environments, and [uv](https://github.com/astral-sh/uv) is installed as a fast package and project manager.

## Go

Go is installed with [GVM](https://github.com/moovweb/gvm) (Go Version Manager). The versions are set by `go_versions` and `go_default`.

## Ruby

Ruby is managed by [RVM](https://rvm.io/). List the installed versions with `rvm list` and switch with `rvm use <ruby_version>`. Some gems are preinstalled for every Ruby: the `neovim` gem, and `puppet` and `puppet-lint` when Puppet is installed.

## Java, Gradle, Groovy and Maven

[SDKMAN!](https://sdkman.io/) manages the JDKs and SDKs. By default it installs Java (OpenJDK), Gradle, Groovy and Maven; see `sdkman_install_packages` in `ansible/roles/software/vars/main.yml`.

## Node

Node is managed by [NVM](https://github.com/nvm-sh/nvm). List the installed versions with `nvm list`. By default the latest LTS is installed. nvm loads lazily, on the first `nvm` call, to keep the shell start fast.

## Rust

[Rust](https://www.rust-lang.org/) is installed with `rustup` and the [Cargo](https://github.com/rust-lang/cargo/) package manager.

## Puppet

The `puppet` and `puppet-lint` gems are installed for every Ruby, together with the latest [PDK](https://www.puppet.com/docs/pdk/latest/pdk.html).

The Puppet language server, [Puppet Editor Services](https://github.com/puppetlabs/puppet-editor-services), is installed in `~/.lsp/puppet-editor-services`.

:::note
By default, Puppet is installed **for all Rubies**. With the latest Puppet **and** an old Ruby (like 2.4.x), the gems may fail on dependencies. To install Puppet only for some Rubies, set `puppet_rubies` in `ansible/vars/overrides.yml` to a list of Ruby names.
:::

## Ansible

Ansible and ansible-lint are installed with pip into the pyenv Python.

The [Ansible Language Server](https://github.com/ansible/vscode-ansible) is installed globally with npm.

To turn linter checks on or off for Ansible files, edit `ansible/roles/config/files/ansible-lint` (deployed as `~/.ansible-lint`).
