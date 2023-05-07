vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "puppet" })

local puppet_opts = {
  cmd = {
    vim.env.HOME .. "/.rvm/rubies/default/bin/ruby",
    vim.env.HOME .. "/.lsp/puppet-editor-services/puppet-languageserver",
    "--stdio",
    "--puppet-settings=--modulepath," .. vim.env.HOME .. "/projects/puppet", -- set this to the director(y/ies) you keep puppet modules
  }
}

require("lvim.lsp.manager").setup("puppet", marksman_opts)
