-- Session restore helper: works around persistence.nvim/mksession not
-- knowing how to serialize the neo-tree explorer (its window holds a
-- `nofile` buffer, not a real file buffer). If the explorer is open when a
-- session is saved, mksession writes its window as a blank `enew` buffer,
-- so restoring a session brings back the layout but not the explorer
-- itself. We record whether the explorer was open in a small marker file
-- (it must survive the process restart between saving and loading a
-- session) and reopen it after load.
--
-- The Snacks dashboard has the exact same problem: its buffer is also
-- `buftype=nofile` (filetype `snacks_dashboard`), not a real file buffer.
-- If a tab/window still shows the dashboard when a session is saved,
-- mksession serializes it as a blank `enew` buffer too, so restoring the
-- session brings back that window/tab as an empty scratch page. Unlike the
-- explorer, the dashboard is just an ephemeral landing screen, so we simply
-- close it before saving instead of trying to reopen it afterwards.
--
-- Beyond Snacks-specific buffers, plain empty scratch windows/tabs (e.g. a
-- stray `:tabnew` or `:enew` left open, or the dashboard's own "New File"
-- action) are just as real a problem: mksession serializes them verbatim,
-- so every future session restore reopens those same blank `[No Name]`
-- pages forever. We close any window/tab showing a truly blank buffer
-- (unnamed, unmodified, empty) before saving so only meaningful windows
-- get persisted.

local M = {}

local function close_dashboard_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_dashboard" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

--- A window counts as "blank" if it shows a normal (buftype == "") buffer
--- that has no name, was never modified, and has no content -- i.e. it's
--- indistinguishable from a fresh `:enew` nobody actually used.
local function is_blank_buf(buf)
  return vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) == ""
    and not vim.bo[buf].modified
    and vim.api.nvim_buf_line_count(buf) <= 1
    and (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == ""
end

local function close_blank_windows()
  -- Never close the last window left; if everything is blank there's
  -- nothing worth saving anyway (persistence.nvim's own `need` check
  -- skips the save in that case).
  local wins = vim.api.nvim_list_wins()
  if #wins <= 1 then
    return
  end
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) and #vim.api.nvim_list_wins() > 1 then
      local buf = vim.api.nvim_win_get_buf(win)
      if is_blank_buf(buf) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

local function marker_path()
  local key = vim.fn.getcwd():gsub("[\\/:]", "%%")
  return vim.fn.stdpath("state") .. "/TetraVim_explorer_open_" .. key
end

local function find_neo_tree_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      return win
    end
  end
  return nil
end

local function remember_explorer_state()
  local win = find_neo_tree_win()

  local path = marker_path()
  if win then
    pcall(vim.api.nvim_win_close, win, true)
    vim.fn.writefile({}, path)
  else
    pcall(vim.fn.delete, path)
  end
end

local function reopen_explorer_if_needed()
  local path = marker_path()
  if vim.fn.filereadable(path) == 1 then
    pcall(vim.fn.delete, path)
    vim.schedule(function()
      -- Guard: a scheduled callback has no autocmd frame to absorb an error,
      -- so an unguarded call here (e.g. neo-tree failed to load) surfaces as
      -- a raw traceback on session restore.
      pcall(function()
        require("neo-tree.command").execute({ action = "focus", source = "filesystem", toggle = false })
      end)
    end)
  end
end

--- Registers autocmds that close the neo-tree explorer, the Snacks dashboard,
--- and any plain blank scratch windows before persistence.nvim saves a
--- session (mksession can't serialize the first two -- neither is a real
--- file buffer -- and the last just pollutes every future restore with
--- `[No Name]` pages), then reopen the explorer after a session is loaded.
function M.setup()
  local group = vim.api.nvim_create_augroup("TetraVim_session_explorer", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "PersistenceSavePre",
    callback = function()
      remember_explorer_state()
      close_dashboard_windows()
      close_blank_windows()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "PersistenceLoadPost",
    callback = reopen_explorer_if_needed,
  })
end

return M
