local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function run_make_command(target)
  -- Define the buffer name
  local buf_name = "Make Output: " .. target

  -- Check if the buffer already exists and delete it
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf_id) and vim.api.nvim_buf_get_name(buf_id):match(vim.pesc(buf_name)) then
      vim.api.nvim_buf_delete(buf_id, { force = true })
    end
  end

  -- Open a split at the right
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)

  -- Rename the new buffer
  vim.api.nvim_buf_set_name(buf, buf_name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

  -- Create the job
  local job_id = vim.fn.jobstart("make " .. target, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
            local line_count = vim.api.nvim_buf_line_count(buf)
            vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, data)
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
            -- Auto-scroll to the bottom
            vim.api.nvim_win_set_cursor(0, { line_count + #data, 0 })
          end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
            local line_count = vim.api.nvim_buf_line_count(buf)
            vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, data)
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
            -- Auto-scroll to the bottom
            vim.api.nvim_win_set_cursor(0, { line_count + #data, 0 })
          end
        end)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
          local line_count = vim.api.nvim_buf_line_count(buf)
          local status = exit_code == 0 and "succeeded" or "failed"
          vim.api.nvim_buf_set_lines(
            buf,
            line_count,
            line_count,
            false,
            { "", string.format("Command 'make %s' %s (exit code: %d)", target, status, exit_code) }
          )
          vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
          vim.api.nvim_win_set_cursor(0, { line_count + 2, 0 })
        end
      end)
    end,
  })

  -- Set buffer local variable to store job_id
  vim.api.nvim_buf_set_var(buf, "make_job_id", job_id)

  -- Set buffer options
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  -- Set the buffer to be deleted and kill job on quit
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    buffer = buf,
    callback = function()
      local job = vim.api.nvim_buf_get_var(buf, "make_job_id")
      if job then
        vim.fn.jobstop(job)
      end
    end,
    once = true,
  })
end

local function extract_makefile_targets(makefile_path)
  local targets = {}
  for line in io.lines(makefile_path) do
    local target = line:match("^([%w-]+):")
    if target then
      table.insert(targets, target)
    end
  end
  return targets
end

local makefile_targets = function(opts)
  opts = opts or {}
  local makefile_path = vim.fn.findfile("Makefile", ".;")

  if makefile_path == "" then
    print("No Makefile found in the current directory or its parents")
    return
  end

  local targets = extract_makefile_targets(makefile_path)

  pickers
      .new(opts, {
        prompt_title = "Makefile Targets",
        finder = finders.new_table({
          results = targets,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            run_make_command(selection[1])
          end)
          return true
        end,
      })
      :find()
end

vim.api.nvim_create_user_command("MakefileTargets", makefile_targets, {})
return require("telescope").register_extension({
  exports = {
    makefile_targets = makefile_targets,
  },
})
