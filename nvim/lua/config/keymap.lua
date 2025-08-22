local opts = { noremap = true, silent = true }
local k = vim.keymap

k.set("n", "<leader>s", ":w<CR>", opts) -- save

-- tmux
function OpenTmuxPopup()
  vim.fn.system("bash $HOME/scripts/toggle_tmux_popup.sh")
end

k.set("n", "<leader>p", function()
  OpenTmuxPopup()
end, opts)

-- diagnostic
local function diagnostics_to_qf()
  local diagnostics = vim.diagnostic.get() -- get all diagnostics
  local qf = vim.diagnostic.toqflist(diagnostics)
  vim.fn.setqflist({}, " ", { title = "Diagnostics", items = qf })
  vim.cmd("copen")
end

k.set("n", "<leader>df", "<cmd>lua vim.diagnostic.open_float()<cr>", opts)
k.set("n", "<leader>dn", "<cmd>lua vim.diagnostic.goto_next()<cr>", opts)
k.set("n", "<leader>dp", "<cmd>lua vim.diagnostic.goto_prev()<cr>", opts)
k.set("n", "<leader>dl", diagnostics_to_qf, vim.tbl_extend("force", opts, { desc = "Send diagnostics to quickfix" }))

-- go to
k.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
k.set("n", "<leader>gr", vim.lsp.buf.references, opts)
k.set("n", "<leader>gi", vim.lsp.buf.implementation, opts)

-- jumps
k.set("n", "<leader>je", "'.", vim.tbl_extend("force", opts, { desc = "Last Edit" }))
k.set("n", "<leader>ji", "'^", vim.tbl_extend("force", opts, { desc = "Last Insert" }))
k.set("n", "<leader>jb", "<C-o>", vim.tbl_extend("force", opts, { desc = "Jump Back" }))
k.set("n", "<leader>jf", "<C-i>", vim.tbl_extend("force", opts, { desc = "Jump Forward" }))
k.set("n", "<leader>jl", "``", vim.tbl_extend("force", opts, { desc = "Last Position" }))
k.set("n", "<leader>ja", "<C-^>", vim.tbl_extend("force", opts, { desc = "Alternate Buffer" }))
