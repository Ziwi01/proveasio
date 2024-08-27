# Own config files

As described in [`config role`](../roles/config) section, there are certain configuration files which are part of this automation. In order to keep your personal configuration in those files, there are two options:

1. (not recommended) Disable particular config file(s) management sections in `ansible/vars/overrides.yml` using `config_tasks_exclude: []`. This will prevent running config for it. For list of sections, see respective `ansible/roles/config/tasks/main.yml`.
2. (**recommended**) I personally suggest to checkout a local branch in this repository (`git checkout -b my-branch`), modify any configuration file(s) in `ansible/roles/config/files` and/or `ansible/roles/config/templates` and commit them. When you want to update changes, just merge release tag (or `master`) to your branch when needed. That way, you can have both your own modifications to the file, and possible upcoming improvements/features which will come with those files. In case of confilcts, you can either choose your own piece of config, or the incoming one, or both.

:::note[Neovim config]
Neovim config (based on AstroNvim) has its own repository. You can fork it and modify for you use, or use your own Neovim config entirely (from your repository). For details see [Neovim usage section](../../usage/vim)
:::
