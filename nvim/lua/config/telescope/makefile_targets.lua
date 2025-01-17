local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Store the current make output buffer id
local current_make_buf = nil
local current_make_win = nil

local function run_make_command(target)
	-- If we have an existing make buffer, clean it up
	if current_make_buf and vim.api.nvim_buf_is_valid(current_make_buf) then
		-- Stop any running make job
		local ok, job = pcall(vim.api.nvim_buf_get_var, current_make_buf, "make_job_id")
		if ok and job then
			vim.fn.jobstop(job)
		end

		-- Clear buffer content and update name
		vim.api.nvim_set_option_value("modifiable", true, { buf = current_make_buf })
		vim.api.nvim_buf_set_lines(current_make_buf, 0, -1, false, { "Press ENTER to close this buffer", "" })
		vim.api.nvim_buf_set_name(current_make_buf, "Make Output: " .. target)
	else
		-- Create new buffer and window if none exists
		vim.cmd("botright vsplit")
		current_make_win = vim.api.nvim_get_current_win()
		current_make_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(current_make_win, current_make_buf)

		-- Set buffer name
		vim.api.nvim_buf_set_name(current_make_buf, "Make Output: " .. target)

		-- Set wrap options
		vim.api.nvim_set_option_value("wrap", true, { win = current_make_win })
		vim.api.nvim_set_option_value("linebreak", true, { win = current_make_win })

		-- Add keymap to close buffer on Enter
		local buf_to_close = current_make_buf -- Create local reference
		local win_to_close = current_make_win -- Create local reference
		vim.keymap.set("n", "<CR>", function()
			if vim.api.nvim_buf_is_valid(buf_to_close) then
				-- Stop any running make job
				local ok, job = pcall(vim.api.nvim_buf_get_var, buf_to_close, "make_job_id")
				if ok and job then
					vim.fn.jobstop(job)
				end

				if vim.api.nvim_win_is_valid(win_to_close) then
					vim.api.nvim_win_close(win_to_close, true)
				end

				vim.api.nvim_buf_delete(buf_to_close, { force = true })
			end
			current_make_buf = nil
			current_make_win = nil
		end, { buffer = current_make_buf, silent = true })

		-- Set buffer options
		vim.api.nvim_set_option_value("buftype", "nofile", { buf = current_make_buf })
		vim.api.nvim_set_option_value("swapfile", false, { buf = current_make_buf })

		-- Initialize buffer with message
		vim.api.nvim_buf_set_lines(current_make_buf, 0, -1, false, { "Press ENTER to close this buffer", "" })
	end

	-- Create the job
	local job_id = vim.fn.jobstart("make " .. target, {
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = function(_, data)
			if data then
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(current_make_buf) then
						vim.api.nvim_set_option_value("modifiable", true, { buf = current_make_buf })
						local line_count = vim.api.nvim_buf_line_count(current_make_buf)
						vim.api.nvim_buf_set_lines(current_make_buf, line_count, line_count, false, data)
						vim.api.nvim_set_option_value("modifiable", false, { buf = current_make_buf })
						-- Auto-scroll to the bottom
						if current_make_win and vim.api.nvim_win_is_valid(current_make_win) then
							vim.api.nvim_win_set_cursor(current_make_win, { line_count + #data, 0 })
						end
					end
				end)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(current_make_buf) then
						vim.api.nvim_set_option_value("modifiable", true, { buf = current_make_buf })
						local line_count = vim.api.nvim_buf_line_count(current_make_buf)
						vim.api.nvim_buf_set_lines(current_make_buf, line_count, line_count, false, data)
						vim.api.nvim_set_option_value("modifiable", false, { buf = current_make_buf })
						-- Auto-scroll to the bottom
						if current_make_win and vim.api.nvim_win_is_valid(current_make_win) then
							vim.api.nvim_win_set_cursor(current_make_win, { line_count + #data, 0 })
						end
					end
				end)
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(current_make_buf) then
					vim.api.nvim_set_option_value("modifiable", true, { buf = current_make_buf })
					local line_count = vim.api.nvim_buf_line_count(current_make_buf)
					local status = exit_code == 0 and "succeeded" or "failed"
					vim.api.nvim_buf_set_lines(current_make_buf, line_count, line_count, false, {
						"",
						string.format("Command 'make %s' %s (exit code: %d)", target, status, exit_code),
						"Press ENTER to close this buffer",
					})
					vim.api.nvim_set_option_value("modifiable", false, { buf = current_make_buf })
					if current_make_win and vim.api.nvim_win_is_valid(current_make_win) then
						vim.api.nvim_win_set_cursor(current_make_win, { line_count + 3, 0 })
					end
				end
			end)
		end,
	})

	-- Set buffer local variable to store job_id
	vim.api.nvim_buf_set_var(current_make_buf, "make_job_id", job_id)
	vim.api.nvim_set_option_value("modifiable", false, { buf = current_make_buf })
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
