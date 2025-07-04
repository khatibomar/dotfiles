return {
    "folke/trouble.nvim",
    opts = {
        auto_close = true,
        auto_open = false,
        auto_preview = true,
        auto_refresh = true,
        focus = false,
        follow = true,
        indent_guides = true,
        max_items = 200,
        multiline = true,
        pinned = false,
        warn_no_results = true,
        open_no_results = false,
    },
    cmd = "Trouble",
    keys = {
        {
            "<leader>dt",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Project Diagnostics (All Files)",
        },
        {
            "<leader>dl",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Current Buffer Diagnostics",
        },
        {
            "<leader>dw",
            "<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.WARN<cr>",
            desc = "Project Warnings Only",
        },
        {
            "<leader>de",
            "<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.ERROR<cr>",
            desc = "Project Errors Only",
        },
        {
            "<leader>ds",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Document Symbols (Trouble)",
        },
        {
            "<leader>dr",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "LSP Definitions / references / ... (Trouble)",
        },
        {
            "<leader>dL",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
        },
        {
            "<leader>dQ",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
        },
    },
}
