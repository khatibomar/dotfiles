return {
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
}
