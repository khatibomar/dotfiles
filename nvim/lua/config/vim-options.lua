vim.cmd([[ 
    set number
    set relativenumber
    set expandtab
    set tabstop=2
    set softtabstop=2
    set shiftwidth=2
]])

-- Enable copy to clipboard
vim.opt.clipboard:append("unnamedplus")
vim.opt.termguicolors = true

-- Color scheme
vim.cmd([[
  silent! colorscheme leaf-light
  highlight String guifg=#77B1B1
  highlight Comment guifg=#6E8D6E
  highlight Function guifg=#9D82A9
  highlight Keyword guifg=#D1A66A
  highlight Identifier guifg=#5F9EB1
  highlight Number guifg=#89C3B3
  highlight Boolean guifg=#A75E5E
  highlight Operator guifg=#737373
  highlight Type guifg=#846C92
]])

-- Enable autoread using the new API
vim.opt.autoread = true

-- Create a new autocmd group for managing changes
local group = vim.api.nvim_create_augroup("AutoReadGroup", { clear = true })

-- Automatically check for file changes when gaining focus or entering a buffer
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter"}, {
  group = group,
  callback = function()
    vim.cmd("checktime")  -- Check if files have changed externally
  end,
  desc = "Check for file changes on focus or buffer enter",
})

