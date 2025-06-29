return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 200,
        expand = 1,
        notify = false,
        triggers = {
            { "<auto>", mode = "nxsot" },
        },
        spec = {
            -- Hide certain keys from showing in which-key
            { "<leader>w", hidden = true }, -- Don't show window commands individually
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
    config = function(_, opts)
        local wk = require("which-key")
        wk.setup(opts)

        -- Smart go-to-definition with tab reuse and navigation stack
        local navigation_stack = {}
        local max_tabs = 8 -- Limit to prevent tab explosion

        -- Helper function to get file path from URI
        local function uri_to_filepath(uri)
            return vim.uri_to_fname(uri)
        end

        -- Helper function to find existing tab with file
        local function find_tab_with_file(filepath)
            local tabs = vim.api.nvim_list_tabpages()
            for _, tab in ipairs(tabs) do
                local wins = vim.api.nvim_tabpage_list_wins(tab)
                for _, win in ipairs(wins) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name == filepath then
                        return tab
                    end
                end
            end
            return nil
        end

        -- Count definition tabs (exclude original)
        local function count_definition_tabs()
            local count = 0
            for _, entry in ipairs(navigation_stack) do
                if vim.api.nvim_tabpage_is_valid(entry.tab) then
                    count = count + 1
                end
            end
            return count
        end

        local function go_to_definition_tab()
            -- Save current position in navigation stack
            local current_tab = vim.api.nvim_get_current_tabpage()
            local current_buf = vim.api.nvim_get_current_buf()
            local current_pos = vim.api.nvim_win_get_cursor(0)
            local current_file = vim.api.nvim_buf_get_name(current_buf)

            local params = vim.lsp.util.make_position_params(0, "utf-8")
            vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
                if err or not result or vim.tbl_isempty(result) then
                    vim.notify("Definition not found or LSP error.")
                    return
                end

                for _, loc in ipairs(result) do
                    if loc and loc.uri and loc.range then
                        local target_file = uri_to_filepath(loc.uri)
                        local existing_tab = find_tab_with_file(target_file)

                        if existing_tab then
                            -- Switch to existing tab
                            vim.api.nvim_set_current_tabpage(existing_tab)
                            vim.lsp.util.show_document(loc, "utf-8", { focus = true })
                            vim.notify("Switched to existing tab: " .. vim.fn.fnamemodify(target_file, ":t"))
                        else
                            -- Check tab limit
                            if count_definition_tabs() >= max_tabs then
                                vim.notify(
                                    "Too many definition tabs open. Use <leader>q to clean up or increase max_tabs.")
                                return
                            end

                            -- Create new tab
                            vim.cmd("tabnew")
                            local new_tab = vim.api.nvim_get_current_tabpage()

                            -- Add to navigation stack
                            table.insert(navigation_stack, {
                                from_tab = current_tab,
                                from_file = current_file,
                                from_pos = current_pos,
                                tab = new_tab,
                                file = target_file,
                                timestamp = os.time()
                            })

                            vim.lsp.util.show_document(loc, "utf-8", { focus = true })
                            vim.notify("Opened: " ..
                                vim.fn.fnamemodify(target_file, ":t") ..
                                " (Tab " .. count_definition_tabs() .. "/" .. max_tabs .. ")")
                        end
                        return
                    end
                end

                vim.notify("No valid definition location found.")
            end)
        end

        local function close_tabs_and_return()
            if #navigation_stack == 0 then
                vim.notify("No definition tabs to close.")
                return
            end

            local closed_count = 0
            -- Close all definition tabs (in reverse order to avoid index issues)
            for i = #navigation_stack, 1, -1 do
                local entry = navigation_stack[i]
                if vim.api.nvim_tabpage_is_valid(entry.tab) then
                    vim.api.nvim_set_current_tabpage(entry.tab)
                    vim.cmd("tabclose")
                    closed_count = closed_count + 1
                end
            end

            -- Return to most recent origin tab
            local last_entry = navigation_stack[#navigation_stack]
            if last_entry and vim.api.nvim_tabpage_is_valid(last_entry.from_tab) then
                vim.api.nvim_set_current_tabpage(last_entry.from_tab)
                -- Restore cursor position
                if last_entry.from_pos then
                    vim.api.nvim_win_set_cursor(0, last_entry.from_pos)
                end
            end

            navigation_stack = {}
            vim.cmd("redraw")
            vim.notify("Closed " .. closed_count .. " definition tabs and returned to origin.")
        end

        -- Clean up invalid tabs from navigation stack
        local function cleanup_navigation_stack()
            navigation_stack = vim.tbl_filter(function(entry)
                return vim.api.nvim_tabpage_is_valid(entry.tab)
            end, navigation_stack)
        end

        -- Show navigation stack info
        local function show_navigation_info()
            cleanup_navigation_stack()
            if #navigation_stack == 0 then
                vim.notify("No definition tabs open.")
                return
            end

            local info = { "Definition Navigation Stack:" }
            for i, entry in ipairs(navigation_stack) do
                local file_name = vim.fn.fnamemodify(entry.file, ":t")
                local from_name = vim.fn.fnamemodify(entry.from_file, ":t")
                table.insert(info, string.format("  %d. %s (from %s)", i, file_name, from_name))
            end
            table.insert(info, "")
            table.insert(info, "Use <leader>q to close all and return to origin.")

            vim.notify(table.concat(info, "\n"))
        end

        -- Tmux popup function (moved from keymaps.lua)
        function OpenTmuxPopup()
            local cmd = "bash $HOME/scripts/toggle_tmux_popup.sh"
            vim.fn.system(cmd)
        end

        -- Global flag to track if diagnostics location list is active
        local diagnostics_loclist_active = false
        local diagnostics_autocmd_id = nil

        -- Auto-updating diagnostics location list function
        function AutoDiagnosticsLocationList()
            -- Function to update diagnostics and check if empty
            local function update_diagnostics()
                -- Get current diagnostics
                local diagnostics = vim.diagnostic.get(0) -- Current buffer

                -- If no diagnostics, close location list and stop autocmd
                if #diagnostics == 0 then
                    vim.cmd('lclose')
                    if diagnostics_autocmd_id then
                        vim.api.nvim_del_autocmd(diagnostics_autocmd_id)
                        diagnostics_autocmd_id = nil
                    end
                    diagnostics_loclist_active = false
                    return
                end

                -- Update location list with diagnostics
                vim.diagnostic.setloclist()
            end

            -- Initial update
            update_diagnostics()
            diagnostics_loclist_active = true

            -- Remove existing autocmd if any
            if diagnostics_autocmd_id then
                vim.api.nvim_del_autocmd(diagnostics_autocmd_id)
            end

            -- Set up autocmd to update on buffer save
            diagnostics_autocmd_id = vim.api.nvim_create_autocmd("BufWritePost", {
                callback = function()
                    -- Check if location list window still exists
                    local loclist_exists = false
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
                        if buf_type == 'quickfix' then
                            local wininfo = vim.fn.getwininfo(win)[1]
                            if wininfo and wininfo.loclist == 1 then
                                loclist_exists = true
                                break
                            end
                        end
                    end

                    -- If location list window was closed manually, stop autocmd
                    if not loclist_exists then
                        if diagnostics_autocmd_id then
                            vim.api.nvim_del_autocmd(diagnostics_autocmd_id)
                            diagnostics_autocmd_id = nil
                        end
                        diagnostics_loclist_active = false
                        return
                    end

                    -- Update diagnostics after a short delay to allow LSP to update
                    vim.defer_fn(update_diagnostics, 100)
                end,
                desc = "Update diagnostics location list on save"
            })
        end

        -- Register leader key mappings with proper grouping
        wk.add({
            -- File operations
            { "<leader><leader>", "<cmd>Telescope find_files<cr>",                desc = "Find Files" },
            { "<leader>/",        "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search Buffer" },
            { "<leader>s",        ":w<CR>",                                       desc = "Save File" },
            { "<leader>p",        function() OpenTmuxPopup() end,                 desc = "Toggle Tmux Popup" },
            { "<leader>q",        function() close_tabs_and_return() end,         desc = "Close Definition Tabs & Return" },

            -- AI/Copilot operations
            { "<leader>a",        group = "AI/Copilot",                           mode = { "n", "v" } },
            { "<leader>ai",       desc = "Ask Copilot Input" },
            { "<leader>ap",       desc = "Copilot Prompt Actions" },
            { "<leader>ae",       "<cmd>CopilotChatExplain<cr>",                  desc = "Explain Code" },
            { "<leader>at",       "<cmd>CopilotChatTests<cr>",                    desc = "Generate Tests" },
            { "<leader>ar",       "<cmd>CopilotChatReview<cr>",                   desc = "Review Code" },
            { "<leader>aR",       "<cmd>CopilotChatRefactor<cr>",                 desc = "Refactor Code" },
            { "<leader>an",       "<cmd>CopilotChatBetterNamings<cr>",            desc = "Better Naming" },
            { "<leader>av",       "<cmd>CopilotChatToggle<cr>",                   desc = "Toggle Copilot Chat" },
            { "<leader>ax",       desc = "Inline Chat" },
            { "<leader>am",       "<cmd>CopilotChatCommit<cr>",                   desc = "Generate Commit Message" },
            { "<leader>aq",       desc = "Quick Chat" },
            { "<leader>ad",       "<cmd>CopilotChatDebugInfo<cr>",                desc = "Debug Info" },
            { "<leader>af",       "<cmd>CopilotChatFix<cr>",                      desc = "Fix Diagnostic" },
            { "<leader>al",       "<cmd>CopilotChatReset<cr>",                    desc = "Clear Chat History" },
            { "<leader>a?",       "<cmd>CopilotChatModels<cr>",                   desc = "Select Models" },

            -- Buffer operations
            { "<leader>b",        group = "Buffers" },
            { "<leader>bf",       "<cmd>Neotree buffers reveal float<cr>",        desc = "Buffer Explorer" },
            { "<leader>bd",       "<cmd>bdelete<cr>",                             desc = "Delete Buffer" },
            { "<leader>bn",       "<cmd>bnext<cr>",                               desc = "Next Buffer" },
            { "<leader>bp",       "<cmd>bprevious<cr>",                           desc = "Previous Buffer" },

            -- Code operations
            { "<leader>c",        group = "Code" },
            { "<leader>ca",       desc = "Code Action" },
            { "<leader>cr",       "<cmd>lua vim.lsp.buf.rename()<cr>",            desc = "Rename Symbol" },
            { "<leader>cf",       "<cmd>lua vim.lsp.buf.format()<cr>",            desc = "Format Code" },

            -- Git operations
            { "<leader>g",        group = "Git/Go" },
            { "<leader>gd",       desc = "Go to Definition" },
            { "<leader>gr",       desc = "Go to References" },
            { "<leader>gf",       desc = "Format Code" },
            { "<leader>gs",       "<cmd>Neotree git_status<cr>",                  desc = "Git Status" },
            { "<leader>gb",       "<cmd>Telescope git_branches<cr>",              desc = "Git Branches" },
            { "<leader>gc",       "<cmd>Telescope git_commits<cr>",               desc = "Git Commits" },

            -- Search/List operations
            { "<leader>l",        group = "List/Search" },
            { "<leader>lb",       "<cmd>Telescope buffers<cr>",                   desc = "List Buffers" },
            { "<leader>lg",       "<cmd>Telescope live_grep<cr>",                 desc = "Live Grep" },
            { "<leader>lh",       "<cmd>Telescope help_tags<cr>",                 desc = "Help Tags" },
            { "<leader>lk",       "<cmd>Telescope keymaps<cr>",                   desc = "Keymaps" },
            { "<leader>lm",       "<cmd>Telescope marks<cr>",                     desc = "Marks" },
            { "<leader>lr",       "<cmd>Telescope registers<cr>",                 desc = "Registers" },

            -- Recent files
            { "<leader>r",        group = "Recent" },
            { "<leader>rf",       "<cmd>Telescope oldfiles<cr>",                  desc = "Recent Files" },

            -- Toggle operations
            { "<leader>t",        group = "Toggle" },
            { "<leader>tn",       desc = "Toggle Notes (Maple)" },
            { "<leader>tw",       "<cmd>set wrap!<cr>",                           desc = "Toggle Word Wrap" },
            { "<leader>ts",       "<cmd>set spell!<cr>",                          desc = "Toggle Spell Check" },
            { "<leader>th",       "<cmd>set hlsearch!<cr>",                       desc = "Toggle Highlight Search" },

            -- Window operations (grouped but minimal display)
            { "<leader>w",        group = "Windows" },
            { "<leader>wh",       "<C-w>h",                                       desc = "Move Left" },
            { "<leader>wj",       "<C-w>j",                                       desc = "Move Down" },
            { "<leader>wk",       "<C-w>k",                                       desc = "Move Up" },
            { "<leader>wl",       "<C-w>l",                                       desc = "Move Right" },
            { "<leader>ws",       "<C-w>s",                                       desc = "Split Horizontal" },
            { "<leader>wv",       "<C-w>v",                                       desc = "Split Vertical" },
            { "<leader>wc",       "<C-w>c",                                       desc = "Close Window" },
            { "<leader>wo",       "<C-w>o",                                       desc = "Close Others" },

            -- Debug/Diagnostics
            { "<leader>d",        group = "Debug/Diagnostics" },
            { "<leader>dt",       "<cmd>Telescope diagnostics<cr>",               desc = "Show Diagnostics" },
            {
                "<leader>dl",
                function() AutoDiagnosticsLocationList() end,
                desc = "Diagnostics to Location List (Auto-update on save)",
            },
            { "<leader>dn", "<cmd>lua vim.diagnostic.goto_next()<cr>",  desc = "Next Diagnostic" },
            { "<leader>dp", "<cmd>lua vim.diagnostic.goto_prev()<cr>",  desc = "Previous Diagnostic" },
            { "<leader>df", "<cmd>lua vim.diagnostic.open_float()<cr>", desc = "Show Diagnostic Float" },

            -- Jump operations (most common navigation)
            { "<leader>j",  group = "Jump" },
            { "<leader>je", "'.",                                       desc = "Jump to Last Edit" },
            { "<leader>ji", "'^",                                       desc = "Jump to Last Insert" },
            { "<leader>jb", "<C-o>",                                    desc = "Jump Back" },
            { "<leader>jf", "<C-i>",                                    desc = "Jump Forward" },
            { "<leader>jl", "``",                                       desc = "Jump to Last Position" },
            { "<leader>ja", "<C-^>",                                    desc = "Jump to Alternate Buffer" },
            { "<leader>jh", "<cmd>Telescope jumplist<cr>",              desc = "Jump History" },
            { "<leader>jn", function() show_navigation_info() end,      desc = "Show Definition Navigation" },

            -- Special keys
            { "<leader>m",  desc = "Toggle Go Struct" },
            { "<leader>?",  desc = "Buffer Local Keymaps" },
        })

        -- Register non-leader key mappings (most important ones)
        wk.add({
            { "gd",    function() go_to_definition_tab() end,  desc = "Go to Definition (New Tab)" },
            { "K",     desc = "Hover Documentation" },
            { "<C-n>", desc = "Toggle File Explorer" },
            { "'.",    desc = "Jump to Last Edit (Important!)" },
            { "``",    desc = "Jump to Last Position" },
            { "<C-o>", desc = "Jump Back" },
            { "<C-i>", desc = "Jump Forward" },
        })

        -- Register Copilot Chat-specific mappings
        wk.add({
            { "gm",  group = "Copilot Chat" },
            { "gmh", desc = "Show Help" },
            { "gmd", desc = "Show Diff" },
            { "gmp", desc = "Show System Prompt" },
            { "gms", desc = "Show Selection" },
            { "gmy", desc = "Yank Diff" },
        })

        -- Register visual mode specific mappings for Copilot
        wk.add({
            { "<leader>a",  group = "AI/Copilot",        mode = "v" },
            { "<leader>ap", desc = "Prompt Actions",     mode = "v" },
            { "<leader>av", ":CopilotChatVisual",        desc = "Visual Chat", mode = "v" },
            { "<leader>ax", ":CopilotChatInline<cr>",    desc = "Inline Chat", mode = "v" },
            { "<leader>ae", desc = "Explain Selection",  mode = "v" },
            { "<leader>at", desc = "Generate Tests",     mode = "v" },
            { "<leader>ar", desc = "Review Selection",   mode = "v" },
            { "<leader>aR", desc = "Refactor Selection", mode = "v" },
            { "<leader>an", desc = "Better Naming",      mode = "v" },
        })

        -- Register go-specific mappings when in go files
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "go",
            callback = function()
                wk.add({
                    { "<leader>g",  group = "Git/Go",                      buffer = true },
                    { "<leader>gi", "<cmd>GoImport<cr>",                   desc = "Go Import",        buffer = true },
                    { "<leader>gt", "<cmd>GoTest<cr>",                     desc = "Go Test",          buffer = true },
                    { "<leader>gT", "<cmd>GoTestFunc<cr>",                 desc = "Go Test Function", buffer = true },
                    { "H",          desc = "Toggle Go Methods Visibility", buffer = true },
                    { "<CR>",       desc = "Jump to Symbol",               buffer = true },
                    { "\\f",        desc = "Center Symbol",                buffer = true },
                    { "\\z",        desc = "Fold Toggle",                  buffer = true },
                    { "R",          desc = "Refresh Symbols",              buffer = true },
                    { "P",          desc = "Preview Open",                 buffer = true },
                    { "\\p",        desc = "Preview Close",                buffer = true },
                })
            end,
        })

        -- Register lua-specific mappings when in lua files
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "lua",
            callback = function()
                wk.add({
                    { "<leader>c",  group = "Code",       buffer = true },
                    { "<leader>cr", "<cmd>luafile %<cr>", desc = "Run Lua File", buffer = true },
                })
            end,
        })

        -- Register mappings for Copilot Chat buffer
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "copilot-chat",
            callback = function()
                wk.add({
                    { "q",      desc = "Close Chat",           buffer = true },
                    { "<C-c>",  desc = "Close Chat (Insert)",  buffer = true, mode = "i" },
                    { "<C-x>",  desc = "Reset Chat",           buffer = true },
                    { "<C-x>",  desc = "Reset Chat (Insert)",  buffer = true, mode = "i" },
                    { "<CR>",   desc = "Submit Prompt",        buffer = true },
                    { "<C-CR>", desc = "Submit (Insert)",      buffer = true, mode = "i" },
                    { "<C-y>",  desc = "Accept Diff",          buffer = true },
                    { "<C-y>",  desc = "Accept Diff (Insert)", buffer = true, mode = "i" },
                    { "<Tab>",  desc = "Complete",             buffer = true, mode = "i" },
                })
            end,
        })

        -- Register mappings for Maple notes buffer
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "maple",
            callback = function()
                wk.add({
                    { "q", desc = "Close Maple", buffer = true },
                    { "m", desc = "Switch Mode", buffer = true },
                })
            end,
        })
    end,
}
