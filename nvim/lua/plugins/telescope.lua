return {
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      local builtin = require("telescope.builtin")
      
      -- Custom function to show buffers (files opened in the current session)
      local function session_oldfiles()
        builtin.buffers({ show_all_buffers = true, sort_mru = true })
      end
      
      vim.keymap.set("n", "<C-p>", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      -- Use buffers for session-specific files
      vim.keymap.set("n", "<leader><leader>", session_oldfiles, {})

      require("telescope").load_extension("ui-select")
    end,
  },
}

