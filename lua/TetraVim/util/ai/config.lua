-- TetraVim AI Assistant settings -- persisted, user-editable at runtime.
--
-- Claude/Copilot/Cursor(avante) are each wired up as their own lazy.nvim
-- spec, gated by `is_enabled(tool)` here, so a disabled tool never gets
-- installed/loaded. Gemini has no such spec -- it shells out to the official
-- `gemini` CLI instead (TetraVim.util.ai.gemini) -- but is still listed here
-- so its <leader>ig* keymaps can be hidden the same way via `<leader>is`.
-- Settings are stored as one JSON file under
-- stdpath("data") so `<leader>is` (the settings picker in core/keymaps.lua)
-- can flip them without editing Lua. Toggling `enabled` only takes effect for
-- lazy.nvim's own spec `enabled = function` on the *next* `:Lazy reload` /
-- restart -- lazy.nvim resolves that field once when it builds the plugin
-- list, not on every keypress.

local M = {}

local ui = require("TetraVim.util.ui")

local PATH = vim.fs.joinpath(vim.fn.stdpath("data"), "TetraVim", "ai.json")

local DEFAULTS = {
  enabled = {
    claude = true,
    gemini = true,
    copilot = true,
  },
  default_provider = "claude",
  models = {
    claude = "claude-sonnet-5",
  },
}

local TOOL_NAMES = { "claude", "gemini", "copilot" }

local cache = nil

local function read_file()
  local fd = io.open(PATH, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  if not content or content == "" then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return nil
  end
  return decoded
end

--- Deep-merge `overrides` onto `defaults`, returning a fresh table.
local function merge(defaults, overrides)
  local result = vim.deepcopy(defaults)
  if type(overrides) ~= "table" then
    return result
  end
  for k, v in pairs(overrides) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

--- Load settings (cached after first read this session).
---@return table
function M.get()
  if not cache then
    cache = merge(DEFAULTS, read_file())
  end
  return cache
end

--- Persist the current in-memory settings to disk.
function M.save()
  if not cache then
    return
  end
  vim.fn.mkdir(vim.fs.dirname(PATH), "p")
  local fd = io.open(PATH, "w")
  if not fd then
    ui.notify_err("Could not write AI settings to " .. PATH, "TetraVim AI")
    return
  end
  fd:write(vim.json.encode(cache))
  fd:close()
end

---@param tool string one of "claude" | "gemini" | "copilot" | "cursor"
---@return boolean
function M.is_enabled(tool)
  return M.get().enabled[tool] == true
end

---@param tool string
---@param value boolean
function M.set_enabled(tool, value)
  M.get().enabled[tool] = value
  M.save()
end

---@return string
function M.default_provider()
  return M.get().default_provider
end

---@param tool string
function M.set_default_provider(tool)
  M.get().default_provider = tool
  M.save()
end

---@param tool "claude"
---@return string|nil
function M.model(tool)
  return M.get().models[tool]
end

---@param tool "claude"
---@param model string
function M.set_model(tool, model)
  M.get().models[tool] = model
  M.save()
end

M.TOOL_NAMES = TOOL_NAMES

return M
