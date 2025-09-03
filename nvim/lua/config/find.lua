function _G.FuzzyFindFunc(cmdarg)
	cmdarg = cmdarg or ""

	local cmd = string.format("fd --hidden --type f . | fzf --filter=%q", cmdarg)
	return vim.fn.systemlist(cmd)
end

vim.o.findfunc = "v:lua.FuzzyFindFunc"
