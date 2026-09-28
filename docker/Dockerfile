# syntax=docker/dockerfile:1

# Proveasio developer workstation image.
# Build from the repository root with `docker buildx bake` (docker-bake.hcl).
# The playbook runs at build time. The `final` stage exists only when
# docker/test.sh passed in the `test` stage. The `update` target of
# docker-bake.hcl builds the `update` stage on an existing image instead of
# `build`.

ARG UBUNTU_VERSION=24.04
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
# The `update` target sets PROVISIONED=update, so the test, receipt and final
# stages start from the `update` stage, which builds on BASE_IMAGE. Docker
# resolves BASE_IMAGE only when that stage is built.
ARG BASE_IMAGE=proveasio:local
ARG PROVISIONED=build

# Local Neovim config. Empty unless the build passes a named context called
# `nvim-config`, which replaces this stage (Bake does that when NVIM_CONFIG is set).
FROM scratch AS nvim-config

FROM ubuntu:${UBUNTU_VERSION} AS build
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG DEBIAN_FRONTEND=noninteractive
# DISABLE_AUTO_UPDATE turns off oh-my-zsh's update check. Without it, zsh
# asks whether to update once the image is 13 days old, and that prompt
# breaks non-interactive zsh starts such as docker/test.sh. Rebuild the image
# to update oh-my-zsh.
ENV LANG=en_US.UTF-8 \
    TZ=Etc/UTC \
    USER=${USERNAME} \
    DISABLE_AUTO_UPDATE=true
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Root bootstrap: what the minimized base lacks, the locale, and the user.
# Recommends are off for every apt install, including Ansible's apt tasks.
# pkgconf, python3-packaging and bsdextrautils (hexdump, needed by gvm) are
# listed because native Ubuntu gets them only through recommended packages.
RUN <<'EOF'
set -euo pipefail
printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' > /etc/apt/apt.conf.d/99-proveasio
apt-get update
apt-get install -y sudo git python3 python3-apt python3-packaging locales tzdata \
  ca-certificates curl wget pkgconf bsdextrautils
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
locale-gen en_US.UTF-8
if id ubuntu >/dev/null 2>&1; then userdel --remove ubuntu; fi
# A USER_GID that the base image already uses (for example 20) keeps its group.
if ! getent group "${USER_GID}" >/dev/null; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi
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
# docker/profile-<PROFILE>.yml is merged unless PROFILE is "full".
ARG PROFILE=full

# docker/provision.sh renders the overrides, checks the tags, runs the
# playbook, installs Mason tools and treesitter parsers, removes build
# leftovers and warms zsh. docker/ is bind-mounted, so the scripts are not
# part of the image.
RUN --mount=type=bind,source=docker,target=/tmp/proveasio-docker \
    --mount=type=bind,from=nvim-config,target=/tmp/nvim-config \
    --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
    PROVEASIO_IMAGE_BUILD=1 bash /tmp/proveasio-docker/provision.sh

COPY --chown=${USER_UID}:${USER_GID} --chmod=0755 docker/test.sh /home/${USERNAME}/proveasio/docker/test.sh
CMD ["zsh", "-l"]

# Update of an existing Proveasio image: the playbook with ANSIBLE_TAGS on
# top of BASE_IMAGE. docker/provision.sh --update lists the checks. The base
# image's user, ENV, SHELL and CMD carry over.
FROM ${BASE_IMAGE} AS update
ARG USERNAME
ARG USER_UID
ARG USER_GID
# As in `build`: RVM's requirements installer runs sudo apt-get, and sudoers keeps DEBIAN_FRONTEND.
ARG DEBIAN_FRONTEND=noninteractive
COPY --chown=${USER_UID}:${USER_GID} ansible /home/${USERNAME}/proveasio/ansible
ARG REFRESH=manual
ARG ANSIBLE_TAGS=""
ARG ANSIBLE_SKIP_TAGS=""
# Only checked against the base image's profile; the update keeps that one.
ARG PROFILE=""
RUN --mount=type=bind,source=docker,target=/tmp/proveasio-docker \
    --mount=type=bind,from=nvim-config,target=/tmp/nvim-config \
    --mount=type=secret,id=GITHUB_TOKEN,env=GITHUB_TOKEN \
    PROVEASIO_IMAGE_BUILD=1 bash /tmp/proveasio-docker/provision.sh --update
COPY --chown=${USER_UID}:${USER_GID} --chmod=0755 docker/test.sh /home/${USERNAME}/proveasio/docker/test.sh

# `build` for a new image, `update` for an update.
FROM ${PROVISIONED} AS provisioned

FROM provisioned AS test
RUN "$HOME/proveasio/docker/test.sh" | tee "$HOME/proveasio/docker/tests-passed"

# Version receipt for CI. Copies from `provisioned` so that `final` stays the
# last stage and a plain `docker build` produces the image.
FROM scratch AS receipt
ARG USERNAME
COPY --from=provisioned /home/${USERNAME}/proveasio/current-versions.yml /current-versions.yml

FROM provisioned AS final
ARG USERNAME
ARG USER_UID
ARG USER_GID
COPY --from=test --chown=${USER_UID}:${USER_GID} /home/${USERNAME}/proveasio/docker/tests-passed /home/${USERNAME}/proveasio/docker/tests-passed
