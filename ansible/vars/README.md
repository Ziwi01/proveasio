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
  - thefuck # do not install thefuck
config_tasks_exclude:
  - zsh # do not configure Puppet
```

If you are NOT using `systemd` on your WSL distro (see [README.md](./README.md) for details), set below:

```yaml
service_manager: sysvinit
```

For all possibilities, see each role vars file (`ansible/<role>/vars/main.yml`)
