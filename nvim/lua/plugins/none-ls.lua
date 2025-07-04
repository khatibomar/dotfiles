return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")
        local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

        -- Create a custom source for fieldalignment
        local fieldalignment_source = {
            name = "fieldalignment",
            method = null_ls.methods.CODE_ACTION,
            filetypes = { "go" },
            generator = {
                fn = function(params)
                    return {
                        {
                            title = "fieldalignment: Fix struct padding",
                            action = function()
                                local file_path = params.bufname
                                vim.cmd("write") -- Save before running
                                vim.fn.jobstart({ "fieldalignment", "-fix", file_path }, {
                                    on_exit = function()
                                        vim.cmd("edit")
                                    end,
                                })
                            end,
                        },
                    }
                end,
            },
        }

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
                vim.api.nvim_create_autocmd("BufWritePre", {
                    pattern = "*.go",
                    callback = function()
                        local params = vim.lsp.util.make_range_params(0, "utf-16")
                        params.context = { only = { "source.organizeImports" } }
                        -- buf_request_sync defaults to a 1000ms timeout. Depending on your
                        -- machine and codebase, you may want longer. Add an additional
                        -- argument after params if you find that you have to write the file
                        -- twice for changes to be saved.
                        -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
                        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
                        for cid, res in pairs(result or {}) do
                            for _, r in pairs(res.result or {}) do
                                if r.edit then
                                    local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
                                    vim.lsp.util.apply_workspace_edit(r.edit, enc)
                                end
                            end
                        end
                        vim.lsp.buf.format({ async = false })
                    end,
                })
            end,
            sources = {
                -- Lua formatting
                null_ls.builtins.formatting.stylua,

                -- Go support with gopls for imports, formatting, and code actions
                null_ls.builtins.code_actions.gomodifytags,
                null_ls.builtins.code_actions.impl,

                -- Custom struct padding fixer
                fieldalignment_source,

                -- Bash support
                null_ls.builtins.formatting.shfmt, -- for Bash formatting

                -- C support
                null_ls.builtins.formatting.clang_format,
                null_ls.builtins.diagnostics.cppcheck,

                -- Proto support
                null_ls.builtins.diagnostics.buf,
            },
        })

        vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Format Code" })
    end,
}
