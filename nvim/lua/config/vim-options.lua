vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- Enable copy to clipboard
vim.opt.clipboard:append("unnamedplus")

-- Color scheme
vim.o.termguicolors = true
vim.cmd [[silent! colorscheme leaf-light]]
vim.cmd [[highlight String guifg=#77B1B1]]
vim.cmd [[highlight Comment guifg=#6E8D6E]]
vim.cmd [[highlight Function guifg=#9D82A9]]
vim.cmd [[highlight Keyword guifg=#D1A66A]]
vim.cmd [[highlight Identifier guifg=#5F9EB1]]
vim.cmd [[highlight Number guifg=#89C3B3]]
vim.cmd [[highlight Boolean guifg=#A75E5E]]
vim.cmd [[highlight Operator guifg=#737373]]
vim.cmd [[highlight Type guifg=#846C92]]
