-- TetraVim Contextual Project Knowledge Base -- Kiro-style persistent
-- project context layer.
--
-- No vector/embedding index -- for a single-repo, file-scale corpus, a plain
-- markdown concatenation resolved fresh on every reference is simpler,
-- requires no extra dependency, and stays in sync with zero index-rebuild
-- step (repo convention: no infrastructure ahead of actual need). `.context/`
-- lives in the CURRENT PROJECT (the one open in Neovim), never inside this
-- distro's own repo -- it is per-project ground truth the agent must read
-- before proposing specs or code, analogous to `.specs/` in
-- TetraVim.util.ai.spec.*.

local M = {}

local DIR = ".context"

--- Concatenate every .context/*.md file into one context blob, each section
--- tagged with its filename so the model can cite which doc a claim came
--- from. Returns nil when the directory doesn't exist or is empty.
---@return string|nil
function M.build()
  if vim.fn.isdirectory(DIR) ~= 1 then
    return nil
  end
  local parts = {}
  for _, path in ipairs(vim.fn.glob(DIR .. "/*.md", true, true)) do
    table.insert(
      parts,
      ("## %s\n\n%s"):format(vim.fn.fnamemodify(path, ":t"), table.concat(vim.fn.readfile(path), "\n"))
    )
  end
  if #parts == 0 then
    return nil
  end
  return table.concat(parts, "\n\n---\n\n")
end

--- codecompanion `variables` entry -- resolved fresh on every `#context`
--- reference in a chat message, so edits to .context/*.md take effect
--- without a Neovim restart.
---@return table
function M.codecompanion_variable()
  return {
    ["context"] = {
      callback = function()
        return M.build() or "(no .context/ files yet in this project -- run <leader>ikx to seed one)"
      end,
      description = "Project context: architecture, conventions, domain, tech stack",
    },
  }
end

--- One-time seed: create empty, clearly-marked stub files under .context/ in
--- the current project so there is a starting point instead of nothing.
--- Never overwrites a file that already exists.
function M.seed()
  local ui = require("TetraVim.util.ui")
  vim.fn.mkdir(DIR, "p")
  local stub = "<!-- Seeded %s -- edit freely, this is ground truth for the agent. -->\n"
  local created = {}
  for _, name in ipairs({ "architecture", "conventions", "domain", "tech-stack" }) do
    local path = DIR .. "/" .. name .. ".md"
    if vim.fn.filereadable(path) ~= 1 then
      vim.fn.writefile(vim.split(stub:format(name), "\n"), path)
      table.insert(created, path)
    end
  end
  if #created == 0 then
    ui.notify_info(".context/ already seeded -- nothing to do", "TetraVim Context")
  else
    ui.notify_info("Seeded: " .. table.concat(created, ", "), "TetraVim Context")
  end
end

return M
