return {
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader><leader>", "<cmd>Telescope find_files<cr>", desc = "Find Files" }
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "node_modules" , ".git" },
        mappings = {
          i = {
            ["<C-u>"] = false,
          }
        },
      },
    },
    config = function()
      require("telescope").setup({
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

