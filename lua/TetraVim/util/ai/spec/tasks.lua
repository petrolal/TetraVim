-- TetraVim Task-Execution State Machine -- reads .specs/tasks.md, finds the
-- next pending `- [ ]` item, and opens a codecompanion chat pre-loaded with
-- the task-executor skill plus that one task's context (design.md +
-- #context, inlined directly rather than left as `#context` text since this
-- bypasses codecompanion's buffer-typed variable-resolution path). Marking a
-- task done is a separate, deterministic text edit -- never something the
-- LLM does itself, mirroring TetraVim.util.ai.spec.gate's approval toggle.

local M = {}

local TASKS_FILE = ".specs/tasks.md"

--- Find the first unchecked `- [ ]` item in .specs/tasks.md.
---@return {line: integer, text: string}|nil
function M.next_task()
  if vim.fn.filereadable(TASKS_FILE) ~= 1 then
    return nil
  end
  for i, line in ipairs(vim.fn.readfile(TASKS_FILE)) do
    local text = line:match("^%s*%-%s*%[%s%]%s*(.+)$")
    if text then
      return { line = i, text = text }
    end
  end
  return nil
end

--- Open a codecompanion chat seeded with the task-executor skill as the
--- system prompt and the next pending task (plus design.md/#context) as the
--- first user message. Read-only with respect to tasks.md -- marking the
--- item done is a separate action (M.mark_done).
function M.run_next()
  local ui = require("TetraVim.util.ui")
  local task = M.next_task()
  if not task then
    if vim.fn.filereadable(TASKS_FILE) ~= 1 then
      ui.notify_warn(TASKS_FILE .. " not found -- run task-planner first (<leader>ikp)", "TetraVim Spec")
    else
      ui.notify_info("No pending tasks -- .specs/tasks.md is fully checked off", "TetraVim Spec")
    end
    return
  end

  local skill = require("TetraVim.util.ai.skills").load()["task-executor"]
  if not skill then
    ui.notify_warn("task-executor skill not found", "TetraVim Spec")
    return
  end

  local parts = { "# Task\n\n" .. task.text }

  if vim.fn.filereadable(".specs/design.md") == 1 then
    table.insert(parts, "# design.md\n\n" .. table.concat(vim.fn.readfile(".specs/design.md"), "\n"))
  end

  local context = require("TetraVim.util.ai.context").build()
  if context then
    table.insert(parts, "# Project Context\n\n" .. context)
  end

  require("codecompanion").chat({
    messages = {
      { role = "system", content = skill.body },
      { role = "user", content = table.concat(parts, "\n\n---\n\n") },
    },
    auto_submit = false,
  })
end

--- Ground the task-executor's self-reported PASS/FAIL in a real command run
--- instead of trusting the chat transcript alone: hands off to overseer's
--- own TEST-tagged template detection (mvn/gradle/npm test/etc -- whatever
--- overseer already resolves for this project, not re-detected here),
--- captures the real output, and opens a fresh chat asking task-executor to
--- reconcile its report against that output before the human runs
--- <leader>ikd.
function M.verify()
  local ui = require("TetraVim.util.ui")
  local task = M.next_task()
  if not task then
    ui.notify_warn("No pending task to verify", "TetraVim Spec")
    return
  end

  local ok, overseer = pcall(require, "overseer")
  if not ok then
    ui.notify_warn("overseer.nvim not available -- cannot run a real verification command", "TetraVim Spec")
    return
  end

  overseer.run_task({ tags = { overseer.TAG.TEST } }, function(ovr_task, err)
    if err then
      ui.notify_warn("Verification task failed to start: " .. err, "TetraVim Spec")
      return
    end
    if not ovr_task then
      ui.notify_info("Verification canceled", "TetraVim Spec")
      return
    end

    ovr_task:subscribe("on_complete", function(t, status)
      local read_ok, lines = pcall(vim.api.nvim_buf_get_lines, t:get_bufnr(), 0, -1, false)
      local output = read_ok and table.concat(lines, "\n") or "(output unavailable)"
      local verdict = status == overseer.STATUS.SUCCESS and "SUCCESS" or tostring(status)

      local skill = require("TetraVim.util.ai.skills").load()["task-executor"]
      local body = table.concat({
        "# Task",
        "",
        task.text,
        "",
        "# Real Verification Run",
        "",
        "Command status: " .. verdict,
        "",
        "```",
        output,
        "```",
        "",
        "Reconcile this real output against your PASS/FAIL report for this task.",
      }, "\n")

      require("codecompanion").chat({
        messages = {
          { role = "system", content = skill and skill.body or "" },
          { role = "user", content = body },
        },
        auto_submit = false,
      })
    end)
  end)
end

--- Deterministically flip the first unchecked task in .specs/tasks.md to
--- `- [x]`. Never called by the LLM -- the human runs this only after
--- reviewing a task-executor PASS report.
function M.mark_done()
  local ui = require("TetraVim.util.ui")
  local task = M.next_task()
  if not task then
    ui.notify_warn("No pending task to mark done", "TetraVim Spec")
    return
  end

  local lines = vim.fn.readfile(TASKS_FILE)
  lines[task.line] = lines[task.line]:gsub("%[%s%]", "[x]", 1)
  vim.fn.writefile(lines, TASKS_FILE)
  ui.notify_info("Marked done: " .. task.text, "TetraVim Spec")
end

return M
