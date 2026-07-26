local M = {}

-- Define the default AI agent globally if not already set
if vim.g.default_ai_agent == nil then
  vim.g.default_ai_agent = vim.env.AI_AGENT or "agy"
end

-- Configuration for available AI agents
-- You can add or modify the CLI commands here
M.agents = {
  agy = "agy",
  openai = "openai",
  claude = "claude",
}

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
  
  local agent_cmd = M.agents[vim.g.default_ai_agent] or vim.g.default_ai_agent
  
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
  -- User command to launch the agent
  vim.api.nvim_create_user_command("AI", function()
    M.toggle_agent()
  end, { desc = "Toggle default AI CLI Agent" })

  -- Keymap to toggle the AI agent
  vim.keymap.set("n", "<leader>a", function()
    M.toggle_agent()
  end, { noremap = true, silent = true, desc = "Toggle AI Agent" })
  
  -- Command to change the default agent on the fly
  vim.api.nvim_create_user_command("AISetAgent", function(opts)
    local agent = opts.args
    if agent and agent ~= "" then
      vim.g.default_ai_agent = agent
      vim.notify("Default AI agent set to: " .. agent, vim.log.levels.INFO)
    end
  end, { 
    nargs = 1,
    complete = function()
      local keys = {}
      for k, _ in pairs(M.agents) do
        table.insert(keys, k)
      end
      return keys
    end,
    desc = "Set default AI Agent" 
  })
end

return M
