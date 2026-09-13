-- TetraVim AI Assistant helpers (copilot.lua front-end).
--
-- Thin wrappers only -- copilot.lua owns the actual ghost-text completion
-- engine and its own `:Copilot` ex-commands. This module exists so
-- core/keymaps.lua's <leader>ip group and health/ai.lua's probe share one
-- guarded entry point instead of each pcall-require-ing "copilot" directly.

local M = {}

local ui = require("tetravim.util.ui")

---@return boolean
function M.available()
  return package.loaded["copilot"] ~= nil or pcall(require, "copilot")
end

local function run_cmd(cmd)
  if not M.available() then
    ui.notify_warn("copilot.lua is not loaded yet -- run :Copilot to lazy-load it", "TetraVim AI")
    return
  end
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    ui.notify_err("Copilot command failed: " .. tostring(err), "TetraVim AI")
  end
end

function M.toggle()
  run_cmd("Copilot toggle")
end

function M.status()
  run_cmd("Copilot status")
end

function M.panel()
  run_cmd("Copilot panel")
end

function M.auth()
  run_cmd("Copilot auth")
end

return M
