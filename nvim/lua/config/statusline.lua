local M = {}
local branch_cache = ""

function M.update_branch()
	vim.fn.jobstart({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and data[1] and data[1] ~= "" and not data[1]:match("fatal:") then
				branch_cache = " " .. data[1]
			else
				branch_cache = ""
			end
		end,
	})
end

function M.branch()
	return branch_cache
end

function M.setup()
	_G.branch = M.branch
	vim.o.statusline = "%f %h%m%r %=%{v:lua.branch()} %l:%c"

	local group = vim.api.nvim_create_augroup("StatusLineGit", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, {
		group = group,
		callback = function()
			M.update_branch()
		end,
	})

	M.update_branch()
end

return M
