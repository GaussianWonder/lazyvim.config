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

return {
  {
    "coder/claudecode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      local claude = find_claude()
      require("claudecode").setup({
        terminal_cmd = claude and vim.fs.normalize(claude),
        git_repo_cwd = true,
      })
    end,
    keys = {
      { "<leader>a", desc = "+AI" },
      -- Core Claude functionality
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },

      -- Context management
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Current Buffer" },
      { "<leader>at", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add File from Tree" },

      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Diff" },

      -- Additional commands
      { "<leader>ax", "<cmd>ClaudeCodeClose<cr>", desc = "Close Claude" },

      -- Visual mode selection
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send Selection to Claude", mode = "v" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.icons = opts.icons or {}
      opts.icons.rules = opts.icons.rules or {}
      vim.list_extend(opts.icons.rules, {
        { pattern = "ai", icon = LazyVim.config.icons.kinds.Copilot, color = "orange" },
      })
    end,
  },
}
