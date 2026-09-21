-- Agent Hooks (TetraVim.util.ai.hooks) -- Kiro-style event-triggered
-- automation, backed by per-project .hooks/*.md files. Covers the parts
-- with no LLM/UI dependency: frontmatter parsing, the event allowlist,
-- setup()'s autocmd wiring, and picker's toggle/scaffold text edits.

describe("TetraVim.util.ai.hooks", function()
  local hooks = require("TetraVim.util.ai.hooks")

  local tmp
  local orig_cwd

  local function write(rel, lines)
    local path = tmp .. "/" .. rel
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile(lines, path)
    return path
  end

  before_each(function()
    orig_cwd = vim.fn.getcwd()
    tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    vim.fn.chdir(tmp)
  end)

  after_each(function()
    vim.fn.chdir(orig_cwd)
  end)

  describe("load()", function()
    it("returns an empty list when .hooks/ doesn't exist", function()
      assert.are.same({}, hooks.load())
    end)

    it("parses a well-formed hook with frontmatter + body", function()
      write(".hooks/on-save.md", {
        "---",
        "name: on-save",
        "description: Suggest a test update",
        "trigger: BufWritePost",
        "pattern: *.lua",
        "---",
        "Do the thing.",
      })
      local loaded = hooks.load()
      assert.are.equal(1, #loaded)
      assert.are.equal("on-save", loaded[1].name)
      assert.are.equal("BufWritePost", loaded[1].trigger)
      assert.are.equal("*.lua", loaded[1].pattern)
      assert.is_true(loaded[1].enabled)
      assert.are.equal("Do the thing.", loaded[1].body)
    end)

    it("defaults enabled to true, honors explicit enabled: false", function()
      write(".hooks/off.md", {
        "---",
        "name: off",
        "trigger: BufWritePost",
        "enabled: false",
        "---",
        "body",
      })
      assert.is_false(hooks.load()[1].enabled)
    end)

    it("drops hooks with an unsupported/unlisted trigger event", function()
      write(".hooks/cursor-spam.md", {
        "---",
        "name: cursor-spam",
        "trigger: CursorMoved",
        "---",
        "body",
      })
      assert.are.same({}, hooks.load())
    end)

    it("drops files with no frontmatter block", function()
      write(".hooks/not-a-hook.md", { "just prose, no frontmatter" })
      assert.are.same({}, hooks.load())
    end)

    it("drops frontmatter with no name field", function()
      write(".hooks/nameless.md", {
        "---",
        "trigger: BufWritePost",
        "---",
        "body",
      })
      assert.are.same({}, hooks.load())
    end)
  end)

  describe("setup()", function()
    it("registers one autocmd per enabled hook, skips disabled ones", function()
      write(".hooks/enabled.md", {
        "---",
        "name: enabled",
        "trigger: BufWritePost",
        "pattern: *.lua",
        "---",
        "body",
      })
      write(".hooks/disabled.md", {
        "---",
        "name: disabled",
        "trigger: BufWritePost",
        "enabled: false",
        "---",
        "body",
      })

      hooks.setup()

      local autocmds = vim.api.nvim_get_autocmds({ group = "TetraVim_agent_hooks" })
      assert.are.equal(1, #autocmds)
      assert.is_truthy(autocmds[1].desc:find("enabled", 1, true))
    end)

    it("is safe to call repeatedly without accumulating duplicate autocmds", function()
      write(".hooks/one.md", {
        "---",
        "name: one",
        "trigger: BufWritePost",
        "---",
        "body",
      })
      hooks.setup()
      hooks.setup()
      hooks.setup()
      local autocmds = vim.api.nvim_get_autocmds({ group = "TetraVim_agent_hooks" })
      assert.are.equal(1, #autocmds)
    end)
  end)

  describe("scaffold()", function()
    it("creates a disabled example hook when .hooks/ is empty", function()
      hooks.scaffold()
      assert.are.equal(1, vim.fn.filereadable(".hooks/example-test-reminder.md"))
      local loaded = hooks.load()
      assert.are.equal(1, #loaded)
      assert.is_false(loaded[1].enabled)
    end)

    it("never overwrites an existing example file", function()
      write(".hooks/example-test-reminder.md", {
        "---",
        "name: example-test-reminder",
        "trigger: BufWritePost",
        "enabled: true",
        "---",
        "custom body",
      })
      hooks.scaffold()
      local loaded = hooks.load()
      assert.are.equal(1, #loaded)
      assert.are.equal("custom body", loaded[1].body)
    end)
  end)

  describe("picker() toggle", function()
    it("flips an existing enabled: field and re-runs setup()", function()
      write(".hooks/toggle-me.md", {
        "---",
        "name: toggle-me",
        "trigger: BufWritePost",
        "enabled: true",
        "---",
        "body",
      })

      -- vim.ui.select is stubbed to immediately pick item 1, mirroring how
      -- other specs in this suite drive picker-shaped functions headlessly.
      local orig_select = vim.ui.select
      vim.ui.select = function(items, _, on_choice)
        on_choice(items[1], 1)
      end

      hooks.picker()

      vim.ui.select = orig_select

      assert.is_false(hooks.load()[1].enabled)
      assert.are.equal(0, #vim.api.nvim_get_autocmds({ group = "TetraVim_agent_hooks" }))
    end)

    it("appends enabled: false when the field is absent (defaulted-true hook)", function()
      write(".hooks/no-enabled-field.md", {
        "---",
        "name: no-enabled-field",
        "trigger: BufWritePost",
        "---",
        "body",
      })

      local orig_select = vim.ui.select
      vim.ui.select = function(items, _, on_choice)
        on_choice(items[1], 1)
      end

      hooks.picker()

      vim.ui.select = orig_select

      assert.is_false(hooks.load()[1].enabled)
    end)
  end)
end)
