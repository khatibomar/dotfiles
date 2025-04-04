return {
	{
		"crusj/structrue-go.nvim",
		branch = "main",
		config = function()
			require("structrue-go").setup({
				show_others_method = true, -- bool show methods of struct whose not in current file
				show_filename = true, -- bool
				number = "no", -- show number: no | nu | rnu
				fold_open_icon = "",
				fold_close_icon = "",
				cursor_symbol_hl = "guibg=Gray guifg=White", -- symbol hl under cursor,
				indent = "│", -- Hierarchical indent icon, nil or empty will be a tab
				position = "botright", -- window position,default botright,also can set float
				symbol = { -- symbol style
					filename = {
						hl = "guifg=#0096C7",
						icon = " ",
					},
					package = {
						hl = "guifg=#0096C7",
						icon = " ",
					},
					import = {
						hl = "guifg=#0096C7",
						icon = " ",
					},
					const = {
						hl = "guifg=#E44755",
						icon = "󰏿 ",
					},
					variable = {
						hl = "guifg=#52A5A2",
						icon = " ",
					},
					func = {
						hl = "guifg=#CEB996",
						icon = "󰡱 ",
					},
					interface = {
						hl = "guifg=#00B4D8",
						icon = " ",
					},
					type = {
						hl = "guifg=#00B4D8",
						icon = " ",
					},
					struct = {
						hl = "guifg=#00B4D8",
						icon = " ",
					},
					field = {
						hl = "guifg=#CEB996",
						icon = " ",
					},
					method_current = {
						hl = "guifg=#CEB996",
						icon = " ",
					},
					method_others = {
						hl = "guifg=#CEB996",
						icon = "󰆧 ",
					},
				},
				keymap = {
					toggle = "<leader>m", -- toggle structure-go window
					show_others_method_toggle = "H", -- show or hidden the methods of struct whose not in current file
					symbol_jump = "<CR>", -- jump to then symbol file under cursor
					center_symbol = "\\f", -- Center the highlighted symbol
					fold_toggle = "\\z",
					refresh = "R", -- refresh symbols
					preview_open = "P", -- preview  symbol context open
					preview_close = "\\p", -- preview  symbol context close
				},
				fold = { -- fold symbols
					import = true,
					const = false,
					variable = false,
					type = false,
					interface = false,
					func = false,
				},
			})
		end,
	},
}
