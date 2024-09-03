<div align="center">
  <img width=400 height=300 src="./docs-web/static/assets/proveasio-logo.png">
</div>

<div align="center">

<a href="">![CI build](https://github.com/Ziwi01/proveasio/actions/workflows/pre-release.yml/badge.svg?branch=master)</a>
<a href="">![License](https://img.shields.io/github/license/Ziwi01/proveasio)</a>
<a href="">![Last commit](https://img.shields.io/github/last-commit/Ziwi01/proveasio)</a>

</div>

## TL;DR

Prepare your Ubuntu terminal dev environment with one command (well, sort of). Become terminal power-user in no time.

Install, configure and maintain Ubuntu 24.04/22.04 terminal environment focused on development and administration. This includes installation/configuration of very useful dev tools and customizations to ease out and speed up terminal usage during day-to-day work and to bump up productivity.

Below project is supported on Ubuntu running on Windows WSL2, but it is also tested on Ubuntu 22.04/24.04 images.

## Features

Below you can find brief summary of included tools and features. For more details see [documentation](https://ziwi01.github.io/proveasio). For usage scenarios with examples (screenshots, videos), see [Usage](https://ziwi01.github.io/preveasio/usage/about).

- Zsh Terminal with [Oh-my-ZSH](https://github.com/ohmyzsh/ohmyzsh) framework, with [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. It features e.g syntax higlighting, autocompletion, history search with [FZF](https://github.com/junegunn/fzf), aliases autosuggestion, easy directory traverse and more.

    <details>
      <summary><b>Example:</b> Terminal commandline</summary>
      <div align="center">
        <img src="./docs-web/static/terminal_preview.png" />
      </div>
    </details>
    <br />

- [TMUX](https://github.com/tmux/tmux) (Terminal multiplexer) - easily divide your terminal, create new windows, sessions, projects.

- GIT improvements and integrations:

  - [LazyGIT](https://github.com/jesseduffield/lazygit) GUI
  - pretty diff formatting
  - `ls` with GIT status
  - new git commands and aliases
  - grouping GIT repos and bulk executing commands on them

- DevOps tools:

  - [Docker](https://www.docker.com/) with [docker-compose](https://docs.docker.com/compose/)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - manage kubernetes cluster
  - [KinD](https://kind.sigs.k8s.io/) - Kubernetes in docker - create a cluster locally
  - [k9s](https://github.com/derailed/k9s) - Terminal GUI for managing kubernetes clusters
  - [Helm](https://github.com/helm/helm) - Kubernetes package manager
  - [Terraform](https://github.com/hashicorp/terraform) - infrastructure as code tool
  - [Terragrunt](https://github.com/gruntwork-io/terragrunt) - wrapper for Terraform to deal with multiple environments
  - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) - CLI interface for Azure management
  - [AWS CLI](https://github.com/aws/aws-cli) - CLI interface to interact with AWS

- Neovim replaces VIM. By default uses custom configured AstroNvim IDE for Neovim, which makes VIM fully functional, feature-rich IDE. You can also use your own config/modifications

- Useful software:

  - [ripgrep](https://github.com/BurntSushi/ripgrep) - much faster grep. Also used from within VIM to grep for text.
  - [fd](https://github.com/sharkdp/fd) - faster `find` command
  - [bat](https://github.com/sharkdp/bat) - prettier cat with syntax highlight, line numbers etc.
  - [yq](https://mikefarah.gitbook.io/yq/) - YAML parser
  - [htop](https://github.com/htop-dev/htop) - better top
  - [jq](https://stedolan.github.io/jq/) - JSON parser

- Languages support (with version management):

  - Python
  - Go
  - Ruby
  - JAVA
  - Groovy
  - NodeJS
  - Puppet
  - Ansible
  - Rust

## Installation and usage

For detailed instructions see [documentation](https://ziwi01.github.io/proveasio)

## Troubleshooting

See [Troubleshooting](https://ziwi01.github.io/proveasio/main/troubleshooting)

## Contributing

If you want to help with this piece of software: fork it, create a branch, make changes, test it (preferably including Github workflow for Ubuntu 22.04) and open a Pull Request. You can see [TODO](./TODO.md) for ideas :)

Thanks in advance!

## Author

Eryk 'Ziwi' Kozakiewicz

## Mentions

- Windows setup was inspired and mostly based on [lholota/dev-setup](https://github.com/lholota/dev-setup) by [Lukas Holota](https://github.com/lholota)
- SDKMan! installation was deeply based on [Comcast/sdkman](https://github.com/Comcast/ansible-sdkman) by Elliot Weiser
