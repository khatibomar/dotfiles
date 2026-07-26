-- Custom Grep command that uses ripgrep and populates quickfix
vim.api.nvim_create_user_command("Grep", function(opts)
	local query = opts.args
	if query == "" then
		vim.notify("Grep requires a query string", vim.log.levels.WARN)
		return
	end

	-- Run ripgrep with vimgrep output format
	local cmd = "rg --vimgrep --smart-case --hidden --trim --no-heading --color=never " .. query
	local results = vim.fn.systemlist(cmd)

	if #results == 0 then
		vim.notify("No matches found for: " .. query, vim.log.levels.WARN)
		return
	end

	if #results == 1 then
		-- Exactly one match, jump directly
		local file, line, col = results[1]:match("^(.-):(%d+):(%d+):")
		if file then
			vim.cmd("edit " .. vim.fn.fnameescape(file))
			vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) - 1 })
		else
			-- Fallback
			vim.notify("Found one match, but couldn't parse line: " .. results[1], vim.log.levels.WARN)
		end
	else
		-- Multiple matches, populate quickfix
		local qf_list = {}
		for _, result in ipairs(results) do
			local file, line, col, text = result:match("^(.-):(%d+):(%d+):(.*)$")
			if file then
				table.insert(qf_list, {
					filename = file,
					lnum = tonumber(line),
					col = tonumber(col),
					text = text
				})
			end
		end

		vim.fn.setqflist({}, " ", {
			title = "Grep: " .. query,
			items = qf_list
		})

		vim.cmd("copen")
	end
end, { nargs = "+", complete = "file" })

-- Override lowercase :grep to use our custom :Grep command
vim.cmd([[cnoreabbrev <expr> grep (getcmdtype() == ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep']])
