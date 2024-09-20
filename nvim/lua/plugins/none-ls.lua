return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        -- Lua formatting
        null_ls.builtins.formatting.stylua,

        -- Go formatting
        null_ls.builtins.formatting.gofmt,     -- for formatting with gofmt
        null_ls.builtins.formatting.goimports, -- for formatting with goimports

        -- Go linting
        null_ls.builtins.diagnostics.golangci_lint.with({
            command = "golangci-lint", -- adjust the command path if necessary
        }),
      },
    })

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
    vim.cmd([[autocmd BufWritePre *.go lua vim.lsp.buf.format()]])
  end,
}
