--- Resolve the opencode binary: PATH first, then the official installer location.
local function opencode_bin()
  local on_path = vim.fn.exepath("opencode")
  if on_path ~= "" then
    return on_path
  end
  local exe = vim.fn.has("win32") == 1 and "opencode.exe" or "opencode"
  local installer = vim.fs.joinpath(vim.uv.os_homedir(), ".opencode", "bin", exe)
  return vim.fn.executable(installer) == 1 and installer or "opencode"
end

local M = {}

---@type snacks.win?
M.term = nil

local function term_valid()
  return M.term ~= nil and M.term:buf_valid()
end

-- opencode.nvim sends prompts to the most recently updated session whose directory matches
-- Neovim's cwd. The OpenCode v2 TUI only creates a session on its first message, so a freshly
-- opened TUI has none and `<leader>ob` etc. fail with "No OpenCode session found".
-- Fix: create the session through the background service (`opencode api`) first, then attach
-- the TUI to it with `--session <id>`. Both sides now point at the same session from the start.

--- Call the OpenCode background service via `opencode api` (handles discovery + auth for us).
---@param args string[]
---@param cb fun(data: any?, err: string?)
local function api(args, cb)
  local cmd = vim.list_extend({ opencode_bin(), "api" }, args)
  vim.system(cmd, { text = true, cwd = vim.fn.getcwd() }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return cb(nil, vim.trim((res.stderr or "") .. (res.stdout or "")))
      end
      local ok, decoded = pcall(vim.json.decode, res.stdout or "")
      if not ok or type(decoded) ~= "table" then
        return cb(nil, "Unexpected response: " .. (res.stdout or ""))
      end
      cb(decoded.data)
    end)
  end)
end

--- Most recently updated, non-archived root session for cwd (the one opencode.nvim targets).
---@param cb fun(id: string?)
local function latest_session(cb)
  api({
    "GET",
    "/api/session",
    "--param",
    "directory=" .. vim.fn.getcwd(),
    "--param",
    "order=desc",
    "--param",
    "parentID=null",
  }, function(sessions)
    for _, s in ipairs(type(sessions) == "table" and sessions or {}) do
      if not (s.time and s.time.archived) then
        return cb(s.id)
      end
    end
    cb(nil)
  end)
end

---@param cb fun(id: string?, err: string?)
local function create_session(cb)
  local body = vim.json.encode({ location = { directory = vim.fn.getcwd() } })
  api({ "POST", "/api/session", "-d", body }, function(session, err)
    cb(session and session.id, err)
  end)
end

---@param id string
---@param enter boolean
local function open_term(id, enter)
  M.term = Snacks.terminal.open({ opencode_bin(), "--session", id }, {
    cwd = vim.fn.getcwd(), -- must match the directory opencode.nvim uses to find the session
    win = {
      position = "right",
      width = 0.30,
      enter = enter,
      wo = { winbar = "" },
    },
  })
end

--- Open the OpenCode TUI in a right split, attached to a session for cwd.
---@param opts? { enter?: boolean, continue?: boolean, on_ready?: fun() }
---  continue: reuse the latest session for cwd instead of starting a new one
function M.open(opts)
  opts = opts or {}
  local enter = opts.enter ~= false
  local function ready()
    if opts.on_ready then
      opts.on_ready()
    end
  end

  if term_valid() then
    M.term:show()
    if enter then
      M.term:focus()
    end
    return ready()
  end

  local function with_new()
    create_session(function(id, err)
      if not id then
        return Snacks.notify.error("Failed to create OpenCode session:\n" .. (err or "?"), { title = "opencode" })
      end
      open_term(id, enter)
      ready()
    end)
  end

  if opts.continue then
    latest_session(function(id)
      if id then
        open_term(id, enter)
        ready()
      else
        with_new()
      end
    end)
  else
    with_new()
  end
end

function M.toggle()
  if term_valid() then
    M.term:toggle()
    if M.term:valid() then
      M.term:focus()
    end
  else
    M.open()
  end
end

function M.focus()
  if term_valid() and M.term:valid() and vim.api.nvim_get_current_win() == M.term.win then
    vim.cmd("wincmd p")
  else
    M.open()
  end
end

function M.close()
  if term_valid() then
    M.term:close()
  end
  M.term = nil
end

--- Restart the TUI on the latest session for cwd.
function M.continue()
  M.close()
  M.open({ continue = true })
end

--- Run `fn` once a TUI + session exist (opens the TUI on the latest session if needed, no focus steal).
---@param fn fun()
function M.with_session(fn)
  if term_valid() then
    return fn()
  end
  M.open({ enter = false, continue = true, on_ready = fn })
end

--- Prefill Ask with the files selected in the snacks explorer (or any picker).
---@param picker? snacks.Picker
function M.send_picker(picker)
  picker = picker or Snacks.picker.get({ source = "explorer" })[1]
  if not picker then
    Snacks.notify.warn("No explorer/picker open", { title = "opencode" })
    return
  end
  local oc = require("opencode")
  local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
    return item.file and oc.format({ path = item.file, from = item.pos, to = item.end_pos }) or item.text
  end, picker:selected({ fallback = true }))
  M.with_session(function()
    oc.ask(table.concat(items, " ") .. " ")
  end)
end

--- Build a keymap rhs that ensures a session, then calls require("opencode")[method](arg).
--- opencode.nvim reads the visual selection from the current mode, and the session check may be
--- async (opening the TUI), so leave visual mode now and restore it with `gv` right before the call.
---@param method "ask" | "prompt" | "select"
---@param arg? string
local function oc(method, arg)
  return function()
    local visual = vim.fn.mode():match("[vV\22]") ~= nil
    local win = vim.api.nvim_get_current_win()
    if visual then
      vim.cmd("normal! \27")
    end
    M.with_session(function()
      if visual and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        vim.cmd("normal! gv")
      end
      require("opencode")[method](arg)
    end)
  end
end

return {
  {
    "nickjvandyke/opencode.nvim",
    -- main branch targets OpenCode v2 (installed: v2.2.x)
    dependencies = { "folke/snacks.nvim" },
    init = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- Called when no running OpenCode service is found: open the TUI on the right without stealing focus.
          start = function()
            M.open({ enter = false, continue = true })
          end,
        },
      }
    end,
    config = function()
      -- Reveal the terminal when OpenCode starts working (e.g. after a prompt sent from a buffer)
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("opencode_terminal", { clear = true }),
        pattern = "OpencodeEvent:session.execution.started",
        callback = function()
          if term_valid() and not M.term:valid() then
            M.term:show()
          end
        end,
      })
    end,
    keys = {
      { "<leader>o", desc = "+OpenCode", mode = { "n", "x" } },
      -- Core
      { "<leader>oc", M.toggle, desc = "Toggle OpenCode" },
      { "<leader>of", M.focus, desc = "Focus OpenCode" },
      { "<leader>oC", M.continue, desc = "Continue OpenCode" },
      { "<leader>ox", M.close, desc = "Close OpenCode" },

      -- Context (opens Ask prefilled with the context; type a question and <CR>)
      { "<leader>ob", oc("ask", "@buffer "), desc = "Add Current Buffer" },
      {
        "<leader>ot",
        function()
          M.send_picker()
        end,
        desc = "Add File from Tree",
      },
      { "<leader>os", oc("ask", "@this: "), desc = "Send Selection to OpenCode", mode = "x" },
      { "<leader>oa", oc("ask", "@this: "), desc = "Ask OpenCode", mode = { "n", "x" } },
      { "<leader>od", oc("prompt", "Fix @diagnostics"), desc = "Fix Diagnostics" },

      -- Prompts / commands picker (explain, review, test, ...)
      { "<leader>op", oc("select"), desc = "Select Prompt/Action", mode = { "n", "x" } },

      -- Operator: go{motion} sends range, goo sends line (dot-repeatable).
      -- Needs the TUI already open (operators must return keys synchronously).
      {
        "go",
        function()
          return require("opencode").operator("@this ")
        end,
        desc = "Send Range to OpenCode",
        expr = true,
        mode = { "n", "x" },
      },
      {
        "goo",
        function()
          return require("opencode").operator("@this ") .. "_"
        end,
        desc = "Send Line to OpenCode",
        expr = true,
      },
    },
  },
  {
    -- <a-o> in any snacks picker / explorer: send selected files to OpenCode Ask
    "folke/snacks.nvim",
    opts = {
      picker = {
        actions = {
          opencode_send = function(picker)
            M.send_picker(picker)
          end,
        },
        win = {
          input = { keys = { ["<a-o>"] = { "opencode_send", mode = { "n", "i" } } } },
          list = { keys = { ["<a-o>"] = { "opencode_send", mode = { "n" } } } },
        },
      },
    },
  },
  {
    -- OpenCode connection/status icon in the statusline (only once the plugin is loaded)
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return require("opencode").statusline()
        end,
        cond = function()
          return package.loaded["opencode"] ~= nil
        end,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.icons = opts.icons or {}
      opts.icons.rules = opts.icons.rules or {}
      vim.list_extend(opts.icons.rules, {
        { pattern = "opencode", icon = "󰚩", color = "green" },
      })
    end,
  },
}
