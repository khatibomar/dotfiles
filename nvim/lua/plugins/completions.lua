return {
	"saghen/blink.cmp",
	dependencies = {
		{ "samiulsami/cmp-go-deep", dependencies = { "kkharji/sqlite.lua" } },
		{ "saghen/blink.compat" },
		{ "onsails/lspkind.nvim" },
	},
	version = "1.*",
	opts = {
		appearance = {
			highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),
			-- Sets the fallback highlight groups to nvim-cmp's highlight groups
			-- Useful for when your theme doesn't support blink.cmp
			-- Will be removed in a future release
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "mono",
		},
		completion = {
			documentation = { auto_show = true },
			menu = {
				draw = {
					padding = { 0, 1 }, -- padding only on right side
					components = {
						kind_icon = {
							text = function(ctx)
								return " " .. ctx.kind_icon .. ctx.icon_gap .. " "
							end,
						},
					},
				},
			},
		},
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
