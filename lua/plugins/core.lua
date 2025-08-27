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
}
