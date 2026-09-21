-- TetraVim Agent Hooks -- Kiro-style event-triggered automation.
--
-- A hook is a `.hooks/*.md` file in the CURRENT PROJECT (same convention as
-- `.context/*.md` steering docs and project `skills/*.md`): frontmatter
-- declares which editor event fires it and which files it watches, the body
-- is the system prompt handed to codecompanion. Unlike task-executor's
-- MCP-backed tool calls, a hook only ever OPENS a chat with
-- `auto_submit = false` -- an autocmd firing an LLM call unattended is
-- already a blast-radius jump versus a keymap; having it also
-- auto-submit-and-let-MCP-edit-files unattended would be a second one this
-- module deliberately does not take. The human still reviews and presses
-- enter, exactly like TetraVim.util.ai.spec.tasks.run_next.
--
-- Only a small, editor-observable event allowlist is supported (see
-- ALLOWED_EVENTS) -- arbitrary vim events (e.g. CursorMoved) would let a
-- misconfigured hook spam LLM calls continuously.

local M = {}

local DIR = ".hooks"

local ALLOWED_EVENTS = {
  BufWritePost = true,
  BufNewFile = true,
  BufAdd = true,
}

-- Same {frontmatter, body} shape as TetraVim.util.ai.skills' parser, plus
-- hook-specific fields (trigger/pattern/enabled) read out of frontmatter.
---@param path string
---@return table|nil
local function parse(path)
  local lines = vim.fn.readfile(path)
  if lines[1] ~= "---" then
    return nil
  end
  local fm_end
  for i = 2, #lines do
    if lines[i] == "---" then
      fm_end = i
      break
    end
  end
  if not fm_end then
    return nil
  end

  local fm = {}
  for i = 2, fm_end - 1 do
    local k, v = lines[i]:match("^(%S+):%s*(.*)$")
    if k then
      fm[k] = v
    end
  end
  local body = table.concat(vim.list_slice(lines, fm_end + 1), "\n")
  return {
    path = path,
    name = fm.name,
    description = fm.description,
    trigger = fm.trigger,
    pattern = fm.pattern,
    enabled = fm.enabled ~= "false",
    body = vim.trim(body),
  }
end

--- Load every `.hooks/*.md` file in the current project.
---@return table[] hooks with an unknown/unsupported `trigger` are dropped
function M.load()
  local hooks = {}
  for _, path in ipairs(vim.fn.glob(DIR .. "/*.md", true, true)) do
    local hook = parse(path)
    if hook and hook.name and ALLOWED_EVENTS[hook.trigger] then
      table.insert(hooks, hook)
    end
  end
  return hooks
end

-- path -> os.time() of its last fire, so a hook whose own chat response
-- gets applied back to the same file (e.g. via MCP in a follow-up) can't
-- retrigger itself in a tight loop.
local last_fired = {}
local DEBOUNCE_SECS = 30

local function fire(hook, bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local now = os.time()
  if last_fired[path] and now - last_fired[path] < DEBOUNCE_SECS then
    return
  end
  last_fired[path] = now

  local ok, codecompanion = pcall(require, "codecompanion")
  if not ok then
    return
  end

  local parts = { "# Changed file: " .. path }
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  table.insert(parts, "```\n" .. content .. "\n```")

  local context = require("TetraVim.util.ai.context").build()
  if context then
    table.insert(parts, "# Project Context\n\n" .. context)
  end

  codecompanion.chat({
    messages = {
      { role = "system", content = hook.body },
      { role = "user", content = table.concat(parts, "\n\n---\n\n") },
    },
    auto_submit = false,
  })
end

local augroup = vim.api.nvim_create_augroup("TetraVim_agent_hooks", { clear = true })

--- (Re)register autocmds for every enabled hook found in `.hooks/` of the
--- current project. Safe to call repeatedly (e.g. on DirChanged) -- clears
--- and rebuilds the augroup each time rather than accumulating duplicates.
function M.setup()
  vim.api.nvim_clear_autocmds({ group = augroup })
  for _, hook in ipairs(M.load()) do
    if hook.enabled then
      vim.api.nvim_create_autocmd(hook.trigger, {
        group = augroup,
        pattern = hook.pattern or "*",
        callback = function(args)
          fire(hook, args.buf)
        end,
        desc = "TetraVim agent hook: " .. hook.name,
      })
    end
  end
end

--- Find the line number of the closing `---` of a file's frontmatter block,
--- so a newly-added `enabled:` field lands inside it rather than the body.
---@param lines string[]
---@return integer|nil
local function fm_end_of(lines)
  if lines[1] ~= "---" then
    return nil
  end
  for i = 2, #lines do
    if lines[i] == "---" then
      return i
    end
  end
  return nil
end

--- vim.ui.select picker: shows every hook found (enabled or not) and toggles
--- `enabled:` in its frontmatter on selection -- a deterministic text edit,
--- mirroring TetraVim.util.ai.spec.gate.toggle_approval, never something an
--- LLM call decides. Re-runs M.setup() afterwards so the change takes
--- effect immediately.
function M.picker()
  local ui = require("TetraVim.util.ui")
  local hooks = M.load()
  if #hooks == 0 then
    M.scaffold()
    return
  end

  local labels = vim.tbl_map(function(h)
    return string.format("%-20s [%s] %s -> %s", h.name, h.enabled and "on" or "off", h.trigger, h.pattern or "*")
  end, hooks)

  vim.ui.select(labels, { prompt = "Toggle agent hook:" }, function(_, idx)
    if not idx then
      return
    end
    local hook = hooks[idx]
    local lines = vim.fn.readfile(hook.path)
    for i, line in ipairs(lines) do
      if line:match("^enabled:") then
        lines[i] = "enabled: " .. tostring(not hook.enabled)
        vim.fn.writefile(lines, hook.path)
        M.setup()
        ui.notify_info(hook.name .. " " .. (hook.enabled and "disabled" or "enabled"), "TetraVim Hooks")
        return
      end
    end
    -- No `enabled:` field present yet (defaults to true) -- add one so the
    -- toggle has something to flip on the next press.
    table.insert(lines, fm_end_of(lines) or #lines, "enabled: false")
    vim.fn.writefile(lines, hook.path)
    M.setup()
    ui.notify_info(hook.name .. " disabled", "TetraVim Hooks")
  end)
end

--- Seed `.hooks/` with one disabled example so there's a concrete starting
--- point instead of an empty directory. Never overwrites an existing file.
function M.scaffold()
  local ui = require("TetraVim.util.ui")
  vim.fn.mkdir(DIR, "p")
  local path = DIR .. "/example-test-reminder.md"
  if vim.fn.filereadable(path) == 1 then
    ui.notify_info(DIR .. "/ already has hooks -- run <leader>ikh again to toggle one", "TetraVim Hooks")
    return
  end
  vim.fn.writefile({
    "---",
    "name: example-test-reminder",
    "description: Suggest an updated test whenever a source file is saved",
    "trigger: BufWritePost",
    "pattern: *.lua",
    "enabled: false",
    "---",
    "You are reviewing a file that was just saved. If it has an associated",
    "test file, check whether the change likely broke or should extend that",
    "test, and say so concisely. Do not edit anything yourself -- only",
    "report what you'd change and let the human decide.",
  }, path)
  ui.notify_info(
    "Seeded " .. path .. " (disabled) -- edit the pattern/prompt, then <leader>ikh to enable",
    "TetraVim Hooks"
  )
end

return M
