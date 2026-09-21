-- TetraVim Agent Skills -- Matt Pocock-style skill pattern: externalized
-- markdown files with a frontmatter IO contract (name/description/
-- inputs/outputs) plus a role/process/constraints body, instead of prompts
-- buried in Lua strings. Skills are git-diffable and human-editable without
-- touching plugin code.
--
-- Two layers, merged by `name` (project wins):
--   * bundled defaults -- shipped with this distro, found via the Neovim
--     runtimepath so they work in any project without per-project setup.
--   * project overrides -- ./skills/*.md in the CURRENT PROJECT, for a repo
--     that wants its own spec-writer/task-planner/task-executor wording
--     (e.g. stricter domain constraints). <leader>iky copies the bundled
--     defaults there as a starting point.
--
-- Read fresh on every call (no caching) so edits to either layer take effect
-- without a Neovim restart -- matches TetraVim.util.ai.context's contract.

local M = {}

local PROJECT_DIR = "skills"
local BUNDLED_GLOB = "lua/TetraVim/util/ai/skills/defaults/*.md"

--- Split a skill .md file into {frontmatter = table, body = string}.
--- Returns nil if the file has no `---`-delimited frontmatter block.
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
  return { path = path, frontmatter = fm, body = vim.trim(body) }
end

--- Load all skills, bundled defaults first then project overrides layered
--- on top by `name`.
---@return table<string, table>
function M.load()
  local skills = {}

  for _, path in ipairs(vim.api.nvim_get_runtime_file(BUNDLED_GLOB, true)) do
    local parsed = parse(path)
    if parsed and parsed.frontmatter.name then
      skills[parsed.frontmatter.name] = parsed
    end
  end

  for _, path in ipairs(vim.fn.glob(PROJECT_DIR .. "/*.md", true, true)) do
    local parsed = parse(path)
    if parsed and parsed.frontmatter.name then
      skills[parsed.frontmatter.name] = parsed
    end
  end

  return skills
end

--- Build one codecompanion prompt_library entry per skill: a chat strategy
--- whose sole system prompt is the skill's role/process/constraints body.
--- Invoke with `:CodeCompanion /<name>` (e.g. `/spec-writer`).
---@return table
function M.prompt_library()
  local entries = {}
  for name, skill in pairs(M.load()) do
    entries["Skill: " .. name] = {
      strategy = "chat",
      description = skill.frontmatter.description,
      opts = { index = 1, is_slash_cmd = true, short_name = name, auto_submit = false },
      prompts = {
        {
          role = "system",
          content = skill.body,
        },
      },
    }
  end
  return entries
end

--- Copy the bundled default skill templates into the current project's
--- ./skills/ directory so they can be edited per-project. Never overwrites
--- a file that already exists there.
function M.eject()
  local ui = require("TetraVim.util.ui")
  vim.fn.mkdir(PROJECT_DIR, "p")
  local copied = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file(BUNDLED_GLOB, true)) do
    local dest = PROJECT_DIR .. "/" .. vim.fn.fnamemodify(path, ":t")
    if vim.fn.filereadable(dest) ~= 1 then
      vim.fn.writefile(vim.fn.readfile(path), dest)
      table.insert(copied, dest)
    end
  end
  if #copied == 0 then
    ui.notify_info("skills/ already has project copies -- nothing to do", "TetraVim Skills")
  else
    ui.notify_info("Copied for editing: " .. table.concat(copied, ", "), "TetraVim Skills")
  end
end

return M
