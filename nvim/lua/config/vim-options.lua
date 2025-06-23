local opt = vim.opt
local api = vim.api

-- General options
opt.number = true -- Show line numbers
opt.relativenumber = true -- Show relative line numbers
opt.cursorline = false -- Disable current line highlighting
opt.wrap = false -- Disable line wrapping
opt.breakindent = true -- Wrapped lines will respect indentation
opt.scrolloff = 8 -- Minimum lines above/below cursor
opt.sidescrolloff = 8 -- Minimum columns left/right of cursor
opt.signcolumn = "yes" -- Always show sign column
opt.numberwidth = 4 -- Set width of the number column
opt.splitbelow = true -- Horizontal splits go below current window
opt.splitright = true -- Vertical splits go to the right of current window
opt.title = true -- Enable title in window title bar
opt.confirm = true -- Ask for confirmation when closing modified buffers
opt.showcmd = false -- Disable command display in the last line
opt.ruler = false -- Disable ruler
opt.fillchars = { eob = " " } -- Use space for empty lines
opt.list = true -- Enable listchars
opt.listchars = { -- Set listchars
    tab = "│ ", -- Tab character with low-visibility indicator
    trail = "·", -- Trailing spaces with subtle dot
}
opt.clipboard:append("unnamedplus") -- Use system clipboard
opt.termguicolors = true -- Enable 24-bit colors
opt.updatetime = 100 -- Reduce update time for completion
opt.timeoutlen = 1000 -- Time to wait for mapped sequence
opt.ruler = true -- Disable ruler
opt.rulerformat = "%l,%v" -- Set ruler format

-- Indentation options
opt.expandtab = true   -- Convert tabs to spaces
opt.tabstop = 2        -- Number of spaces per tab
opt.softtabstop = 2    -- Number of spaces per soft tab
opt.shiftwidth = 2     -- Number of spaces per indent
opt.breakindent = true -- Preserve indentation in wrapped lines

-- File behavior options
opt.backup = false      -- Disable backup files
opt.swapfile = false    -- Disable swap files
opt.writebackup = false -- Disable write backups
opt.undofile = true     -- Enable persistent undo
opt.autoread = true     -- Reload files changed outside of Neovim

-- Colorscheme
vim.cmd([[colorscheme leaf-light]])

-- Set custom colors for listchars
vim.cmd([[
  highlight Whitespace guifg=#C8E4CB gui=nocombine
  highlight NonText guifg=#C8E4CB gui=nocombine
]])

-- don't auto comment new line
api.nvim_create_autocmd("BufEnter", { command = [[set formatoptions-=cro]] })

-- Autocommand group for autoread
local group = api.nvim_create_augroup("AutoReadGroup", { clear = true })
api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    group = group,
    callback = function()
        vim.cmd("checktime") -- Check if files have changed externally
    end,
    desc = "Check for file changes on focus or buffer enter",
})

-- Enable spell checking for certain file types
api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.txt", "*.md", "*.tex" },
    callback = function()
        vim.opt.spell = true
        vim.opt.spelllang = "en_us" -- Arabic and Japanese are not supported
    end,
})

-- Enhanced diff mode configuration
api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.opt.diff:get() then
            -- Better diff options for merge conflicts
            vim.opt.diffopt:append("algorithm:patience")
            vim.opt.diffopt:append("linematch:60")

            -- Diff mode key mappings
            local diff_opts = { noremap = true, silent = true, desc = "Diff operation" }

            -- Get changes from different sources
            vim.keymap.set("n", "<leader>1", ":diffget LOCAL<CR>:diffupdate<CR>",
                vim.tbl_extend("force", diff_opts, { desc = "Get from LOCAL" }))
            vim.keymap.set("n", "<leader>2", ":diffget BASE<CR>:diffupdate<CR>",
                vim.tbl_extend("force", diff_opts, { desc = "Get from BASE" }))
            vim.keymap.set("n", "<leader>3", ":diffget REMOTE<CR>:diffupdate<CR>",
                vim.tbl_extend("force", diff_opts, { desc = "Get from REMOTE" }))

            -- Navigation and utilities
            vim.keymap.set("n", "<leader>u", ":diffupdate<CR>",
                vim.tbl_extend("force", diff_opts, { desc = "Update diff" }))
            vim.keymap.set("n", "<leader>m", "<C-w>l",
                vim.tbl_extend("force", diff_opts, { desc = "Focus merged file" }))

            -- Window navigation
            vim.keymap.set("n", "<C-h>", "<C-w>h", diff_opts)
            vim.keymap.set("n", "<C-j>", "<C-w>j", diff_opts)
            vim.keymap.set("n", "<C-k>", "<C-w>k", diff_opts)
            vim.keymap.set("n", "<C-l>", "<C-w>l", diff_opts)

            -- Enhanced diff highlighting
            vim.cmd([[
				highlight DiffAdd    guifg=#ffffff guibg=#005f00 ctermfg=15 ctermbg=22
				highlight DiffDelete guifg=#ffffff guibg=#5f0000 ctermfg=15 ctermbg=52
				highlight DiffChange guifg=#ffffff guibg=#00005f ctermfg=15 ctermbg=17
				highlight DiffText   guifg=#ffffff guibg=#870000 ctermfg=15 ctermbg=88
			]])
        end
    end,
})

vim.filetype.add({
    extension = {
        gotmpl = "go",
    },
})

-- Set Go-specific indentation settings (including gotmpl)
api.nvim_create_autocmd("FileType", {
    pattern = { "gotmpl" },
    callback = function()
        vim.bo.expandtab = false -- Use tabs instead of spaces
        vim.bo.tabstop = 8 -- Tab width of 8 spaces
        vim.bo.softtabstop = 8 -- Soft tabs of 8 spaces
        vim.bo.shiftwidth = 8 -- Indent with 8 spaces
    end,
})
