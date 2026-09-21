-- TetraVim Spec-Driven Development Review Gate.
--
-- Prompt instructions alone ("stop and wait for approval") are soft -- a
-- model can be talked past them. This module makes the approval check
-- deterministic Lua instead: task-planner/task-executor keymaps refuse to
-- fire unless the upstream .specs/*.md file's frontmatter literally reads
-- `status: approved`, and only a human action (<leader>ika, never the LLM)
-- can set that. Mirrors the confirm-before-destructive-action pattern
-- already established in TetraVim.plugins.tools-diffview's confirm_then().

local M = {}

--- Read the `status:` frontmatter field from a spec file's first few lines.
---@param path string
---@return string|nil
local function status_of(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  for _, line in ipairs(vim.fn.readfile(path, "", 5)) do
    local s = line:match("^status:%s*(%S+)$")
    if s then
      return s
    end
  end
  return nil
end

--- Toggle the frontmatter `status:` field of the current buffer between
--- draft/approved. Deterministic text edit -- no LLM involved, so approval
--- can never be granted by anything other than the human at the keyboard.
--- Refuses (with a warning) on any buffer outside .specs/.
function M.toggle_approval()
  local ui = require("TetraVim.util.ui")
  local path = vim.fn.expand("%:p")
  if not path:match("%.specs[/\\]") then
    ui.notify_warn("Not a .specs/ file -- open requirements.md or design.md first", "TetraVim Spec")
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("^status:") then
      local new_status = line:match("approved") and "draft" or "approved"
      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { "status: " .. new_status })
      ui.notify_info("status: " .. new_status, "TetraVim Spec")
      return
    end
  end

  ui.notify_warn("No `status:` frontmatter field found in this file", "TetraVim Spec")
end

--- Refuse (with a warning) unless `path` has `status: approved`.
---@param path string
---@param what string human-readable name of the action being gated, for the message
---@return boolean
function M.require_approved(path, what)
  if status_of(path) ~= "approved" then
    require("TetraVim.util.ui").notify_warn(
      ("%s requires %s to have `status: approved` first (open it and run <leader>ika)"):format(what, path),
      "TetraVim Spec"
    )
    return false
  end
  return true
end

M._status_of = status_of -- exposed for tests only

return M
