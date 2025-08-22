local g = vim.g

-- Leader keys
vim.keymap.set("", "<space>", "<nop>", { desc = "space is only a leader key now" })
g.mapleader = " "
g.maplocalleader = " "

require("config.lazy")
require("config.keymap")
require("config.vim-options")
require("config.find")
require("config.statusline").setup()
