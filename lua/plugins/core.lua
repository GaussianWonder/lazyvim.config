return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_enable_bold = 1
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox-material",
    },
  },
  {
    "snacks.nvim",
    opts = function(_, opts)
      if not opts.scroll then
        opts.scroll = {}
      end

      opts.scroll.enabled = not vim.g.neovide
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if not opts.inlay_hints then
        opts.inlay_hints = {}
      end

      opts.inlay_hints.enabled = true
    end,
  },
  {
    "ibhagwan/smartyank.nvim",
    opts = {
      highlight = {
        enabled = true, -- highlight yanked text
        higroup = "IncSearch", -- highlight group
        timeout = 2000, -- timeout for highlight
      },
      clipboard = {
        enabled = true, -- enables OSC 52 clipboard integration
      },
      tmux = {
        enabled = true, -- enable tmux clipboard integration
        -- remove `-w` to disable copy to host client's clipboard
        cmd = { "tmux", "set-buffer", "-w" },
      },
      osc52 = {
        enabled = true, -- enable OSC 52 integration
        ssh_only = true, -- only use OSC 52 when SSH session detected
        silent = false, -- suppress notifications
        echo_hl = "Directory", -- highlight group for echo message
      },
    },
  },
}
