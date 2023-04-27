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

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.view.width = 45
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
  "terraform",
  "hcl",
  "dockerfile",
  "go",
  "markdown",
  "markdown_inline"
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

-- Debug LSP servers

-- vim.lsp.set_log_level 'debug'
-- require('vim.lsp.log').set_format_func(vim.inspect)

-- generic LSP settings

-- ---@usage disable automatic installation of servers
-- lvim.lsp.automatic_servers_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "ansiblels", "puppet", "marksman", "tflint", "terraformls" }, 1, 1) -- Manually configure some servers

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
local marksman_opts = {}
local tflint_opts = {}
local terraformls_opts = {}

require("lvim.lsp.manager").setup("puppet", puppet_opts)
require("lvim.lsp.manager").setup("ansiblels", ansible_opts)
require("lvim.lsp.manager").setup("marksman", marksman_opts)
require("lvim.lsp.manager").setup("tflint", tflint_opts)
require("lvim.lsp.manager").setup("terraformls", terraformls_opts)

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

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "zsh",
  callback = function()
    -- let treesitter use bash highlight for zsh files as well
    require("nvim-treesitter.highlight").attach(0, "bash")
  end,
})
vim.api.nvim_create_autocmd("BufRead", {
  -- Force `Jenkinsfile` to groovy filetype.
  pattern = { "Jenkinsfile" },
  command = "set ft=groovy",
})

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
-- `ge` to follow anchor links
vim.g.vim_markdown_follow_anchor = 1

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

lvim.builtin.telescope.defaults = {
  file_ignore_patterns = { "%.git/", "^node_modules/" }, -- Ignore .git/ and node_modules/ in Telescopes find_files <Leader>f
	path_display = { "absolute" },
  wrap_results = true,
  layout_config = { -- Set width and height for dropdown (default) config
     width  = 0.8,
     height = 0.2
  },
}

-- Include hidden files when grepping for text
lvim.builtin.telescope.pickers = {
  live_grep = {
      additional_args = function()
          return { '--hidden' }
      end
  },
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

-- Search and replace (roobert/search-replace.nvim)
keymap = lvim.builtin.which_key.mappings
keymap["r"] = { name = "SearchReplaceSingleBuffer" }
keymap["r"]["s"] = { "<CMD>SearchReplaceSingleBufferSelections<CR>", "SearchReplaceSingleBuffer [s]elction list" }
keymap["r"]["o"] = { "<CMD>SearchReplaceSingleBufferOpen<CR>", "[o]pen" }
keymap["r"]["w"] = { "<CMD>SearchReplaceSingleBufferCWord<CR>", "[w]ord" }
keymap["r"]["W"] = { "<CMD>SearchReplaceSingleBufferCWORD<CR>", "[W]ORD" }
keymap["r"]["e"] = { "<CMD>SearchReplaceSingleBufferCExpr<CR>", "[e]xpr" }
keymap["r"]["f"] = { "<CMD>SearchReplaceSingleBufferCFile<CR>", "[f]ile" }
keymap["r"]["b"] = { name = "SearchReplaceMultiBuffer" }
keymap["r"]["b"]["s"] = { "<CMD>SearchReplaceMultiBufferSelections<CR>","SearchReplaceMultiBuffer [s]elction list" }
keymap["r"]["b"]["o"] = { "<CMD>SearchReplaceMultiBufferOpen<CR>", "[o]pen" }
keymap["r"]["b"]["w"] = { "<CMD>SearchReplaceMultiBufferCWord<CR>", "[w]ord" }
keymap["r"]["b"]["W"] = { "<CMD>SearchReplaceMultiBufferCWORD<CR>", "[W]ORD" }
keymap["r"]["b"]["e"] = { "<CMD>SearchReplaceMultiBufferCExpr<CR>", "[e]xpr" }
keymap["r"]["b"]["f"] = { "<CMD>SearchReplaceMultiBufferCFile<CR>", "[f]ile" }

lvim.keys.visual_block_mode["<C-r>"] = [[<CMD>SearchReplaceSingleBufferVisualSelection<CR>]]
lvim.keys.visual_block_mode["<C-s>"] = [[<CMD>SearchReplaceWithinVisualSelection<CR>]]
lvim.keys.visual_block_mode["<C-b>"] = [[<CMD>SearchReplaceWithinVisualSelectionCWord<CR>]]

-- show the effects of a search / replace in a live preview window
vim.o.inccommand = "split"

-- When opening file, place cursor where it was last edited
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
