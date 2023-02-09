-- general
lvim.log.level = "warn"
lvim.format_on_save = false
lvim.colorscheme = "catppuccin-mocha"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "ruby",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

-- generic LSP settings

-- ---@usage disable automatic installation of servers
-- lvim.lsp.automatic_servers_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "ansiblels", "puppet" }, 1, 1) -- Manually configure Ansible/Puppet Language Servers
local puppet_opts = {
  cmd = {
    vim.env.HOME .. "/.rvm/rubies/default/bin/ruby",
    vim.env.HOME .. "/.lsp/puppet-editor-services/puppet-languageserver",
    "--stdio",
    "--puppet-settings=--modulepath," .. vim.env.HOME .. "/projects/puppet", -- set this to the director(y/ies) you keep puppet modules
  }
}
local ansible_opts = {
  settings = {
    ansibleLint = {
      arguments = 'ansible-lint -c ~/.ansible-lint'
    }
  }
}
require("lvim.lsp.manager").setup("puppet", puppet_opts)
require("lvim.lsp.manager").setup("ansiblels", ansible_opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skiipped for the current filetype
-- vim.tbl_map(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  {
    command = "puppet-lint",
    extra_args = { "--fix", "--no-autoloader_layout-check" },
    filetypes = { "puppet" },
  },
  -- {
  --   -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
  --   command = "prettier",
  --   ---@usage arguments to pass to the formatter
  --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
  --   extra_args = { "--print-with", "100" },
  --   ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
  --   filetypes = { "typescript", "typescriptreact" },
  -- },
}

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "shellcheck",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--severity", "warning" },
--   },
--   {
--     command = "codespell",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "javascript", "python" },
--   },
-- }

-- Additional Plugins
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
    -- Markdown dynamic preview (`:markdownPreview`)
    { "iamcco/markdown-preview.nvim",
      run = function() vim.fn["mkdp#util#install"]() end
    },
    -- Tabularize
    { "godlygeek/tabular" },
    -- Fuzzy finder
    { "junegunn/fzf" },
    { "junegunn/fzf.vim" },
    -- GIT integration
    { "tpope/vim-fugitive" }, -- GIT wrapper (`:G <any_git_command>`)
    { "kdheepak/lazygit.nvim" }, -- GIT manager in VIM. Awesome. (`:LazyGit`, or <Leader>gg)
    { "mhinz/vim-signify" }, -- show git status on particular lines
    { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }, -- Awesome Git diff (":DiffviewOpen <revision>")
    {
      "f-person/git-blame.nvim", -- show Git Blame info inline virtual text
      event = "BufRead",
      config = function()
        vim.cmd "highlight default link gitblame SpecialComment"
        vim.g.gitblame_enabled = 0
      end,
    },
    -- Completion
    {
      "tzachar/cmp-tabnine",
      run = "./install.sh",
      requires = "hrsh7th/nvim-cmp",
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
    { 'windwp/nvim-spectre' },
    -- Fallback search and replace (:Ack or <leader>a for search, :Acks or <leader>r to substitute)
    { "wincent/ferret" },
    -- Cool colorscheme :)
    { "catppuccin/nvim", name = "catppuccin" },
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "zsh",
  callback = function()
    -- let treesitter use bash highlight for zsh files as well
    require("nvim-treesitter.highlight").attach(0, "bash")
  end,
})
-- vim.api.nvim_create_autocmd("BufRead", {
--   -- Force `yaml.ansible` filetype in ansible projects directory.
--   pattern = { vim.env.HOME .. "/projects/ansible/*.yml", vim.env.HOME .. "/projects/ansible/*.yaml" },
--   command = "set ft=yaml.ansible",
-- })

-- Do not show Git Blame inline for NvimTree
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if (vim.bo.filetype == 'NvimTree')
    then
      vim.g.gitblame_display_virtual_text = 0
    else
      vim.g.gitblame_display_virtual_text = 1
    end
  end,
})

-- Windows clipboard support
vim.opt.clipboard = "unnamedplus"

-- Do not fold Markdown files
vim.g.vim_markdown_folding_disabled = 1

-- Enable transparency
-- lvim.transparent_window = true

-- <S-h> and <S-l> for buffer previous/next
vim.api.nvim_set_keymap('n', '<S-h>', ':bprevious<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-l>', ':bnext<CR>', { noremap = true, silent = true })

-- Keep the original clipboard buffer after pasting something with `p`
vim.api.nvim_set_keymap('v', 'p', '"_dP', { noremap = true, silent = true })

-- Trouble Toggle
lvim.builtin.which_key.mappings["t"] = {
  name = "Diagnostics",
  t = { "<cmd>TroubleToggle<cr>", "trouble" },
  w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "workspace" },
  d = { "<cmd>TroubleToggle document_diagnostics<cr>", "document" },
  q = { "<cmd>TroubleToggle quickfix<cr>", "quickfix" },
  l = { "<cmd>TroubleToggle loclist<cr>", "loclist" },
  r = { "<cmd>TroubleToggle lsp_references<cr>", "references" },
}

-- Ignore .git/ and node_modules/ in Telescopes find_files <Leader>f
lvim.builtin.telescope.defaults.file_ignore_patterns = { "%.git/", "^node_modules/" }
-- Use fd to "find files" and return absolute paths
lvim.builtin.telescope.defaults = {
	find_command = { "fd", "-t=f", "-a" },
	path_display = { "absolute" },
  wrap_results = true
}

-- Strip Whitespace on save
vim.g.strip_whitespace_on_save = 1
vim.g.strip_whitespace_confirm = 0

-- Wrap long lines
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.list = false

-- TMUX panes / VIM splits navigation config (Alt+Arrows)
vim.g.tmux_navigator_no_mappings = 1
lvim.keys.normal_mode["<A-Left>"] = ":TmuxNavigateLeft<cr>"
lvim.keys.normal_mode["<A-Right>"] = ":TmuxNavigateRight<cr>"
lvim.keys.normal_mode["<A-Up>"] = ":TmuxNavigateUp<cr>"
lvim.keys.normal_mode["<A-Down>"] = ":TmuxNavigateDown<cr>"
