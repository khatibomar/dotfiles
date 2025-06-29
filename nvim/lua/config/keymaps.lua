require("config.keymaps.go-definition")

function OpenTmuxPopup()
	local cmd = "bash $HOME/scripts/toggle_tmux_popup.sh"
	vim.fn.system(cmd)
end

vim.keymap.set("n", "<leader>s", ":w<CR>", { noremap = true, silent = true, desc = "Save File" })
vim.keymap.set(
	"n",
	"<Leader>p",
	":lua OpenTmuxPopup()<CR>",
	{ noremap = true, silent = true, desc = "Toggle Tmux Popup" }
)
