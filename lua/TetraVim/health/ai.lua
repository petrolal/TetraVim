-- TetraVim Healthcheck -- AI Assistants (Claude, Gemini, Copilot, Cursor)
-- Gemini has no lazy.nvim spec -- it shells out to the official `gemini` CLI
-- (TetraVim.util.ai.gemini) instead of an in-editor plugin.

local M = {}

function M.check()
  vim.health.start("TetraVim AI Assistants")

  local config = require("TetraVim.util.ai.config")
  local cc = require("TetraVim.util.ai.codecompanion")
  local gemini = require("TetraVim.util.ai.gemini")
  local copilot = require("TetraVim.util.ai.copilot")

  vim.health.info("Default provider: " .. config.default_provider() .. " (<leader>is to change)")

  -- Claude
  if not config.is_enabled("claude") then
    vim.health.info("Claude: disabled in TetraVim.util.ai.config (<leader>is to enable)")
  else
    if cc.api_key_present() then
      vim.health.ok("Claude: $ANTHROPIC_API_KEY set")
    else
      vim.health.info("Claude: $ANTHROPIC_API_KEY not set -- will use Copilot adapter if authenticated")
    end
  end

  if cc.available() then
    vim.health.ok("codecompanion.nvim: resolvable")
  else
    vim.health.info("codecompanion.nvim: not yet loaded -- lazy-loads on first <leader>ic keymap")
  end

  -- Gemini (official `gemini` CLI)
  if not config.is_enabled("gemini") then
    vim.health.info("Gemini: disabled in TetraVim.util.ai.config (<leader>is to enable)")
  elseif gemini.available() then
    vim.health.ok("gemini CLI: found on $PATH")
  else
    vim.health.info("gemini CLI: NOT found on $PATH -- install it (npm i -g @google/gemini-cli)")
  end

  -- Copilot
  if not config.is_enabled("copilot") then
    vim.health.info("Copilot: disabled in TetraVim.util.ai.config (<leader>is to enable)")
  elseif copilot.available() then
    vim.health.ok("copilot.lua: resolvable -- run :Copilot status to confirm auth")
  else
    vim.health.info("copilot.lua: not yet loaded -- lazy-loads on InsertEnter or :Copilot")
  end

  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl: installed (codecompanion request backend)")
  else
    vim.health.warn("curl: NOT found on $PATH -- codecompanion cannot make requests")
  end

  -- MCP tool-calling (ai-mcphub.lua) -- gives task-executor and other chats
  -- real filesystem/shell/etc tool access instead of text-only output.
  if not config.is_enabled("claude") then
    vim.health.info("mcphub.nvim: disabled alongside Claude (<leader>is to enable)")
  elseif vim.fn.executable("mcp-hub") == 1 then
    vim.health.ok("mcp-hub: installed -- MCP tool-calling available to codecompanion chats")
  else
    vim.health.info("mcp-hub: NOT found on $PATH -- run :Lazy build mcphub.nvim (npm i -g mcp-hub)")
  end

  -- Agent hooks (util/ai/hooks.lua) -- event-triggered .hooks/*.md prompts.
  local hooks = require("TetraVim.util.ai.hooks").load()
  if #hooks == 0 then
    vim.health.info("Agent hooks: none in .hooks/ (<leader>ikh to seed an example)")
  else
    local enabled = vim.tbl_count(vim.tbl_filter(function(h)
      return h.enabled
    end, hooks))
    vim.health.ok(("Agent hooks: %d loaded, %d enabled"):format(#hooks, enabled))
  end
end

return M
