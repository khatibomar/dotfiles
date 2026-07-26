local M = {}



local win_id = nil
local buf_id = nil

local function open_split_win()
  -- Create a vertical split on the right
  vim.cmd("botright vnew")
  
  -- Set a reasonable width (e.g., 40% of the screen or at least 40 cols)
  local width = math.floor(vim.o.columns * 0.4)
  if width < 40 then width = 40 end
  vim.api.nvim_win_set_width(0, width)
  
  win_id = vim.api.nvim_get_current_win()
  buf_id = vim.api.nvim_get_current_buf()
  
  -- Set buffer options to be a terminal scratch buffer
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf_id })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf_id })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf_id })
  
  -- Optional: add a buffer-local map to close the terminal easily? 
  -- But we already have the exit handling
end

function M.toggle_agent()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
    win_id = nil
    buf_id = nil
    return
  end

  open_split_win()
  
  local agent_cmd = vim.env.AI_AGENT or "agy"
  
  vim.fn.termopen(agent_cmd, {
    on_exit = function()
      if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
        win_id = nil
        buf_id = nil
      end
    end
  })
  
  vim.cmd("startinsert")
end

function M.setup()
  -- Keymap to toggle the AI agent
  vim.keymap.set("n", "<leader>a", function()
    M.toggle_agent()
  end, { noremap = true, silent = true, desc = "Toggle AI Agent" })
end

return M
