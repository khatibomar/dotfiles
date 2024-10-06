require("config.keymaps.go-definition")

function OpenTmuxPopup()
  local cmd = 'tmux display-popup -E "cd ' .. vim.fn.getcwd() .. ' && $SHELL "'
  vim.fn.system(cmd)
end

vim.keymap.set('n', '<leader>s', ':w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>p', ':lua OpenTmuxPopup()<CR>', { noremap = true, silent = true })

