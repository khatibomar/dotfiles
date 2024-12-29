local g = vim.g

-- Leader keys
g.mapleader = " "
g.maplocalleader = " "

require("config.lazy")
require("config.vim-options")
require("config.diagnostic")
require("config.keymaps")
require("config.signs")
require("config.icons")
require("config.telescope.makefile_targets")
