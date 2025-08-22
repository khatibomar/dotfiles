return {
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
        style = "light",
      })
    end,
  },
  {
    "yorik1984/newpaper.nvim",
    priority = 1000,
    config = function()
      require("newpaper").setup({
        style = "light",
      })
    end,
  },
}
