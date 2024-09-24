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
