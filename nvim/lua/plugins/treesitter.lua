return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local config = require("nvim-treesitter.configs")
      config.setup({
        -- Enable automatic installation of language parsers
        auto_install = true,

        -- Specify which parsers to ensure are installed
        ensure_installed = {
          "go",         -- Go language parser
        },

        -- Enable syntax highlighting using Treesitter
        highlight = {
          enable = true,               -- Enable Treesitter-based highlighting
          additional_vim_regex_highlighting = false,
        },

        -- Enable indentation based on Treesitter parsing
        indent = {
          enable = true,
        },
      })
    end
  }
}

