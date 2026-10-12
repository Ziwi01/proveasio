---
sidebar_position: 9
title: Changelog
format: md
---

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).




## [latest] - 2026-10-12
### :boom: BREAKING CHANGES
- due to [`824bfc9`](https://github.com/Ziwi01/proveasio/commit/824bfc9793a2020e0dffc6abbd88cd7e92918127) - Make packages, yq and zsh required *(commit by [@Ziwi01](https://github.com/Ziwi01))*:

  an overrides file that excludes packages, yq or zsh now  
  fails the run. Remove the entry. Removing zsh from config_tasks_exclude  
  makes the next run replace ~/.zshrc (a backup is kept by default).


### :sparkles: New Features
- [`10fb0e6`](https://github.com/Ziwi01/proveasio/commit/10fb0e6de85e22c32ed6bf99db1e665a41ee551e) - **neovim**: Add tarball install and local config source *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`3e548a9`](https://github.com/Ziwi01/proveasio/commit/3e548a9007c556ee6ea523809d25b90e44e7e156) - **docker**: Allow installing the Docker client without the engine *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`2568ee8`](https://github.com/Ziwi01/proveasio/commit/2568ee8096f962a639cd3fe5c14ecdb90b8ddd83) - **docker**: Build Proveasio as a Docker image *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`824bfc9`](https://github.com/Ziwi01/proveasio/commit/824bfc9793a2020e0dffc6abbd88cd7e92918127) - Make packages, yq and zsh required *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`b6339c8`](https://github.com/Ziwi01/proveasio/commit/b6339c862dc2377cc732c3eaddad7a7c5e222846) - **docker**: Move the playbook step into provision.sh and stop early without required tasks *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`53dd858`](https://github.com/Ziwi01/proveasio/commit/53dd858565c3cb435b749d4ee907505536989c57) - **docker**: Add image profiles, the slim image and *_tasks_include *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`7130fbd`](https://github.com/Ziwi01/proveasio/commit/7130fbdadf851c328574d88314647e721803c666) - **docker**: Add an update target for tools in a built image *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`4334479`](https://github.com/Ziwi01/proveasio/commit/433447991d89c0b057bbc2fc8c043bf7f23b101f) - **docker**: Warn about UID mismatches, keep prompt colors and document SSH mounts *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`69576ca`](https://github.com/Ziwi01/proveasio/commit/69576ca9d20e3bd58572d6b327821d21a04b41f5) - **azcli**: Add kubelogin *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ceadb72`](https://github.com/Ziwi01/proveasio/commit/ceadb7242f7308d14cb9c09aed750e4d27551654) - **opencode**: Add support for Opencode v2 *(commit by [@Ziwi01](https://github.com/Ziwi01))*

### :bug: Bug Fixes
- [`bcb76e3`](https://github.com/Ziwi01/proveasio/commit/bcb76e32e48c2b469d2ff1422b48a7cc14faad8b) - **zsh**: Keep .zshrc working when tools are excluded *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`0ab5e02`](https://github.com/Ziwi01/proveasio/commit/0ab5e02d2a963521ca4303caa327f2ebf398066f) - **zsh**: Link the eza completion into ~/.zfunc so --skip-tags eza keeps the zsh config *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`0775c48`](https://github.com/Ziwi01/proveasio/commit/0775c48623f59cf8d92d1410b6ac251a6c8ededf) - **docker**: Stop updates that would test uninstalled new tools *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`3537ce2`](https://github.com/Ziwi01/proveasio/commit/3537ce2b41f81fbd728693ec4210b16ea6bc7017) - **neovim**: Update plugins once after the first config install *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`a9b2244`](https://github.com/Ziwi01/proveasio/commit/a9b22447cc839ff7874f7c25ddab29008b28bc34) - **nvm**: Upgrade nvm when the installed version differs *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ed02c2e`](https://github.com/Ziwi01/proveasio/commit/ed02c2e73b718ecfbf0f8e02ac07b0711eeb26e9) - **sdkman**: Load SDKMAN in .zshrc *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`4254ef8`](https://github.com/Ziwi01/proveasio/commit/4254ef89800ade8b64e8963f207ca340e7d2642d) - **ci**: Use master instead of the triggering branch in the build workflow *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`93cd4be`](https://github.com/Ziwi01/proveasio/commit/93cd4bed848fa856fbc9b3f56022abecf84a45f4) - **docs-pages**: typo on checkout action *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`79c4756`](https://github.com/Ziwi01/proveasio/commit/79c4756b69445645596cc53568839c0863738c21) - Add support for passing corporate CA when behind mitm proxy *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`cffd8bd`](https://github.com/Ziwi01/proveasio/commit/cffd8bd6f470ec37b099010bf9742c08fb676e32) - **ccmux**: Update ccmux to work on opencode v2 (not yet fully supports it) *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`8dd0857`](https://github.com/Ziwi01/proveasio/commit/8dd08577815c8e5e8a970d35f1285d395281935f) - **sudo**: Force sudo-ws, since ansible-core not yet supports sudo-rs *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`e5877a1`](https://github.com/Ziwi01/proveasio/commit/e5877a15aa3d4ce1cae3b5c164efbb6711465cd5) - **ccmux**: Drop OpenCode v1-only workaround, ccmux 1.4.3 supports v2 *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`b681da9`](https://github.com/Ziwi01/proveasio/commit/b681da921702998c319c984a2b5023413aef1fb9) - **opencode**: Retry version lookup when opencode.ai answers 500 *(commit by [@Ziwi01](https://github.com/Ziwi01))*

### :wrench: Chores
- [`7a1da91`](https://github.com/Ziwi01/proveasio/commit/7a1da916db96508a05257669184c70677266a39b) - **opencode**: Better support for installing Opencode v2 *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`9188acc`](https://github.com/Ziwi01/proveasio/commit/9188acc0b7a497b1e261b320680ab9354bb59d5f) - **workflow**: Update actions/checkout action *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`c151a40`](https://github.com/Ziwi01/proveasio/commit/c151a40bd91d2a7301d5bc44cf02e3d358277417) - **docs**: Update dockerhub username *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`a12e5d3`](https://github.com/Ziwi01/proveasio/commit/a12e5d3f8d4ef41b61a9b60b2944384e1f719626) - **docs**: Move docker to top *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ae6c821`](https://github.com/Ziwi01/proveasio/commit/ae6c8212d463abae454ec5b9b29abe3ae307a2cd) - Remove .latest-versions.yml and LunarVim leftovers *(commit by [@Ziwi01](https://github.com/Ziwi01))*

[latest]: https://github.com/Ziwi01/proveasio/compare/v4.0.0...latest
