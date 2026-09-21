-- Thin wrapper around mini.files.open() -- resolves the path to open from
-- the current buffer, since nvim_buf_get_name() returns the raw buffer name
-- which for non-file buffers (term://, snacks pickers, ...) isn't a real
-- filesystem path mini.files can open.

local M = {}

function M.open()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.fn.filereadable(path) == 0 and vim.fn.isdirectory(path) == 0 then
    path = vim.fn.getcwd()
  end
  require("mini.files").open(path, true)
end

--- Open mini.files rooted at the current project's .specs/ (Kiro-style
--- requirements/design/tasks pipeline -- see TetraVim.util.ai.spec.*).
--- Falls back to seeding an empty .specs/ dir rather than erroring, since a
--- project that hasn't run spec-writer yet just doesn't have one.
function M.open_specs()
  local path = vim.fs.joinpath(vim.fn.getcwd(), ".specs")
  vim.fn.mkdir(path, "p")
  require("mini.files").open(path, true)
end

return M
