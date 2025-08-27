return {
  {
    "coder/claudecode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      -- The plugin will use sensible defaults unless this is defined
      require("claudecode").setup({})
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
      opts.icons = {
        rules = {
          { pattern = "ai", icon = LazyVim.config.icons.kinds.Copilot, color = "orange" },
        },
      }
    end,
  },
}
