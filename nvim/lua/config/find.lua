-- https://github.com/kristijanhusak/neovim-config/blob/431e64822eb40ef6563177a501e143c401ffe442/nvim/after/plugin/find.lua
local function get_filenames()
  local exec = {
    name = "fd",
    cmd = { "fd", "--type", "file", "--follow" },
  }

  local result = vim.system(exec.cmd, { text = false }):wait()
  if result and result.code == 0 then
    return vim.split(result.stdout, "\n")
  end

  return vim.fn.glob("**", false, true)
end

local function complete(arg_lead)
  local files = get_filenames()

  if vim.trim(arg_lead or "") == "" then
    return files
  end
  return vim.fn.matchfuzzy(files, arg_lead)
end

_G.ayn = _G.ayn or {}
_G.ayn.findfunc = function(cmd_arg)
  return complete(cmd_arg)
end
vim.o.findfunc = "v:lua.ayn.findfunc"
