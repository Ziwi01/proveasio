Place an `overrides.yml` file in this directory for overriding anything set in any role.
You can disable overriding particular config file, or set paticular software versions of your choosing or anything else.

Please put at least below (modified accordingly):

```yaml
# .gitconfig info
git:
  name: James
  mail: james.doe@hell.no

# If windows automation is used
win_username: jimmy
```

Also, you can manipulate which tasks from each role does not get executed, putting there:

```yaml
software_tasks_exclude:
  - azurecli # do not install azurecli
config_tasks_exclude:
  - zsh # do not configure zsh
```

If you are NOT using `systemd` on your WSL distro (see [README.md](./README.md) for details), set below:

```yaml
service_manager: sysvinit
```

To avoid GitHub API rate limits when resolving `latest` versions (60 req/hour unauthenticated, 5000 when authenticated), you can provide a token here. Alternatively set `GITHUB_TOKEN`/`GH_TOKEN` in your environment, or just run `gh auth login` once (all are auto-detected):

```yaml
github_api_token: ghp_xxx
```

For all possibilities, see each role vars file (`ansible/<role>/vars/main.yml`)
