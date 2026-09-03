---
sidebar_position: 9
title: Changelog
format: md
---

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [latest] - 2026-09-03
### :sparkles: New Features
- [`3a2c6e4`](https://github.com/Ziwi01/proveasio/commit/3a2c6e432c85fd3a7d3e3f74c199aa2a4d14926f) - Add Opencode and UV installation *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`026f795`](https://github.com/Ziwi01/proveasio/commit/026f795b6903dc67108ed6750ad40046dd2da65e) - Update default versions for bottom, tmuxp, java, gradle, groovy, go, maven *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`6a5943e`](https://github.com/Ziwi01/proveasio/commit/6a5943e53d5d5d5271ae4931ffe95497558fdfb2) - Add Ubuntu 26 test build *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`daf2c2a`](https://github.com/Ziwi01/proveasio/commit/daf2c2ad7257ece7c18e54226dae585527a515cb) - Add support for cleaning up old versions of the installed software *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`48664b6`](https://github.com/Ziwi01/proveasio/commit/48664b60a2feaf1a8cc06e807b4b9e29c1fcd326) - Add cleanup for Node versions and AWS-CLI *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`6c212de`](https://github.com/Ziwi01/proveasio/commit/6c212de6f8885fde7b7d638725fef560e36a7c4a) - Add hunk installation for diff review for agents *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`854cceb`](https://github.com/Ziwi01/proveasio/commit/854cceb8bf479e6bcc9eb7bef6b89a13534f84d5) - Add ccmux for tracking AI agents in tmux, with wsl-notify-send *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`376f60f`](https://github.com/Ziwi01/proveasio/commit/376f60f9ffe790b3f736bcc591f4d7e1c7f9f785) - Add proper AGENTS.md and register serena project with memories *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ab88f08`](https://github.com/Ziwi01/proveasio/commit/ab88f080cdfce815c98b00c41fa24ade3ee9ee46) - Add global Opencode Fuzzy finder for sessions across filesystem *(commit by [@Ziwi01](https://github.com/Ziwi01))*

### :bug: Bug Fixes
- [`c65d24e`](https://github.com/Ziwi01/proveasio/commit/c65d24e738aa565cc985e735ded9d9549f8ea43b) - Tmux support for OpenCode newline (shift+enter) and other passthrough special chars *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`a954d6d`](https://github.com/Ziwi01/proveasio/commit/a954d6d8833632a3fe0ca130a326c1b9e452f49a) - **tmux/opencode**: Prevent OSC52 characters from leaking in opencode when in tmux *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`9767a5e`](https://github.com/Ziwi01/proveasio/commit/9767a5e6e33c77ca672e71d598bf486e0d0f31f0) - **tmux**: Bring back the passthrough for OSC52 chars - fix moved to neovim config *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ee54a05`](https://github.com/Ziwi01/proveasio/commit/ee54a05b71546ea7afd23695d0cf828d22c9fc47) - **git**: Seamless migration from previous APT repo module (remove old apt sources) *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`1e0d44c`](https://github.com/Ziwi01/proveasio/commit/1e0d44cfcb1b1ddef64c971a9a3ffafcee2f3e83) - Update SDKMan command for selfupdate, fix Lazygit deprecated config *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`834c772`](https://github.com/Ziwi01/proveasio/commit/834c772d4e709b1017a6c61be014a11525e38141) - Authenticate GitHub API version lookups to avoid rate limiting *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`e3e9fe8`](https://github.com/Ziwi01/proveasio/commit/e3e9fe8c3ac10793a51eb224ab2d68407c66bae2) - ccmux completions fix, Tmux sessions rename *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`9e1761d`](https://github.com/Ziwi01/proveasio/commit/9e1761dfc8c735cf12dba2297b79bf19ac2e6920) - Deep merge github versions in overrides.yml instead replacing it *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`4fabe62`](https://github.com/Ziwi01/proveasio/commit/4fabe62c346c89d2c760803917afe0ed6f8417ed) - Add ansible-lint GH workflow, fix linting config, update docs *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`7de5d5c`](https://github.com/Ziwi01/proveasio/commit/7de5d5c084ff61d7767e6665bdf48fbb301ad19e) - **ci**: Restore CHANGELOG generation and publish it to the docs site *(commit by [@Ziwi01](https://github.com/Ziwi01))*

### :wrench: Chores
- [`1112684`](https://github.com/Ziwi01/proveasio/commit/1112684d12ae4bdb37f615b7d1c9ebf87d91bf77) - Get rid of deprecation warnings *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`0a63fd4`](https://github.com/Ziwi01/proveasio/commit/0a63fd49318863df9299242894aa6790a9f712dd) - **docs**: Add new Neovim diffing support from Neo Tree *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ce81153`](https://github.com/Ziwi01/proveasio/commit/ce81153fb5ac209933947c1fe744f966e84e3305) - Update commands that don't change anything not to appear as "changed". Improve shell commands changed_when mechanisms *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`2716a2e`](https://github.com/Ziwi01/proveasio/commit/2716a2e8a769575162e163c423f8c99ecd208417) - **ccmux**: Update Windows notification format *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`0185e23`](https://github.com/Ziwi01/proveasio/commit/0185e23b03a0ea598862313da3cc7bb6f91888fb) - Update TODO *(commit by [@Ziwi01](https://github.com/Ziwi01))*

[latest]: https://github.com/Ziwi01/proveasio/compare/v3.0.0...latest
