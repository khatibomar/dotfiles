local opt = vim.opt
local api = vim.api

-- =====================================================
-- ESSENTIAL EDITOR SETTINGS
-- =====================================================

-- Line numbers and display
opt.number = true
opt.relativenumber = true
opt.cursorline = false -- No visual distraction
opt.wrap = false
opt.breakindent = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.linebreak = true
opt.textwidth = 80

-- Sign column and splits
opt.signcolumn = "yes"
opt.numberwidth = 4
opt.splitbelow = true
opt.splitright = true

-- Status and command
opt.title = true
opt.confirm = true
opt.showcmd = false
opt.ruler = true
opt.rulerformat = "%l,%v"
opt.laststatus = 3

-- Simple fill characters - no fancy symbols
opt.fillchars = { eob = " " }

-- Minimal list characters
opt.list = true
opt.listchars = {
	tab = "│ ",
	trail = "·",
}

-- =====================================================
-- EDITING BEHAVIOR
-- =====================================================

opt.clipboard:append("unnamedplus")
opt.mouse = "a"
opt.termguicolors = true
opt.updatetime = 200
opt.timeoutlen = 500

-- =====================================================
-- INDENTATION
-- =====================================================

-- Default: 2 spaces
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.shiftround = true
opt.autoindent = true
opt.smartindent = true

-- =====================================================
-- FILE HANDLING
-- =====================================================

opt.backup = false
opt.swapfile = false
opt.writebackup = false
opt.undofile = true
opt.autoread = true
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- =====================================================
-- SEARCH
-- =====================================================

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- =====================================================
-- COMPLETION
-- =====================================================

opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 10

-- =====================================================
-- FOLDING
-- =====================================================

opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldcolumn = "0" -- No fold column visual distraction

-- =====================================================
-- COLORSCHEME
-- =====================================================

vim.cmd([[colorscheme leaf-light]])

-- Minimal highlighting - no distractions
vim.cmd([[
  highlight Whitespace guifg=#C8E4CB gui=nocombine
  highlight NonText guifg=#C8E4CB gui=nocombine
]])

-- =====================================================
-- AUTO COMMANDS
-- =====================================================

-- Don't auto comment new lines
api.nvim_create_autocmd("BufEnter", {
	command = [[set formatoptions-=cro]],
})

-- Auto-reload files
api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	callback = function()
		vim.cmd("checktime")
	end,
})

-- Highlight yanked text briefly
api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 150 })
	end,
})

-- Spell check for text files
api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.txt", "*.md", "*.tex" },
	callback = function()
		opt.spell = true
		opt.spelllang = "en_us"
	end,
})

-- Clean trailing whitespace on save
api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		local save_cursor = vim.fn.getpos(".")
		vim.cmd([[%s/\s\+$//e]])
		vim.fn.setpos(".", save_cursor)
	end,
})

-- Restore cursor position
api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line("$")
		local not_commit = vim.b[args.buf].filetype ~= "commit"
		if valid_line and not_commit then
			vim.cmd([[normal! g`"]])
		end
	end,
})

-- =====================================================
-- GO-SPECIFIC SETTINGS
-- =====================================================

-- Go file detection
vim.filetype.add({
	extension = {
		gotmpl = "go",
	},
})

-- Go-specific settings
api.nvim_create_autocmd("FileType", {
	pattern = { "go", "gomod", "gowork", "gotmpl" },
	callback = function()
		-- Go uses tabs
		vim.bo.expandtab = false
		vim.bo.tabstop = 4
		vim.bo.softtabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.textwidth = 80
	end,
})

-- =====================================================
-- MINIMAL DIAGNOSTIC CONFIGURATION
-- =====================================================

vim.diagnostic.config({
	virtual_text = false, -- No inline diagnostics - visual distraction
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		focusable = false,
		style = "minimal",
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
	},
})

-- =====================================================
-- PERFORMANCE
-- =====================================================

-- Disable unused providers
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Better grep if available
if vim.fn.executable("rg") == 1 then
	opt.grepprg = "rg --vimgrep --smart-case"
	opt.grepformat = "%f:%l:%c:%m"
end
