vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- Enable copy to clipboard
vim.opt.clipboard:append("unnamedplus")

-- Color scheme
vim.o.termguicolors = true
vim.cmd [[silent! colorscheme leaf-light]]
