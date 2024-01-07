# Neovim with LunarVIM

[LunarVIM](https://github.com/LunarVim/LunarVim) is set as default `EDITOR`, also aliased as `vim` (you can change it in `ansible/roles/config/templates/zshrc.j2`).

For details on how to navigate and power-use this IDE like a boss, see [Neovim usage](../../usage/vim)

Core Neovim plugins, which are installed by LunarVIM, can be found [here](https://www.lunarvim.org/plugins/01-core-plugins-list.html).

Additionally, I setup the plugins below:

- [folke/trouble.nvim](https://github.com/folke/trouble.nvim) - Toggle diagnostic windows and browse through them (`<Space>t` will list options to open)
- [rodjek/vim-puppet](https://github.com/rodjek/vim-puppet) - Puppet syntax support
- [pearofducks/ansible-vim](https://github.com/pearofducks/ansible-vim) - Ansible support
- [nanotee/zoxide.vim](https://github.com/nanotee/zoxide.vim) - Zoxide inside VIM: `:Zi` or `:Z <query>`.For Zoxide descrption see above for Zoxide description
- [will133/vim-dirdiff](https://github.com/will133/vim-dirdiff) - Diff directories. (`:DirDiff <dir1> <dir2>`)
- [plasticboy/vim-markdown](https://github.com/preservim/vim-markdown) - Markdown support
- [Sid0fc/mkdx](https://github.com/SidOfc/mkdx) - Markdown support #2
- [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) - Preview your markdown files in the browser (with dynamic scroll and refresh)
- [godlygeek/tabular](https://github.com/godlygeek/tabular) - easily line up text (like align with equal sign etc.)
- [junegunn/fzf](https://github.com/junegunn/fzf) and [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim) - FZF integration in VIM
- GIT integration plugins:
    - [tpope/fugitive](https://github.com/tpope/vim-fugitive) - Git wrapper, execute any Git command from VIM
    - [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) - Neovim integration with awesome GIT wrapper (LazyGIT). See `software` role description for details.
    - [mhinz/vim-signify](https://github.com/mhinz/vim-signify) - shows GIT info about modified/added/removed lines
    - [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) - great GIT diff plugin for comparing file tree with particular revision(s) or browse file/selection history
    - [f-person/git-blame.nvim](https://github.com/f-person/git-blame.nvim) - show Git blame in-line virtual text.
    - [junegunn/gv](https://github.com/junegunn/gv.vim) - show git commits graph
- [tzachar/cmp-tabnine](https://github.com/tzachar/cmp-tabnine) - AI completion mechanism
- [rmagatti/goto-preview](https://github.com/rmagatti/goto-preview) - do not jump around the definition in new tabs/buffers - show floating preview window and edit it there, close the preview. Being on top of searched function: `gpd` (for definition).
- [itchyny/vim-cursorword](https://github.com/itchyny/vim-cursorword) - underline all the words that the cursor is on right now. Handy for typo spotting.
- [auto-save.nvim](https://github.com/Pocco81/auto-save.nvim) - exactly what the name suggests.
- [tpope/vim-obsession](https://github.com/tpope/vim-obsession) - VIM session manager
- [tpope/vim-surround](https://github.com/tpope/vim-surround) - easily surrond text with brackets, braces, quotes
- [ntpeters/vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace) - automatically trim/prune obsolete whitespace
- [preservim/vimux](https://github.com/preservim/vimux) - integrate neovim with TMUX - run commands in splits easily (@TODO: Add keymappings)
- [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) - integrate movements between TMUX splits and VIM windows/splits
- [towolf/vim-helm](https://github.com/towolf/vim-helm) - Helm files support
- [jvgrootveld/telescope-zoxide](https://github.com/jvgrootveld/telescope-zoxide) - Use Zoxide inside vim
- [kevinhwang91/nvim-bqf](https://github.com/kevinhwang91/nvim-bqf) - much better quickfix window
- [nvim-pack/nvim-spectre](https://github.com/nvim-pack/nvim-spectre) - Search and replace like on other IDEs
- [wincent/ferret](https://github.com/wincent/ferret) - Search and replace for files in your project. To be used if Spectre doesn't work as expected (see LunarVim usage docs for details)
- [roobert/search-replace.nvim](https://github.com/roobert/search-replace.nvim) - Better local search and replace
- [catpuccin/nvim](https://github.com/catppuccin/nvim) - Colorscheme
- [ggandor/leap.nvim](https://github.com/ggandor/leap.nvim) - Jump around the buffer like crazy

:::note
In LunarVIM there is an automatic LSP installer plugin - [lazy.nvim](https://github.com/folke/lazy.nvim) which will install supported language servers and use them, when you open a specific filetype. However, this doesn't work 100% of the time. I add custom configurations for terraform, ansible, markdown and puppet. If you have issues with automatic LSP config/attachment, you can add your own configurations for filetypes in `ansible/roles/config/files/lvim/ftplugin/<filetype>.lua` - all of the files from there will be copied over to LunarVim config. See: [LunarVIM docs](https://www.lunarvim.org/docs/configuration/language-features/language-servers) for details. I will be adding more LSP configs in the future probably.
:::
