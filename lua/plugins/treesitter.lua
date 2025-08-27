return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    if not opts.ensure_installed then
      opts.ensure_installed = {}
    end
    vim.list_extend(opts.ensure_installed, {
      "bash",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "query",
      "regex",
      "tsx",
      "typescript",
      "vim",
      "yaml",
      "tsx",
    })
  end,
}
