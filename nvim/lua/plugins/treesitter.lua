return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		lazy = false,
		config = function()
			-- Specify which parsers to ensure are installed
			require("nvim-treesitter").install({
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
			})

			-- Automatically enable highlighting and indentation for any
			-- filetype that has an installed parser (replaces the old
			-- auto_install/highlight.enable/indent.enable options).
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(args.match) or args.match
					if vim.treesitter.language.add(lang) then
						vim.treesitter.start()
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
}
