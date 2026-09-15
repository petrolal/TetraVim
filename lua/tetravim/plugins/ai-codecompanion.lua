-- TetraVim AI Chat / Inline-Edit Assistant -- Claude group (<leader>ic).
--
-- codecompanion.nvim is the sole AI chat/inline-edit/agentic engine for
-- Claude (never a hand-rolled HTTP client to a model API): it ships an
-- `anthropic` adapter that reads $ANTHROPIC_API_KEY -- no key is ever stored
-- in this repo. Gemini intentionally has no in-editor group here -- the
-- user drives Gemini via the official `gemini` CLI outside Neovim instead,
-- so this plugin no longer registers a gemini adapter. The custom pieces
-- this file's keymaps drive live in tetravim.util.ai.codecompanion,
-- mirroring how tools-http.lua owns only the plugin spec while <leader>a's
-- actual keymaps live in core/keymaps.lua.
--
-- Lazy-loaded on first use only -- an idle LLM client should cost nothing at
-- startup. Installed only while Claude is enabled in tetravim.util.ai.config
-- (<leader>is to change; needs :Lazy reload/restart to take effect).
-- :checkhealth tetravim (health/ai.lua) reports whether it has been loaded
-- yet and whether the API key is present.

local config = require("tetravim.util.ai.config")

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    enabled = function()
      return config.is_enabled("claude")
    end,
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    opts = {
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            schema = {
              model = {
                default = config.model("claude"),
              },
            },
          })
        end,
      },
      strategies = {
        chat = { adapter = "anthropic" },
        inline = { adapter = "anthropic" },
        cmd = { adapter = "anthropic" },
      },
      display = {
        -- Persistent split, never a floating window, per this distro's
        -- established response-display convention (see kulala.nvim / gRPC /
        -- Endpoints-panel output in tools-http.lua / util/clients).
        chat = { window = { layout = "vertical", position = "right" } },
      },
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
    end,
  },
}
