-- general
lvim.log.level = "warn"
lvim.format_on_save = false
lvim.colorscheme = "catppuccin-mocha"

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

-- Windows clipboard support
vim.opt.clipboard = "unnamedplus"

-- Do not fold Markdown files
vim.g.vim_markdown_folding_disabled = 1

-- `ge` to follow anchor links
vim.g.vim_markdown_follow_anchor = 1

-- Enable transparency
-- lvim.transparent_window = true

-- Strip Whitespace on save
vim.g.strip_whitespace_on_save = 1
vim.g.strip_whitespace_confirm = 0

-- Wrap long lines
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.list = false

-- show the effects of a search / replace in a live preview window
vim.o.inccommand = "split"
