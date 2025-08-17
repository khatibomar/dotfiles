-- Function to find project root
local function find_project_root()
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

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

-- Custom live_multigrep picker
local function live_multigrep(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.uv.cwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local pieces = vim.split(prompt, "  ")
			local args = { "rg" }
			if pieces[1] then
				table.insert(args, "-e")
				table.insert(args, pieces[1])
			end

			if pieces[2] then
				table.insert(args, "-g")
				table.insert(args, pieces[2])
			end

			return vim.tbl_flatten({
				args,
				{ "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
			})
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})

	pickers
		.new(opts, {
			debounce = 100,
			prompt_title = "Multi Grep",
			finder = finder,
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
		})
		:find()
end

return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader><leader>", "<cmd>Telescope find_files<cr>", desc = "Find Files (all)" },
			{ "<leader>lb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>rf", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
			{ "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in Buffer" },
			{
				"<leader>lg",
				live_multigrep,
				desc = "Search Text in Workspace (Multi Grep)",
			},
		},
		config = function()
			require("telescope").setup({
				defaults = {
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
						"^.git",
						"%.pb%.go",
						"^.idea",
						"^.run",
					},
					hidden = true,
					no_ignore = true,
					no_ignore_parent = true,
				},
				pickers = {
					find_files = {
						hidden = true,
						no_ignore = true,
						no_ignore_parent = true,
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
