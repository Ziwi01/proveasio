vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "ansiblels" })

local ansible_opts = {
  settings = {
    ansibleLint = {
      arguments = 'ansible-lint -c ~/.ansible-lint'
    }
  }
}

require("lvim.lsp.manager").setup("ansiblels", marksman_opts)

