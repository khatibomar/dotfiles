return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")
		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

		null_ls.setup({
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format()
						end,
					})
				end
			end,
			sources = {
				-- Lua formatting
				null_ls.builtins.formatting.stylua,

				-- Go support with gopls for imports, formatting, and code actions
				null_ls.builtins.formatting.gofumpt,
				null_ls.builtins.code_actions.gomodifytags,
				null_ls.builtins.code_actions.impl,
				null_ls.builtins.diagnostics.golangci_lint,
				null_ls.builtins.diagnostics.staticcheck,
				null_ls.builtins.formatting.goimports_reviser,

				-- Bash support
				null_ls.builtins.formatting.shfmt, -- for Bash formatting
				null_ls.builtins.diagnostics.shellcheck, -- for Bash linting

				-- C support
				null_ls.builtins.formatting.clang_format,
				null_ls.builtins.diagnostics.cppcheck,
			},
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
