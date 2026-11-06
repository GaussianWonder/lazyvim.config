-- Claude Code + OpenCode sidebars under <leader>a. Logic lives in lua/ai/.
--   <leader>ac / <leader>ao  toggle Claude / OpenCode (only one sidebar shown at a time)
--   <leader>ab / as / at / af / ax / aC / ar  act on whichever sidebar is active
return {
  {
    "coder/claudecode.nvim",
    lazy = true, -- loaded on first `require("claudecode")` from lua/ai/claude.lua
    dependencies = { "folke/snacks.nvim" },
    init = function()
      require("ai").setup()
    end,
    config = function()
      local claude = require("ai.claude").find_bin()
      require("claudecode").setup({
        terminal_cmd = claude and vim.fs.normalize(claude),
        git_repo_cwd = true,
      })
    end,
  },
  {
    "nickjvandyke/opencode.nvim",
    -- main branch targets OpenCode v2 (installed: v2.2.x)
    lazy = true, -- loaded on first `require("opencode")`
    dependencies = { "folke/snacks.nvim" },
    init = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- Called when no running OpenCode service is found: open the TUI on the right without stealing focus.
          start = function()
            require("ai.opencode").open({ enter = false, continue = true })
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
          local oc = require("ai.opencode")
          if oc.buf() and not oc.win() then
            oc.term:show()
          end
        end,
      })
    end,
  },
  {
    -- <a-a> in any snacks picker / explorer: send selected files to the active AI sidebar
    "folke/snacks.nvim",
    opts = {
      picker = {
        actions = {
          ai_send = function(picker)
            require("ai").send_picker(picker)
          end,
        },
        win = {
          input = { keys = { ["<a-a>"] = { "ai_send", mode = { "n", "i" } } } },
          list = { keys = { ["<a-a>"] = { "ai_send", mode = { "n" } } } },
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
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>a", group = "ai", mode = { "n", "x" } })
      opts.icons = opts.icons or {}
      opts.icons.rules = opts.icons.rules or {}
      vim.list_extend(opts.icons.rules, {
        { pattern = "opencode", icon = "󰚩", color = "green" },
        { pattern = "claude", icon = LazyVim.config.icons.kinds.Copilot, color = "orange" },
        { pattern = "ai", icon = LazyVim.config.icons.kinds.Copilot, color = "orange" },
      })
    end,
  },
}
