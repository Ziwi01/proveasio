# Build definition for the Proveasio Docker image, used by local builds and CI.
#
#   docker buildx bake                          build, test and load proveasio:local
#   PROFILE=slim docker buildx bake             the slim image, loaded as proveasio:slim
#   GITHUB_TOKEN=... docker buildx bake         authenticate GitHub API version lookups
#   REFRESH=dev docker buildx bake              keep the cached playbook layer
#   docker buildx bake image receipt            also write ./out/current-versions.yml
#   ANSIBLE_TAGS=terraform docker buildx bake update
#                                               update tools in proveasio:local in place
#
# `image receipt` builds both targets in one run with one REFRESH timestamp,
# so the receipt matches the image. A separate `docker buildx bake receipt`
# gets a new timestamp and runs the playbook again.
#
# A local Neovim config outside the repository needs read access granted with
# --allow; without it Bake stops with "additional privileges requested":
#   NVIM_CONFIG="$HOME/my-nvim" docker buildx bake --allow fs.read="$HOME/my-nvim"
#
# Every variable can be set from the environment. User docs are in
# docs-web/docs/main/docker/.

# A new value re-runs the playbook, so `latest` versions are resolved again.
variable "REFRESH" {
  default = timestamp()
}
variable "UBUNTU_VERSION" {
  default = "24.04"
}
variable "USERNAME" {
  default = "dev"
}
# Bake cannot run `id`, and bash and zsh do not export UID, so the default
# stays 1000. Pass USER_UID=$(id -u) USER_GID=$(id -g) to match your user.
variable "USER_UID" {
  default = "1000"
}
variable "USER_GID" {
  default = "1000"
}
variable "ANSIBLE_TAGS" {
  default = ""
}
variable "ANSIBLE_SKIP_TAGS" {
  default = ""
}
# docker/profile-<PROFILE>.yml is merged unless PROFILE is "full".
variable "PROFILE" {
  default = "full"
}
# Directory with a local Neovim config. Empty means neovim_config_url is cloned.
variable "NVIM_CONFIG" {
  default = ""
}
# proveasio:local for the full profile, proveasio:<PROFILE> for the others.
variable "IMAGE" {
  default = PROFILE == "full" ? "proveasio:local" : "proveasio:${PROFILE}"
}
# Image the `update` target starts from. Defaults to the image it replaces.
variable "BASE_IMAGE" {
  default = IMAGE
}
# Read from the environment; used to expand `~` in NVIM_CONFIG.
variable "HOME" {
  default = null
}

# CI replaces this target with the tags and labels from docker/metadata-action.
target "docker-metadata-action" {
  tags = [IMAGE]
}

target "_common" {
  context    = "."
  dockerfile = "docker/Dockerfile"
  platforms  = ["linux/amd64"]
  pull       = true
  args = {
    REFRESH           = REFRESH
    UBUNTU_VERSION    = UBUNTU_VERSION
    USERNAME          = USERNAME
    USER_UID          = USER_UID
    USER_GID          = USER_GID
    ANSIBLE_TAGS      = ANSIBLE_TAGS
    ANSIBLE_SKIP_TAGS = ANSIBLE_SKIP_TAGS
    PROFILE           = PROFILE
  }
  contexts = NVIM_CONFIG == "" ? {} : {
    nvim-config = regex_replace(NVIM_CONFIG, "^~", HOME)
  }
  # Optional: without it the version lookups run unauthenticated.
  secret = ["id=GITHUB_TOKEN,env=GITHUB_TOKEN"]
}

target "image" {
  inherits = ["_common", "docker-metadata-action"]
  target   = "final"
  output   = ["type=docker"]
}

target "receipt" {
  inherits = ["_common"]
  target   = "receipt"
  output   = ["type=local,dest=out"]
}

# Runs the playbook with ANSIBLE_TAGS on top of BASE_IMAGE, runs the smoke
# tests and loads the result as IMAGE. pull = false because BASE_IMAGE is
# usually only in the local image store.
target "update" {
  inherits = ["_common", "docker-metadata-action"]
  target   = "final"
  pull     = false
  args = {
    PROVISIONED = "update"
    BASE_IMAGE  = BASE_IMAGE
  }
  output = ["type=docker"]
}

group "default" {
  targets = ["image"]
}
