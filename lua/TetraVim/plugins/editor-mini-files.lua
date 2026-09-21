-- mini.files -- buffer-edit-the-filesystem explorer, replacing oil.nvim
-- (removed). Bound to <leader>e (core/keymaps.lua owns the keymap; this
-- spec only declares it so lazy.nvim lazy-loads the plugin on first use).
return {
  "echasnovski/mini.files",
  version = false,
  keys = {
    {
      "<leader>e",
      function()
        require("TetraVim.util.mini_files").open()
      end,
      desc = "Open file explorer (mini.files)",
    },
  },
  opts = {},
  config = function(_, opts)
    require("mini.files").setup(opts)
    -- Pin the "go in"/confirm target to the center editor window (never the
    -- pinned right agent chat or bottom terminal drawer), regardless of
    -- which window happened to be current when the explorer was opened --
    -- see TetraVim.util.layout.center_win(). mini.files exposes exactly this
    -- hook via MiniFiles.set_target_window(), read on every explorer open
    -- since the "current" window can change between opens.
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesExplorerOpen",
      group = vim.api.nvim_create_augroup("TetraVim_mini_files_target", { clear = true }),
      callback = function()
        require("mini.files").set_target_window(require("TetraVim.util.layout").center_win())
      end,
    })
  end,
}
