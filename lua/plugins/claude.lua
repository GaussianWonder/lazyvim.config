return {
  "coder/claudecode.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    require("claudecode").setup({
      -- The plugin will use sensible defaults unless this is defined
    })
  end,
}
