-- TetraVim MCP Tool-Calling -- gives the task-executor skill (and any other
-- codecompanion chat) real tool access: filesystem edits, shell commands,
-- and whatever other MCP servers the user registers, instead of the LLM
-- only ever producing text a human has to apply by hand.
--
-- mcphub.nvim owns server process management + the `:MCPHub` config UI; this
-- distro ships no default server list -- add/edit servers there, which
-- writes to mcphub's own config file (~/.config/mcphub/servers.json by
-- default), matching mcphub's own convention rather than reinventing one
-- here. The codecompanion integration is a one-line `extensions.mcphub`
-- entry in ai-codecompanion.lua's opts.
--
-- Gated behind the same Claude toggle as codecompanion itself
-- (TetraVim.util.ai.config) -- MCP tools are meaningless without a chat
-- engine to hand them to.

local config = require("TetraVim.util.ai.config")

return {
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    enabled = function()
      return config.is_enabled("claude")
    end,
    cmd = { "MCPHub" },
    build = "npm install -g mcp-hub@latest",
    opts = {
      -- Every tool call surfaces in the chat for review before running --
      -- no server is auto-approved distro-wide. Per-server/per-tool
      -- auto-approve is the user's call, set from :MCPHub.
      auto_approve = false,
      extensions = {
        codecompanion = {
          show_result_in_chat = true,
          make_vars = true,
          make_slash_commands = true,
        },
      },
    },
    config = function(_, opts)
      require("mcphub").setup(opts)
    end,
  },
}
