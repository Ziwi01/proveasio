vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "marksman" })

local marksman_opts = {}

require("lvim.lsp.manager").setup("marksman", marksman_opts)
