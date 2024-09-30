return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = { "node_modules", ".DS_Store" },
          always_show = { ".gitignore" },
        },
        follow_current_file = { enabled = true },  -- Updated line
        hijack_netrw_behavior = "open_current",
      },
      window = {
        position = "left",
        width = 35,
        mappings = {
          ["<space>"] = "toggle_node",
          ["<CR>"] = "open",
          ["S"] = "split_with_window_picker",
          ["s"] = "vsplit_with_window_picker",
          ["t"] = "open_tabnew",
        },
      },
      buffers = {
        show_unloaded = true,
      },
    })

    -- Keymaps
    vim.keymap.set("n", "<C-n>", ":Neotree toggle filesystem left<CR>", {})
    vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", {})
    vim.keymap.set("n", "<leader>gs", ":Neotree git_status<CR>", {})

    -- Custom highlight groups for better coloring, including text in popups
    vim.cmd([[
      highlight NeoTreeNormal guibg=#f0f4c3 guifg=#333333
      highlight NeoTreeDirectoryName guifg=#61afef
      highlight NeoTreeGitAdded guifg=#98c379
      highlight NeoTreeGitModified guifg=#e5c07b
      highlight NeoTreeGitUntracked guifg=#e06c75
      highlight NeoTreeGitConflict guifg=#d19a66
      highlight NeoTreeFileNameOpened guifg=#56b6c2 gui=bold

      " Customize popup/floating window colors for file actions
      highlight NuiPopupNormal guibg=#f0f4c3 guifg=#333333
      highlight NuiBorder guifg=#3e4452 guibg=#f0f4c3
      highlight NuiInput guifg=#333333 guibg=#f0f4c3

      " Fix for the input text (when creating a file/directory)
      highlight NeoTreePopupBorder guifg=#3e4452 guibg=#f0f4c3
      highlight NeoTreePopupNormal guifg=#333333 guibg=#f0f4c3
      highlight NeoTreePopupTitle guifg=#333333 guibg=#f0f4c3
    ]])
  end,
}

