---
sidebar_position: 1
slug: /
title: About
hide_title: true
hide_table_of_contents: true
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
import {Hero, FeatureGrid} from '@site/src/components/Landing';

<Hero />

<FeatureGrid />

## Quick start

<Tabs groupId="install">
<TabItem value="native" label="Ubuntu / WSL2" default>

```shell
git clone https://github.com/Ziwi01/proveasio.git ~/proveasio
sudo ~/proveasio/prepare-ubuntu.sh
# close and reopen the terminal, then:
cd ~/proveasio/ansible && ansible-playbook -i inventory.yml setup-ubuntu.yml -K
```

Before the first run, set your git identity and read the [requirements](./requirements.md). The full steps are in [Installation](./installation.md).

</TabItem>
<TabItem value="docker" label="Docker image">

```shell
git clone https://github.com/Ziwi01/proveasio.git && cd proveasio
USER_UID=$(id -u) USER_GID=$(id -g) docker buildx bake
docker run -it --rm -v "$PWD":/workspace -w /workspace proveasio:local
```

See [Build the image](./docker/10-build.md) and [Run the image](./docker/30-run.md).

</TabItem>
</Tabs>

Proveasio supports **Ubuntu 24.04** and **Ubuntu 26.04**, natively or on WSL2. See [Requirements](./requirements.md#supported-systems).

## Why Proveasio

The project aims to:

- set up a new machine the same way every time, mainly for automation work (DevOps, system administration), but also for general development.
- be safe to run again: each run updates the tools and configuration to their latest versions, or keeps the versions you pinned.
- be easy to extend and configure for your own needs.
- document every feature and usage, so that someone new to these tools can learn them, and someone experienced can pick up ideas for their workflow.

The [usage scenarios](../usage/10-about.md) also make the project a learning resource: they show workflows and tools that would otherwise take a while to discover on your own.

:::note

Proveasio is an opinionated set of tools that I use every day. Tailor it to your needs. Every tool is listed and described, together with any custom changes. Ideas, features and fixes are welcome as pull requests, see [Contributing](https://github.com/Ziwi01/proveasio#contributing).

Read this documentation before you run the playbook on an existing system, and look through the tasks to see what they change.

:::
