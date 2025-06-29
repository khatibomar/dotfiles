-- Store the original tab and a list of spawned tabs
local original_tab = nil
local spawned_tabs = {}

-- Function to go to definition in a new tab
local function go_to_definition_tab()
	-- Store the original tab page if it hasn't been set
	if not original_tab then
		original_tab = vim.api.nvim_get_current_tabpage()
	end
	local params = vim.lsp.util.make_position_params(0, "utf-8")
	vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
		if err or not result or vim.tbl_isempty(result) then
			vim.notify("Definition not found or LSP error.")
			return
		end

		-- Open a new tab
		vim.cmd("tabnew")

		-- Track the new tab ID
		local new_tab = vim.api.nvim_get_current_tabpage()
		table.insert(spawned_tabs, new_tab)

		-- Jump to the first valid location
		for _, loc in ipairs(result) do
			if loc and loc.uri and loc.range then
				vim.lsp.util.show_document(loc, "utf-8", { focus = true })
				return
			end
		end

		-- Close the tab if no valid location is found
		vim.notify("No valid definition location found.")
		vim.cmd("tabclose")
	end)
end

-- Function to close all spawned tabs and return to the original tab
local function close_tabs_and_return()
	-- Close each spawned tab
	for _, tab in ipairs(spawned_tabs) do
		if vim.api.nvim_tabpage_is_valid(tab) then
			vim.api.nvim_set_current_tabpage(tab) -- Switch to the tab
			vim.cmd("tabclose") -- Close the current tab
		end
	end

	-- Return to the original tab if it's valid
	if original_tab and vim.api.nvim_tabpage_is_valid(original_tab) then
		vim.api.nvim_set_current_tabpage(original_tab)
	end

	-- Reset the original tab and spawned tabs
	original_tab = nil
	spawned_tabs = {}
	vim.cmd("redraw")
end

-- Keymap to go to definition in a new tab
vim.keymap.set("n", "gd", go_to_definition_tab, { noremap = true, silent = true, desc = "Go to Definition (New Tab)" })

-- Keymap to close all tabs and return to the original tab
vim.keymap.set("n", "<leader>q", close_tabs_and_return, { noremap = true, silent = true, desc = "Close Tabs & Return" })
