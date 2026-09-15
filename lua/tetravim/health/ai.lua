-- TetraVim Healthcheck -- AI Assistants (Claude, Gemini, Copilot, Cursor)
-- Gemini has no lazy.nvim spec -- it shells out to the official `gemini` CLI
-- (tetravim.util.ai.gemini) instead of an in-editor plugin.

local M = {}

function M.check()
  vim.health.start("TetraVim AI Assistants")

  local config = require("tetravim.util.ai.config")
  local cc = require("tetravim.util.ai.codecompanion")
  local gemini = require("tetravim.util.ai.gemini")
  local copilot = require("tetravim.util.ai.copilot")
  local cursor = require("tetravim.util.ai.cursor")

  vim.health.info("Default provider: " .. config.default_provider() .. " (<leader>is to change)")

  -- Claude
  if not config.is_enabled("claude") then
    vim.health.info("Claude: disabled in tetravim.util.ai.config (<leader>is to enable)")
  else
    if cc.api_key_present() then
      vim.health.ok("Claude: $ANTHROPIC_API_KEY set")
    else
      vim.health.warn("Claude: $ANTHROPIC_API_KEY not set -- <leader>ic* keymaps will fail to authenticate")
    end
  end

  if cc.available() then
    vim.health.ok("codecompanion.nvim: resolvable")
  else
    vim.health.info("codecompanion.nvim: not yet loaded -- lazy-loads on first <leader>ic keymap")
  end

  -- Gemini (official `gemini` CLI)
  if not config.is_enabled("gemini") then
    vim.health.info("Gemini: disabled in tetravim.util.ai.config (<leader>is to enable)")
  elseif gemini.available() then
    vim.health.ok("gemini CLI: found on $PATH")
  else
    vim.health.info("gemini CLI: NOT found on $PATH -- install it (npm i -g @google/gemini-cli)")
  end

  -- Copilot
  if not config.is_enabled("copilot") then
    vim.health.info("Copilot: disabled in tetravim.util.ai.config (<leader>is to enable)")
  elseif copilot.available() then
    vim.health.ok("copilot.lua: resolvable -- run :Copilot status to confirm auth")
  else
    vim.health.info("copilot.lua: not yet loaded -- lazy-loads on InsertEnter or :Copilot")
  end

  -- Cursor (avante.nvim)
  if not config.is_enabled("cursor") then
    vim.health.info("Cursor (avante.nvim): disabled in tetravim.util.ai.config (<leader>is to enable)")
  elseif cursor.available() then
    vim.health.ok("avante.nvim: resolvable")
  else
    vim.health.info("avante.nvim: not yet loaded -- lazy-loads on first <leader>iv keymap")
  end

  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl: installed (codecompanion's anthropic adapter request backend)")
  else
    vim.health.warn("curl: NOT found on $PATH -- the anthropic adapter cannot make requests")
  end

  if vim.fn.executable("make") == 1 then
    vim.health.ok("make: installed (avante.nvim's optional native build step)")
  else
    vim.health.info("make: NOT found on $PATH -- avante.nvim falls back to its pure-Lua path")
  end
end

return M
