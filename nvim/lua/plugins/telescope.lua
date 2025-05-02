-- Function to find project root
local function find_project_root()
	-- Look for common project markers
	local markers = { ".git", "go.mod", "package.json", "Cargo.toml" }
	for _, marker in ipairs(markers) do
		local root = vim.fs.find(marker, {
			upward = true,
			stop = vim.env.HOME,
			path = vim.fn.expand("%:p:h"),
		})[1]
		if root then
			return vim.fs.dirname(root)
		end
	end
	return vim.loop.cwd()
end

return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			-- Find files including hidden and ignored files
			{
				"<leader><leader>",
				"<cmd>Telescope find_files<cr>",
				desc = "Find Files (including hidden and ignored)",
			},
			-- Other key bindings
			{ "<leader>lb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>rf", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
			{ "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in Current Buffer" },
			{ "<leader>lg", "<cmd>Telescope live_grep<cr>", desc = "Search Text in Workspace" },
			{ "<leader>ld", "<cmd>Telescope diagnostics<cr>", desc = "List Diagnostics" },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					-- Apply global options for all pickers
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
					},
					file_ignore_patterns = {
						"node_modules",
						".git",
						"%.pb%.go",
						".idea",
						".run",
					},
					-- Apply hidden and no_ignore globally
					hidden = true, -- Include hidden files by default
					no_ignore = true, -- Include ignored files by .gitignore
					no_ignore_parent = true, -- Include ignored files from parent .gitignore
				},
				pickers = {
					-- Ensure find_files uses these options
					find_files = {
						hidden = true, -- Include hidden files
						no_ignore = true, -- Include ignored files
						no_ignore_parent = true, -- Include parent .gitignore
					},
					-- Ensure live_grep uses these options
					live_grep = {
						additional_args = function()
							return { "--hidden", "--no-ignore" }
						end, -- Include hidden and ignored files
					},
					diagnostics = {
						root_dir = find_project_root(),
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			require("telescope").load_extension("ui-select")
		end,
	},
}
