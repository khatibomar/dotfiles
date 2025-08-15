return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local config = require("nvim-treesitter.configs")
			config.setup({
				ignore_install = {},
				-- Enable automatic installation of language parsers
				auto_install = true,
				sync_install = false,

				-- Specify which parsers to ensure are installed
				ensure_installed = {
					"go",
					"gomod",
					"gowork",
					"gosum",
					"lua",
					"bash",
					"cpp",
					"proto",
					"diff",
					"markdown",
				},

				-- Enable syntax highlighting using Treesitter
				highlight = {
					enable = true, -- Enable Treesitter-based highlighting
					additional_vim_regex_highlighting = false,
				},

				-- Enable indentation based on Treesitter parsing
				indent = {
					enable = true,
				},
			})
		end,
	},
}
