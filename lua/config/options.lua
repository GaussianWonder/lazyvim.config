if vim.fn.has("win32") == 1 then
  -- Store-installed pwsh is an app execution alias that nvim can't execute, so resolve the real
  -- (versioned) exe from the package and cache it; re-resolve only when the cached path goes stale
  local function find_pwsh()
    if vim.fn.executable("pwsh.exe") == 1 then
      return "pwsh.exe"
    end
    local cache = vim.fn.stdpath("data") .. "/pwsh_path"
    local ok, lines = pcall(vim.fn.readfile, cache)
    if ok and lines[1] and vim.fn.executable(lines[1]) == 1 then
      return lines[1]
    end
    local dir = vim.fn.system({
      "powershell.exe",
      "-NoProfile",
      "-Command",
      "(Get-AppxPackage Microsoft.PowerShell).InstallLocation",
    })
    local exe = vim.trim(dir) .. "\\pwsh.exe"
    if vim.v.shell_error == 0 and vim.fn.executable(exe) == 1 then
      pcall(vim.fn.writefile, { exe }, cache)
      return exe
    end
    return "powershell.exe"
  end
  -- quoted because the WindowsApps path contains a space
  vim.o.shell = '"' .. find_pwsh() .. '"'
  vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
  vim.o.shellredir = "-RedirectStandardOutput %s -NewWindow -Wait"
  vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
end

if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font:h12"
  vim.g.neovide_refresh_rate_idle = 5
  vim.g.neovide_scale_factor = 1.0

  vim.g.neovide_opacity = 0.999
  vim.g.neovide_window_blurred = true

  vim.g.neovide_cursor_animation_length = 0.1
  vim.g.neovide_cursor_short_animation_length = 0.04
  vim.g.neovide_cursor_trail_size = 0.5
  vim.g.neovide_cursor_vfx_mode = "pixiedust"

  vim.g.neovide_scroll_animation_length = 0.05
  vim.g.neovide_scroll_animation_far_lines = 10
  vim.g.neovide_position_animation_length = 0.05

  -- vim.keymap.set({ "n", "v" }, "<C-+>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
  -- vim.keymap.set({ "n", "v" }, "<C-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
end

vim.g.snacks_animate = false
