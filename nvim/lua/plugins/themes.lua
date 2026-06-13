return {
  {
    "khatibomar/tsoding.nvim",
    priority = 1000,
    config = function()
      require("tsoding").setup({
        theme = "dark",
        transparent = false,
        italics = {
          comments = true,
          keywords = false,
          functions = false,
          strings = false,
          variables = false,
        },
      })
      require("tsoding").colorscheme()
    end,
  },
  {
    "khatibomar/gopher.nvim",
    priority = 1000,
    config = function()
      require("gopher").setup({
        theme = "dark",
        transparent = false,
        italics = {
          comments = true,
          keywords = false,
          functions = false,
          strings = false,
          variables = false,
        },
      })
      require("gopher").colorscheme()
    end,
  },
  {
    "khatibomar/leaf",
    config = function()
      require("leaf").setup({
        theme = "light",
        transparent = false,
        italics = {
          comments = false,
          keywords = false,
          functions = false,
          strings = false,
          variables = false,
        },
      })
    end,
  },
}
