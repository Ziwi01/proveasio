local util = require "lspconfig/util"
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "terraformls", "tflint" })

local tflint_opts = {
  root_dir = util.root_pattern(".*")
}
local terraformls_opts = {
  root_dir = util.root_pattern(".*")
}

require("lvim.lsp.manager").setup("tflint", tflint_opts)
require("lvim.lsp.manager").setup("terraformls", terraformls_opts)
