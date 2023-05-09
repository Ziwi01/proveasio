lvim.plugins = {
    -- Diagnostics, references, telescope results, quickfix and location lists
    {
      "folke/trouble.nvim",
      cmd = "TroubleToggle",
    },
    -- Puppet support
    { "rodjek/vim-puppet" },
    -- Ansible syntax highlight
    { "pearofducks/ansible-vim" },
    -- Directory traverse
    { "nanotee/zoxide.vim" },
    -- Diff directories (:DirDiff <dir1> <dir2>)
    { "will133/vim-dirdiff" },
    -- Markdown support
    { "plasticboy/vim-markdown" },
    -- Markdown support #2
    { "SidOfc/mkdx" },
    -- Markdown dynamic preview (`:markdownPreview`)
    { "iamcco/markdown-preview.nvim",
      build = function() vim.fn["mkdp#util#install"]() end
    },
    -- Terraform support
    { "hashivim/vim-terraform" },
    -- Tabularize
    { "godlygeek/tabular" },
    -- Fuzzy finder
    { "junegunn/fzf" },
    { "junegunn/fzf.vim" },
    -- Git graph
    { 'junegunn/gv.vim' },
    -- GIT wrapper (`:G <any_git_command>`)
    { "tpope/vim-fugitive" },
    -- GIT manager in VIM. Awesome. (`:LazyGit`, or <Leader>gg)
    { "kdheepak/lazygit.nvim" },
    -- show git status on particular lines
    { "mhinz/vim-signify" },
    -- Awesome Git diff (":DiffviewOpen <revision>")
    { 'sindrets/diffview.nvim',
      dependencies = 'nvim-lua/plenary.nvim'
    },
    -- show Git Blame info inline virtual text
    {
      "f-person/git-blame.nvim",
      event = "BufRead",
      config = function()
        vim.cmd("highlight default link gitblame SpecialComment")
        vim.g.gitblame_enabled = 0
      end,
    },
    -- Completion
    {
      "tzachar/cmp-tabnine",
      build = "./install.sh",
      dependencies = "hrsh7th/nvim-cmp",
      event = "InsertEnter",
    },
    -- goto Preview
    {
      "rmagatti/goto-preview", -- Edit preview in a floating windows. (`gpd`)
      config = function()
      require('goto-preview').setup {
            width = 120; -- Width of the floating window
            height = 25; -- Height of the floating window
            default_mappings = true; -- Bind default mappings
            debug = false; -- Print debug information
            opacity = nil; -- 0-100 opacity level of the floating window where 100 is fully transparent.
            post_open_hook = nil; -- A function taking two arguments, a buffer and a window to be ran as a hook.
            -- You can use "default_mappings = true" setup option
            -- Or explicitly set keybindings
            -- vim.cmd("nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>")
            -- vim.cmd("nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
            -- vim.cmd("nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>")
        }
      end
    },
    -- Underline cursor under the word
    {
      "itchyny/vim-cursorword",
        event = {"BufEnter", "BufNewFile"},
        config = function()
          vim.api.nvim_command("augroup user_plugin_cursorword")
          vim.api.nvim_command("autocmd!")
          vim.api.nvim_command("autocmd FileType NvimTree,lspsagafinder,dashboard,vista let b:cursorword = 0")
          vim.api.nvim_command("autocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endif")
          vim.api.nvim_command("autocmd InsertEnter * let b:cursorword = 0")
          vim.api.nvim_command("autocmd InsertLeave * let b:cursorword = 1")
          vim.api.nvim_command("augroup END")
          end
    },
    -- Auto save
    {
      "Pocco81/auto-save.nvim",
      config = function()
         require("auto-save").setup {
          -- your config goes here
         }
      end,
    },
    -- Session manager
    { "tpope/vim-obsession" },
    -- Convenient word surrounding
    { "tpope/vim-surround" },
    -- Remove trailing whitespace
    { "ntpeters/vim-better-whitespace" },
    -- Running commands in TMUX split
    { "preservim/vimux" },
    -- Seamless TMUX panes Navigation
    { "christoomey/vim-tmux-navigator" },
    -- HELM support
    { "towolf/vim-helm" },
    -- Zoxide support
    { "jvgrootveld/telescope-zoxide" },
    -- Better quickfix window
    {'kevinhwang91/nvim-bqf', ft = 'qf'},
    -- Spectre search and replace (:Spectre)
    { 'nvim-pack/nvim-spectre' },
    -- Fallback search and replace (:Ack or <leader>a for search, :Acks or <leader>r to substitute)
    { "wincent/ferret" },
    -- Improve local search and replace
    { "roobert/search-replace.nvim",
      config = function()
        require("search-replace").setup({
          -- optionally override defaults
          -- default_replace_single_buffer_options = "gcI",
          -- default_replace_multi_buffer_options = "egcI",
        })
      end,
    },
    -- Cool colorscheme :)
    { "catppuccin/nvim", name = "catppuccin" },
    -- Motions on steroids
    {
      "ggandor/leap.nvim",
      name = "leap",
      config = function()
        require("leap").add_default_mappings()
      end,
    },
}
