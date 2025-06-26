-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Window navigation with Ctrl+arrows (replacing panel resize)
vim.keymap.del("n", "<C-Up>", { silent = true })
vim.keymap.del("n", "<C-Down>", { silent = true })
vim.keymap.del("n", "<C-Left>", { silent = true })
vim.keymap.del("n", "<C-Right>", { silent = true })

-- Map Ctrl+arrows to window navigation (same as Ctrl+hjkl)
map("n", "<C-Left>", "<C-h>", { desc = "Go to Left Window", remap = true })
map("n", "<C-Down>", "<C-j>", { desc = "Go to Lower Window", remap = true })
map("n", "<C-Up>", "<C-k>", { desc = "Go to Upper Window", remap = true })
map("n", "<C-Right>", "<C-l>", { desc = "Go to Right Window", remap = true })

-- Half page navigation with pg up/down (Ctrl+Alt+arrows set in terminal) (centered)
-- other platforms need to remap C-A-[...] to PageUp/PageDown
map("n", "<PageUp>", "<C-u>zz", { desc = "Half Page Up (Centered)" })
map("n", "<PageDown>", "<C-d>zz", { desc = "Half Page Down (Centered)" })
map("v", "<PageUp>", "<C-u>zz", { desc = "Half Page Up (Centered)" })
map("v", "<PageDown>", "<C-d>zz", { desc = "Half Page Down (Centered)" })
-- neovide
map("n", "<C-A-Up>", "<C-u>zz", { desc = "Half Page Up (Centered)" })
map("n", "<C-A-Down>", "<C-d>zz", { desc = "Half Page Down (Centered)" })
map("v", "<C-A-Up>", "<C-u>zz", { desc = "Half Page Up (Centered)" })
map("v", "<C-A-Down>", "<C-d>zz", { desc = "Half Page Down (Centered)" })

-- Move selected lines up/down in visual mode with Alt+arrows
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up" })
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down" })

-- Declarative which-key group setup
local wk = require("which-key")

wk.add({
  -- Main AI group
  { "<leader>a", group = "AI/Assistant" },

  -- Core Claude functionality
  { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
  { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
  { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
  { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },

  -- Context management
  { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Current Buffer" },
  {
    "<leader>at",
    "<cmd>ClaudeCodeTreeAdd<cr>",
    desc = "Add File from Tree",
  },

  -- Diff management
  { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Diff" },
  { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Diff" },

  -- Additional useful commands (if available)
  { "<leader>ax", "<cmd>ClaudeCodeClose<cr>", desc = "Close Claude" },
})

-- Visual mode AI mappings
wk.add({
  { "<leader>a", group = "AI/Assistant", mode = "v" },
  { "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send Selection to Claude", mode = "v" },
})
