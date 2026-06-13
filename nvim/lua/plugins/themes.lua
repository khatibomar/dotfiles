return {
	{
		"blazkowolf/gruber-darker.nvim",
		priority = 1000,
		init = function()
			vim.cmd.colorscheme("gruber-darker")
		end,
	},
	{
		"khatibomar/leaf",
		config = function()
			require("leaf").setup({
				theme = "light",
				transparent = false,
				italics = {
					comments = false,
					keywords = false,
					functions = false,
					strings = false,
					variables = false,
				},
			})
		end,
	},
}
