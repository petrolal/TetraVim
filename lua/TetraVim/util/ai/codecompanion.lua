-- TetraVim AI Assistant helpers (codecompanion.nvim front-end, Claude only).
--
-- Thin wrappers only -- codecompanion.nvim owns every actual chat/inline/
-- agentic call. Drives the Claude group (<leader>ic, the "anthropic"
-- adapter). Gemini has no in-editor group here -- the user drives it via the
-- official `gemini` CLI outside Neovim instead. This module exists so
-- core/keymaps.lua's <leader>ic group and health/ai.lua's probe share one
-- guarded entry point instead of each pcall-require-ing "codecompanion"
-- directly.

local M = {}

local ui = require("TetraVim.util.ui")

local ADAPTER = "anthropic"
local API_KEY_ENV = "ANTHROPIC_API_KEY"

--- Whether codecompanion.nvim has been lazy-loaded yet.
---@return boolean
function M.available()
  return package.loaded["codecompanion"] ~= nil or pcall(require, "codecompanion")
end

--- Whether the anthropic adapter's API key is present in the environment
--- (presence only -- never logged or notified with its value).
---@return boolean
function M.api_key_present()
  local key = os.getenv(API_KEY_ENV)
  return key ~= nil and key ~= ""
end

--- Run a codecompanion ex-command, surfacing a clean notification instead of
--- a raw Lua stack trace when the plugin (or its adapter) isn't ready.
---@param cmd string
local function run_cmd(cmd)
  if not M.api_key_present() then
    ui.notify_warn(
      "$" .. API_KEY_ENV .. " is not set -- the " .. ADAPTER .. " adapter cannot authenticate",
      "TetraVim AI"
    )
    return
  end
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    ui.notify_err("CodeCompanion command failed: " .. tostring(err), "TetraVim AI")
  end
end

function M.toggle_chat()
  run_cmd("CodeCompanionChat Toggle " .. ADAPTER)
end

function M.actions()
  run_cmd("CodeCompanionActions " .. ADAPTER)
end

--- Run one of codecompanion's built-in prompt-library slash commands
--- (`/explain`, `/fix`, `/tests`, ...) over the current visual selection.
---@param slash string e.g. "/explain"
function M.visual_prompt(slash)
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    ui.notify_warn("Select code in visual mode first -- this action needs a selection", "TetraVim AI")
    return
  end
  run_cmd("'<,'>CodeCompanion " .. ADAPTER .. " " .. slash)
end

--- Add the current visual selection to the open (or newly opened) chat
--- buffer as context, rather than running a one-shot prompt against it.
function M.add_selection_to_chat()
  run_cmd("'<,'>CodeCompanionChat Add")
end

--- Free-form inline instruction over the current selection or cursor
--- position (e.g. "add null checks", "convert to a switch expression").
function M.custom_prompt()
  -- Capture visual-vs-normal *before* vim.ui.input runs -- entering the
  -- input's command-line already exits visual mode, so checking
  -- vim.fn.mode() from inside the callback would always see "n".
  local had_selection = vim.fn.mode():match("^[vV\22]") ~= nil
  vim.ui.input({ prompt = "AI instruction (" .. ADAPTER .. "): " }, function(instruction)
    if not instruction or instruction == "" then
      return
    end
    if had_selection then
      run_cmd("'<,'>CodeCompanion " .. ADAPTER .. " " .. instruction)
    else
      run_cmd("CodeCompanion " .. ADAPTER .. " " .. instruction)
    end
  end)
end

--- Generate a commit message from the staged diff (no selection needed).
function M.commit_message()
  run_cmd("CodeCompanion " .. ADAPTER .. " /commit")
end

return M
