return {
  "kndndrj/nvim-dbee",
  commit = "dda517694889a5d238d7aa407403984da9f80cc0",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  build = function()
    -- Install tries to automatically detect the install method.
    -- if it fails, try calling it with one of these parameters:
    --    "curl", "wget", "bitsadmin", "go"
    require("dbee").install()
  end,
  config = function()
    require("dbee").setup(--[[optional config]])
  end,
  keys = {
    {
      "<leader>db",
      function()
        require("dbee").toggle()
      end,
      desc = "Toggle Database View",
    },
  },
}
