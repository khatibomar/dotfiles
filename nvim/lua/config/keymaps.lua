require("config.keymaps.go-definition")

vim.keymap.set('n', '<leader>s', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>p', ':execute "!tmux display-popup -E \\"cd ' .. vim.fn.getcwd() .. ' && zsh -c \\"exit\\"\\""<CR>', { noremap = true, silent = true })

