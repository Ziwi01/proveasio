-- Debug LSP servers

-- vim.lsp.set_log_level 'debug'
-- require('vim.lsp.log').set_format_func(vim.inspect)

-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  {
    command = "puppet-lint",
    extra_args = { "--fix", "--no-autoloader_layout-check" },
    filetypes = { "puppet" },
  },
}

-- set additional linters
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "flake8", filetypes = { "python" } },
  {
    -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
    command = "shellcheck",
    ---@usage arguments to pass to the formatter
    -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
    extra_args = { "--severity", "warning" },
  },
  {
    command = "codespell",
    ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
    filetypes = { "javascript", "python" },
  },
}

-- Attach LSP for Azure Pipelines for YAML files in .azuredevops directory
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*/.azuredevops/*.yaml",
  callback = function()
    require("lspconfig").azure_pipelines_ls.setup {
      settings = {
          yaml = {
              schemas = {
                  ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
                      "*/.azuredevops/**/*.y*ml",
                  },
              },
          },
      },
    }
  end,
})
