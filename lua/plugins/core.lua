return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"

      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_enable_bold = 0

      vim.cmd.colorscheme("gruvbox-material")

      local function apply_style()
        local red = "#ea6962"
        local orange = "#e78a4e"
        local yellow = "#d8a657"
        local green = "#a9b665"
        local aqua = "#89b482"
        local blue = "#7daea3"
        local purple = "#d3869b"
        local fg = "#d4be98"
        local grey_neutral = "#a89984"

        local hl = vim.api.nvim_set_hl

        hl(0, "@string", { fg = yellow })
        hl(0, "@string.regex", { fg = yellow })

        hl(0, "@lsp.type.type", { fg = blue })
        hl(0, "@lsp.type.typeParameter", { fg = blue })
        hl(0, "@type.definition", { fg = blue })
        hl(0, "@type", { fg = blue, italic = false })
        hl(0, "@type.builtin", { fg = blue, italic = false })
        hl(0, "@lsp.type.class", { fg = blue, italic = false })
        hl(0, "@lsp.type.interface", { fg = blue, italic = false })
        hl(0, "@lsp.type.enum", { fg = blue, italic = false })
        hl(0, "@lsp.type.struct", { fg = blue, italic = false })

        hl(0, "@property", { fg = fg })
        hl(0, "@field", { fg = fg })
        hl(0, "@lsp.type.property", { fg = fg })

        hl(0, "@constant", { fg = purple })

        hl(0, "@namespace", { fg = fg })
        hl(0, "@module", { fg = fg })
        hl(0, "@lsp.type.namespace", { fg = fg })

        hl(0, "@preproc", { fg = aqua, italic = false })
        hl(0, "@keyword.directive", { fg = aqua, italic = false })

        hl(0, "@label", { fg = aqua })

        hl(0, "@punctuation.special", { fg = green })
        hl(0, "@tag.attribute", { fg = yellow })

        -- base folder/file color, neutral instead of green/white
        hl(0, "Directory", { fg = grey_neutral }) -- also fixes NeoTreeDirectoryName/Icon
        hl(0, "NeoTreeFileName", { fg = grey_neutral })
        hl(0, "NeoTreeFileNameOpened", { fg = grey_neutral, bold = false })
        hl(0, "NeoTreeRootName", { fg = grey_neutral, bold = false, italic = false })

        -- git status new = green, changed = yellow
        hl(0, "NeoTreeGitUntracked", { fg = green, italic = false })
        hl(0, "NeoTreeGitAdded", { fg = green })
        hl(0, "NeoTreeGitStaged", { fg = green })
        hl(0, "NeoTreeGitModified", { fg = yellow })
        hl(0, "NeoTreeGitUnstaged", { fg = yellow, italic = false, bold = false })
        hl(0, "NeoTreeGitRenamed", { fg = yellow })
        hl(0, "NeoTreeGitDeleted", { fg = red })
        hl(0, "NeoTreeGitConflict", { fg = red, italic = false, bold = false })

        hl(0, "SnacksPickerDirectory", { fg = grey_neutral })
        hl(0, "SnacksPickerGitStatusUntracked", { fg = green })
        hl(0, "SnacksPickerGitStatusAdded", { fg = green })
        hl(0, "SnacksPickerGitStatusStaged", { fg = green })
        hl(0, "SnacksPickerGitStatusModified", { fg = yellow })
        hl(0, "SnacksPickerGitStatusRenamed", { fg = yellow })
        hl(0, "SnacksPickerGitStatusDeleted", { fg = red })
        hl(0, "SnacksPickerGitStatusUnmerged", { fg = red })
      end

      apply_style()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "gruvbox-material",
        callback = apply_style,
      })
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
  { "akinsho/git-conflict.nvim", config = true },
}
