-- TetraVim File Explorer -- VSCode-style sidebar tree (<leader>e).
--
-- neo-tree.nvim is the closest native-Neovim match to VSCode's Explorer
-- panel: a persistent left sidebar tree (not a buffer-per-directory list
-- like oil.nvim) with inline git-status glyphs, LSP diagnostic counts, and
-- its own "document symbols" source that mirrors VSCode's Outline view via
-- treesitter/LSP. `filesystem.hijack_netrw_behavior = "open_default"`
-- (the v3.x default) replaces netrw the same way oil's
-- `default_file_explorer` did, so `nvim .` / `nvim <dir>` still opens
-- straight into the tree.

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  init = function()
    local opened_dir = false
    for _, arg in
      ipairs(vim.fn.argv() --[[@as string[] ]])
    do
      if vim.fn.isdirectory(arg) == 1 then
        opened_dir = true
        break
      end
    end
    if opened_dir then
      require("neo-tree")
    end
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = true,
    enable_git_status = true,
    enable_diagnostics = true,
    default_component_configs = {
      indent = { with_expanders = true },
    },
    window = {
      width = 32,
    },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false,
        hide_dotfiles = true,
        hide_gitignored = false,
      },
    },
  },
}
