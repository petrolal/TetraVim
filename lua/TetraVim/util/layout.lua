-- TetraVim fixed IDE layout -- Kiro-style pinned left explorer / right AI
-- agent sidebar / bottom terminal drawer, orchestrated on top of plugins
-- this distro already ships (snacks.nvim's explorer + terminal,
-- codecompanion.nvim's chat) instead of a dedicated pane-manager plugin.
--
-- Each pane is just a normal split with `winfixwidth`/`winfixheight` set --
-- `core/autocmds.lua`'s "resize_splits" group already runs `wincmd =` on
-- every VimResized and explicitly leaves fixed-size windows alone, so no
-- separate resize bookkeeping is needed here.

local M = {}

M.LEFT_WIDTH = 32
M.RIGHT_WIDTH = 42
M.BOTTOM_HEIGHT = 14

--- Toggle the Snacks explorer as a pinned left sidebar. `Snacks.explorer()`
--- already toggles closed if a picker with source "explorer" is open
--- (snacks.picker.pick closes the existing instance instead of opening a
--- second one) -- this just pins the width once it's shown.
function M.toggle_explorer()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    require("TetraVim.util.ui").notify_warn("snacks.nvim not available", "TetraVim Layout")
    return
  end

  snacks.explorer()
  vim.schedule(function()
    local explorer = snacks.picker.get({ source = "explorer" })[1]
    local win = explorer and explorer.list and explorer.list.win and explorer.list.win.win
    if win and vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winfixwidth = true
      vim.api.nvim_win_set_width(win, M.LEFT_WIDTH)
    end
  end)
end

--- Toggle a Snacks terminal pinned as a bottom drawer. `Snacks.terminal()`
--- is itself a toggle (`snacks.terminal.M.toggle`), so this just pins the
--- height once it's shown.
function M.toggle_terminal_drawer()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    require("TetraVim.util.ui").notify_warn("snacks.nvim not available", "TetraVim Layout")
    return
  end

  local term = snacks.terminal(nil, { win = { position = "bottom", height = M.BOTTOM_HEIGHT } })
  vim.schedule(function()
    if term and term.win and vim.api.nvim_win_is_valid(term.win) then
      vim.wo[term.win].winfixheight = true
      vim.api.nvim_win_set_height(term.win, M.BOTTOM_HEIGHT)
    end
  end)
end

--- Toggle the codecompanion chat, pinned as a right sidebar. Delegates the
--- actual open/close to TetraVim.util.ai.codecompanion (the module
--- core/keymaps.lua's <leader>icc already binds) and only adds the
--- fixed-width pin on top, since codecompanion's own `display.chat.window`
--- config has no `winfixwidth` knob.
function M.toggle_agent_panel()
  require("TetraVim.util.ai.codecompanion").toggle_chat()
  vim.schedule(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "codecompanion" then
        vim.wo[win].winfixwidth = true
        vim.api.nvim_win_set_width(win, M.RIGHT_WIDTH)
        return
      end
    end
  end)
end

--- True for the pinned right agent chat window, or the pinned bottom
--- terminal drawer -- the two panes a "target the center editor" operation
--- (mini.files' `go_in`, this module's own startup focus restore) must never
--- land in. Snacks terminals carry buftype "terminal"; codecompanion's chat
--- carries filetype "codecompanion" -- checking both covers every pane this
--- module opens without depending on window position/ordering.
---@param win integer
---@return boolean
function M.is_chrome_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].filetype == "codecompanion" or vim.bo[buf].buftype == "terminal"
end

--- The window mini.files (and startup focus restore) should treat as "the
--- central editor": the current window if it isn't agent/terminal chrome,
--- else the first non-chrome window in the tabpage, else just the current
--- window (nothing better to target).
---@return integer
function M.center_win()
  local cur = vim.api.nvim_get_current_win()
  if not M.is_chrome_win(cur) then
    return cur
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not M.is_chrome_win(win) then
      return win
    end
  end
  return cur
end

--- Launch the default Kiro-style agentic layout on startup: right agent
--- sidebar pinned open, focus left in the center editor window (never the
--- chat). The bottom terminal drawer stays closed by default -- opened
--- on demand via <leader>wt -- so a session doesn't start with an idle
--- shell eating screen space. Called once from core/autocmds.lua's VimEnter
--- "agentic_layout" group -- toggle_agent_panel only ever *opens* here
--- since a fresh session has no chat pane up yet, so there's no risk of
--- this accidentally closing it.
function M.open_default()
  local center = M.center_win()
  M.toggle_agent_panel()
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(center) then
      vim.api.nvim_set_current_win(center)
    end
  end)
end

return M
