return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
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
        null_ls.builtins.formatting.shfmt,   -- for Bash formatting
        null_ls.builtins.diagnostics.shellcheck, -- for Bash linting
      },
    })

    -- Automatically format and fix imports on save for Go files
    vim.cmd([[autocmd BufWritePre *.go lua vim.lsp.buf.format()]])
    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}

