require("config.keymaps.go-definition")

vim.keymap.set('n', '<leader>s', ':w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>p', ':!tmux display-popup -E "$SHELL"<CR>', { noremap = true, silent = true })
