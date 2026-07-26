function _G.FuzzyFindFunc(ArgLead)
	local query = ArgLead or ""

	-- 1. fd: include hidden but exclude noisy directories, and clean the paths
	local fd_cmd = "fd --hidden --type f --exclude .git --exclude node_modules --strip-cwd-prefix"
	
	-- 2. fzf: filter the results, and tiebreak to prioritize filename matches and shorter paths
	local fzf_cmd = string.format("fzf --filter=%q --tiebreak=end,length", query)
	
	local cmd = fd_cmd .. " | " .. fzf_cmd
	return vim.fn.systemlist(cmd)
end

-- Fallback for native find (though we override the command below)
vim.o.findfunc = "v:lua.FuzzyFindFunc"

-- Custom Find command that populates quickfix list on multiple matches
vim.api.nvim_create_user_command("Find", function(opts)
	local query = opts.args
	
	-- If it's an exact file path that exists, just open it
	if vim.fn.filereadable(query) == 1 then
		vim.cmd("edit " .. vim.fn.fnameescape(query))
		return
	end

	-- Fuzzy search using fd and fzf
	local fd_cmd = "fd --hidden --type f --exclude .git --exclude node_modules --strip-cwd-prefix"
	local fzf_cmd = string.format("fzf --filter=%q --tiebreak=end,length", query)
	local cmd = fd_cmd .. " | " .. fzf_cmd
	
	local results = vim.fn.systemlist(cmd)
	
	if #results == 0 then
		vim.notify("No files found matching: " .. query, vim.log.levels.WARN)
		return
	end
	
	if #results == 1 then
		-- Exactly one match, open it directly
		vim.cmd("edit " .. vim.fn.fnameescape(results[1]))
	else
		-- Multiple matches, populate quickfix
		local qf_list = {}
		for _, file in ipairs(results) do
			table.insert(qf_list, { filename = file, text = file })
		end
		
		vim.fn.setqflist({}, " ", {
			title = "Find: " .. query,
			items = qf_list
		})
		
		vim.cmd("copen")
	end
end, { nargs = "?", complete = "customlist,v:lua.FuzzyFindFunc" })

-- Override lowercase :find to use our custom :Find command
vim.cmd([[cnoreabbrev <expr> find (getcmdtype() == ':' && getcmdline() ==# 'find') ? 'Find' : 'find']])
