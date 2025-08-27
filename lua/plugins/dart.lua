return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      require("lspconfig").dartls.setup({
        cmd = { "dart", "language-server", "--protocol=lsp" },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if not opts.ensure_installed then
        opts.ensure_installed = {}
      end
      vim.list_extend(opts.ensure_installed, {
        "dart",
      })
    end,
  },
}
