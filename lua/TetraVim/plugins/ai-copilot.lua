-- TetraVim AI Inline Completion Assistant -- Copilot group (<leader>ip).
--
-- zbirenbaum/copilot.lua is the native-Lua GitHub Copilot client (over
-- copilot.vim's Node CLI wrapper): insert-mode ghost-text suggestions driven
-- from the official Copilot language server. Authentication is entirely
-- out-of-repo (`:Copilot auth` opens a device-code browser flow; no token is
-- ever stored here). Installed only while "copilot" is enabled in
-- TetraVim.util.ai.config (<leader>is to change; needs :Lazy reload/restart
-- to take effect).
--
-- Unlike the chat-driven tools, Copilot's actual value is its insert-mode
-- ghost text (accepted with <Tab> by default) -- the <leader>ip keymaps in
-- core/keymaps.lua only cover toggling/status/panel, wired through
-- TetraVim.util.ai.copilot.

local config = require("TetraVim.util.ai.config")

return {
  {
    "zbirenbaum/copilot.lua",
    enabled = function()
      return config.is_enabled("copilot")
    end,
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { auto_trigger = true },
      panel = { enabled = true },
    },
  },
}
