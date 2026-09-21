-- TetraVim AI Chat / Inline-Edit Assistant -- Claude group (<leader>ic).
--
-- codecompanion.nvim is the sole AI chat/inline-edit/agentic engine for
-- Claude (never a hand-rolled HTTP client to a model API): it ships an
-- `anthropic` adapter that reads $ANTHROPIC_API_KEY -- no key is ever stored
-- in this repo. Gemini intentionally has no in-editor group here -- the
-- user drives Gemini via the official `gemini` CLI outside Neovim instead,
-- so this plugin no longer registers a gemini adapter. The custom pieces
-- this file's keymaps drive live in TetraVim.util.ai.codecompanion,
-- mirroring how tools-http.lua owns only the plugin spec while <leader>a's
-- actual keymaps live in core/keymaps.lua.
--
-- Lazy-loaded on first use only -- an idle LLM client should cost nothing at
-- startup. Installed only while Claude is enabled in TetraVim.util.ai.config
-- (<leader>is to change; needs :Lazy reload/restart to take effect).
-- :checkhealth TetraVim (health/ai.lua) reports whether it has been loaded
-- yet and whether the API key is present.

local config = require("TetraVim.util.ai.config")

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
    -- Function form (not a static table): the prompt_library/variables below
    -- pull in TetraVim.util.ai.skills + .context, which glob the current
    -- project on every read -- deferring to plugin-load time (matches
    -- tools-diffview.lua's opts-as-function pattern) keeps that off the
    -- startup path when Claude is disabled or codecompanion hasn't loaded.
    opts = function()
      return {
        adapters = {
          copilot = function()
            return require("codecompanion.adapters").extend("copilot", {
              schema = {
                model = {
                  default = "claude-3.5-sonnet",
                },
              },
            })
          end,
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
          chat = {
            adapter = os.getenv("ANTHROPIC_API_KEY") and "anthropic" or "copilot",
            -- `#context` -- Kiro-style contextual project knowledge base
            -- (TetraVim.util.ai.context): architecture/conventions/domain/
            -- tech-stack, resolved fresh from .context/*.md on every use.
            variables = require("TetraVim.util.ai.context").codecompanion_variable(),
          },
          inline = { adapter = os.getenv("ANTHROPIC_API_KEY") and "anthropic" or "copilot" },
          cmd = { adapter = os.getenv("ANTHROPIC_API_KEY") and "anthropic" or "copilot" },
        },
        -- Spec Mode's spec-writer/task-planner/task-executor skills
        -- (TetraVim.util.ai.skills, Pocock-pattern externalized markdown),
        -- invoked as `/spec-writer` etc. -- see <leader>ik keymaps.
        prompt_library = require("TetraVim.util.ai.skills").prompt_library(),
        -- MCP tool-calling (ai-mcphub.lua) -- gives every chat, task-executor
        -- included, real filesystem/shell/etc access via whatever servers
        -- are registered in :MCPHub, instead of text-only suggestions.
        extensions = {
          mcphub = {
            callback = "mcphub.extensions.codecompanion",
            opts = {
              show_result_in_chat = true,
              make_vars = true,
              make_slash_commands = true,
            },
          },
        },
        display = {
          -- Persistent split, never a floating window, per this distro's
          -- established response-display convention (see kulala.nvim / gRPC /
          -- Endpoints-panel output in tools-http.lua / util/clients).
          chat = { window = { layout = "vertical", position = "right" } },
        },
      }
    end,
    config = function(_, opts)
      require("codecompanion").setup(opts)
    end,
  },
}
