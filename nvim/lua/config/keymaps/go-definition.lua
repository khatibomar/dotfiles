-- Ensure vertical splits open to the right
vim.o.splitright = true

-- Store the original window and a list of spawned windows
local original_window = nil
local spawned_windows = {}

-- Function to go to definition in a vertical split
local function go_to_definition_split()
  -- Store the original window
  if not original_window then
    original_window = vim.api.nvim_get_current_win()
  end

  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      vim.notify("Definition not found or LSP error.")
      return
    end

    -- Open a new vertical split
    vim.cmd("vsplit")

    -- Get the new window ID
    local new_window = vim.api.nvim_get_current_win()
    table.insert(spawned_windows, new_window)

    -- Jump to the first valid location
    for _, loc in ipairs(result) do
      if loc and loc.uri and loc.range then
        vim.lsp.util.jump_to_location(loc)
        return
      end
    end

    -- Close the split if no valid location is found
    vim.notify("No valid definition location found.")
    vim.cmd("quit")
  end)
end

-- Function to close all spawned splits and return to the original window
local function close_splits_and_return()
  -- Close each spawned window if it's valid
  for _, win in ipairs(spawned_windows) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, false)
    end
  end

  -- Switch back to the original window if it's valid
  if original_window and vim.api.nvim_win_is_valid(original_window) then
    vim.api.nvim_set_current_win(original_window)
  end

  -- Reset the original window and spawned windows
  original_window = nil
  spawned_windows = {}
  vim.cmd('redraw')
end

-- Keymap to go to definition in a vertical split
vim.keymap.set("n", "gd", go_to_definition_split, { noremap = true, silent = true })

-- Keymap to close all splits and return to the original buffer
vim.keymap.set("n", "<leader>q", close_splits_and_return, { noremap = true, silent = true })
