-- TetraVim AI Inline-Edit Assistant -- Cursor group (<leader>iv).
--
-- Cursor itself is a separate IDE, not something embeddable in Neovim; the
-- closest native-Neovim equivalent to its inline diff-apply editing UX
-- (distinct from codecompanion's chat/prompt-library model) is
-- yetone/avante.nvim -- "Ask"/"Edit" open a diff the user reviews and applies
-- hunk-by-hunk, rather than pasting code into a chat transcript. It defaults
-- to the Claude/anthropic provider (reusing $ANTHROPIC_API_KEY, no key ever
-- stored in this repo); `:AvanteSwitchProvider` (<leader>ivm) swaps it at
-- runtime. Installed only while "cursor" is enabled in
-- TetraVim.util.ai.config (<leader>is to change; needs :Lazy reload/restart
-- to take effect).
--
-- avante.nvim ships a small Rust helper built via `make` on install; this is
-- best-effort like the Quarkus/MicroProfile jar fetch in lsp-quarkus.lua --
-- a failed/skipped build does not break the pure-Lua ask/edit/apply flow.

local config = require("TetraVim.util.ai.config")

return {
  {
    "yetone/avante.nvim",
    enabled = function()
      return config.is_enabled("cursor")
    end,
    build = "make",
    cmd = { "AvanteAsk", "AvanteEdit", "AvanteToggle", "AvanteRefresh", "AvanteSwitchProvider" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      provider = "claude",
      providers = {
        claude = {
          model = config.model("claude"),
        },
      },
      -- avante.nvim otherwise registers its own global <leader>a* keymaps
      -- (ask/edit/refresh/toggle/select_history/...), which collide with
      -- this repo's existing <leader>a "api/data" group (ah=http, ad=db,
      -- ag=grpc). Every action stays reachable through the <leader>iv group
      -- in core/keymaps.lua (TetraVim.util.ai.cursor), which this repo owns.
      behaviour = {
        auto_set_keymaps = false,
      },
    },
  },
}
