# Changelog

All notable changes to this project are documented in this file. It is generated
from the git history by [git-cliff](https://git-cliff.org); do not edit it by hand.

## Unreleased

### Features

- **docker**: Add proveasio cleanup and uninstall subcommands ([`cc1d9c3`](https://github.com/Ziwi01/proveasio/commit/cc1d9c30cac9514702b7d76f555a82ca22795241))
- **packages**: Install bind9-dnsutils for nslookup and dig ([`bb13a5b`](https://github.com/Ziwi01/proveasio/commit/bb13a5bd182fb988494507e38e131622370871b4))

## v5.2.0 - 2026-11-11

### Features

- **BREAKING** **windows**: Install Ubuntu 26.04 in WSL ([`8d75c63`](https://github.com/Ziwi01/proveasio/commit/8d75c6355df7cfae3c527f6874c2684ec6cfcdf4))
- **BREAKING** **build**: Run the build and release on Ubuntu 26.04 ([`59ee179`](https://github.com/Ziwi01/proveasio/commit/59ee179ea522882120ecda3eb22558484d8a9d7c))
- **BREAKING** **docker**: Build the image on Ubuntu 26.04 ([`bcf5e5c`](https://github.com/Ziwi01/proveasio/commit/bcf5e5c4ec871100076f1575b3363663b493dd0b))
- **packages**: Install command-not-found ([`c495f9e`](https://github.com/Ziwi01/proveasio/commit/c495f9e07638f92574abe0eda8b6dec0f0ece4f3))
- **docker**: Add proveasio launcher and image defaults ([`5101776`](https://github.com/Ziwi01/proveasio/commit/5101776c5da592adefede4996f0bf160a37f333d))
- **software**: Manage Terraform tools with tenv ([`03ad545`](https://github.com/Ziwi01/proveasio/commit/03ad54599e904e6b734a738533c72b3be2f75e83))
- **software**: Add AWS, Kubernetes and IaC tools ([`89a0410`](https://github.com/Ziwi01/proveasio/commit/89a04100eb5e265c7891d09d1e04f4166ccac103))
- **software**: Add tool bundles ([`776ad84`](https://github.com/Ziwi01/proveasio/commit/776ad8450a61b24c16c7a4a2ca82a700272c2b39))
- **opencode**: Add Homebrew install option for firewall-blocked networks ([`ab01ed0`](https://github.com/Ziwi01/proveasio/commit/ab01ed0acf94927d17040741cb14184a7e3ce961))

### Bug Fixes

- **zsh**: Pass a fixed prompt prefix to pay-respects ([`b26b376`](https://github.com/Ziwi01/proveasio/commit/b26b37691fe9542912cdee970f21eb9acef0ec38))
- **docker**: Harden proveasio launcher ([`e616384`](https://github.com/Ziwi01/proveasio/commit/e6163844f926f8cdea166627865cca1f45f45601))
- **opencode**: Handle undefined opencode_version in task names ([`7366b5f`](https://github.com/Ziwi01/proveasio/commit/7366b5f6f53abab2c4ddba476bddcc997d5527fc))

### Documentation

- **docker**: Clone into ~/proveasio and link the launcher from there ([`463d260`](https://github.com/Ziwi01/proveasio/commit/463d260f0b4dc98688c21767a4a7584bbea41bd5))
- **superpowers**: Add Docker launcher spec and plan ([`fe215a7`](https://github.com/Ziwi01/proveasio/commit/fe215a7aa2f68a8a5e8bfead6f99f0de2fb0ddbc))
- **superpowers**: Add AWS tools and bundles spec and plan ([`66e7e7e`](https://github.com/Ziwi01/proveasio/commit/66e7e7e2c9c7673ad01371c4cc07edd3a477759d))
- Document new tools, bundles and slim profile ([`aa86c99`](https://github.com/Ziwi01/proveasio/commit/aa86c995a616282d6433162a3c4b72b58adedddd))

### CI

- Pass GitHub token to playbook for API rate limiting ([`97ea775`](https://github.com/Ziwi01/proveasio/commit/97ea77549b16b1782d0e030c3d2945da2204a973))
- Update GitHub Actions versions and replace delete-releases action ([`d2d9b90`](https://github.com/Ziwi01/proveasio/commit/d2d9b9082f5f2560c5fbdbbccb16be80f20de1c1))

### Chores

- **zsh**: Remove shallow clone of powerlevel10k due to ansible-core crash ([`1079bcd`](https://github.com/Ziwi01/proveasio/commit/1079bcdb6cac1e1e4f055f4c0a94c1d4690d7bc5))

## v5.1.1 - 2026-10-28

### Features

- Add rsync to default apt packages ([`82ca69b`](https://github.com/Ziwi01/proveasio/commit/82ca69b9fe36f4fb2127eae8b4c12456ad753265))

### Bug Fixes

- **docker**: Stop SIGPIPE from un-excluding tasks in test.sh ([`f267e1b`](https://github.com/Ziwi01/proveasio/commit/f267e1b4ad56098fab2debecc1db93850d5bdb42))
- **config**: Improve SSH/TMUX window renaming logic ([`d1db30c`](https://github.com/Ziwi01/proveasio/commit/d1db30c1a1bd9ac48863ec10ce15440cf0e16380))

## v5.1.0 - 2026-10-25

### Features

- **opencode**: Use the baseline build in Docker images ([`619b15f`](https://github.com/Ziwi01/proveasio/commit/619b15f9c281c12b3e0f4af0b6d5996b43c45d53))
- **revdiff**: Enable untracked files and word-diff by default ([`d6e60c7`](https://github.com/Ziwi01/proveasio/commit/d6e60c7bf9c79088116da81f8f6aac644f6f8a96))
- **hunk-popup**: Add ref support and persist user notes ([`ce1d696`](https://github.com/Ziwi01/proveasio/commit/ce1d696783cb932ee2c37e09d8618ac66359749a))
- **tmux**: Colour window list by AI agent state ([`1a71584`](https://github.com/Ziwi01/proveasio/commit/1a71584f21fe361758712e1baa1dca85356b0382))
- **opencode-config**: Install shared OpenCode config ([`32be201`](https://github.com/Ziwi01/proveasio/commit/32be2013da2b21b1b469faab274e8ca7f4b0a3b1))
- **git**: Add revdiff for diff review and hunk popup in tmux ([`5d91e15`](https://github.com/Ziwi01/proveasio/commit/5d91e1577dece4132e1c658e66d24dcbe6f3ef1c))
- **zsh**: Open URLs in the Windows browser on WSL ([`7e137ae`](https://github.com/Ziwi01/proveasio/commit/7e137ae7685c8efeba150e46b9be570e621fdc0a))
- **tmux**: Toggle Neovim pane with e and E ([`4b4ca38`](https://github.com/Ziwi01/proveasio/commit/4b4ca389c08c2bc99de5f73a26a545dbfb682c96))
- **tmux**: Add binding to open Neovim in a left pane ([`ebdeb59`](https://github.com/Ziwi01/proveasio/commit/ebdeb59d3d7e72c20cfeb9f75d69543224293cae))

### Bug Fixes

- **windows**: Use wslinfo to find Windows host instead of /etc/resolv.conf ([`fddcdc0`](https://github.com/Ziwi01/proveasio/commit/fddcdc06bb9493c2315a1db633c042525e2a0b6a))
- **opencode-config**: Show installer warnings and tolerate empty output ([`66f239b`](https://github.com/Ziwi01/proveasio/commit/66f239b63ce120d720b87e348cceb0e1e3f0e536))
- **neovim**: Fix installed version check ([`34e30b0`](https://github.com/Ziwi01/proveasio/commit/34e30b09b064b58e9d3223d9f4daaa66a197e04d))

### Refactor

- **zsh**: Extract ocs function to standalone script ([`f0ab7fd`](https://github.com/Ziwi01/proveasio/commit/f0ab7fd28ac687a65184ed2e12a7503a94b47a82))

### Documentation

- **opencode**: Add baseline build design and plan ([`27bae67`](https://github.com/Ziwi01/proveasio/commit/27bae67fa5843385be0e31b614c449e8812cc358))
- **ai**: Clarify revdiff behavior after review completion ([`7969a7f`](https://github.com/Ziwi01/proveasio/commit/7969a7fa1b01bbcf56859c12fcd4af0773f8808c))
- **opencode-config**: Document shared OpenCode config and add image check ([`b8d00a1`](https://github.com/Ziwi01/proveasio/commit/b8d00a1c8f154714e2fa097e0e942439c352162b))

### CI

- **docker**: Simplify image tagging and remove develop builds ([`ccbbf81`](https://github.com/Ziwi01/proveasio/commit/ccbbf81f53597b9f88d2b93b45cf614a7da1d6b5))

## v5.0.0 - 2026-10-20

### Features

- **lazygit**: Condense diff sent to the AI commit splitter ([`5c30963`](https://github.com/Ziwi01/proveasio/commit/5c30963bbd51016c50cb4d206fc1dc9cac897b3a))
- **ccmux**: Auto-start daemon and improve plugin detection ([`5060d7e`](https://github.com/Ziwi01/proveasio/commit/5060d7ed28a0611ed3183ae9b50d33f65321bd3c))
- **software**: Add curlie ([`e7664b8`](https://github.com/Ziwi01/proveasio/commit/e7664b86aede0cdc78c1182e9a2ec35f5471d6fa))
- **software**: Add argocd and argonaut ([`4bd34ab`](https://github.com/Ziwi01/proveasio/commit/4bd34abb257df7062dbabc7e40a865add0f5bbc6))
- **lazygit**: Add Diffview review of proposed commit split ([`88f45f3`](https://github.com/Ziwi01/proveasio/commit/88f45f36254844c004387753bd1ea669c0b93d31))
- **software**: Add shellcheck, tofu, kubeconform, dyff and helm-unittest ([`dd03603`](https://github.com/Ziwi01/proveasio/commit/dd0360352d4e4d81d62c169cd805477d4494c547))
- **lazygit**: Add AI commit message and split helpers ([`685d8e6`](https://github.com/Ziwi01/proveasio/commit/685d8e6e14cad7489527b0108f462dd7822a1a5f))
- Better support for no nerd fonts ([`cfd6676`](https://github.com/Ziwi01/proveasio/commit/cfd6676ad5dd073e7128c5290e9dbe3d1813d34e))
- Add support for disabling glyphs and icons for use in remote sessions ([`c34a47c`](https://github.com/Ziwi01/proveasio/commit/c34a47c26a305a575417fb3b73bf0a22a306e002))
- **opencode**: Add support for Opencode v2 ([`ceadb72`](https://github.com/Ziwi01/proveasio/commit/ceadb7242f7308d14cb9c09aed750e4d27551654))
- **azcli**: Add kubelogin ([`69576ca`](https://github.com/Ziwi01/proveasio/commit/69576ca9d20e3bd58572d6b327821d21a04b41f5))
- **docker**: Warn about UID mismatches, keep prompt colors and document SSH mounts ([`4334479`](https://github.com/Ziwi01/proveasio/commit/433447991d89c0b057bbc2fc8c043bf7f23b101f))
- **docker**: Add an update target for tools in a built image ([`7130fbd`](https://github.com/Ziwi01/proveasio/commit/7130fbdadf851c328574d88314647e721803c666))
- **docker**: Add image profiles, the slim image and *_tasks_include ([`53dd858`](https://github.com/Ziwi01/proveasio/commit/53dd858565c3cb435b749d4ee907505536989c57))
- **docker**: Move the playbook step into provision.sh and stop early without required tasks ([`b6339c8`](https://github.com/Ziwi01/proveasio/commit/b6339c862dc2377cc732c3eaddad7a7c5e222846))
- **BREAKING** Make packages, yq and zsh required ([`824bfc9`](https://github.com/Ziwi01/proveasio/commit/824bfc9793a2020e0dffc6abbd88cd7e92918127))
- **docker**: Build Proveasio as a Docker image ([`2568ee8`](https://github.com/Ziwi01/proveasio/commit/2568ee8096f962a639cd3fe5c14ecdb90b8ddd83))
- **docker**: Allow installing the Docker client without the engine ([`3e548a9`](https://github.com/Ziwi01/proveasio/commit/3e548a9007c556ee6ea523809d25b90e44e7e156))
- **neovim**: Add tarball install and local config source ([`10fb0e6`](https://github.com/Ziwi01/proveasio/commit/10fb0e6de85e22c32ed6bf99db1e665a41ee551e))

### Bug Fixes

- **prepare**: Make pyenv bootstrap robust and rerunnable ([`2370413`](https://github.com/Ziwi01/proveasio/commit/237041305438062f098553e51a7ab1fa83cdbf53))
- **opencode**: Retry version lookup when opencode.ai answers 500 ([`b681da9`](https://github.com/Ziwi01/proveasio/commit/b681da921702998c319c984a2b5023413aef1fb9))
- **ccmux**: Drop OpenCode v1-only workaround, ccmux 1.4.3 supports v2 ([`e5877a1`](https://github.com/Ziwi01/proveasio/commit/e5877a15aa3d4ce1cae3b5c164efbb6711465cd5))
- **sudo**: Force sudo-ws, since ansible-core not yet supports sudo-rs ([`8dd0857`](https://github.com/Ziwi01/proveasio/commit/8dd08577815c8e5e8a970d35f1285d395281935f))
- **ccmux**: Update ccmux to work on opencode v2 (not yet fully supports it) ([`cffd8bd`](https://github.com/Ziwi01/proveasio/commit/cffd8bd6f470ec37b099010bf9742c08fb676e32))
- Add support for passing corporate CA when behind mitm proxy ([`79c4756`](https://github.com/Ziwi01/proveasio/commit/79c4756b69445645596cc53568839c0863738c21))
- **docs-pages**: typo on checkout action ([`93cd4be`](https://github.com/Ziwi01/proveasio/commit/93cd4bed848fa856fbc9b3f56022abecf84a45f4))
- **ci**: Use master instead of the triggering branch in the build workflow ([`4254ef8`](https://github.com/Ziwi01/proveasio/commit/4254ef89800ade8b64e8963f207ca340e7d2642d))
- **sdkman**: Load SDKMAN in .zshrc ([`ed02c2e`](https://github.com/Ziwi01/proveasio/commit/ed02c2e73b718ecfbf0f8e02ac07b0711eeb26e9))
- **nvm**: Upgrade nvm when the installed version differs ([`a9b2244`](https://github.com/Ziwi01/proveasio/commit/a9b22447cc839ff7874f7c25ddab29008b28bc34))
- **neovim**: Update plugins once after the first config install ([`3537ce2`](https://github.com/Ziwi01/proveasio/commit/3537ce2b41f81fbd728693ec4210b16ea6bc7017))
- **docker**: Stop updates that would test uninstalled new tools ([`0775c48`](https://github.com/Ziwi01/proveasio/commit/0775c48623f59cf8d92d1410b6ac251a6c8ededf))
- **zsh**: Link the eza completion into ~/.zfunc so --skip-tags eza keeps the zsh config ([`0ab5e02`](https://github.com/Ziwi01/proveasio/commit/0ab5e02d2a963521ca4303caa327f2ebf398066f))
- **zsh**: Keep .zshrc working when tools are excluded ([`bcb76e3`](https://github.com/Ziwi01/proveasio/commit/bcb76e32e48c2b469d2ff1422b48a7cc14faad8b))

### Documentation

- Rewrite and expand the documentation ([`acf93f9`](https://github.com/Ziwi01/proveasio/commit/acf93f9ef4607d68f1f5932a35499d7202321d3b))
- **memory**: Note cleanup_versions prefix collision ([`5b9ba96`](https://github.com/Ziwi01/proveasio/commit/5b9ba96e65e0c6824e43cec61717d21ec9cb5b45))
- **serena**: Update memories for the entrypoint, blink.cmp, build.yml and removed files ([`92b7e42`](https://github.com/Ziwi01/proveasio/commit/92b7e4204b103a9b8827b3f5463b2fea6a19639b))
- **serena**: Update memories for profiles, updates and measured sizes ([`5613f41`](https://github.com/Ziwi01/proveasio/commit/5613f41838778343964cb3f966ef00102faa0a49))
- Add design and plan for the slim image, image updates and required tasks ([`92872dc`](https://github.com/Ziwi01/proveasio/commit/92872dcfda6f06daf36422bb5a91c3000433d064))

### Build

- **docs**: Upgrade Docusaurus and restyle the site ([`b6e78ed`](https://github.com/Ziwi01/proveasio/commit/b6e78eddff435f2c2150b4d7e7a93db5b142bb1b))

### Chores

- Remove .latest-versions.yml and LunarVim leftovers ([`ae6c821`](https://github.com/Ziwi01/proveasio/commit/ae6c8212d463abae454ec5b9b29abe3ae307a2cd))
- **docs**: Move docker to top ([`a12e5d3`](https://github.com/Ziwi01/proveasio/commit/a12e5d3f8d4ef41b61a9b60b2944384e1f719626))
- **docs**: Update dockerhub username ([`c151a40`](https://github.com/Ziwi01/proveasio/commit/c151a40bd91d2a7301d5bc44cf02e3d358277417))
- **workflow**: Update actions/checkout action ([`9188acc`](https://github.com/Ziwi01/proveasio/commit/9188acc0b7a497b1e261b320680ab9354bb59d5f))
- **opencode**: Better support for installing Opencode v2 ([`7a1da91`](https://github.com/Ziwi01/proveasio/commit/7a1da916db96508a05257669184c70677266a39b))

## v4.0.0 - 2026-09-03

### Features

- Add global Opencode Fuzzy finder for sessions across filesystem ([`ab88f08`](https://github.com/Ziwi01/proveasio/commit/ab88f080cdfce815c98b00c41fa24ade3ee9ee46))
- Add proper AGENTS.md and register serena project with memories ([`376f60f`](https://github.com/Ziwi01/proveasio/commit/376f60f9ffe790b3f736bcc591f4d7e1c7f9f785))
- Add ccmux for tracking AI agents in tmux, with wsl-notify-send ([`854cceb`](https://github.com/Ziwi01/proveasio/commit/854cceb8bf479e6bcc9eb7bef6b89a13534f84d5))
- Add hunk installation for diff review for agents ([`6c212de`](https://github.com/Ziwi01/proveasio/commit/6c212de6f8885fde7b7d638725fef560e36a7c4a))
- Add cleanup for Node versions and AWS-CLI ([`48664b6`](https://github.com/Ziwi01/proveasio/commit/48664b60a2feaf1a8cc06e807b4b9e29c1fcd326))
- Add support for cleaning up old versions of the installed software ([`daf2c2a`](https://github.com/Ziwi01/proveasio/commit/daf2c2ad7257ece7c18e54226dae585527a515cb))
- Add Ubuntu 26 test build ([`6a5943e`](https://github.com/Ziwi01/proveasio/commit/6a5943e53d5d5d5271ae4931ffe95497558fdfb2))
- Update default versions for bottom, tmuxp, java, gradle, groovy, go, maven ([`026f795`](https://github.com/Ziwi01/proveasio/commit/026f795b6903dc67108ed6750ad40046dd2da65e))
- Add Opencode and UV installation ([`3a2c6e4`](https://github.com/Ziwi01/proveasio/commit/3a2c6e432c85fd3a7d3e3f74c199aa2a4d14926f))

### Bug Fixes

- **ci**: Restore CHANGELOG generation and publish it to the docs site ([`7de5d5c`](https://github.com/Ziwi01/proveasio/commit/7de5d5c084ff61d7767e6665bdf48fbb301ad19e))
- Add ansible-lint GH workflow, fix linting config, update docs ([`4fabe62`](https://github.com/Ziwi01/proveasio/commit/4fabe62c346c89d2c760803917afe0ed6f8417ed))
- Deep merge github versions in overrides.yml instead replacing it ([`9e1761d`](https://github.com/Ziwi01/proveasio/commit/9e1761dfc8c735cf12dba2297b79bf19ac2e6920))
- ccmux completions fix, Tmux sessions rename ([`e3e9fe8`](https://github.com/Ziwi01/proveasio/commit/e3e9fe8c3ac10793a51eb224ab2d68407c66bae2))
- Authenticate GitHub API version lookups to avoid rate limiting ([`834c772`](https://github.com/Ziwi01/proveasio/commit/834c772d4e709b1017a6c61be014a11525e38141))
- Update SDKMan command for selfupdate, fix Lazygit deprecated config ([`1e0d44c`](https://github.com/Ziwi01/proveasio/commit/1e0d44cfcb1b1ddef64c971a9a3ffafcee2f3e83))
- **git**: Seamless migration from previous APT repo module (remove old apt sources) ([`ee54a05`](https://github.com/Ziwi01/proveasio/commit/ee54a05b71546ea7afd23695d0cf828d22c9fc47))
- **tmux**: Bring back the passthrough for OSC52 chars - fix moved to neovim config ([`9767a5e`](https://github.com/Ziwi01/proveasio/commit/9767a5e6e33c77ca672e71d598bf486e0d0f31f0))
- **tmux/opencode**: Prevent OSC52 characters from leaking in opencode when in tmux ([`a954d6d`](https://github.com/Ziwi01/proveasio/commit/a954d6d8833632a3fe0ca130a326c1b9e452f49a))
- Tmux support for OpenCode newline (shift+enter) and other passthrough special chars ([`c65d24e`](https://github.com/Ziwi01/proveasio/commit/c65d24e738aa565cc985e735ded9d9549f8ea43b))

### Chores

- Update TODO ([`0185e23`](https://github.com/Ziwi01/proveasio/commit/0185e23b03a0ea598862313da3cc7bb6f91888fb))
- **ccmux**: Update Windows notification format ([`2716a2e`](https://github.com/Ziwi01/proveasio/commit/2716a2e8a769575162e163c423f8c99ecd208417))
- Update commands that don't change anything not to appear as "changed". Improve shell commands changed_when mechanisms ([`ce81153`](https://github.com/Ziwi01/proveasio/commit/ce81153fb5ac209933947c1fe744f966e84e3305))
- **docs**: Add new Neovim diffing support from Neo Tree ([`0a63fd4`](https://github.com/Ziwi01/proveasio/commit/0a63fd49318863df9299242894aa6790a9f712dd))
- Get rid of deprecation warnings ([`1112684`](https://github.com/Ziwi01/proveasio/commit/1112684d12ae4bdb37f615b7d1c9ebf87d91bf77))

### Other

- **build**: Changelog proper order ([`a0bae0c`](https://github.com/Ziwi01/proveasio/commit/a0bae0ced467b469a5d7e71481f29b1d2de4fec6))

## v3.0.0 - 2026-03-05

### Features

- **BREAKING** Drop support for Ubuntu 22.04. Soon we will have next LTS after 24.04 ([`1b58dbf`](https://github.com/Ziwi01/proveasio/commit/1b58dbfd5b6f5b90445d2d51e27b31e6ec2981e3))
- Add FX tool for interactive JSON edits ([`c16323a`](https://github.com/Ziwi01/proveasio/commit/c16323a1423ed2c52398a83dfff13691c0115ee7))
- Add EZA as modern ls replacement ([`420a5a5`](https://github.com/Ziwi01/proveasio/commit/420a5a5d36a5897fb88b5edcb1c5eaae03f0678b))
- Update to Python 3.14.0 ([`98d7e0c`](https://github.com/Ziwi01/proveasio/commit/98d7e0c77d5b2a7a43f88535cbf0b3f1ac32a7d8))
- Update tmuxp, add theme config ([`0496939`](https://github.com/Ziwi01/proveasio/commit/0496939800f4dadc872fefc70a50eda1f7b35280))
- Add Lazygit custom command to diff branches, fix GUI icons ([`25d2b00`](https://github.com/Ziwi01/proveasio/commit/25d2b00fc334ff298e9fbc2abe5f5fed01f4b8fb))
- Update Node version to lts/jod (22.x) ([`88b26bc`](https://github.com/Ziwi01/proveasio/commit/88b26bc3147ae8b19242c0aaf6c579cc7ec757eb))
- Add DRY installation with AI prompt ([`f0da034`](https://github.com/Ziwi01/proveasio/commit/f0da0344b7001afc22ab9df7ff2b5ca5f72b140b))

### Bug Fixes

- Update deprecated vars usage ([`46814a9`](https://github.com/Ziwi01/proveasio/commit/46814a988e8d946eeb5407e5a1e02125a872eaa7))
- Update ansible built-in variable reference to get rid of deprecation warnings ([`54ce6e4`](https://github.com/Ziwi01/proveasio/commit/54ce6e4dbd44abe4c5d9001f171bef37a86ba88e))
- **node**: When installing new node, make it default ([`90235ea`](https://github.com/Ziwi01/proveasio/commit/90235ea30bf9a9966268bd7330f8226f03487bc9))
- Allow broken conditionals for ruby role to work ([`d07740b`](https://github.com/Ziwi01/proveasio/commit/d07740bd697271c956e44a11dbf6e793158a21e1))
- Remove os-specific variables load for config role ([`cbca238`](https://github.com/Ziwi01/proveasio/commit/cbca238c3ff09053cb16dd0f23eb34668e778974))
- **regression**: Bring back removed installation of software ([`85a1fa0`](https://github.com/Ziwi01/proveasio/commit/85a1fa09ae8741327c622079e3c5ecf2ea3b0b26))
- **kubeswitch**: Update zshrc to not infinitely add completion lines ([`f83bf1e`](https://github.com/Ziwi01/proveasio/commit/f83bf1e74dadf370faf620da4c4463abcfd239b8))
- **batcat**: Fix naming for batcat binary between Ubuntu 22 and 24 ([`a0eb0e8`](https://github.com/Ziwi01/proveasio/commit/a0eb0e8ed94ee79e968baf3ce8fc6c0853d75cd6))

### Chores

- Update docusaurus, update config for deprecation warnings ([`cc2a593`](https://github.com/Ziwi01/proveasio/commit/cc2a5937a24c9f78546a4b8ba084d41e65d3af21))
- Add installing pyenv-update plugin, run update always. Add colored output ([`f73a532`](https://github.com/Ziwi01/proveasio/commit/f73a53286a9fd5c8bd26c384accd431a5174cef8))
- Do not create default_session file for Tmuxp if any other file is there ([`3c7fcdf`](https://github.com/Ziwi01/proveasio/commit/3c7fcdf9411b3dc974c6e4a9d36ca7967e78b15f))
- Refactor save_version.yml to not use reserved parameter "query" ([`27115e4`](https://github.com/Ziwi01/proveasio/commit/27115e416c6d8cecd9615416821ddd1035b4fb96))
- Add TMUX theme ([`7675170`](https://github.com/Ziwi01/proveasio/commit/7675170b2b12e1cd2c58a702a6c52d87eb00dba7))
- **fzf**: Use built-in sourcing for completion and key bindings ([`2d4a04f`](https://github.com/Ziwi01/proveasio/commit/2d4a04f3ecdb45370910793ac079624f3d792e8e))

## v2.2.0 - 2025-05-05

### Features

- Add kubecolor for colorized kubectl output. Update completions ([`2fa6ebf`](https://github.com/Ziwi01/proveasio/commit/2fa6ebf1fc6fc698e91a9c46c2b71f324e28b6eb))
- Add az-account-switcher for easy Azure subscription change ([`b18dfd8`](https://github.com/Ziwi01/proveasio/commit/b18dfd86f7f4343bb59612f259c6a70473a3e832))
- Add kubeswitch - kubectl context switcher ([`6b28766`](https://github.com/Ziwi01/proveasio/commit/6b28766ca99551b9839e4d63ece0f93dbcfbd159))
- Add iffse/pay-respects as a replacement for thefuck for command autocorrect ([`84817b0`](https://github.com/Ziwi01/proveasio/commit/84817b043cfac7302fb5afe73b85b1e1b012e15e))
- Update Docusaurus ([`b8e109f`](https://github.com/Ziwi01/proveasio/commit/b8e109f8406737c7cc313f277b728dd0d42200e4))

### Bug Fixes

- Do not fail Neovim config update ([`bab1604`](https://github.com/Ziwi01/proveasio/commit/bab160412ba5e4d8ca8ca432668c6d7c9b6e7f2f))
- Update deploy-pages action ([`f3344bf`](https://github.com/Ziwi01/proveasio/commit/f3344bf7c7c0a076e5e2966d1141c2f6b51eb99e))
- Update unsported upload-pages-artifact action ([`a38bc82`](https://github.com/Ziwi01/proveasio/commit/a38bc821842ef403ed518b346b1f1d5c4af4fc41))
- **neovim**: Update Neovim release asset name as it changed ([`4abff0f`](https://github.com/Ziwi01/proveasio/commit/4abff0fca1bdb71f39b11d6adc3d1833265ab124))

### Chores

- Migrate from deprecated YAML callback plugin to built-in result format ([`af3e81b`](https://github.com/Ziwi01/proveasio/commit/af3e81b8123dc48688240821c4c48da311aeb11a))
- Cleanup thefuck automation (replaced with pay-respects) ([`fc541d9`](https://github.com/Ziwi01/proveasio/commit/fc541d9de983ce20f8acfd7099949167acbdd417))

## v2.1.0 - 2025-02-12

### Features

- Update Docusaurus ([`44088ca`](https://github.com/Ziwi01/proveasio/commit/44088cafb1e18a0fbdab8730bac8044bc7f6573a))

### Bug Fixes

- Update deploy-pages action ([`2becbdb`](https://github.com/Ziwi01/proveasio/commit/2becbdba71ff47f60e281d33dfc66aca4fc8c29a))
- Update unsported upload-pages-artifact action ([`6ec9892`](https://github.com/Ziwi01/proveasio/commit/6ec9892afe94516423bba646355dce69631e5843))
- **neovim**: Update Neovim release asset name as it changed ([`4a943c1`](https://github.com/Ziwi01/proveasio/commit/4a943c1ad0a5fece777d79af8b3841f5ec1009d4))
- **RVM**: Overwrite gpg_key_servers to avoid skipping gpg install task ([`816a2bf`](https://github.com/Ziwi01/proveasio/commit/816a2bf3c0d2746e7fe821ff11b339d5ad933649))

## v2.0.0 - 2024-09-07

### Features

- Support also ubuntu 22 for backward compatibility ([`c28f984`](https://github.com/Ziwi01/proveasio/commit/c28f984f01bc3db508c850d0beccded4d0bd38ce))
- Refactor AstroNvim implicit to more general Neovim config ([`7f0e506`](https://github.com/Ziwi01/proveasio/commit/7f0e506dede894ad643b743d53913e9750c6eb28))
- **docusaurus**: Update Docusaurus and docs search engine ([`0fbfe48`](https://github.com/Ziwi01/proveasio/commit/0fbfe48df1ef298c26c7b8db7fd68eaf34b0cee3))
- **BREAKING** **thefuck**: Drop support for thefuck until it supports Python 3.12.x ([`73d2e72`](https://github.com/Ziwi01/proveasio/commit/73d2e72fb5dca0220babe446410fee77df067e55))
- **BREAKING** **python**: Update python to 3.12.5 ([`66c0856`](https://github.com/Ziwi01/proveasio/commit/66c0856096036dabe695ceeecf42f1aafd725f14))
- Support Ubuntu 24.04 LTS ([`1185d4e`](https://github.com/Ziwi01/proveasio/commit/1185d4ede465d47e7cdc8f1325cb1c81edd03676))
- **zshrc**: Add kubectl plugin for autocompletion ([`335f705`](https://github.com/Ziwi01/proveasio/commit/335f70510b629a69cf397ad561c0d75afb178112))
- **ruby**: Update Ruby to 3.3.4 ([`d13b6dd`](https://github.com/Ziwi01/proveasio/commit/d13b6dd0ac4c2558e8a1ec446a9f9ebd73efac6e))
- **apt**: Add lua and luarocks installation ([`1d03f9e`](https://github.com/Ziwi01/proveasio/commit/1d03f9ed77ada335a7b66da1b95bc8f706a34006))
- **BREAKING** **build**: Update runner image to Ubuntu 24.04 ([`eb685f0`](https://github.com/Ziwi01/proveasio/commit/eb685f00d89db9b3f843442f62abbda36501dd54))
- **docusaurus**: Update Docusaurus and docs search engine ([`3e25db4`](https://github.com/Ziwi01/proveasio/commit/3e25db4dc13fbb367c9d26f266c483455d3e0e95))
- **BREAKING** **thefuck**: Drop support for thefuck until it supports Python 3.12.x ([`4bd4e9e`](https://github.com/Ziwi01/proveasio/commit/4bd4e9e24f8d29cb8d298d19705b41b1ff44bccf))
- **BREAKING** **python**: Update python to 3.12.5 ([`589ea0d`](https://github.com/Ziwi01/proveasio/commit/589ea0d1b16f1b3e715c37d37558037c470ddda7))
- Support Ubuntu 24.04 LTS ([`f31bcc2`](https://github.com/Ziwi01/proveasio/commit/f31bcc2b2a3fa448aa7a5d9b4289859c7819a4a5))
- **BREAKING** Replace LunarVim with AstroNvim custom config ([`71d1fc6`](https://github.com/Ziwi01/proveasio/commit/71d1fc65e19f29084608f94949e95073b68836c7))
- Add jq ZSH plugin ([`d14a24f`](https://github.com/Ziwi01/proveasio/commit/d14a24feb13534c95c9a493fa7fd77495b0081f6))
- **software**: Use latest Tmuxp version by default ([`d48c484`](https://github.com/Ziwi01/proveasio/commit/d48c48426986a1e209f485c93324274d55ad2ee6))
- **software**: Update Go version, fix GVM source in terminal ([`1832ac8`](https://github.com/Ziwi01/proveasio/commit/1832ac865cf2fcae2067c293bb886d11879ca151))
- **software**: Replace Java 11.x with 21.x. Upgrade Gradle (8.5), update Groovy and Maven fix versions ([`c9417a9`](https://github.com/Ziwi01/proveasio/commit/c9417a9cf8604ad4f83a7c9a5c4bcb2a5c8ab803))
- **software**: Use Node lts/iron (20.x) by default ([`ff69e16`](https://github.com/Ziwi01/proveasio/commit/ff69e16d60b22dc4e84f5a27522ef0a6337d47ac))
- **software**: Update Puppet to 8.4.0 and puppet-lint gem to 4.2.3 ([`17ece4d`](https://github.com/Ziwi01/proveasio/commit/17ece4d72ea3dadb359a2072a4241242af2d2b82))
- **software**: Update Ruby default version to 3.3.0 ([`0035c99`](https://github.com/Ziwi01/proveasio/commit/0035c99b0247d4fd2477712243c435a88080e806))

### Bug Fixes

- Ansible facts pull for specific Ubuntu version ([`0d17537`](https://github.com/Ziwi01/proveasio/commit/0d1753744204755f8506085c49dfedd886b4862f))
- Ubuntu 24 command typo ([`f718108`](https://github.com/Ziwi01/proveasio/commit/f71810801d437b4ae5e4573060d05790d2fbf42d))
- Typo in command, minor docs fixes ([`63b3599`](https://github.com/Ziwi01/proveasio/commit/63b359938aa6704c0828d850f15eeced2a14ef27))
- **neovim**: Fix playbook path and variable name ([`a5c3b1f`](https://github.com/Ziwi01/proveasio/commit/a5c3b1f1bf6f49c4450e3627239b4da9d98c2876))
- **zshrc**: Ensure proper PATH is propagated in zshrc in case installation fails before config part ([`5d83c11`](https://github.com/Ziwi01/proveasio/commit/5d83c1149022a8e622b7ed9b468d70179e6cc793))
- **nvm**: Fix NVM git submodule clone error ([`888b49e`](https://github.com/Ziwi01/proveasio/commit/888b49eb114bb7cd5420fc0a985cce2181e6ef7d))
- Migrate bat installation from Github to APT ([`1f43bd0`](https://github.com/Ziwi01/proveasio/commit/1f43bd00cd6e89abe449cc5fcd1b14bda7bcf817))
- Add gh-cli installation, migrate mlocate to plocate ([`29e4747`](https://github.com/Ziwi01/proveasio/commit/29e47478bf4800a173e6c3e5b895399545251d9d))
- **neovim**: Update neovim ruby gem to 0.10.0 ([`ac1bc53`](https://github.com/Ziwi01/proveasio/commit/ac1bc53fa21ddf456675b113d5df43372c8d4b8a))
- **nvm**: Run installation through bash ([`593f614`](https://github.com/Ziwi01/proveasio/commit/593f61402196da7898a1b4c10485e6fb9bcae8c4))
- **nvm**: Fix home path for NVM_DIR ([`3ee621d`](https://github.com/Ziwi01/proveasio/commit/3ee621dcd5a7e56cc31c14ef039b7d7d6bbe872a))
- **zshrc**: Ensure proper PATH is propagated in zshrc in case installation fails before config part ([`8a684a8`](https://github.com/Ziwi01/proveasio/commit/8a684a8c35325e413fb161c78a16e851f2432ceb))
- **nvm**: Fix NVM git submodule clone error ([`8ee0929`](https://github.com/Ziwi01/proveasio/commit/8ee09296facaf5dd358f427232a9c95493181934))
- Migrate bat installation from Github to APT ([`80bd1b6`](https://github.com/Ziwi01/proveasio/commit/80bd1b629c6e3097231e4cf09a5ab5fe72beaa91))
- Add gh-cli installation, migrate mlocate to plocate ([`f490638`](https://github.com/Ziwi01/proveasio/commit/f490638a94fa94ec81548be0dbd9ae7876258bfa))
- **fzf**: Save Fzf version properly ([`ab00ba0`](https://github.com/Ziwi01/proveasio/commit/ab00ba08abd8e32d7d6826a5112e2751858000e5))
- **versions**: FZF and bottom packages release naming change ([`a411ced`](https://github.com/Ziwi01/proveasio/commit/a411ced1820ab413e5f8052b14e1d5c6ec92b325))
- **lunarvim**: Prevent double dash on enter in lists for Markdown files ([`89197cd`](https://github.com/Ziwi01/proveasio/commit/89197cde55dfb79015faddc93a01a1a70cff30ae))
- **tmuxp**: Add default session file for TMUXP ([`17d36e7`](https://github.com/Ziwi01/proveasio/commit/17d36e735b1236b8a15ab597a13ad44289285a54))
- **apt**: Allow dowgrades for azure-cli and docker APT packages ([`16c7bc5`](https://github.com/Ziwi01/proveasio/commit/16c7bc5e646f41134abe17ef1bff32cf738a8103))
- **git**: Wrong .gitconfig target filename ([`e0a3363`](https://github.com/Ziwi01/proveasio/commit/e0a33631e9ed78b39f9f05a415343edd529806dd))
- **neovim**: Update version query for better tag discovery ([`48e73d1`](https://github.com/Ziwi01/proveasio/commit/48e73d1b094f6d1bc9350796e1471fee9f70c7c4))

### Documentation

- update CHANGELOG.md for develop ([`18505a5`](https://github.com/Ziwi01/proveasio/commit/18505a5357dc6e31c6ad48d59283f7e6d6b201a9))

### Chores

- Rebase instead of merge during publish ([`c6e8b49`](https://github.com/Ziwi01/proveasio/commit/c6e8b49d65613543eb3fb9b86671c9ef21884b03))
- **docs**: Add note about version overrides. Fix wrong md link ([`1608ef4`](https://github.com/Ziwi01/proveasio/commit/1608ef442679da8c6f8c6feaa1f52cd3dd815f2d))
- **docs**: Update docs ([`0c366c7`](https://github.com/Ziwi01/proveasio/commit/0c366c7e7f19f3e24ac760735f5bcb07cc596cba))
- **docs**: Update docs for new Neovim config ([`e41bc4f`](https://github.com/Ziwi01/proveasio/commit/e41bc4fa9b00f32dc87dd76a070e5ca5203ecc1f))
- **docs**: Align documentation with the code. Prepare for Astronvim docs ([`6276b4b`](https://github.com/Ziwi01/proveasio/commit/6276b4bf75fae3dc77e259ef41a5ec09db6b662b))
- Skip var naming rule in ansible-lint ([`898eb85`](https://github.com/Ziwi01/proveasio/commit/898eb85ea70aa50f105bb52b01266496d32932d0))
- **lint**: Disable ansible-lint no-role-prefix naming lint ([`99f9444`](https://github.com/Ziwi01/proveasio/commit/99f9444b4f0b47753a80240c9ae6f64736e1b434))
- **docs**: Align documentation with the code. Prepare for Astronvim docs ([`fdf84a8`](https://github.com/Ziwi01/proveasio/commit/fdf84a8d2c1511ec0273bf3e9b98989d263ea994))
- Skip var naming rule in ansible-lint ([`9f22ceb`](https://github.com/Ziwi01/proveasio/commit/9f22cebb10148e3962e3f530e9915b6f161eee75))
- **docs**: Add TODO, update README ([`d3bdbd9`](https://github.com/Ziwi01/proveasio/commit/d3bdbd97f91af99bae4767e5acb9c7613bb00d55))

## v1.0.0 - 2024-01-10

### Features

- New Github Actions release workflow ([`f4aea99`](https://github.com/Ziwi01/proveasio/commit/f4aea99047f794db9992962201e84b49eab5fe53))
- **releases**: Refactor Github Actions for releases. Add CHANGELOG generation. ([`562c22a`](https://github.com/Ziwi01/proveasio/commit/562c22af8299575ac73017a5a71fc06c64a78ebf))
- **docs**: Migrate documentation to Github Pages ([`1af116d`](https://github.com/Ziwi01/proveasio/commit/1af116d7d7d80664c1f7b80451de16f85769df13))
- **software**: Update Node to latest LTS, bump neovim ruby gem ([`78c85e1`](https://github.com/Ziwi01/proveasio/commit/78c85e136d06e288348eec8ad3ab8bc42e515bb8))

### Bug Fixes

- **release**: Exclude latest tag from last tag search. Remove pre-release on release. ([`97f269b`](https://github.com/Ziwi01/proveasio/commit/97f269b1ef7531c59a092650231d7046bb795bab))
- **docs**: Update publish.sh script to update stable docs directory ([`77db3c6`](https://github.com/Ziwi01/proveasio/commit/77db3c6e0b028691daeaa340126eca5af73c436d))
- **docs**: Fix Github actions for building Pages website ([`c5a2ef7`](https://github.com/Ziwi01/proveasio/commit/c5a2ef7a184352d60251a64b6bd1594d6b010cf3))
- **docker**: docker-cli should use latest in develop ([`22961bc`](https://github.com/Ziwi01/proveasio/commit/22961bc8bfea3d6510266bbe367b45f9d4ef1197))
- **docker**: Remove explicit containerd.io installation to not fail after package upgrade ([`8977146`](https://github.com/Ziwi01/proveasio/commit/89771460b6c4ea4a55ddc80a7283a6bc3cae3824))

### Other

- Update versions ([`5b2a3e9`](https://github.com/Ziwi01/proveasio/commit/5b2a3e92164079f96bb90dff474f55e8ca7a86cb))
- Update versions ([`be1644f`](https://github.com/Ziwi01/proveasio/commit/be1644f682c6a401d0ce2a696d12385a45a0da1b))

## v0.11.3 - 2023-12-04

### Features

- **neovim**: Add support for Azure Pipelines LSP ([`0c7b6fb`](https://github.com/Ziwi01/proveasio/commit/0c7b6fb5d9689015c70542eb45acba569dfad01d))
- **nvim**: Add support to open files in new tab from inside LazyGit plugin ([`f53ff2b`](https://github.com/Ziwi01/proveasio/commit/f53ff2b4bca80ffd88607e30bad7a6f9657fa67c))

### Bug Fixes

- **software**: Update Ripgrep package name, force PES cloning ([`5a63cbc`](https://github.com/Ziwi01/proveasio/commit/5a63cbcb04ba674bcbca1f5ac6365bcf4c1b0967))

### Other

- Update versions ([`1d97b0e`](https://github.com/Ziwi01/proveasio/commit/1d97b0e4aa63c9b18f181c1bfaa2930444abd80c))
- Update versions ([`4e49fd3`](https://github.com/Ziwi01/proveasio/commit/4e49fd34afbc2b747f2aef7ee710deff99401140))
- Update versions ([`c2f2c35`](https://github.com/Ziwi01/proveasio/commit/c2f2c355c8995913d8f55599e3b263857c208635))
- Update versions ([`8fbb302`](https://github.com/Ziwi01/proveasio/commit/8fbb302b170c96697a695f59d7da317512d6d8f8))
- Update versions ([`939320d`](https://github.com/Ziwi01/proveasio/commit/939320d5a22239aef21246482c84fa37dc25c9a8))
- Update versions ([`3acc0d8`](https://github.com/Ziwi01/proveasio/commit/3acc0d8b115597487f6c239815deb3db5732e316))

## v0.11.2 - 2023-08-23

### Bug Fixes

- **azurecli**: Install latest version of azurecli ([`7e8318e`](https://github.com/Ziwi01/proveasio/commit/7e8318eacbb2d8dade99864f78c356ae86b2a855))
- **compilation**: Remove implicit docker-compose-plugin installation ([`5ca227d`](https://github.com/Ziwi01/proveasio/commit/5ca227d48cd5df4689087b297a631e0b677e5e65))
- **packages**: Remove implicit docker-ce-cli installation, update azurecli to latest by default ([`61cb4be`](https://github.com/Ziwi01/proveasio/commit/61cb4bea4f57ebe1d82fa037a604b547b0a91638))
- **fonts**: Update fonts to NerdFonts v3 ([`97ca32e`](https://github.com/Ziwi01/proveasio/commit/97ca32e838859aeb6988fc62c9ec83fe9691e0da))

### Chores

- **lunarvim**: Refactor config.lua into separate files for clearance ([`8bc7a4c`](https://github.com/Ziwi01/proveasio/commit/8bc7a4c7c4da10ec43b1170c906ea7dbc011abd9))

### Other

- Update versions ([`d08650d`](https://github.com/Ziwi01/proveasio/commit/d08650d96f130a5ae75c37c81d5763ec7fb68ca6))
- Update versions ([`6994ed5`](https://github.com/Ziwi01/proveasio/commit/6994ed5c98aa908ed493b48e3c68de6ea6271ead))
- Update versions ([`63cac29`](https://github.com/Ziwi01/proveasio/commit/63cac293d0c7e73a03e3146a9f11a4dfa5c3ec61))
- Update versions ([`cc84ac3`](https://github.com/Ziwi01/proveasio/commit/cc84ac3fd89d952c59d1c76303a01ec698d1f5ec))
- Update versions ([`888854a`](https://github.com/Ziwi01/proveasio/commit/888854a9ec93dd3cbdf7129091206b35d5713ffd))
- Update versions ([`508c201`](https://github.com/Ziwi01/proveasio/commit/508c201ca2abeddd7467dff7c861940058e0f759))
- Update versions ([`af1f183`](https://github.com/Ziwi01/proveasio/commit/af1f183d915dfd9d0da90937d6325dfbb571e1a7))
- Update versions ([`944dc05`](https://github.com/Ziwi01/proveasio/commit/944dc0577ad43ef7395842b392bcd902d8f46db1))
- Update versions ([`83828d4`](https://github.com/Ziwi01/proveasio/commit/83828d417d92f0855fb6aefb1cbe7f52f68c7947))

## v0.11.1 - 2023-05-07

### Features

- Add fzf-tab-sources plugin for ZSH ([`406e160`](https://github.com/Ziwi01/proveasio/commit/406e16092e6e803c503f9895b7b0cbcfaffb96d6))

### Bug Fixes

- **neovim**: Separate LSP config to prevent errors on startup ([`57f58a2`](https://github.com/Ziwi01/proveasio/commit/57f58a294384b43b3ceb64747c9b8d8bd379dd69))

### Chores

- **docs**: Update ftplugin description ([`0d25ddf`](https://github.com/Ziwi01/proveasio/commit/0d25ddf723d32d3c087ef1da89ac1c83cf9249c8))

### Other

- Update versions ([`6823b6a`](https://github.com/Ziwi01/proveasio/commit/6823b6a429852ef2fb502f2b5f6f46bf1f30130d))
- Update versions ([`cde4f38`](https://github.com/Ziwi01/proveasio/commit/cde4f386d1020ee1e0dccabe12efb221cca169fd))

## v0.11.0 - 2023-05-06

### Features

- Add AWS CLI installation ([`deeee58`](https://github.com/Ziwi01/proveasio/commit/deeee585054cd9fb00a905b4a368a4e41e14dc8f))
- Add Go installation support using GVM ([`03ae48b`](https://github.com/Ziwi01/proveasio/commit/03ae48bd8402aebfda6ccadef76dee74690cc183))
- **tmux**: Add tmuxp session manager ([`68ef2d6`](https://github.com/Ziwi01/proveasio/commit/68ef2d658a231d281c8e4e5dc5ac08facb75e46f))

### Bug Fixes

- **nvim**: Move LSP config after plugin installation, add note for first-time open ([`2345e26`](https://github.com/Ziwi01/proveasio/commit/2345e261daa5f308917d456578fab5e53a4efd0c))
- Ensure common packages are installed before yq installation ([`f46b8c0`](https://github.com/Ziwi01/proveasio/commit/f46b8c00b83060d1308e6817ef680b611ef6de35))
- **nvim**: Do not skip automatic LSP installation for servers, just launch them ([`6f6491b`](https://github.com/Ziwi01/proveasio/commit/6f6491bddd92523ca01e2107350e41878864b834))
- **gvm**: Proper first time install ([`1e7eb89`](https://github.com/Ziwi01/proveasio/commit/1e7eb8933b22c6de4a65e0a8e537337dd331c014))
- **zsh**: Actually load fzf-tab functionality ([`4afa617`](https://github.com/Ziwi01/proveasio/commit/4afa617ee9321f56fd7125f857148d28be88d5aa))

### Chores

- **docs**: Add yaml callback for prettier first ansible run ([`4d702bc`](https://github.com/Ziwi01/proveasio/commit/4d702bc7a165e25a9b8903c7f8558facee616df3))
- Run pre-release build once a week to ensure everything is working ([`4dffa83`](https://github.com/Ziwi01/proveasio/commit/4dffa83e7a18d937b82060decb01d3a089affa10))
- **docs**: Update installation instructions ([`2ec9a85`](https://github.com/Ziwi01/proveasio/commit/2ec9a85ed41b5d44267248fb6cf3e0f683d96e56))

### Other

- Update versions ([`0e7a934`](https://github.com/Ziwi01/proveasio/commit/0e7a93467ffe27e1045c0a203e92c691dbb9795e))
- Update versions ([`237c5ce`](https://github.com/Ziwi01/proveasio/commit/237c5ce43e639602959b8f66ebdf1fa5219ca256))
- Update versions ([`2acf2da`](https://github.com/Ziwi01/proveasio/commit/2acf2da14021a351b36b21511b6c8e955d110267))
- Update versions ([`4328ed1`](https://github.com/Ziwi01/proveasio/commit/4328ed12ee15c4679ae2cb9ffd3e61c3ec6195b6))

## v0.10.0 - 2023-04-27

### Features

- **lvim**: Add leap plugin for awesome motions ([`b92766b`](https://github.com/Ziwi01/proveasio/commit/b92766b745827fc66da3a18780ad81e2a7c351f1))
- **tmux**: Open new panes in current directory, add vi-style copy mode ([`0827067`](https://github.com/Ziwi01/proveasio/commit/082706790fd7fba1ff29b9018cbd3c47a07127d1))
- **neovim**: Add support for Neovim nightly installation ([`6e52836`](https://github.com/Ziwi01/proveasio/commit/6e528366c89b4f57388d43b08c7424899f3db03b))
- Add Azure CLI installation ([`46af5dd`](https://github.com/Ziwi01/proveasio/commit/46af5ddb299c5a5c3cef9eaf0d79e34943f955d7))
- Add Terraform and Terragrunt support ([`623e4fc`](https://github.com/Ziwi01/proveasio/commit/623e4fcfad16fa49cad9e3d2334286f0a25fdecd))

### Bug Fixes

- **neovim**: Installation fail when no neovim is there ([`9019b9e`](https://github.com/Ziwi01/proveasio/commit/9019b9eb5d279a6238c5eaecfa78466f4f3abd78))
- **sdkman**: Actually bump maven version ([`ec3641d`](https://github.com/Ziwi01/proveasio/commit/ec3641d4d62bd051f6a9da59ead5839256e5655b))
- **sdkman**: Bump maven version because of corrupted zip file ([`2ba1b3a`](https://github.com/Ziwi01/proveasio/commit/2ba1b3acfa07fa996c64f5e14c5bbb834bb80a97))
- Set Lunarvim to latest instead of master by default ([`c92c356`](https://github.com/Ziwi01/proveasio/commit/c92c3568be0d1a2700be5a387bd1f6c3ee68fbdb))
- README.md build badge path changed ([`5b9786d`](https://github.com/Ziwi01/proveasio/commit/5b9786df9816961e8a77f2f4a480c23dd9f0873c))

### Other

- Update versions ([`978478d`](https://github.com/Ziwi01/proveasio/commit/978478dfaba4f20c8a982a973f49b7bfa25446a9))
- Update versions ([`1d70b2f`](https://github.com/Ziwi01/proveasio/commit/1d70b2f894afe91773f7b12ec53fb6da00685eb7))
- Update versions ([`b1facf7`](https://github.com/Ziwi01/proveasio/commit/b1facf7b237c75d9231e194702b0881661503121))
- Update versions ([`40b18c7`](https://github.com/Ziwi01/proveasio/commit/40b18c798370dbbf86daf40a14002f40eeedef98))
- Update versions ([`8260b7c`](https://github.com/Ziwi01/proveasio/commit/8260b7c566e234c52b72ea770ff40446f88b50cc))

## v0.9.1 - 2023-03-15

### Features

- Prepare release workflow ([`ddb7425`](https://github.com/Ziwi01/proveasio/commit/ddb7425d19599683e0ddbfb990b6263fd58bafa9))
- **font**: Migrate to FiraCode Nerd Font instead of DejaVu ([`7dc3ce9`](https://github.com/Ziwi01/proveasio/commit/7dc3ce96b6c249f1b79e0191fed54aff9a2dee2b))
- Add automatic release action workflow ([`223b416`](https://github.com/Ziwi01/proveasio/commit/223b416ce256f1239ab4a1b9e54345382f142129))
- Add yq YAML parser installation. Further version refactor for release process ([`36b1e55`](https://github.com/Ziwi01/proveasio/commit/36b1e555ccbde856ed34a9a760b2f2f97b98815a))
- Add pyenv and pyenv-virtualenv setup. Install all PIP packages to new python version ([`9902744`](https://github.com/Ziwi01/proveasio/commit/9902744501f115f30225dcf6b57f21872b6452a5))
- Add support for installing gems for ruby versions ([`e1dcf22`](https://github.com/Ziwi01/proveasio/commit/e1dcf229e34d1ce906b4356ff74fc1e42f7e2ecb))
- Add docker, kubectl, k9s, kind. Update docs, lint all tasks ([`98f33a8`](https://github.com/Ziwi01/proveasio/commit/98f33a850373548d5dbf79470bb4bfbe3e8da279))
- Assign tags to all tasks, update README, include Ubuntu 20 in CI build ([`6d9186b`](https://github.com/Ziwi01/proveasio/commit/6d9186b0742d111c71a1969050ad68a4a7955ffe))
- Change colorscheme ([`5d142c9`](https://github.com/Ziwi01/proveasio/commit/5d142c96fcb275560d75e28f820e8a157d171cc9))
- Add TMUX extrakto plugin ([`d5c9493`](https://github.com/Ziwi01/proveasio/commit/d5c9493c3845e32dafebf7f09c0b70e0d1d88b25))
- **neovim**: Add keymap for keeping clipboard buffer after paste ([`39f6185`](https://github.com/Ziwi01/proveasio/commit/39f61856d680d825836c8067110a2be59fb1f8d2))
- Add new plugins to Neovim ([`ca59276`](https://github.com/Ziwi01/proveasio/commit/ca5927691b9409bd78aab48dc321b98bdb7be004))
- **Neovim**: Add Markdown preview and Tabularize plugins ([`9e627df`](https://github.com/Ziwi01/proveasio/commit/9e627dfe1a05abeed4c46605d0cb1cc891c1ca36))
- Support both Ubuntu 20.04 and 22.04 ([`8b8129e`](https://github.com/Ziwi01/proveasio/commit/8b8129ebc4b6cf652d06a6960fe2e575ea0dd72b))
- Migrate to Ubuntu-22.04 ([`5785905`](https://github.com/Ziwi01/proveasio/commit/5785905ac044b0b3de189af985e1dbefa49d7311))
- Add NVIM telescope Zoxide. Update ssh command tmux rename command ([`de1b207`](https://github.com/Ziwi01/proveasio/commit/de1b207131bfd981d5c56239544423a8599a3a6e))
- Add GIT update, add Diffview Neovim plugin ([`301e4ce`](https://github.com/Ziwi01/proveasio/commit/301e4cefae8771fa6fb57f25dff7407a8020bb4d))
- Add all roles tasks exclude, add Helm Neovim plugin ([`6d3e72e`](https://github.com/Ziwi01/proveasio/commit/6d3e72e0f70bcbcaed00989db4992e879c18cda0))
- VIM+TMUX easy pane/split navigation ([`b23f560`](https://github.com/Ziwi01/proveasio/commit/b23f560164e9c1ae5787369eea1167f23ca0fbff))
- **lvim**: Add trailing whitespace plugin ([`905b800`](https://github.com/Ziwi01/proveasio/commit/905b800c782a227643b26690a21a53170f5241a6))
- Add nvim/tmux session support ([`2d56671`](https://github.com/Ziwi01/proveasio/commit/2d5667149a584497da9a447b1c4a268d68c9d295))
- Add SDKman installation, latest ripgrep and fd ([`1ccc891`](https://github.com/Ziwi01/proveasio/commit/1ccc891592acf35baf26ae1228c3b3e26d3494c1))
- Update docs, add overrides.yaml ([`32866d2`](https://github.com/Ziwi01/proveasio/commit/32866d2b60ee8ef46e7ac4c7acb4258ee6f87be5))
- New Neovim functional plugins ([`57e4ea1`](https://github.com/Ziwi01/proveasio/commit/57e4ea1d604717089fc3abaef30206b189821a1d))
- Show exact versions that got installed. ([`bbd3acc`](https://github.com/Ziwi01/proveasio/commit/bbd3acc4f800cb2b714eecdfe4b962770e83a86d))
- Add latest tmux installation. Get all software versions displayed at the end of play ([`81f9d19`](https://github.com/Ziwi01/proveasio/commit/81f9d1934074a905f5855e47a814801598e4cd81))
- Add LazyGit installation, various refactors ([`d4701a2`](https://github.com/Ziwi01/proveasio/commit/d4701a2cb93b3c07b3012cac5d2b175a6032f174))
- Add TMUX fuzzback plugin, name tmux window on SSH connection ([`bc98027`](https://github.com/Ziwi01/proveasio/commit/bc98027fa051732eb607831cc8bd6a4a5058153e))
- Update ansible-lint config ([`1a4c40e`](https://github.com/Ziwi01/proveasio/commit/1a4c40e3541355a4336b44686c0be17545c8d0b9))
- Neovim - add new plugins and mappings; Update readme ([`25614b0`](https://github.com/Ziwi01/proveasio/commit/25614b0c65a399c2023f22e07f39487fd59cd1ad))
- Add puppet/ansible langauge tools ([`b8b3416`](https://github.com/Ziwi01/proveasio/commit/b8b3416115426f80e9976161534bbb19bc76b20f))
- Add Neovim/LunarVIM, Gita, update configs, update fonts and more ([`068d182`](https://github.com/Ziwi01/proveasio/commit/068d182f15d0861d34921815663e3c95362e7c57))
- Update README, minor fixes ([`01c1947`](https://github.com/Ziwi01/proveasio/commit/01c194709174a1fb28ad182b9f2baaafbeeff96a))
- Add more windows tasks, slight overall refactor ([`e251d96`](https://github.com/Ziwi01/proveasio/commit/e251d965ae7b16c5a59ff2154636c77570ad4fd1))
- Add Windows setup ([`7c3e76d`](https://github.com/Ziwi01/proveasio/commit/7c3e76d118f84164eb50d8fef4efa9633ffd6b7b))
- Add PDK and NVM installation ([`e6e6bf1`](https://github.com/Ziwi01/proveasio/commit/e6e6bf1f32ed402e51a9acda214a4e6f61c3e9e5))
- Add RVM installation and some default Rubies ([`7e88424`](https://github.com/Ziwi01/proveasio/commit/7e88424c588ba5892e99d14d9c239f5311cb41d9))

### Bug Fixes

- latest versions file got overwritten ([`d7ee34a`](https://github.com/Ziwi01/proveasio/commit/d7ee34acb63a0879b2e70bc1cf162568c731a9a7))
- **vim**: Fix markdown LSP, add new plugin, describe usages ([`4050f0c`](https://github.com/Ziwi01/proveasio/commit/4050f0cc8d9f820f5a9171b3f94f6d5eeb9a7d70))
- **ansible**: Get actual PIP version for ansible ([`5abcbcd`](https://github.com/Ziwi01/proveasio/commit/5abcbcd4b6d6bbc214f30791276fc3acbc348ce9))
- **zsh**: Correct node preloading, enable thefuck lazyload ([`7a21ae3`](https://github.com/Ziwi01/proveasio/commit/7a21ae354ed6c12a16864966caac1367e0d929cb))
- kubectl and p10k version save ([`826f616`](https://github.com/Ziwi01/proveasio/commit/826f616322c20d719bd9f1854092d8333eabe83a))
- **ansible**: For prepare-ubuntu.sh use the same ansible version which is in software vars ([`99deb4b`](https://github.com/Ziwi01/proveasio/commit/99deb4b77bc9e3caa12d404aace9829e68eec86f))
- **build**: Ubuntu 22.04 runner grub error, RVM URL variable typo ([`931f243`](https://github.com/Ziwi01/proveasio/commit/931f243018eeb08d82faf1b5b901fe6c58d971ad))
- **p10k**: Version tag has v prefix ([`838294e`](https://github.com/Ziwi01/proveasio/commit/838294e910901e259e02347d2e986a020b70701e))
- **versions**: Do not set app_url when no URL or URI is passed ([`a5fea9f`](https://github.com/Ziwi01/proveasio/commit/a5fea9fc277c58c705ba3a04434a5745de57f206))
- **versioning**: Properly include tags for getting software versions ([`a720ac4`](https://github.com/Ziwi01/proveasio/commit/a720ac4c73d96221654bb7d55228e23348dda214))
- **versions**: Proper sdkman packages and defaults objects in current-versions.yml ([`26dc170`](https://github.com/Ziwi01/proveasio/commit/26dc170c09e34b2b79ba65b75e119ec3f56ec626))
- After refactor fixes for saving versions ([`8c416b1`](https://github.com/Ziwi01/proveasio/commit/8c416b1abb675894e0ffb53d941b6baad276d839))
- Lunarvim and Neovim version task include ([`b60eb66`](https://github.com/Ziwi01/proveasio/commit/b60eb668dcd11a926774d3192335b6f2c9222ff1))
- Neovim version in vars ([`6c7101f`](https://github.com/Ziwi01/proveasio/commit/6c7101f01c34fa7dfc5d1541a5f4f80c56fac17f))
- Lazygit github URI ([`e8734d0`](https://github.com/Ziwi01/proveasio/commit/e8734d030bcce1d1d34d3950ae27af8e3c271994))
- Github workflow file update ([`0901897`](https://github.com/Ziwi01/proveasio/commit/0901897f6625a4903c03b688f4cd94a901b9b123))
- **zsh**: Preload node version and lazyload nvm for faster startup time ([`4a79fba`](https://github.com/Ziwi01/proveasio/commit/4a79fba3be35b7c82bab03b233ff1d2e4ef2e096))
- **zsh**: Bring down startup time from ~4s to ~0.8s ([`9b44bf2`](https://github.com/Ziwi01/proveasio/commit/9b44bf2c76dda1ce6d290e64d68da6cc30d30e9e))
- Ubuntu runner needs explicit PIP shim path ([`457ab36`](https://github.com/Ziwi01/proveasio/commit/457ab36ce039e229a74b9aae958046f3162c0816))
- Docker repository architecture ([`dbab046`](https://github.com/Ziwi01/proveasio/commit/dbab0468fad1e3652445a489a7bff51ba086d4d8))
- use apt-get instead of apt ([`09a9cf4`](https://github.com/Ziwi01/proveasio/commit/09a9cf403d196cb51a4330b6993684616da41b57))
- kubectl get version, docker requirement for Ubuntu 22.04 ([`e35fb29`](https://github.com/Ziwi01/proveasio/commit/e35fb290e42b40b67ee53bd098d4f1b5379744ac))
- Add apt cache update for Docker repo ([`073b469`](https://github.com/Ziwi01/proveasio/commit/073b469a4ebfe60a27fb7c99f317404faf42b3c3))
- Remove ruby 2.4.x installation from Ubuntu 20.04 ([`8adc0a2`](https://github.com/Ziwi01/proveasio/commit/8adc0a2f3808730eb244511a928e36ac452c24dd))
- Packer to Lazy migration, telescope grep include hidden files ([`3646a93`](https://github.com/Ziwi01/proveasio/commit/3646a937b7aca75df443b4b4de34a34106278987))
- TMUX ektrakto plugin path ([`c28e18b`](https://github.com/Ziwi01/proveasio/commit/c28e18b89605067eb0af4da626aee39b6d3a494f))
- **TMUX**: Fix resurrect process for LunarVim, add extrakto plugin ([`1ca0220`](https://github.com/Ziwi01/proveasio/commit/1ca0220a716a5d32395148c325fb93290fc3031c))
- Proper include vars for overrides ([`4013db7`](https://github.com/Ziwi01/proveasio/commit/4013db74c78ead01ea74b91afa6043068982dbb6))
- Conditional overrides.yml loading ([`b6cdaeb`](https://github.com/Ziwi01/proveasio/commit/b6cdaeb59cad8bcbd3d4f3a698cc668e7ace5a1d))
- Load overrides.yml conditionally ([`78bb253`](https://github.com/Ziwi01/proveasio/commit/78bb253ff28ffdb8ee171565f0c87ca263ad897f))
- Set specific puppet/puppet-lint gem versions ([`3af0a7a`](https://github.com/Ziwi01/proveasio/commit/3af0a7aa6de61573520a55c0f4e8d6dbe519721d))
- Remove ruby 2.7 installation ([`5f1e655`](https://github.com/Ziwi01/proveasio/commit/5f1e655aa8d3371e1faa4b6ccc3df8e711bf31ef))
- downgrade to ruby 2.7.6 ([`c9564e2`](https://github.com/Ziwi01/proveasio/commit/c9564e28a7b2a2c1291afb1e8007d0e84f31f315))
- Update puppet and puppet-lint gems ([`a395dd0`](https://github.com/Ziwi01/proveasio/commit/a395dd0022a869f95d87543f118ec5585a65d5c9))
- Remove things from excludes ([`e5954cf`](https://github.com/Ziwi01/proveasio/commit/e5954cf5b6ef02c96cf56875e101a12e656d3a1c))
- Fail whole run if Tmux installation fails. Add missing package for gitlab runner ([`3e925c2`](https://github.com/Ziwi01/proveasio/commit/3e925c2cb6d985a5457c3a1b042e74997d28b315))
- Remove warn: off from ansible commands ([`4c20213`](https://github.com/Ziwi01/proveasio/commit/4c20213b859805d52d43dcb23ee49f8285d77c0e))
- ctags package rename to universal-ctags ([`d9d3486`](https://github.com/Ziwi01/proveasio/commit/d9d348619027da08e0acb808f1b6b525f71599b2))
- puppet-lint verstion to support ruby 2.4.10 ([`0bfe34e`](https://github.com/Ziwi01/proveasio/commit/0bfe34e03b91fb097a9cd57d1aca554c42852890))
- proper loading of overrides.yml variables ([`fb27190`](https://github.com/Ziwi01/proveasio/commit/fb27190e8497e94233e64b50da638e3ac2ef028f))
- Add missing vim shortcuts and tmux transparency ([`836d2d0`](https://github.com/Ziwi01/proveasio/commit/836d2d079a207c609ae0a22c78f743aa244628a9))
- SDKman handler name fix ([`96411a6`](https://github.com/Ziwi01/proveasio/commit/96411a6500a9213fabcb7e842dd52b8474c8704e))
- Telescope absoulte paths, TMUX TERM for ssh connection ([`888afd9`](https://github.com/Ziwi01/proveasio/commit/888afd90181d4e8f5b09fe560763b9e777bae307))
- Do not show git blame inline for NvimTree ([`ce34088`](https://github.com/Ziwi01/proveasio/commit/ce340882433bc54c63b7b72217571898c723cca7))
- Get rid of artificial 'user' variable ([`edc7c2c`](https://github.com/Ziwi01/proveasio/commit/edc7c2c24a7e8daa5c5b462210592618e7900033))
- Actual WSL first install ([`dc507a1`](https://github.com/Ziwi01/proveasio/commit/dc507a1c0939da095f729c06517fe01bbcb67262))
- Try to fix gitlab runner NVM search ([`7e24f4a`](https://github.com/Ziwi01/proveasio/commit/7e24f4a98cce6b280270a0107aa0c35e0d0d51ff))
- Add Tmux plugin manager installation, update docs ([`5697118`](https://github.com/Ziwi01/proveasio/commit/56971180e6246d528f156dd41ca322de34297841))
- Uncomment testing ([`bc233df`](https://github.com/Ziwi01/proveasio/commit/bc233df418182953ba0cabad47bfa649fd8cdcfe))
- Update firs time install, update docs ([`7cc5df2`](https://github.com/Ziwi01/proveasio/commit/7cc5df2827487e211aacc1182ba9a16851a109fc))
- NPM modules installation ([`e95dc3f`](https://github.com/Ziwi01/proveasio/commit/e95dc3fc8263cc63f03d1a5a1aadf861608492ef))
- ansible LSP installation, LunarVIM install, remove hostname change, update README ([`c852776`](https://github.com/Ziwi01/proveasio/commit/c8527764c225eb9d52eb24b884d073c9b23260ff))
- Ansible LSP npm installation, update README ([`398688c`](https://github.com/Ziwi01/proveasio/commit/398688c8f3e3fa3a780ea1017f6fb160e5afc9d9))
- Update Readme.md ([`a302f6c`](https://github.com/Ziwi01/proveasio/commit/a302f6c69f0002fbcb46b4c1bd7fa4e16bf58948))
- Update docs part #1 ([`997294e`](https://github.com/Ziwi01/proveasio/commit/997294e27018c42a0b43ef6c1c9d305cbe9e8cbb))
- Puppet LSP bundle install for all rubies ([`647c9ea`](https://github.com/Ziwi01/proveasio/commit/647c9ea3c8a466010569b3bb41bfe79b2192b9b9))
- Puppet bundle install ([`7cf457c`](https://github.com/Ziwi01/proveasio/commit/7cf457c55289f35e226538a27d266f057f23dade))
- Ansible playbook order, update LUA config file ([`f88d793`](https://github.com/Ziwi01/proveasio/commit/f88d793a7150862e76f131be38a855217b18267c))
- Puppet LSP bundle install ([`9dc4dab`](https://github.com/Ziwi01/proveasio/commit/9dc4dabc23dd7fe95eb4f4b94287ec518a6392fb))
- First time run fixes ([`3ac7bed`](https://github.com/Ziwi01/proveasio/commit/3ac7bedd4bcf919caad442634dbe8c0773763e59))
- thefuck config directory ([`af31a68`](https://github.com/Ziwi01/proveasio/commit/af31a680a08f7e280036bf561ddc5c78663f5cba))
- Uncomment tests ([`535c9c3`](https://github.com/Ziwi01/proveasio/commit/535c9c3c32a674d475e22c53cbcd42df00d57e94))
- various fixes for ansible/puppet ([`19041ff`](https://github.com/Ziwi01/proveasio/commit/19041ff8d2acaebb8a5dc6d246a4fa1de3e1ff31))
- Zoxide version fix ([`bbab10f`](https://github.com/Ziwi01/proveasio/commit/bbab10f4fc5cf82e6e96c998620ecde0f854fa23))
- Update windows prepare script ([`83d85cd`](https://github.com/Ziwi01/proveasio/commit/83d85cdde37b8a228da2f2c1017571d121a16b46))
- Add lsg for wsl, use credssp for windows ([`7a0b01e`](https://github.com/Ziwi01/proveasio/commit/7a0b01e738d2afbab4aea76f729992c2dad8238e))
- use credssp auth instead of basic ([`91f04c8`](https://github.com/Ziwi01/proveasio/commit/91f04c83712d35906502d5ace9b426b9b66c9dfe))
- Windows part fixes, various updates ([`97ce13f`](https://github.com/Ziwi01/proveasio/commit/97ce13f986aafcc5278c8f12c0cb87f2faf29297))
- final touches ([`e18cb36`](https://github.com/Ziwi01/proveasio/commit/e18cb365d9a862aba62ba95de875170500b2ab8a))
- CI tests #2 ([`096a344`](https://github.com/Ziwi01/proveasio/commit/096a34488a1b3b57ff743d0f080cc1abbeab0cf7))
- CI test path ([`7ba5b1e`](https://github.com/Ziwi01/proveasio/commit/7ba5b1ead191a1e1a10d2e98c55f7e2e7dd6956c))
- uncomment missing roles ([`1b41e4d`](https://github.com/Ziwi01/proveasio/commit/1b41e4d3750039f92a51e05d1d70ee7a86278737))
- templating error on github runner instance ([`60c627e`](https://github.com/Ziwi01/proveasio/commit/60c627e1ca0beb9e6b04ea96f8e1956168fca07f))
- Ansible task names fixes, gitlab CI fix ([`29237f7`](https://github.com/Ziwi01/proveasio/commit/29237f7707cf08703235b7749cd02f90f2319ad1))
- Gitlab CI fix env file sed path ([`0acfd16`](https://github.com/Ziwi01/proveasio/commit/0acfd169c285f2706560eae0fc315c497bfaeeff))

### Refactor

- Change logo and name ([`9cc4fa5`](https://github.com/Ziwi01/proveasio/commit/9cc4fa54770a68a79dae90271a76ff3654f7cafb))
- Simplify config management and backups ([`ef06ae8`](https://github.com/Ziwi01/proveasio/commit/ef06ae8655e6c51eaa326ca0f0154e8eb0c97d32))
- Merge dev and software role. Fix bugs after previous refactor ([`d88663c`](https://github.com/Ziwi01/proveasio/commit/d88663c086a0121ed281fa86b6f57af9d9cad09c))
- Major refactor for getting installed versions ([`511cd35`](https://github.com/Ziwi01/proveasio/commit/511cd35db058085b6b4c210be1b94ff94c1cb1d2))
- Reorganize version management, prepare for release process ([`88c1da9`](https://github.com/Ziwi01/proveasio/commit/88c1da95e57fdb3273866f2f0f681f4093a52d12))

### Documentation

- Update TODO, add logo ([`55d4eff`](https://github.com/Ziwi01/proveasio/commit/55d4eff8c49b1ebe66f24b9ac24e255cb1526f5c))
- Update README, fix: settings.json font name, feat: neovim autosave plugin ([`2947b27`](https://github.com/Ziwi01/proveasio/commit/2947b2784a17f48e9b57f5837bd20eb4a46ecf1c))
- Update Readme.md ([`4287656`](https://github.com/Ziwi01/proveasio/commit/42876568d8dffee4b8a6b43897e36b1a63a5cb46))
- Update markdown, minor fixes. ([`1fc2df4`](https://github.com/Ziwi01/proveasio/commit/1fc2df44348d923522b55ed59af2ace697608a0c))

### Tests

- Lunarvim latest tag install hangs, check master ([`a8620a2`](https://github.com/Ziwi01/proveasio/commit/a8620a24b1062951434e8fa52742122744b133d8))

### Chores

- **docs**: Update Usages.md ([`0993b2c`](https://github.com/Ziwi01/proveasio/commit/0993b2caca8ffd2f334b4aa96a2025481dd1f2d4))
- update terminal preview with new font ([`dc86f11`](https://github.com/Ziwi01/proveasio/commit/dc86f1151e09129f733b81028f7e059f1b6b26eb))
- Remove changes.md ([`6cb061c`](https://github.com/Ziwi01/proveasio/commit/6cb061c24598360914154d2bfc54914aad9c759c))
- **docs**: Missing pieces to Usages.md ([`be3ae17`](https://github.com/Ziwi01/proveasio/commit/be3ae179c6760c08d22b260a4b8e04367226f462))
- Update docs ([`db26fe6`](https://github.com/Ziwi01/proveasio/commit/db26fe658da64a582a8a577ddaf46d8926862fd0))
- Add usage scenarios ([`e00d4c8`](https://github.com/Ziwi01/proveasio/commit/e00d4c8f3069790c923d74ae63c0a62bce8de792))
- Update docs ([`ff3f932`](https://github.com/Ziwi01/proveasio/commit/ff3f9322c01ef290435f3976ba30ca9737e74b4b))

### Other

- Update versions ([`bfc7edb`](https://github.com/Ziwi01/proveasio/commit/bfc7edbee66dbe7c532a43513e47264686062e65))
- Update software versions to latest for development ([`5da2dfe`](https://github.com/Ziwi01/proveasio/commit/5da2dfee8a93fb61f6a000e52eb5a7ddc32e3559))
- Set latest version for development ([`8d82555`](https://github.com/Ziwi01/proveasio/commit/8d82555bfdb4753a9f93f3b71844b40f6217b975))
- Publish changes to master ([`7209359`](https://github.com/Ziwi01/proveasio/commit/7209359736cb5e60079bd542126d0a91a9c0c8c2))
- **!**: Drop official Ubuntu 20.04 support ([`4ff33eb`](https://github.com/Ziwi01/proveasio/commit/4ff33eb253387d0dde2666c549a380dda0dbeb81))
- Debug NVM error ([`b251cdd`](https://github.com/Ziwi01/proveasio/commit/b251cdd1f611488d323f78cb23a5b4d7993151a7))
- Debug NVM ([`e60ac26`](https://github.com/Ziwi01/proveasio/commit/e60ac265cfd5ccd9e7eb713ba3bf7eb856a323c6))
- Debug NVM error ([`bee4038`](https://github.com/Ziwi01/proveasio/commit/bee4038314246fce4d663a820bfdeca9a3edc68d))
- Debug NVM problem ([`65a0e01`](https://github.com/Ziwi01/proveasio/commit/65a0e0141a9a1c6805c467bfb0608e638f729762))
- Update prepare-windows.ps1 ([`9a2c6c5`](https://github.com/Ziwi01/proveasio/commit/9a2c6c55363aa01a994864881396011eaf0407c4))
- Update nvm.yml ([`0d1fdb1`](https://github.com/Ziwi01/proveasio/commit/0d1fdb104ea99da1657e5451fe15e7a4c9c94214))
- Update README.md ([`0a93367`](https://github.com/Ziwi01/proveasio/commit/0a933671fecb3b5852faad2496a043ce3eced3bf))
- Update README.md ([`a43cde6`](https://github.com/Ziwi01/proveasio/commit/a43cde65fcaa657c0b9c79a85db1fd3ce1d39e0b))
- Update README.md ([`d817a9d`](https://github.com/Ziwi01/proveasio/commit/d817a9d814181e067eff33418a2adc3a7efa4f09))
- Minor changes and improvements ([`36c596a`](https://github.com/Ziwi01/proveasio/commit/36c596a87464948954bca0f45b81e8af3e9c6ed4))
- Add git-fuzzy installation ([`5e523c3`](https://github.com/Ziwi01/proveasio/commit/5e523c3d68bc98402f3ccbcfbe3b449199fb3ec6))
- Refacotr role names, add code for software installation, add configuration setup ([`b73d1d8`](https://github.com/Ziwi01/proveasio/commit/b73d1d8ae2a1192f6b5940062e7de5971fbcf400))
- Fix workflow ([`c71dcc7`](https://github.com/Ziwi01/proveasio/commit/c71dcc73737a1a9251dcd16155522523dcc7ea8b))
- Refactor ([`ad7872c`](https://github.com/Ziwi01/proveasio/commit/ad7872c612e5b5847250d6abb3e00401f191a464))
- Fix hosts ([`22b6ea4`](https://github.com/Ziwi01/proveasio/commit/22b6ea4e782e5ba89dc96a6658d01268ae3878f7))
- Change working directory for ansible playbook ([`2cf361b`](https://github.com/Ziwi01/proveasio/commit/2cf361b1bfdffbc7a215dd8e4c8093cdb4552fc3))
- Various updates ([`2355c55`](https://github.com/Ziwi01/proveasio/commit/2355c55ab307ab75ab0e66f9eda8db5965389582))
- Add ansible initial structure, basic tasks. Update environment files. ([`a6155d8`](https://github.com/Ziwi01/proveasio/commit/a6155d887ceb35cd602f2dee21076648831677fe))
- GPG sign test ([`f0b4386`](https://github.com/Ziwi01/proveasio/commit/f0b438688b2a421097e4a273c3b3753b64157a69))
- Test ssh/gpg keys ([`31db8d5`](https://github.com/Ziwi01/proveasio/commit/31db8d538a5583f817424107e30e361e0b6c198d))
- Minor refactor. Add dotfiles and VIM config, update tmux.conf and vimrc ([`d131ff3`](https://github.com/Ziwi01/proveasio/commit/d131ff306d36ebd12aadc64e9ce57f83ac830f19))
- Fix conflicts ([`c880e7d`](https://github.com/Ziwi01/proveasio/commit/c880e7d8e0496b4ca23bf7edcaba44d54b28e1e6))
- Add Windows Terminal settings ([`18c6c04`](https://github.com/Ziwi01/proveasio/commit/18c6c04edc0d3c4ed35738aedb13f36e51c822fd))
- Start refactoring ide.vim only into environment init repository with automated setup ([`115262d`](https://github.com/Ziwi01/proveasio/commit/115262d421864fc08633d2feebd7201e0a8c0eda))
- Create hw.yml ([`dbd96d6`](https://github.com/Ziwi01/proveasio/commit/dbd96d6d2d9549ea4da59d529f769d3231258c4c))
- Add config files ([`82b5cf0`](https://github.com/Ziwi01/proveasio/commit/82b5cf041a488367298dba56e43cf465a19c88f0))
- Add plugins, change colorscheme ([`a603261`](https://github.com/Ziwi01/proveasio/commit/a603261474ed0a73df6b4a62b90fed23a8b9277d))
- Add currently used things (puppet/editorconfig etc.) to vimrc ([`e7e2161`](https://github.com/Ziwi01/proveasio/commit/e7e21611d3f131fbaa55f228f09feea07237c965))
- Integrate vim clipboard copy with WSL, minor behavior changes ([`2052ace`](https://github.com/Ziwi01/proveasio/commit/2052acea1108f52dcfa7f58125a702c7d4af8fba))
- Update README ([`9f7002d`](https://github.com/Ziwi01/proveasio/commit/9f7002d7546e5921226eec85c8722ab4ec79d1f5))
- Modify vimrc to suit our needs ([`80da80a`](https://github.com/Ziwi01/proveasio/commit/80da80a423242e0f66fddd49c6ac0cbca254cd2b))
- Disable python and ruby mode by default. ([`dbcf8e1`](https://github.com/Ziwi01/proveasio/commit/dbcf8e1e525b8100ff5e3af937658835afc2b404))
- Add Vundle Windows compability ([`8bc1072`](https://github.com/Ziwi01/proveasio/commit/8bc1072799a01cdd9a1a37fa9c6dd62bef4ee29a))
- Fix global changes per filetype ([`a4819ab`](https://github.com/Ziwi01/proveasio/commit/a4819ab7434da0a6273d27f49ecd3567535dcc4f))
- Enable python and ruby support ([`16b2278`](https://github.com/Ziwi01/proveasio/commit/16b227831fd506bf97a284abef88f29e7561c749))
- Add guifont size ([`33bd99d`](https://github.com/Ziwi01/proveasio/commit/33bd99d0cb400040afc0b530dc9a2ac7d6a70af8))
- Move to GutenTags ([`e915bc8`](https://github.com/Ziwi01/proveasio/commit/e915bc8d5644bfd29efe01e554e2bc085ed73f7f))
- Add support for non-standard file types. Add quickfilx window ([`93553fe`](https://github.com/Ziwi01/proveasio/commit/93553fe4ef52307930f255dbfe655d8b9d88e061))
- Fix ctags for Windows. Add yaml file handling. ([`5b384dc`](https://github.com/Ziwi01/proveasio/commit/5b384dc20d542392b1acd9902d6a092397f2ce44))
- Add support for Windows. ([`9cd5226`](https://github.com/Ziwi01/proveasio/commit/9cd5226514c0e7a0e371b7650c9e1e6df0fe1e14))
- Add color support for GVim ([`2a2533b`](https://github.com/Ziwi01/proveasio/commit/2a2533b87e2c9426b143594c4a417e9418190a8b))
- Move to netrw ([`99434c2`](https://github.com/Ziwi01/proveasio/commit/99434c25c76120b22f54b06fd63ebec9eeb902d1))
- VIM Imporvements. Colors for vim-tasks ([`3b468b5`](https://github.com/Ziwi01/proveasio/commit/3b468b5277cdfdeef4255e05d1bd3b6b5db19d02))
- Add tpope unimaired ([`d3c7f30`](https://github.com/Ziwi01/proveasio/commit/d3c7f309361b9db6e4f08751cdbc6c723944e71c))
- Move to VIM 8.0. Remove unused plugins. Replace Syntastic with Ale ([`71b6325`](https://github.com/Ziwi01/proveasio/commit/71b632583a9bec79a1f968889399b45d2fec335e))
- Move to rodjek vim-puppet. Add better support for GitGutter. JenkinsFile syntax support. Vim-tasks .todo do not wrap ([`788c216`](https://github.com/Ziwi01/proveasio/commit/788c216b16823d47323fe418e30845521976a535))
- Add gitgutter, xml and gradle support ([`1f4479a`](https://github.com/Ziwi01/proveasio/commit/1f4479adaa19f5e737ee4085141e717e7303372d))
- Add some usefoult options ([`732055b`](https://github.com/Ziwi01/proveasio/commit/732055b4b81104bae959b7fc461eaf18d695faca))
- Bind copy/paste to * buffer and Windows MS Clipboard ([`159702b`](https://github.com/Ziwi01/proveasio/commit/159702b032fd7013f2361f459e9f522a8ecf8440))
- Add Maven support ([`2a31585`](https://github.com/Ziwi01/proveasio/commit/2a3158576bc0ddcbda0f1a9e8af1c54265b3f138))
- Make sure that trailing lines are not highlited ([`bd9bd52`](https://github.com/Ziwi01/proveasio/commit/bd9bd52c6b6859e99d2ca7dbb7a9f45edd99c9e4))
- Add yamllint checker ([`05336e5`](https://github.com/Ziwi01/proveasio/commit/05336e537663bc161fff486b56db27f3b196dd16))
- Switch to voxpupuli ([`4d91a77`](https://github.com/Ziwi01/proveasio/commit/4d91a77c67e0b44969c66fdda5e00ce924806c41))
- Add small support for GUI. Disable Synastic on open since it takes long time with larger files ([`d931086`](https://github.com/Ziwi01/proveasio/commit/d931086d7843a53166aed057d11c557c27de8251))
- Disable conceal to see full links ([`f30f94a`](https://github.com/Ziwi01/proveasio/commit/f30f94a3d5c0c7f01d8f2582bf3d552eb8ad6aa7))
- Add shortcuts for creating multiple tabs ([`e9f7ee4`](https://github.com/Ziwi01/proveasio/commit/e9f7ee48bfb1bde32ce2e992a123273b4fe22dda))
- Move to vim-tasks ([`495d5f2`](https://github.com/Ziwi01/proveasio/commit/495d5f26c0c3cb6f20f0329f21293ef8b86f710f))
- Remove orgmode add simple todo ([`354713e`](https://github.com/Ziwi01/proveasio/commit/354713e36400e7cce5e0bdac019f03010347ebbe))
- Remove vim-orgmode ([`4160caf`](https://github.com/Ziwi01/proveasio/commit/4160cafbdd63fd9a9c5637f4b20bb708a2c647ac))
- Add file format to statusline ([`3e9101d`](https://github.com/Ziwi01/proveasio/commit/3e9101debfaf8f3b0f1b7e4d262231696170f94f))
- Add autoread ([`db81413`](https://github.com/Ziwi01/proveasio/commit/db81413ef074769251bf1645f246b927340cfe0e))
- Set auto line wrapping to 140 ([`955749a`](https://github.com/Ziwi01/proveasio/commit/955749af47013f7a74f4e3799c8486660c19f344))
- Improve todo.org ([`ace71e4`](https://github.com/Ziwi01/proveasio/commit/ace71e46c518405e68a4b65f16d6f43af38fce16))
- Fix path for vimrc ([`8832afb`](https://github.com/Ziwi01/proveasio/commit/8832afbf81a8d43478a4a6653f3052f1f5ed8c4a))
- Update readme ([`ef56c3a`](https://github.com/Ziwi01/proveasio/commit/ef56c3a838201d36e2c10af1127dfd7371714e09))
- Make ide.vim primary module ([`e8e63d4`](https://github.com/Ziwi01/proveasio/commit/e8e63d417a3db3cc4fd44bfbb7cd32067f4272e0))
- Moved from bugi.vim project ([`2f9ab5d`](https://github.com/Ziwi01/proveasio/commit/2f9ab5daeb2925f92f2a0afc00708838478870e5))

