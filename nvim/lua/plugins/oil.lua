return {
	"stevearc/oil.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("oil").setup({
			-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
			default_file_explorer = true,
			-- Id is automatically added at the beginning, and name at the end
			columns = {
				"icon",
				-- "permissions",
				-- "size",
				-- "mtime",
			},
			-- Buffer-local options to use for oil buffers
			buf_options = {
				buflisted = false,
				bufhidden = "hide",
			},
			-- Window-local options to use for oil buffers
			win_options = {
				wrap = false,
				signcolumn = "no",
				cursorcolumn = false,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			-- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
			delete_to_trash = false,
			-- Skip the confirmation popup for simple operations (:help oil.skip-confirm)
			skip_confirm_for_simple_edits = false,
			-- Selecting a new/moved/renamed file or directory will prompt you to save changes first
			-- (:help prompt_save_on_select_new_entry)
			prompt_save_on_select_new_entry = true,
			-- Oil will automatically delete hidden buffers after this delay
			cleanup_delay_ms = 2000,
			lsp_file_methods = {
				-- Time to wait for LSP file operations to complete before skipping
				timeout_ms = 1000,
				-- Set to true to autosave buffers that are updated with LSP willRenameFiles
				-- Set to "unmodified" to only autosave unmodified buffers
				autosave_changes = false,
			},
			-- Constrain the cursor to the editable parts of the oil buffer
			constrain_cursor = "editable",
			-- Set to true to watch the filesystem for changes and reload oil
			watch_for_changes = false,
			-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
			-- options with a `callback` (e.g. { callback = function() ... end, desc = "" })
			keymaps = {
				-- Help
				["?"] = "actions.show_help",

				-- Navigation (Vim-like)
				["<CR>"] = "actions.select",
				["l"] = "actions.select",
				["h"] = "actions.parent",
				["-"] = "actions.parent",

				-- Splits (Vim patterns)
				["s"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
				["v"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
				["t"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },

				-- File operations
				["p"] = "actions.preview",
				["x"] = "actions.open_external",

				-- Directory operations
				["."] = "actions.toggle_hidden",
				["R"] = "actions.refresh",

				-- Project navigation
				["gr"] = {
					callback = function()
						local oil = require("oil")
						-- Find project root (look for .git, package.json, etc.)
						local root_patterns =
							{ ".git", "package.json", "Cargo.toml", "go.mod", "pyproject.toml", "Makefile" }
						local current_dir = oil.get_current_dir() or vim.fn.getcwd()
						local root = vim.fs.find(root_patterns, { path = current_dir, upward = true })[1]
						if root then
							local project_root = vim.fs.dirname(root)
							oil.open(project_root)
						else
							vim.notify("No project root found", vim.log.levels.WARN)
						end
					end,
					desc = "Go to project root",
				},
				["gh"] = {
					callback = function()
						local oil = require("oil")
						oil.open(vim.fn.expand("~"))
					end,
					desc = "Go to home directory",
				},
				["gw"] = {
					callback = function()
						local oil = require("oil")
						oil.open(vim.fn.getcwd())
					end,
					desc = "Go to working directory",
				},

				-- Working directory
				["cd"] = "actions.cd",

				-- Sorting
				["gs"] = "actions.change_sort",

				-- Close
				["q"] = "actions.close",
			},
			-- Set to false to disable all of the above keymaps
			use_default_keymaps = true,
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = false,
				-- This function defines what is considered a "hidden" file
				is_hidden_file = function(name, bufnr)
					return vim.startswith(name, ".")
				end,
				-- This function defines what will never be shown, even when `show_hidden` is set
				is_always_hidden = function(name, bufnr)
					return false
				end,
				-- Sort file names in a more intuitive order for humans. Is less performant,
				-- so you can set to false if you prefer raw alphabetical order
				natural_order = true,
				sort = {
					-- sort order can be "asc" or "desc"
					-- see :help oil-columns to see which columns are sortable
					{ "type", "asc" },
					{ "name", "asc" },
				},
			},
			-- Extra arguments to pass to SCP when moving/copying files over SSH
			ssh = {
				scp_extra_args = {},
			},
			-- EXPERIMENTAL support for performing file operations with git
			git = {
				-- Return true to automatically git add/mv/rm files
				add = function(path)
					return false
				end,
				mv = function(src_path, dest_path)
					return false
				end,
				rm = function(path)
					return false
				end,
			},
			-- Configuration for the floating window in oil.open_float
			float = {
				-- Padding around the floating window
				padding = 2,
				max_width = 0,
				max_height = 0,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				-- preview_split: Split direction: "auto", "left", "right", "above", "below".
				preview_split = "auto",
				-- This is the config that will be passed to nvim_open_win.
				-- Change values here to customize the layout
				override = function(conf)
					return conf
				end,
			},
			-- Configuration for the actions floating preview window
			preview = {
				-- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				-- min_width and max_width can be a single value or a list of mixed integer/float types.
				max_width = 0.9,
				-- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
				min_width = { 40, 0.4 },
				-- optionally define an integer/float for the exact width of the preview window
				width = nil,
				-- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				max_height = 0.9,
				min_height = { 5, 0.1 },
				height = nil,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				-- Whether the preview window is automatically updated when the cursor is moved
				update_on_cursor_moved = true,
			},
			-- Configuration for the floating progress window
			progress = {
				max_width = 0.9,
				min_width = { 40, 0.4 },
				width = nil,
				max_height = { 10, 0.9 },
				min_height = { 5, 0.1 },
				height = nil,
				border = "rounded",
				minimalist = false,
				win_options = {
					winblend = 0,
				},
			},
			-- Configuration for the floating SSH window
			ssh = {
				border = "rounded",
			},
		})

		-- Clean Oil keymaps (no repetition)
		vim.keymap.set("n", "<C-n>", "<CMD>Oil<CR>", { desc = "Open current directory" })
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open current directory" })
		vim.keymap.set("n", "<leader>e", "<CMD>Oil --float<CR>", { desc = "Open directory (floating)" })

		-- Smart project navigation
		vim.keymap.set("n", "<leader>r", function()
			local oil = require("oil")
			-- Find project root
			local root_patterns = { ".git", "package.json", "Cargo.toml", "go.mod", "pyproject.toml", "Makefile" }
			local current_dir = vim.fn.expand("%:p:h")
			local root = vim.fs.find(root_patterns, { path = current_dir, upward = true })[1]
			if root then
				local project_root = vim.fs.dirname(root)
				oil.open(project_root)
			else
				vim.notify("No project root found", vim.log.levels.WARN)
			end
		end, { desc = "Open project root in Oil" })

		-- Directory of current file
		vim.keymap.set("n", "<leader>d", function()
			local oil = require("oil")
			local current_file = vim.fn.expand("%:p:h")
			oil.open(current_file)
		end, { desc = "Open directory of current file" })
	end,
}
