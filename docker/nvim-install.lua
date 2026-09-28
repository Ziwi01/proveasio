-- Install the Mason tools and treesitter parsers of a Neovim config, and wait
-- for them to finish. docker/Dockerfile runs it in the playbook step with
-- `dofile` inside `pcall`, so a missing file or a load error also fails:
--   NVIM_APPNAME=<app> nvim --headless -c 'lua ... pcall(dofile, ...) ...' -c qa
-- Configs start these installs in the background, so a plain headless start
-- exits before they finish. Each part is skipped when the config does not use
-- the plugin. A failed package or parser is reported, not fatal; a timeout or
-- an error exits with status 1.
local deadline -- set in the pcall at the end of the file

local function log(msg)
  -- Neovim's own messages do not end in a newline.
  io.stderr:write("\nnvim-install: " .. msg .. "\n")
end

local function time_left()
  return math.max(deadline - vim.uv.now(), 1)
end

local function mason()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return
  end
  local started, failed = false, {}
  registry:on("package:install:handle", function()
    started = true
  end)
  registry:on("package:install:failed", function(pkg)
    table.insert(failed, pkg.name)
  end)
  -- MasonToolsInstallSync never returns when ensure_installed lists a package
  -- twice (AstroNvim merges the lists of several packs, so it does). Start the
  -- async command instead and wait until no package is installing.
  if vim.fn.exists(":MasonToolsInstall") == 2 then
    vim.api.nvim_create_autocmd("User", {
      pattern = { "MasonToolsStartingInstall", "MasonToolsUpdateCompleted" },
      callback = function()
        started = true
      end,
    })
    vim.cmd("MasonToolsInstall")
    -- Installs start after a registry refresh; none start when nothing is missing.
    vim.wait(120000, function()
      return started
    end, 500)
  end
  local function idle()
    for _, pkg in ipairs(registry.get_all_packages()) do
      if pkg:is_installing() then
        return false
      end
    end
    return true
  end
  if not vim.wait(time_left(), idle, 500) then
    error("Mason installs did not finish in time")
  end
  log(("mason: %d packages installed%s"):format(
    #registry.get_installed_package_names(),
    #failed > 0 and (", failed: " .. table.concat(failed, " ")) or ""
  ))
end

local function treesitter()
  -- nvim-treesitter `master` branch.
  if vim.fn.exists(":TSUpdateSync") == 2 then
    vim.cmd("TSUpdateSync")
    return
  end
  -- The `main` branch has no sync command. install() also waits for languages
  -- that are already installing. The language list is read from AstroNvim.
  local ok, ts = pcall(require, "nvim-treesitter")
  local langs = vim.tbl_get(package.loaded, "astrocore", "config", "treesitter", "ensure_installed")
  if not ok or type(ts.install) ~= "function" or not langs or vim.fn.executable("tree-sitter") ~= 1 then
    return
  end
  local all = ts.install(langs, { summary = true }):wait(time_left())
  log("treesitter: " .. (all and "all parsers installed" or "some parsers failed, see :TSLog"))
end

local ok, err = pcall(function()
  deadline = vim.uv.now() + 25 * 60 * 1000
  mason()
  treesitter()
end)
if not ok then
  log("error: " .. tostring(err))
  vim.cmd("cquit 1")
end
