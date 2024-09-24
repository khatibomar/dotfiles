return {
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      -- Find files including hidden and ignored files
      { "<leader><leader>", "<cmd>Telescope find_files<cr>", desc = "Find Files (including hidden and ignored)" },
      -- Other key bindings
      { "<leader>lb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>rf", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in Current Buffer" },
      { "<leader>lg", "<cmd>Telescope live_grep<cr>", desc = "Search Text in Workspace" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          -- Apply global options for all pickers
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
          },
          file_ignore_patterns = {   -- Exclude node_modules and .git directories
            "node_modules",
            ".git",
          },
          -- Apply hidden and no_ignore globally
          hidden = true,             -- Include hidden files by default
          no_ignore = true,          -- Include ignored files by .gitignore
          no_ignore_parent = true,   -- Include ignored files from parent .gitignore
        },
        pickers = {
          -- Ensure find_files uses these options
          find_files = {
            hidden = true,             -- Include hidden files
            no_ignore = true,          -- Include ignored files
            no_ignore_parent = true,   -- Include parent .gitignore
          },
          -- Ensure live_grep uses these options
          live_grep = {
            additional_args = function() return { "--hidden", "--no-ignore" } end, -- Include hidden and ignored files
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })

      require("telescope").load_extension("ui-select")
    end,
  },
}

