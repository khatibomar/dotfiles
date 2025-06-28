local M = {}

function M.branch()
	local h = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
	if not h then
		return ""
	end
	local b = h:read("*a"):gsub("%s+$", "")
	h:close()
	return b ~= "" and " " .. b or ""
end

function M.setup()
	_G.branch = M.branch
	vim.o.statusline = "%f %h%m%r %=%{v:lua.branch()} %l:%c"
end

return M
