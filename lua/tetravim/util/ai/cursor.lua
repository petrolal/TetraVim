-- TetraVim AI Assistant helpers (avante.nvim front-end -- the "Cursor" group).
--
-- Cursor itself is a separate IDE, not a Neovim plugin; avante.nvim is the
-- closest Neovim-native equivalent to Cursor's inline diff-apply editing UX
-- (as opposed to codecompanion's chat/prompt-library model), so it drives
-- the <leader>iv ("cursor") group. Thin wrappers only -- avante.nvim owns
-- every actual ask/edit/apply call. This module exists so core/keymaps.lua
-- and health/ai.lua's probe share one guarded entry point instead of each
-- pcall-require-ing "avante" directly.

local M = {}

local ui = require("tetravim.util.ui")

---@return boolean
function M.available()
  return package.loaded["avante"] ~= nil or pcall(require, "avante")
end

local function run_cmd(cmd)
  if not M.available() then
    ui.notify_warn("avante.nvim is not loaded yet -- run :AvanteAsk to lazy-load it", "TetraVim AI")
    return
  end
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    ui.notify_err("Avante command failed: " .. tostring(err), "TetraVim AI")
  end
end

function M.toggle()
  run_cmd("AvanteToggle")
end

function M.ask()
  run_cmd("AvanteAsk")
end

--- Edit the current visual selection with a free-form instruction.
function M.edit()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    ui.notify_warn("Select code in visual mode first -- Edit needs a selection", "TetraVim AI")
    return
  end
  run_cmd("'<,'>AvanteEdit")
end

function M.refresh()
  run_cmd("AvanteRefresh")
end

function M.switch_provider()
  run_cmd("AvanteSwitchProvider")
end

return M
