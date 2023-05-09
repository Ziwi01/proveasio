local M = {}
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

M.ruby = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "~ Run tests in Vimux ~",
    finder = finders.new_table {
      results = {
        { "Ruby: bundle exec rake parallel_spec", "pspec" },
        { "Ruby: rspec current file", "rspec" },
      },
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1],
          ordinal = entry[1],
          cmd = entry[2]
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local switch = {
            pspec = function()    -- for case 1
                return ":call VimuxRunCommand(\"bundle exec rake parallel_spec\")"
            end,
            rspec = function()    -- for case 2
                return ":call VimuxRunCommand(\"clear; rspec \" . bufname(\"%\"))"
            end,
        }
        local command = switch[selection['cmd']]()
        vim.cmd(command)
      end)
      return true
    end,
  }):find()
end

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

lvim.builtin.telescope.pickers.live_grep = {
  theme = "dropdown",
}

lvim.builtin.telescope.pickers.grep_string = {
  theme = "dropdown",
}

lvim.builtin.telescope.pickers.find_files = {
  theme = "dropdown",
  previewer = false,
}

lvim.builtin.telescope.pickers.buffers = {
  theme = "dropdown",
  previewer = false,
  initial_mode = "normal",
}

lvim.builtin.telescope.pickers.planets = {
  show_pluto = true,
  show_moon = true,
}

lvim.builtin.telescope.pickers.colorscheme = {
  enable_preview = true,
}

lvim.builtin.telescope.pickers.lsp_references = {
  theme = "dropdown",
  initial_mode = "normal",
}

lvim.builtin.telescope.pickers.lsp_definitions = {
  theme = "dropdown",
  initial_mode = "normal",
}

lvim.builtin.telescope.pickers.lsp_declarations = {
  theme = "dropdown",
  initial_mode = "normal",
}

lvim.builtin.telescope.pickers.lsp_implementations = {
  theme = "dropdown",
  initial_mode = "normal",
}

return M
