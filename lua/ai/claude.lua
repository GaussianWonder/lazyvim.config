--- Claude Code backend (coder/claudecode.nvim) for the unified AI dispatcher in `ai/init.lua`.
local util = require("ai.util")

--- Locate the claude binary. Returns an absolute path or nil (plugin then falls back to "claude").
--- Order: PATH, native installer, well-known static dirs, then dirs reported by package managers.
local function find_claude()
  local is_win = vim.fn.has("win32") == 1
  local exts = is_win and { ".exe", ".cmd", ".bat" } or { "" }
  local home = vim.uv.os_homedir()

  local function env(name)
    local v = vim.env[name]
    return (v and v ~= "") and v or nil
  end

  local function join(...)
    for i = 1, select("#", ...) do
      if not select(i, ...) then
        return nil
      end
    end
    return vim.fs.joinpath(...)
  end

  local function probe(dir)
    if not dir or dir == "" then
      return nil
    end
    for _, ext in ipairs(exts) do
      local path = join(dir, "claude" .. ext)
      if path and vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  -- Runs a package-manager query
  local function query(cmd)
    if vim.fn.executable(cmd[1]) ~= 1 then
      return nil
    end
    if is_win then
      cmd = vim.list_extend({ "cmd.exe", "/c" }, cmd)
    end
    local ok, res = pcall(function()
      return vim.system(cmd, { text = true }):wait(3000)
    end)
    if not ok or res.code ~= 0 then
      return nil
    end
    local out = vim.trim(res.stdout or ""):match("[^\r\n]+$") -- last line, ignores warnings
    return out ~= "" and out or nil
  end

  -- 1. Whatever the shell would resolve
  local on_path = vim.fn.exepath("claude")
  if on_path ~= "" then
    return on_path
  end

  -- 2. Static locations (cheap, no process spawn)
  local local_app = env("LOCALAPPDATA")
  local app_data = env("APPDATA")
  local xdg_data = env("XDG_DATA_HOME") or join(home, ".local", "share")
  local static = {
    join(home, ".local", "bin"), -- native installer (all platforms)
    join(home, ".claude", "local"), -- legacy local install
    join(home, ".claude", "local", "node_modules", ".bin"),
    join(env("BUN_INSTALL") or join(home, ".bun"), "bin"), -- bun
    join(env("PNPM_HOME") or (is_win and join(local_app, "pnpm") or join(xdg_data, "pnpm"))), -- pnpm
    join(home, "Library", "pnpm"), -- pnpm (macOS)
    join(env("VOLTA_HOME") or (is_win and join(local_app, "Volta") or join(home, ".volta")), "bin"), -- volta
    env("NVM_BIN"),
    join(home, ".yarn", "bin"), -- yarn classic
    join(home, ".config", "yarn", "global", "node_modules", ".bin"),
    join(local_app, "Yarn", "bin"),
    join(app_data, "npm"), -- npm on Windows
    join(env("NPM_CONFIG_PREFIX"), is_win and "" or "bin"),
    join(home, ".npm-global", "bin"),
    join(home, ".asdf", "shims"),
    join(xdg_data, "mise", "shims"),
    join(home, ".nix-profile", "bin"),
    join(home, "scoop", "shims"),
    join(local_app, "Microsoft", "WinGet", "Links"),
    join(env("ChocolateyInstall"), "bin"),
    "/opt/homebrew/bin",
    "/home/linuxbrew/.linuxbrew/bin",
    "/usr/local/bin",
    "/usr/bin",
  }
  for _, dir in ipairs(static) do
    local found = probe(dir)
    if found then
      return found
    end
  end

  -- 3. Ask package managers for their global bin dir (slower, last resort)
  local npm_prefix = query({ "npm", "prefix", "-g" })
  local queried = {
    npm_prefix and (is_win and npm_prefix or join(npm_prefix, "bin")),
    query({ "pnpm", "bin", "-g" }),
    query({ "yarn", "global", "bin" }),
    query({ "bun", "pm", "bin", "-g" }),
  }
  for i = 1, 4 do
    local found = probe(queried[i])
    if found then
      return found
    end
  end
end


local M = { name = "claude", label = "Claude" }

M.find_bin = find_claude

--- Run a claudecode command (requiring the module first lazy-loads the plugin and its commands).
---@param cmd string
local function run(cmd)
  return function()
    require("claudecode")
    vim.cmd(cmd)
  end
end

---@return integer?
function M.buf()
  if not package.loaded["claudecode"] then
    return nil
  end
  local ok, buf = pcall(function()
    return require("claudecode.terminal").get_active_terminal_bufnr()
  end)
  return ok and buf or nil
end

---@return integer?
function M.win()
  return util.buf_win(M.buf())
end

function M.hide()
  if M.win() then
    require("claudecode.terminal").simple_toggle()
  end
end

M.toggle = run("ClaudeCode")
M.focus = run("ClaudeCodeFocus")
M.close = run("ClaudeCodeClose")
M.continue = run("ClaudeCode --continue")
M.resume = run("ClaudeCode --resume")
M.add_buffer = run("ClaudeCodeAdd %")
M.send_selection = run("ClaudeCodeSend") -- reads the visual selection from the current mode
M.add_tree = run("ClaudeCodeTreeAdd")
M.diff_accept = run("ClaudeCodeDiffAccept")
M.diff_deny = run("ClaudeCodeDiffDeny")

---@param picker snacks.Picker
function M.send_picker(picker)
  local cc = require("claudecode")
  for _, item in ipairs(util.picker_items(picker)) do
    local from, to = item.pos and item.pos[1], item.end_pos and item.end_pos[1]
    -- claudecode line numbers are 0-indexed
    cc.send_at_mention(item.file, from and from - 1, to and to - 1, "picker")
  end
end

return M
