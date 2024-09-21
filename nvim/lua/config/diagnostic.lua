vim.diagnostic.config({
  virtual_text = false,
})
vim.keymap.set('n', '<leader>fd','<cmd>lua vim.diagnostic.open_float()<cr>')
