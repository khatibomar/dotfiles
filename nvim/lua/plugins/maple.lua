-- I like this plugin but it broke recently and I haven't had time to fix it.
-- Disabling for now.
return {}

-- return {
--     "forest-nvim/maple.nvim",
--     config = function()
--         require("maple").setup({
--             -- Appearance
--             width = 0.6,        -- Width of the popup (ratio of the editor width)
--             height = 0.6,       -- Height of the popup (ratio of the editor height)
--             border = "rounded", -- Border style ('none', 'single', 'double', 'rounded', etc.)
--             title = " maple ",
--             title_pos = "center",
--             winblend = 10,       -- Window transparency (0-100)
--             show_legend = false, -- Whether to show keybind legend in the UI

--             -- Storage
--             storage_path = vim.fn.stdpath("data") .. "/maple",

--             -- Notes management
--             notes_mode = "project",            -- "global" or "project"
--             use_project_specific_notes = true, -- Store notes by project

--             -- Keymaps (set to nil to disable)
--             keymaps = {
--                 toggle = "<leader>tn", -- Key to toggle Maple
--                 close = "q",           -- Key to close the window
--                 switch_mode = "m",     -- Key to switch between global and project view
--             },
--         })

--         -- Add auto-save functionality after maple is opened
--         local save_timer = nil

--         -- Hook into maple's open function to add auto-save
--         vim.api.nvim_create_user_command("MapleNotes", function()
--             require("maple").open_notes()

--             -- Set up auto-save after a short delay
--             vim.defer_fn(function()
--                 local buf = vim.api.nvim_get_current_buf()
--                 if vim.api.nvim_buf_is_valid(buf) then
--                     local augroup = vim.api.nvim_create_augroup("MapleAutoSave", { clear = true })

--                     -- Auto-save on text changes with debouncing
--                     vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
--                         group = augroup,
--                         buffer = buf,
--                         callback = function()
--                             if save_timer then
--                                 save_timer:stop()
--                                 save_timer:close()
--                             end

--                             save_timer = vim.loop.new_timer()
--                             save_timer:start(1000, 0, vim.schedule_wrap(function()
--                                 if vim.api.nvim_buf_is_valid(buf) then
--                                     local content = require("maple.ui.renderer").get_notes_content()
--                                     require("maple.storage").save_notes({ content = content })
--                                 end
--                                 save_timer:close()
--                                 save_timer = nil
--                             end))
--                         end
--                     })

--                     -- Clean up timer on buffer delete
--                     vim.api.nvim_create_autocmd("BufDelete", {
--                         group = augroup,
--                         buffer = buf,
--                         callback = function()
--                             if save_timer then
--                                 save_timer:stop()
--                                 save_timer:close()
--                                 save_timer = nil
--                             end
--                         end
--                     })
--                 end
--             end, 200)
--         end, { desc = "Open Maple Notes with auto-save" })
--     end,
-- }
