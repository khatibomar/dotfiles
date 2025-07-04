return {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    event = "LspAttach",
    cmd = { "Refactor" },
    config = function()
        require("refactoring").setup({
            prompt_func_return_type = {
                go = false,
                java = false,
                cpp = false,
                c = false,
                h = false,
                hpp = false,
                cxx = false,
            },
            prompt_func_param_type = {
                go = false,
                java = false,
                cpp = false,
                c = false,
                h = false,
                hpp = false,
                cxx = false,
            },
            printf_statements = {},
            print_var_statements = {},
            show_success_message = true, -- shows a message with information about the refactor on success
        })

        -- Load refactoring Telescope extension if available
        local telescope_ok, telescope = pcall(require, "telescope")
        if telescope_ok then
            telescope.load_extension("refactoring")
        end
    end,
}
