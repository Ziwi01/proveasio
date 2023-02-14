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
  - bat # do not install BAT
dev_tasks_exclude:
  - puppet # do not install Puppet
```

If you are using `systemd` on your WSL distro, set below (default is `sysvinit``):

```yaml
service_manager: systemd
```

For all possibilities, see each role vars file (`ansible/<role>/vars/main.yml`)
