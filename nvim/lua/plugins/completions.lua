return {
	"saghen/blink.cmp",
	dependencies = {
		{ "samiulsami/cmp-go-deep", dependencies = { "kkharji/sqlite.lua" } },
		{ "saghen/blink.compat" },
	},
	version = "1.*",
	opts = {
		completion = { documentation = { auto_show = true } },
		fuzzy = { implementation = "prefer_rust_with_warning" },
		keymap = { preset = "enter" },
		sources = {
			default = {
				"go_deep",
				"lsp",
				"path",
				"snippets",
				"buffer",
			},
			providers = {
				go_deep = {
					name = "go_deep",
					module = "blink.compat.source",
					min_keyword_length = 3,
					max_items = 5,
					---@module "cmp_go_deep"
					---@type cmp_go_deep.Options
					opts = {
						-- See below for configuration options
					},
				},
			},
		},
	},
}
