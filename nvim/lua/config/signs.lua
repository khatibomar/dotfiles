local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Define unified styles for LSP and Neo-tree
local unified_styles = {
	default = {
		icons = {
			folder_closed = "", -- Default closed folder
			folder_open = "", -- Default open folder
			file = "", -- Default file icon
			symlink = "", -- Default symlink icon
		},
		diagnostics = {
			Error = "󰅚", -- Cross mark
			Warn = "󰀪", -- Warning symbol
			Hint = "󰌶", -- Hint icon
			Info = "󰋼", -- Info icon
			Deprecated = "", -- Strikethrough or prohibition
			Trace = "󰎝", -- Trace (debugging or log trace icon)
		},
	},
	geometric = {
		icons = {
			folder_closed = "◆", -- Geometric closed folder
			folder_open = "◇", -- Geometric open folder
			file = "▸", -- Geometric file icon
			symlink = "➤", -- Geometric symlink icon
		},
		diagnostics = {
			Error = "◆", -- Diamond
			Warn = "▲", -- Triangle
			Hint = "●", -- Dot
			Info = "◈", -- Diamond
			Deprecated = "⬦", -- Hollow diamond
			Trace = "⬤", -- Filled circle
		},
	},
	expressive = {
		icons = {
			folder_closed = "📁", -- Emoji closed folder
			folder_open = "📂", -- Emoji open folder
			file = "📄", -- Emoji file icon
			symlink = "🔗", -- Emoji symlink icon
		},
		diagnostics = {
			Error = "✗", -- Bold X
			Warn = "⚡", -- Lightning
			Hint = "💡", -- Light bulb
			Info = "ℹ", -- Info
			Deprecated = "❌", -- Cross mark
			Trace = "🐞", -- Bug icon
		},
	},
	playful = {
		icons = {
			folder_closed = "😎", -- Fun closed folder
			folder_open = "🤩", -- Fun open folder
			file = "🎵", -- Fun file icon
			symlink = "🌀", -- Fun symlink icon
		},
		diagnostics = {
			Error = "😡", -- Angry emoji
			Warn = "⚠️", -- Warning sign
			Hint = "🤔", -- Thinking emoji
			Info = "💬", -- Speech bubble
			Deprecated = "👎", -- Thumbs down
			Trace = "🔍", -- Magnifying glass
		},
	},
}

-- Get the config directory path
local function get_config_dir()
	local config_dir = vim.fn.stdpath("config")
	return config_dir
end

-- Get the path for storing the style preference
local function get_style_file_path()
	return get_config_dir() .. "/diagnostic_style.txt"
end

-- Save the selected style to a file
local function save_style(style_name)
	local file = io.open(get_style_file_path(), "w")
	if file then
		file:write(style_name)
		file:close()
	end
end

-- Load the saved style
local function load_saved_style()
	local file = io.open(get_style_file_path(), "r")
	if file then
		local style = file:read("*all")
		file:close()
		return style
	end
	return "default" -- fallback to default if no saved style
end

-- Apply LSP diagnostic signs
local function apply_lsp_diagnostic_signs(diagnostics)
	for type, icon in pairs(diagnostics) do
		local hl = "DiagnosticSign" .. type
		vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
	end
end

-- Apply Neo-tree styles
local function apply_neotree_styles(style)
	require("neo-tree").setup({
		default_component_configs = {
			icon = {
				folder_closed = style.icons.folder_closed,
				folder_open = style.icons.folder_open,
				file = style.icons.file,
				symlink = style.icons.symlink,
			},
			diagnostics = {
				symbols = {
					error = style.diagnostics.Error,
					warn = style.diagnostics.Warn,
					hint = style.diagnostics.Hint,
					info = style.diagnostics.Info,
					deprecated = style.diagnostics.Deprecated,
					trace = style.diagnostics.Trace,
				},
			},
		},
	})
end

-- Unified function to apply a style for both LSP and Neo-tree
local function apply_unified_style(style_name)
	local style = unified_styles[style_name]
	if not style then
		return
	end
	apply_lsp_diagnostic_signs(style.diagnostics)
	apply_neotree_styles(style)
	save_style(style_name)
end

local change_diagnostic_style = function(opts)
	opts = opts or {}

	local targets = {
		"default",
		"geometric",
		"expressive",
		"playful",
	}

	pickers
		.new(opts, {
			prompt_title = "Change Diagnostic Style",
			finder = finders.new_table({
				results = targets,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					apply_unified_style(selection[1])
				end)
				return true
			end,
		})
		:find()
end

-- Apply the default style on startup (choose one)
local saved_style = load_saved_style()
apply_unified_style(saved_style)

-- Register the command to change the diagnostic style
vim.api.nvim_create_user_command("ChangeDiagnosticStyle", change_diagnostic_style, {})
return require("telescope").register_extension({
	exports = {
		change_diagnostic_style = change_diagnostic_style,
	},
})
