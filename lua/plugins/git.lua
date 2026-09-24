return {
  {
    "dlyongemallo/diffview-plus.nvim",
    main = "diffview", -- repo name != module name
    version = "*",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewMergeFiles",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = {
      { "<leader>gcc", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gcq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
      { "<leader>gch", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
    },
    opts = function()
      local a = require("diffview.actions")

      local hunk, file = {}, {}
      for k, v in pairs({ o = "ours", t = "theirs", b = "base", a = "all" }) do
        vim.list_extend(hunk, {
          { "n", "<leader>c" .. k, false },
          { "n", "<leader>gc" .. k, a.conflict_choose(v), { desc = "Choose " .. v .. " (hunk)" } },
        })
        vim.list_extend(file, {
          { "n", "<leader>c" .. k:upper(), false },
          { "n", "<leader>gc" .. k:upper(), a.conflict_choose_all(v), { desc = "Choose " .. v .. " (all)" } },
        })
      end

      local panel = {
        { "n", "<leader>e", false },
        { "n", "<leader>b", false },
        { "n", "<leader>gcf", a.focus_files, { desc = "Focus file panel" } },
        { "n", "<leader>gcF", a.toggle_files, { desc = "Toggle file panel" } },
      }

      local conflicts = vim.list_extend(vim.deepcopy(hunk), file)
      return {
        enhanced_diff_hl = true,
        view = { merge_tool = { layout = "diff3_mixed" } },
        keymaps = {
          view = panel,
          diff1 = vim.deepcopy(conflicts),
          diff3 = vim.deepcopy(conflicts),
          diff4 = vim.deepcopy(conflicts),
          file_panel = vim.list_extend(vim.deepcopy(panel), file),
          file_history_panel = vim.deepcopy(panel),
        },
      }
    end,
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gc", group = "Conflicts", icon = { icon = "⇄", color = "red" } },
      },
    },
  },
}
