--- Unified AI sidebar: routes shared actions (add buffer, send selection, ...) to whichever
--- backend (Claude Code / OpenCode) is currently in use. Backends live in `ai/<name>.lua` and
--- expose the same interface: buf, win, hide, toggle, focus, close, continue, resume,
--- add_buffer, send_selection, add_tree, send_picker (+ backend-specific extras).
local M = {}

---@alias ai.Name "claude" | "opencode"

M.order = { "claude", "opencode" } ---@type ai.Name[]
M.backends = {
  claude = require("ai.claude"),
  opencode = require("ai.opencode"),
}

--- Backend used most recently (toggled, focused or targeted). Fallback when no sidebar is visible.
---@type ai.Name
M.last = "claude"

--- Which backend shared actions go to:
--- 1. the one whose terminal you are in
--- 2. the only visible one (or the most recently used, if both are visible)
--- 3. the most recently used one
---@return ai.Name
function M.active()
  local cur = vim.api.nvim_get_current_buf()
  local visible = {}
  for _, name in ipairs(M.order) do
    local b = M.backends[name]
    if b.buf() == cur then
      return name
    end
    if b.win() then
      visible[#visible + 1] = name
    end
  end
  if #visible == 1 then
    return visible[1]
  end
  return M.last
end

--- Hide every visible sidebar except `keep`, so only one AI terminal occupies the right side.
---@param keep ai.Name
local function hide_others(keep)
  for _, name in ipairs(M.order) do
    if name ~= keep then
      M.backends[name].hide()
    end
  end
end

--- Keymap rhs: toggle a specific backend (hiding the other one when showing it).
---@param name ai.Name
function M.toggle(name)
  return function()
    local b = M.backends[name]
    if not b.win() then
      hide_others(name)
    end
    M.last = name
    b.toggle()
  end
end

--- Keymap rhs: run `method` on the active backend. Called synchronously, so visual mode is preserved.
---@param method string
function M.dispatch(method, ...)
  local args = { ... }
  return function()
    local name = M.active()
    local fn = M.backends[name][method]
    if not fn then
      return Snacks.notify.warn(
        ("`%s` is not supported by %s"):format(method, M.backends[name].label),
        { title = "AI" }
      )
    end
    M.last = name
    fn(unpack(args))
  end
end

--- Keymap rhs: run `method` on a specific backend.
---@param name ai.Name
---@param method string
function M.on(name, method)
  return function()
    M.last = name
    M.backends[name][method]()
  end
end

--- Snacks picker action: send selected files to the active backend.
---@param picker snacks.Picker
function M.send_picker(picker)
  -- The picker window is focused, so `active()` falls through to visibility / last used.
  M.dispatch("send_picker", picker)()
end

function M.setup()
  -- Entering an AI terminal makes it the most recently used one.
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("ai_last_used", { clear = true }),
    callback = function(ev)
      for _, name in ipairs(M.order) do
        if M.backends[name].buf() == ev.buf then
          M.last = name
          return
        end
      end
    end,
  })

  local map = function(lhs, rhs, desc, mode)
    vim.keymap.set(mode or "n", lhs, rhs, { desc = desc })
  end

  -- Backend toggles
  map("<leader>ac", M.toggle("claude"), "Toggle Claude")
  map("<leader>ao", M.toggle("opencode"), "Toggle OpenCode")

  -- Shared: act on the active sidebar
  map("<leader>af", M.dispatch("focus"), "Focus AI")
  map("<leader>ax", M.dispatch("close"), "Close AI")
  map("<leader>aC", M.dispatch("continue"), "Continue AI Session")
  map("<leader>ar", M.dispatch("resume"), "Resume AI Session")
  map("<leader>ab", M.dispatch("add_buffer"), "Add Current Buffer to AI")
  map("<leader>at", M.dispatch("add_tree"), "Add File from Tree to AI")
  map("<leader>as", M.dispatch("send_selection"), "Send Selection to AI", "x")

  -- Claude-only: diffs
  map("<leader>aa", M.on("claude", "diff_accept"), "Accept Diff (Claude)")
  map("<leader>ad", M.on("claude", "diff_deny"), "Deny Diff (Claude)")

  -- OpenCode-only: prompts / ask
  local oc = M.backends.opencode
  map("<leader>aq", function()
    M.last = "opencode"
    oc.ask()
  end, "Ask OpenCode", { "n", "x" })
  map("<leader>ap", function()
    M.last = "opencode"
    oc.select()
  end, "Select Prompt/Action (OpenCode)", { "n", "x" })
  map("<leader>aD", M.on("opencode", "fix_diagnostics"), "Fix Diagnostics (OpenCode)")

  -- OpenCode operator: go{motion} sends range, goo sends line (dot-repeatable).
  -- Needs the TUI already open (operators must return keys synchronously).
  vim.keymap.set({ "n", "x" }, "go", function()
    return require("opencode").operator("@this ")
  end, { desc = "Send Range to OpenCode", expr = true })
  vim.keymap.set("n", "goo", function()
    return require("opencode").operator("@this ") .. "_"
  end, { desc = "Send Line to OpenCode", expr = true })
end

return M
