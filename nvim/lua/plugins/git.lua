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
		keys = {
			{ "<leader>dv", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
			{ "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
		},
	},
}
