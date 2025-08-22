local g = vim.g

-- Leader keys
g.mapleader = " "
g.maplocalleader = " "

require("config.lazy")
require("config.vim-options")
require("config.statusline").setup()
