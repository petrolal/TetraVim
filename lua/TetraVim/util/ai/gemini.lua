-- TetraVim AI Assistant helpers -- Gemini group (<leader>ig), driven by the
-- official `gemini` CLI (https://github.com/google-gemini/gemini-cli), not
-- an in-editor plugin -- Google does not publish one. Same pattern this
-- distro already uses for other CLI-only tools with no dedicated Neovim
-- plugin (TetraVim.util.cloud.docker, .k8s): shell out via
-- TetraVim.util.term, guarded by an `executable()` check, no shell string
-- interpolation of user/selection text (argv lists only).
--
-- `gemini -i "<prompt>"` runs one prompt non-interactively, then drops into
-- the CLI's normal interactive/agentic session so follow-ups work; plain
-- `gemini` opens straight into that session. Auth is whatever the CLI itself
-- is configured with (`$GEMINI_API_KEY` or an interactive Google login) --
-- this module never reads or stores a key itself.

local M = {}

local term = require("TetraVim.util.term")
local ui = require("TetraVim.util.ui")

---@return boolean
function M.available()
  return vim.fn.executable("gemini") == 1
end

local function run(argv)
  if not M.available() then
    ui.notify_warn("`gemini` CLI not found on $PATH -- install it (npm i -g @google/gemini-cli)", "TetraVim AI")
    return
  end
  term.run_term(argv, { title = "Gemini CLI" })
end

--- Open (or focus) an interactive gemini CLI session.
function M.toggle_chat()
  run({ "gemini" })
end

--- Return the current visual selection as a single string (line-exact).
local function visual_selection()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.fn.getline(s[2], e[2])
  if type(lines) == "string" then
    lines = { lines }
  end
  if #lines == 0 then
    return ""
  end
  lines[#lines] = string.sub(lines[#lines], 1, e[3])
  lines[1] = string.sub(lines[1], s[3])
  return table.concat(lines, "\n")
end

--- Run a one-shot instruction over the current visual selection, then drop
--- into the CLI's normal interactive session for follow-ups.
---@param instruction string e.g. "Explain this code"
local function visual_prompt(instruction)
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    ui.notify_warn("Select code in visual mode first -- this action needs a selection", "TetraVim AI")
    return
  end
  local code = visual_selection()
  local ft = vim.bo.filetype
  local prompt = instruction .. ":\n\n```" .. ft .. "\n" .. code .. "\n```"
  run({ "gemini", "-i", prompt })
end

function M.explain()
  visual_prompt("Explain this code")
end

function M.fix()
  visual_prompt("Find and fix bugs in this code")
end

function M.tests()
  visual_prompt("Write tests for this code")
end

--- Free-form instruction over the current selection or the whole buffer.
function M.custom_prompt()
  local had_selection = vim.fn.mode():match("^[vV\22]") ~= nil
  vim.ui.input({ prompt = "Gemini instruction: " }, function(instruction)
    if not instruction or instruction == "" then
      return
    end
    if had_selection then
      visual_prompt(instruction)
    else
      run({ "gemini", "-i", instruction })
    end
  end)
end

--- Generate a commit message from the staged diff (no selection needed).
function M.commit_message()
  if not M.available() then
    ui.notify_warn("`gemini` CLI not found on $PATH -- install it (npm i -g @google/gemini-cli)", "TetraVim AI")
    return
  end
  vim.system({ "git", "diff", "--staged" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or not res.stdout or res.stdout == "" then
        ui.notify_warn("No staged diff to summarize -- `git add` first", "TetraVim AI")
        return
      end
      local prompt = "Write a concise git commit message for this staged diff:\n\n" .. res.stdout
      run({ "gemini", "-i", prompt })
    end)
  end)
end

return M
