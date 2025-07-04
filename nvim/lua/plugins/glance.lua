return {
    "dnlhc/glance.nvim",
    event = "LspAttach",
    cmd = { "Glance" },
    config = function()
        require("glance").setup({
            height = 18,         -- Height of the window
            zindex = 45,         -- Z-index of the window
            preview_win_opts = { -- Configure preview window options
                cursorline = true,
                number = true,
                wrap = true,
            },
            list = {
                position = "right", -- Position of the list window 'left'|'right'
                width = 0.33,       -- 33% of screen width
            },
            theme = {               -- Enable theme support
                enable = true,      -- Will merge with the default theme
                mode = "auto",      -- 'brighten'|'darken'|'auto'
            },
            mappings = {
                list = {
                    ["j"] = "next_item",
                    ["k"] = "previous_item",
                    ["<Down>"] = "next_item",
                    ["<Up>"] = "previous_item",
                    ["<Tab>"] = "next_item",
                    ["<S-Tab>"] = "previous_item",
                    ["<C-u>"] = "preview_scroll_win 5",
                    ["<C-d>"] = "preview_scroll_win -5",
                    ["v"] = "jump_vsplit",
                    ["s"] = "jump_split",
                    ["t"] = "jump_tab",
                    ["<CR>"] = "jump",
                    ["o"] = "jump",
                    ["l"] = "open_fold",
                    ["h"] = "close_fold",
                    ["<leader>l"] = "enter_win",
                    ["q"] = "close",
                    ["Q"] = "close",
                    ["<Esc>"] = "close",
                    ["<C-q>"] = "quickfix",
                },
                preview = {
                    ["Q"] = "close",
                    ["<Tab>"] = "next_location",
                    ["<S-Tab>"] = "previous_location",
                    ["<leader>l"] = "enter_win",
                },
            },
            hooks = {
                before_open = function(results, open, jump, method)
                    local uri = vim.uri_from_bufnr(0)
                    if #results == 1 then
                        local target_uri = results[1].uri or results[1].targetUri
                        if target_uri == uri then
                            jump(results[1])
                        else
                            open(results)
                        end
                    else
                        open(results)
                    end
                end,
            },
            folds = {
                fold_closed = "",
                fold_open = "",
                folded = true, -- Automatically fold list on startup
            },
            indent_lines = {
                enable = true,
                icon = "│",
            },
            winbar = {
                enable = true, -- Available strating from nvim-0.8+
            },
        })
    end,
}
