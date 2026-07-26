return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				attach_to_untracked = true,
			})
		end,
		keys = {
			{ "<leader>gh", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview Hunk" },
			{ "<leader>gb", "<cmd>Gitsigns blame_line<CR>", desc = "Blame Line" },
			{ "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset Hunk" },
			{ "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage Hunk" },
			{ "]g", "<cmd>Gitsigns next_hunk<CR>", desc = "Next Hunk" },
			{ "[g", "<cmd>Gitsigns prev_hunk<CR>", desc = "Prev Hunk" },
		},
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
		},
		config = true,
		keys = {
			{ "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
		},
	},
	{
		"sindrets/diffview.nvim",
		config = function()
			require("diffview").setup({
				hooks = {
					view_opened = function(view)
						local lib = require("diffview.lib")
						local views_to_close = {}
						for _, v in ipairs(lib.views) do
							if v ~= view then
								table.insert(views_to_close, v)
							end
						end
						for _, v in ipairs(views_to_close) do
							v:close()
						end
					end,
				},
			})
		end,
		keys = {
			{ "<leader>dv", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
			{ "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
		},
	},
}
