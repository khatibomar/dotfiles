-- WhichKey navigation stack for definition tracking
local navigation_stack = {}
local current_tab_before_navigation = nil

-- Utility functions for tab management and navigation
function uri_to_filepath(uri)
	return vim.uri_to_fname(uri)
end

function find_tab_with_file(filepath)
	for i = 1, vim.fn.tabpagenr("$") do
		local buflist = vim.fn.tabpagebuflist(i)
		for _, bufnr in ipairs(buflist) do
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			if bufname == filepath then
				return i
			end
		end
	end
	return nil
end

function count_definition_tabs()
	local count = 0
	for i = 1, vim.fn.tabpagenr("$") do
		local tabinfo = vim.fn.gettabvar(i, "is_definition_tab")
		if tabinfo == 1 then
			count = count + 1
		end
	end
	return count
end

function go_to_definition_tab()
	-- Store current tab if not already navigating
	if current_tab_before_navigation == nil then
		current_tab_before_navigation = vim.fn.tabpagenr()
	end

	local current_position = vim.api.nvim_win_get_cursor(0)
	local current_file = vim.api.nvim_buf_get_name(0)

	table.insert(navigation_stack, {
		file = current_file,
		position = current_position,
		tab = vim.fn.tabpagenr(),
	})

	local params = vim.lsp.util.make_position_params()
	local results = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 1000)

	if not results or vim.tbl_isempty(results) then
		print("No definition found")
		return
	end

	for client_id, result in pairs(results) do
		if result.result and not vim.tbl_isempty(result.result) then
			local definition = result.result[1]
			local target_file = uri_to_filepath(definition.uri)

			-- Check if file is already open in a tab
			local existing_tab = find_tab_with_file(target_file)

			if existing_tab then
				vim.cmd("tabnext " .. existing_tab)
			else
				vim.cmd("tabnew " .. target_file)
				vim.t.is_definition_tab = 1
			end

			local target_line = definition.range.start.line + 1
			local target_col = definition.range.start.character
			vim.api.nvim_win_set_cursor(0, { target_line, target_col })
			break
		end
	end
end

function close_tabs_and_return()
	if current_tab_before_navigation == nil then
		print("No navigation history")
		return
	end

	-- Close all definition tabs
	local tabs_to_close = {}
	for i = vim.fn.tabpagenr("$"), 1, -1 do
		if vim.fn.gettabvar(i, "is_definition_tab") == 1 then
			table.insert(tabs_to_close, i)
		end
	end

	for _, tab in ipairs(tabs_to_close) do
		vim.cmd("tabclose " .. tab)
	end

	-- Return to original tab and position
	if current_tab_before_navigation <= vim.fn.tabpagenr("$") then
		vim.cmd("tabnext " .. current_tab_before_navigation)
	end

	-- Restore original position if possible
	if #navigation_stack > 0 then
		local original = navigation_stack[1]
		if vim.fn.bufexists(original.file) == 1 then
			vim.cmd("edit " .. original.file)
			vim.api.nvim_win_set_cursor(0, original.position)
		end
	end

	cleanup_navigation_stack()
end

function cleanup_navigation_stack()
	navigation_stack = {}
	current_tab_before_navigation = nil
end

function show_navigation_info()
	local def_count = count_definition_tabs()
	local stack_size = #navigation_stack
	print(string.format("Definition tabs: %d, Navigation stack: %d", def_count, stack_size))

	if current_tab_before_navigation then
		print("Original tab: " .. current_tab_before_navigation)
	end
end

-- Tmux popup integration
function OpenTmuxPopup()
	vim.fn.system("bash $HOME/scripts/toggle_tmux_popup.sh")
end

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {
		preset = "classic",
		delay = 300,
		spec = {
			-- Core file operations
			{ "<leader><leader>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search Buffer" },
			{ "<leader>s", ":w<CR>", desc = "Save File" },
			{
				"<leader>q",
				function()
					close_tabs_and_return()
				end,
				desc = "Close Definition Tabs",
			},
			{
				"<leader>p",
				function()
					OpenTmuxPopup()
				end,
				desc = "Tmux Popup",
			},

			-- AI/Copilot
			{ "<leader>a", group = "AI/Copilot" },
			{ "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code" },
			{ "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "Generate Tests" },
			{ "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "Review Code" },
			{ "<leader>aR", "<cmd>CopilotChatRefactor<cr>", desc = "Refactor Code" },
			{ "<leader>an", "<cmd>CopilotChatBetterNamings<cr>", desc = "Better Naming" },
			{ "<leader>av", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Chat" },
			{ "<leader>am", "<cmd>CopilotChatCommit<cr>", desc = "Generate Commit" },
			{ "<leader>af", "<cmd>CopilotChatFix<cr>", desc = "Fix Diagnostic" },

			-- Buffer operations
			{ "<leader>b", group = "Buffers" },
			{ "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete Buffer" },
			{ "<leader>bn", "<cmd>bnext<cr>", desc = "Next Buffer" },
			{ "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous Buffer" },

			-- Code operations
			{ "<leader>c", group = "Code Analysis & Navigation" },
			{ "<leader>ca", desc = "Code Action" },
			{
				"<leader>cr",
				function()
					return ":IncRename " .. vim.fn.expand("<cword>")
				end,
				expr = true,
				desc = "Rename Symbol (inc-rename)",
			},
			{ "<leader>cf", "<cmd>lua vim.lsp.buf.format()<cr>", desc = "Format Code" },
			{ "<leader>cd", "<cmd>Glance definitions<cr>", desc = "Peek Definitions" },
			{ "<leader>cD", "<cmd>Glance type_definitions<cr>", desc = "Peek Type Definitions" },
			{ "<leader>ci", "<cmd>Glance implementations<cr>", desc = "Peek Implementations" },
			{ "<leader>cR", "<cmd>Glance references<cr>", desc = "Peek References" },
			{ "<leader>cs", desc = "Document Symbols (handled in trouble config)" },

			-- Diagnostics & Trouble
			{ "<leader>d", group = "Diagnostics & Issues" },
			{ "<leader>dt", desc = "Project Diagnostics (All Files)" },
			{ "<leader>dl", desc = "Current Buffer Diagnostics" },
			{ "<leader>dw", desc = "Project Warnings Only" },
			{ "<leader>de", desc = "Project Errors Only" },
			{ "<leader>ds", desc = "Document Symbols" },
			{ "<leader>dr", desc = "LSP References & Definitions" },
			{ "<leader>dL", desc = "Location List" },
			{ "<leader>dQ", desc = "Quickfix List" },
			{ "<leader>dn", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "Next Diagnostic" },
			{ "<leader>dp", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "Previous Diagnostic" },
			{ "<leader>df", "<cmd>lua vim.diagnostic.open_float()<cr>", desc = "Show Diagnostic Details" },

			-- Go development
			{ "<leader>g", group = "Go" },
			{ "<leader>gd", vim.lsp.buf.definition, desc = "Go to Definition" },
			{ "<leader>gr", vim.lsp.buf.references, desc = "Find References" },
			{ "<leader>gi", vim.lsp.buf.implementation, desc = "Go to Implementation" },
			{ "<leader>gf", vim.lsp.buf.format, desc = "Format Code" },

			-- Git operations
			{ "<leader>G", group = "Git" },
			{ "<leader>Gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
			{ "<leader>Gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },

			-- Find/Search
			{ "<leader>f", group = "Find" },
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
			{ "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },

			-- Jump operations
			{ "<leader>j", group = "Jump" },
			{ "<leader>je", "'.", desc = "Last Edit" },
			{ "<leader>ji", "'^", desc = "Last Insert" },
			{ "<leader>jb", "<C-o>", desc = "Jump Back" },
			{ "<leader>jf", "<C-i>", desc = "Jump Forward" },
			{ "<leader>jl", "``", desc = "Last Position" },
			{ "<leader>ja", "<C-^>", desc = "Alternate Buffer" },
			{
				"<leader>jn",
				function()
					show_navigation_info()
				end,
				desc = "Navigation Info",
			},

			-- Toggle operations
			{ "<leader>t", group = "Toggle" },
			{ "<leader>tn", desc = "Toggle Notes (Maple)" },
			{
				"<leader>tw",
				"<cmd>set wrap!<cr>",
				desc = "Word Wrap",
			},
			{
				"<leader>ts",
				"<cmd>set spell!<cr>",
				desc = "Spell Check",
			},
			{
				"<leader>th",
				"<cmd>set hlsearch!<cr>",
				desc = "Highlight Search",
			},

			-- Window operations
			{ "<leader>w", group = "Windows" },
			{
				"<leader>wh",
				"<C-w>h",
				desc = "Move Left",
			},
			{
				"<leader>wj",
				"<C-w>j",
				desc = "Move Down",
			},
			{ "<leader>wk", "<C-w>k", desc = "Move Up" },
			{
				"<leader>wl",
				"<C-w>l",
				desc = "Move Right",
			},
			{
				"<leader>ws",
				"<C-w>s",
				desc = "Split Horizontal",
			},
			{
				"<leader>wv",
				"<C-w>v",
				desc = "Split Vertical",
			},
			{
				"<leader>wc",
				"<C-w>c",
				desc = "Close Window",
			},

			-- Refactoring & Code Transformation
			{ "<leader>r", group = "Refactoring & Code Transform" },
			{ "<leader>re", desc = "Extract Function", mode = "v" },
			{ "<leader>rf", desc = "Extract to File", mode = "v" },
			{ "<leader>rv", desc = "Extract Variable", mode = "v" },
			{
				"<leader>ri",
				desc = "Inline Variable",
				mode = { "n", "v" },
			},
			{ "<leader>rb", desc = "Extract Block", mode = "n" },
			{ "<leader>rB", desc = "Extract Block to File", mode = "n" },
			{ "<leader>rp", desc = "Insert Debug Print", mode = "n" },
			{
				"<leader>rP",
				desc = "Debug Print Variable",
				mode = { "n", "v" },
			},
			{ "<leader>rc", desc = "Clean Debug Prints", mode = "n" },
			{
				"<leader>rs",
				desc = "Refactoring Menu",
				mode = { "n", "v" },
			},

			-- Search & Replace (Global)
			{ "<leader>S", group = "Search & Replace (Global)" },
			{
				"<leader>Ss",
				function()
					require("spectre").toggle()
				end,
				desc = "Open Spectre (Global Find/Replace)",
			},
			{
				"<leader>Sw",
				"<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
				desc = "Search Current Word (Project)",
				mode = "n",
			},
			{
				"<leader>Sw",
				"<cmd>lua require('spectre').open_visual()<cr>",
				desc = "Search Current Word (Project)",
				mode = "v",
			},
			{
				"<leader>Sp",
				"<cmd>lua require('spectre').open_file_search({select_word=true})<cr>",
				desc = "Search in Current File Only",
			},
			{
				"<leader>Sc",
				"<cmd>lua require('spectre.actions').run_current_replace()<cr>",
				desc = "Replace Current Line",
			},

			-- Special keys
			{ "<leader>m", desc = "Toggle Go Struct View" },
		},
		icons = {
			breadcrumb = "»",
			separator = "➜",
			group = "+",
		},
		win = {
			border = "single",
			padding = { 1, 1 },
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		-- Global non-leader mappings
		wk.add({
			{
				"gd",
				function()
					go_to_definition_tab()
				end,
				desc = "Go to Definition (Tab)",
			},
			{ "K", desc = "Hover Documentation" },
			{ "<C-n>", desc = "Toggle File Explorer" },
			{ "'.", desc = "Jump to Last Edit" },
			{ "``", desc = "Jump to Last Position" },
			{ "<C-o>", desc = "Jump Back" },
			{ "<C-i>", desc = "Jump Forward" },
		})

		-- Go-specific mappings (cleaned up - no unused go.nvim commands)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "go",
			callback = function()
				wk.add({
					-- Struct viewer mappings only
					{ "H", desc = "Toggle Methods Visibility", buffer = true },
					{ "<CR>", desc = "Jump to Symbol", buffer = true },
					{ "\\f", desc = "Center Symbol", buffer = true },
					{ "\\z", desc = "Fold Toggle", buffer = true },
					{ "R", desc = "Refresh Symbols", buffer = true },
					{ "P", desc = "Preview Open", buffer = true },
					{ "\\p", desc = "Preview Close", buffer = true },
				})
			end,
		})

		-- Copilot Chat buffer mappings
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "copilot-chat",
			callback = function()
				wk.add({
					{ "q", desc = "Close Chat", buffer = true },
					{ "<C-c>", desc = "Close Chat", buffer = true, mode = "i" },
					{ "<CR>", desc = "Submit Prompt", buffer = true },
					{ "<C-y>", desc = "Accept Diff", buffer = true },
				})
			end,
		})
	end,
}
