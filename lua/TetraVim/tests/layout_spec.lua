-- Kiro-style fixed IDE layout (TetraVim.util.layout). Covers the pure-logic
-- part with no floating/split-window dependency -- the toggle functions
-- themselves open real snacks.nvim pickers/terminals and a codecompanion
-- chat window, and stay manually verified like this repo's other AI UI
-- modules (see hooks_spec.lua's own note on the same tradeoff).

describe("TetraVim.util.layout", function()
  local layout = require("TetraVim.util.layout")

  it("exposes sane positive-integer pane size constants", function()
    assert.is_number(layout.LEFT_WIDTH)
    assert.is_number(layout.RIGHT_WIDTH)
    assert.is_number(layout.BOTTOM_HEIGHT)
    assert.is_true(layout.LEFT_WIDTH > 0)
    assert.is_true(layout.RIGHT_WIDTH > 0)
    assert.is_true(layout.BOTTOM_HEIGHT > 0)
  end)

  it("exposes the three independent toggle functions", function()
    assert.is_function(layout.toggle_explorer)
    assert.is_function(layout.toggle_terminal_drawer)
    assert.is_function(layout.toggle_agent_panel)
  end)

  it("exposes open_default for the startup autocmd", function()
    assert.is_function(layout.open_default)
  end)

  describe("is_chrome_win / center_win", function()
    it("treats a plain editor window as not chrome, and as the center window", function()
      local win = vim.api.nvim_get_current_win()
      assert.is_false(layout.is_chrome_win(win))
      assert.are.equal(win, layout.center_win())
    end)

    it("treats a terminal-buftype window as chrome, and skips it for center_win", function()
      -- `split | enew` first, not a bare `split`: a plain split reuses the
      -- *same* buffer in both windows, so termopen()'ing it in place would
      -- flip buftype for both windows (they share one buffer) and defeat
      -- this test. `enew` gives the new window its own fresh buffer first.
      vim.cmd("split | enew")
      local term_win = vim.api.nvim_get_current_win()
      vim.fn.termopen({ "true" })
      assert.is_true(layout.is_chrome_win(term_win))

      -- center_win(), called from inside the chrome window, must return the
      -- *other* window in the tabpage rather than the terminal itself.
      local center = layout.center_win()
      assert.is_false(layout.is_chrome_win(center))
      assert.are_not.equal(term_win, center)

      vim.api.nvim_win_close(term_win, true)
    end)

    it("returns false for an invalid window handle", function()
      assert.is_false(layout.is_chrome_win(999999))
    end)
  end)
end)
