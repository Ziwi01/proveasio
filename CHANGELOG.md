# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [latest] - 2024-08-28
### :boom: BREAKING CHANGES
- due to [`71d1fc6`](https://github.com/Ziwi01/proveasio/commit/71d1fc65e19f29084608f94949e95073b68836c7) - Replace LunarVim with AstroNvim custom config:

  Replace LunarVim with AstroNvim custom config

- due to [`589ea0d`](https://github.com/Ziwi01/proveasio/commit/589ea0d1b16f1b3e715c37d37558037c470ddda7) - Update python to 3.12.5 *(commit by [@Ziwi01](https://github.com/Ziwi01))*:

  Update python to 3.12.5

- due to [`4bd4e9e`](https://github.com/Ziwi01/proveasio/commit/4bd4e9e24f8d29cb8d298d19705b41b1ff44bccf) - Drop support for thefuck until it supports Python 3.12.x *(commit by [@Ziwi01](https://github.com/Ziwi01))*:

  Drop support for thefuck until it supports Python 3.12.x

- due to [`eb685f0`](https://github.com/Ziwi01/proveasio/commit/eb685f00d89db9b3f843442f62abbda36501dd54) - Update runner image to Ubuntu 24.04 *(commit by [@Ziwi01](https://github.com/Ziwi01))*:

  Update runner image to Ubuntu 24.04


### :sparkles: New Features
- [`0035c99`](https://github.com/Ziwi01/proveasio/commit/0035c99b0247d4fd2477712243c435a88080e806) - **software**: Update Ruby default version to 3.3.0 *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`17ece4d`](https://github.com/Ziwi01/proveasio/commit/17ece4d72ea3dadb359a2072a4241242af2d2b82) - **software**: Update Puppet to 8.4.0 and puppet-lint gem to 4.2.3 *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ff69e16`](https://github.com/Ziwi01/proveasio/commit/ff69e16d60b22dc4e84f5a27522ef0a6337d47ac) - **software**: Use Node lts/iron (20.x) by default *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`c9417a9`](https://github.com/Ziwi01/proveasio/commit/c9417a9cf8604ad4f83a7c9a5c4bcb2a5c8ab803) - **software**: Replace Java 11.x with 21.x. Upgrade Gradle (8.5), update Groovy and Maven fix versions *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`1832ac8`](https://github.com/Ziwi01/proveasio/commit/1832ac865cf2fcae2067c293bb886d11879ca151) - **software**: Update Go version, fix GVM source in terminal *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`d48c484`](https://github.com/Ziwi01/proveasio/commit/d48c48426986a1e209f485c93324274d55ad2ee6) - **software**: Use latest Tmuxp version by default *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`d14a24f`](https://github.com/Ziwi01/proveasio/commit/d14a24feb13534c95c9a493fa7fd77495b0081f6) - Add jq ZSH plugin
- [`71d1fc6`](https://github.com/Ziwi01/proveasio/commit/71d1fc65e19f29084608f94949e95073b68836c7) - Replace LunarVim with AstroNvim custom config
- [`f31bcc2`](https://github.com/Ziwi01/proveasio/commit/f31bcc2b2a3fa448aa7a5d9b4289859c7819a4a5) - Support Ubuntu 24.04 LTS *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`589ea0d`](https://github.com/Ziwi01/proveasio/commit/589ea0d1b16f1b3e715c37d37558037c470ddda7) - **python**: Update python to 3.12.5 *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`4bd4e9e`](https://github.com/Ziwi01/proveasio/commit/4bd4e9e24f8d29cb8d298d19705b41b1ff44bccf) - **thefuck**: Drop support for thefuck until it supports Python 3.12.x *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`3e25db4`](https://github.com/Ziwi01/proveasio/commit/3e25db4dc13fbb367c9d26f266c483455d3e0e95) - **docusaurus**: Update Docusaurus and docs search engine *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`eb685f0`](https://github.com/Ziwi01/proveasio/commit/eb685f00d89db9b3f843442f62abbda36501dd54) - **build**: Update runner image to Ubuntu 24.04 *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`1d03f9e`](https://github.com/Ziwi01/proveasio/commit/1d03f9ed77ada335a7b66da1b95bc8f706a34006) - **apt**: Add lua and luarocks installation *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`d13b6dd`](https://github.com/Ziwi01/proveasio/commit/d13b6dd0ac4c2558e8a1ec446a9f9ebd73efac6e) - **ruby**: Update Ruby to 3.3.4 *(commit by [@Ziwi01](https://github.com/Ziwi01))*

### :bug: Bug Fixes
- [`48e73d1`](https://github.com/Ziwi01/proveasio/commit/48e73d1b094f6d1bc9350796e1471fee9f70c7c4) - **neovim**: Update version query for better tag discovery *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`e0a3363`](https://github.com/Ziwi01/proveasio/commit/e0a33631e9ed78b39f9f05a415343edd529806dd) - **git**: Wrong .gitconfig target filename *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`16c7bc5`](https://github.com/Ziwi01/proveasio/commit/16c7bc5e646f41134abe17ef1bff32cf738a8103) - **apt**: Allow dowgrades for azure-cli and docker APT packages *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`17d36e7`](https://github.com/Ziwi01/proveasio/commit/17d36e735b1236b8a15ab597a13ad44289285a54) - **tmuxp**: Add default session file for TMUXP *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`89197cd`](https://github.com/Ziwi01/proveasio/commit/89197cde55dfb79015faddc93a01a1a70cff30ae) - **lunarvim**: Prevent double dash on enter in lists for Markdown files
- [`a411ced`](https://github.com/Ziwi01/proveasio/commit/a411ced1820ab413e5f8052b14e1d5c6ec92b325) - **versions**: FZF and bottom packages release naming change
- [`ab00ba0`](https://github.com/Ziwi01/proveasio/commit/ab00ba08abd8e32d7d6826a5112e2751858000e5) - **fzf**: Save Fzf version properly
- [`f490638`](https://github.com/Ziwi01/proveasio/commit/f490638a94fa94ec81548be0dbd9ae7876258bfa) - Add gh-cli installation, migrate mlocate to plocate *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`80bd1b6`](https://github.com/Ziwi01/proveasio/commit/80bd1b629c6e3097231e4cf09a5ab5fe72beaa91) - Migrate bat installation from Github to APT *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`8ee0929`](https://github.com/Ziwi01/proveasio/commit/8ee09296facaf5dd358f427232a9c95493181934) - **nvm**: Fix NVM git submodule clone error *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`8a684a8`](https://github.com/Ziwi01/proveasio/commit/8a684a8c35325e413fb161c78a16e851f2432ceb) - **zshrc**: Ensure proper PATH is propagated in zshrc in case installation fails before config part *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`3ee621d`](https://github.com/Ziwi01/proveasio/commit/3ee621dcd5a7e56cc31c14ef039b7d7d6bbe872a) - **nvm**: Fix home path for NVM_DIR *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`593f614`](https://github.com/Ziwi01/proveasio/commit/593f61402196da7898a1b4c10485e6fb9bcae8c4) - **nvm**: Run installation through bash *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`ac1bc53`](https://github.com/Ziwi01/proveasio/commit/ac1bc53fa21ddf456675b113d5df43372c8d4b8a) - **neovim**: Update neovim ruby gem to 0.10.0 *(commit by [@Ziwi01](https://github.com/Ziwi01))*

### :wrench: Chores
- [`d3bdbd9`](https://github.com/Ziwi01/proveasio/commit/d3bdbd97f91af99bae4767e5acb9c7613bb00d55) - **docs**: Add TODO, update README
- [`9f22ceb`](https://github.com/Ziwi01/proveasio/commit/9f22cebb10148e3962e3f530e9915b6f161eee75) - Skip var naming rule in ansible-lint *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`fdf84a8`](https://github.com/Ziwi01/proveasio/commit/fdf84a8d2c1511ec0273bf3e9b98989d263ea994) - **docs**: Align documentation with the code. Prepare for Astronvim docs *(commit by [@Ziwi01](https://github.com/Ziwi01))*
- [`99f9444`](https://github.com/Ziwi01/proveasio/commit/99f9444b4f0b47753a80240c9ae6f64736e1b434) - **lint**: Disable ansible-lint no-role-prefix naming lint *(commit by [@Ziwi01](https://github.com/Ziwi01))*

[latest]: https://github.com/Ziwi01/proveasio/compare/v1.0.0...latest
