return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern",
		delay = 200,
		expand = 1,
		notify = false,
		triggers = {
			{ "<auto>", mode = "nxsot" },
		},
		spec = {
			-- Hide certain keys from showing in which-key
			{ "<leader>w", hidden = true }, -- Don't show window commands individually
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		-- Register leader key mappings with proper grouping
		wk.add({
			-- File operations
			{ "<leader><leader>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search Buffer" },
			{ "<leader>s", ":w<CR>", desc = "Save File" },
			{ "<leader>p", ":lua OpenTmuxPopup()<CR>", desc = "Toggle Tmux Popup" },
			{ "<leader>q", desc = "Close Tabs & Return" },

			-- AI/Copilot operations
			{ "<leader>a", group = "AI/Copilot", mode = { "n", "v" } },
			{ "<leader>ai", desc = "Ask Copilot Input" },
			{ "<leader>ap", desc = "Copilot Prompt Actions" },
			{ "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code" },
			{ "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "Generate Tests" },
			{ "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "Review Code" },
			{ "<leader>aR", "<cmd>CopilotChatRefactor<cr>", desc = "Refactor Code" },
			{ "<leader>an", "<cmd>CopilotChatBetterNamings<cr>", desc = "Better Naming" },
			{ "<leader>av", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
			{ "<leader>ax", desc = "Inline Chat" },
			{ "<leader>am", "<cmd>CopilotChatCommit<cr>", desc = "Generate Commit Message" },
			{ "<leader>aq", desc = "Quick Chat" },
			{ "<leader>ad", "<cmd>CopilotChatDebugInfo<cr>", desc = "Debug Info" },
			{ "<leader>af", "<cmd>CopilotChatFix<cr>", desc = "Fix Diagnostic" },
			{ "<leader>al", "<cmd>CopilotChatReset<cr>", desc = "Clear Chat History" },
			{ "<leader>a?", "<cmd>CopilotChatModels<cr>", desc = "Select Models" },

			-- Buffer operations
			{ "<leader>b", group = "Buffers" },
			{ "<leader>bf", "<cmd>Neotree buffers reveal float<cr>", desc = "Buffer Explorer" },
			{ "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete Buffer" },
			{ "<leader>bn", "<cmd>bnext<cr>", desc = "Next Buffer" },
			{ "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous Buffer" },

			-- Code operations
			{ "<leader>c", group = "Code" },
			{ "<leader>ca", desc = "Code Action" },
			{ "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename Symbol" },
			{ "<leader>cf", "<cmd>lua vim.lsp.buf.format()<cr>", desc = "Format Code" },

			-- Git operations
			{ "<leader>g", group = "Git/Go" },
			{ "<leader>gd", desc = "Go to Definition" },
			{ "<leader>gr", desc = "Go to References" },
			{ "<leader>gf", desc = "Format Code" },
			{ "<leader>gs", "<cmd>Neotree git_status<cr>", desc = "Git Status" },
			{ "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
			{ "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },

			-- Search/List operations
			{ "<leader>l", group = "List/Search" },
			{ "<leader>lb", "<cmd>Telescope buffers<cr>", desc = "List Buffers" },
			{ "<leader>lg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>ld", "<cmd>Telescope diagnostics<cr>", desc = "List Diagnostics" },
			{ "<leader>lh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
			{ "<leader>lk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
			{ "<leader>lm", "<cmd>Telescope marks<cr>", desc = "Marks" },
			{ "<leader>lr", "<cmd>Telescope registers<cr>", desc = "Registers" },

			-- Recent files
			{ "<leader>r", group = "Recent" },
			{ "<leader>rf", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },

			-- Toggle operations
			{ "<leader>t", group = "Toggle" },
			{ "<leader>tn", desc = "Toggle Notes (Maple)" },
			{ "<leader>tw", "<cmd>set wrap!<cr>", desc = "Toggle Word Wrap" },
			{ "<leader>ts", "<cmd>set spell!<cr>", desc = "Toggle Spell Check" },
			{ "<leader>th", "<cmd>set hlsearch!<cr>", desc = "Toggle Highlight Search" },

			-- Window operations (grouped but minimal display)
			{ "<leader>w", group = "Windows" },
			{ "<leader>wh", "<C-w>h", desc = "Move Left" },
			{ "<leader>wj", "<C-w>j", desc = "Move Down" },
			{ "<leader>wk", "<C-w>k", desc = "Move Up" },
			{ "<leader>wl", "<C-w>l", desc = "Move Right" },
			{ "<leader>ws", "<C-w>s", desc = "Split Horizontal" },
			{ "<leader>wv", "<C-w>v", desc = "Split Vertical" },
			{ "<leader>wc", "<C-w>c", desc = "Close Window" },
			{ "<leader>wo", "<C-w>o", desc = "Close Others" },

			-- Debug/Diagnostics
			{ "<leader>d", group = "Debug/Diagnostics" },
			{ "<leader>dt", "<cmd>Telescope diagnostics<cr>", desc = "Show Diagnostics" },
			{
				"<leader>dl",
				"<cmd>lua vim.diagnostic.setloclist()<cr>",
				desc = "Diagnostics to Location List",
			},
			{ "<leader>dn", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "Next Diagnostic" },
			{ "<leader>dp", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "Previous Diagnostic" },

			-- Special keys
			{ "<leader>m", desc = "Toggle Go Struct" },
			{ "<leader>?", desc = "Buffer Local Keymaps" },
		})

		-- Register non-leader key mappings
		wk.add({
			{ "gd", desc = "Go to Definition (New Tab)" },
			{ "K", desc = "Hover Documentation" },
			{ "<C-n>", desc = "Toggle File Explorer" },
		})

		-- Register Copilot Chat-specific mappings
		wk.add({
			{ "gm", group = "Copilot Chat" },
			{ "gmh", desc = "Show Help" },
			{ "gmd", desc = "Show Diff" },
			{ "gmp", desc = "Show System Prompt" },
			{ "gms", desc = "Show Selection" },
			{ "gmy", desc = "Yank Diff" },
		})

		-- Register visual mode specific mappings for Copilot
		wk.add({
			{ "<leader>a", group = "AI/Copilot", mode = "v" },
			{ "<leader>ap", desc = "Prompt Actions", mode = "v" },
			{ "<leader>av", ":CopilotChatVisual", desc = "Visual Chat", mode = "v" },
			{ "<leader>ax", ":CopilotChatInline<cr>", desc = "Inline Chat", mode = "v" },
			{ "<leader>ae", desc = "Explain Selection", mode = "v" },
			{ "<leader>at", desc = "Generate Tests", mode = "v" },
			{ "<leader>ar", desc = "Review Selection", mode = "v" },
			{ "<leader>aR", desc = "Refactor Selection", mode = "v" },
			{ "<leader>an", desc = "Better Naming", mode = "v" },
		})

		-- Register go-specific mappings when in go files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "go",
			callback = function()
				wk.add({
					{ "<leader>g", group = "Git/Go", buffer = true },
					{ "<leader>gi", "<cmd>GoImport<cr>", desc = "Go Import", buffer = true },
					{ "<leader>gt", "<cmd>GoTest<cr>", desc = "Go Test", buffer = true },
					{ "<leader>gT", "<cmd>GoTestFunc<cr>", desc = "Go Test Function", buffer = true },
					{ "H", desc = "Toggle Go Methods Visibility", buffer = true },
					{ "<CR>", desc = "Jump to Symbol", buffer = true },
					{ "\\f", desc = "Center Symbol", buffer = true },
					{ "\\z", desc = "Fold Toggle", buffer = true },
					{ "R", desc = "Refresh Symbols", buffer = true },
					{ "P", desc = "Preview Open", buffer = true },
					{ "\\p", desc = "Preview Close", buffer = true },
				})
			end,
		})

		-- Register lua-specific mappings when in lua files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "lua",
			callback = function()
				wk.add({
					{ "<leader>c", group = "Code", buffer = true },
					{ "<leader>cr", "<cmd>luafile %<cr>", desc = "Run Lua File", buffer = true },
				})
			end,
		})

		-- Register mappings for Copilot Chat buffer
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "copilot-chat",
			callback = function()
				wk.add({
					{ "q", desc = "Close Chat", buffer = true },
					{ "<C-c>", desc = "Close Chat (Insert)", buffer = true, mode = "i" },
					{ "<C-x>", desc = "Reset Chat", buffer = true },
					{ "<C-x>", desc = "Reset Chat (Insert)", buffer = true, mode = "i" },
					{ "<CR>", desc = "Submit Prompt", buffer = true },
					{ "<C-CR>", desc = "Submit (Insert)", buffer = true, mode = "i" },
					{ "<C-y>", desc = "Accept Diff", buffer = true },
					{ "<C-y>", desc = "Accept Diff (Insert)", buffer = true, mode = "i" },
					{ "<Tab>", desc = "Complete", buffer = true, mode = "i" },
				})
			end,
		})

		-- Register mappings for Maple notes buffer
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "maple",
			callback = function()
				wk.add({
					{ "q", desc = "Close Maple", buffer = true },
					{ "m", desc = "Switch Mode", buffer = true },
				})
			end,
		})
	end,
}
