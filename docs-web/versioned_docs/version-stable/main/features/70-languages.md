# Languages

## Python

Python gets instaled with pretty recent version using [`pyenv`](https://github.com/pyenv/pyenv) version manager. This Python is set as default for ZSH shell and all PIP packages which get installed during ansible run are installed there.

Also, there is [`pyenv-virtualenv`](https://github.com/pyenv/pyenv-virtualenv) available to easily manage Python virtual environments.

For usage examples see [Usage](../../usage/terminal#languages)

# Go

Automatic installation of Go is done using [`GVM`](https://github.com/moovweb/gvm) - Go Version Manager. See [Usage](../../usage/terminal#languages) for details.

## Ruby

For Ruby management, there is [Ruby Version Manager (RVM)](https://rvm.io/) installed. See available Ruby's with `rvm list`, use particular with `rvm use <ruby_version>`. There are some gems already preinstalled on Rubys available here (like `neovim` gem, or if Puppet is being installed, it installs `puppet` and `puppet-lint` gems).

## JAVA/groovy

For multiple versions management for Java, groovy, gradle JDKs/SDKs, [SDKMAN!](https://sdkman.io/) manager is installed and some default JAVA and groovy versions.

## Node

For Node, there is [NVM](https://github.com/nvm-sh/nvm) installed. See NPM versions with `nvm list`. By default there is latest LTS installed.

## Puppet

`Puppet` and `puppet-lint` gems are installed on all configured rubys. Also, latest [PDK](https://puppet.com/try-puppet/puppet-development-kit/) is available.

There is Puppet LSP (language server protocol) called [Puppet Editor Services](https://github.com/puppetlabs/puppet-editor-services) installed in `~/.lsp/puppet-editor-services`.

:::note
By default, Puppet gets installed **for all rubies**. If you choose to install latest puppet **AND** older rubies (like 2.4.x), there might be some dependencies errors. If you don't want to install Puppet for all rubies, set `puppet_rubies` in `vars/overrides.yml` to an array with rubies names. With latest 3.x.x ruby there shouldn't be a problem
:::

## Ansible

Ansible gets installed using PIP in designated `pyenv` Python environment. Also ansible-lint gets installed.

Also, there is an [Ansible Language Server](https://github.com/ansible/ansible-language-server) installed globally using default NPM.

To configure linter diagnostics (enable/disable some checks) for Ansible files, see: `ansible/roles/config/files/ansible-lint`

## Rust

[Rust](https://www.rust-lang.org/) is installed with [Cargo](https://github.com/rust-lang/cargo/) package manager.
