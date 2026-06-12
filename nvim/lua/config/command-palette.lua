local M = {}

local actions = {
  {
    text = "Change Color Theme",
    cmd = "Change Color Theme",
    desc = "Switch to a different colorscheme with live preview",
    action = function()
      Snacks.picker.colorschemes()
    end,
  },
  {
    text = "Toggle Transparency",
    cmd = "Toggle Transparency",
    desc = "Toggle background transparency on/off",
    action = function()
      vim.cmd("let g:leaf_transparent = exists('g:leaf_transparent') && g:leaf_transparent ? 0 : 1")
      vim.cmd("colorscheme " .. vim.g.colors_name)
    end,
  },
  {
    text = "Open File",
    cmd = "Open File",
    desc = "Search and open files with fuzzy finder",
    action = function()
      Snacks.picker.files()
    end,
  },
  {
    text = "Search in Files (Grep)",
    cmd = "Search in Files (Grep)",
    desc = "Search text across all files in the project",
    action = function()
      Snacks.picker.grep()
    end,
  },
  {
    text = "Switch Buffer",
    cmd = "Switch Buffer",
    desc = "Switch between open buffers",
    action = function()
      Snacks.picker.buffers()
    end,
  },
  {
    text = "Recently Opened Files",
    cmd = "Recently Opened Files",
    desc = "Browse recently opened files",
    action = function()
      Snacks.picker.recent()
    end,
  },
  {
    text = "Git Status",
    cmd = "Git Status",
    desc = "View and manage git changes",
    action = function()
      Snacks.picker.git_status()
    end,
  },
  {
    text = "Git Branches",
    cmd = "Git Branches",
    desc = "Switch or create git branches",
    action = function()
      Snacks.picker.git_branches()
    end,
  },
  {
    text = "Git Log",
    cmd = "Git Log",
    desc = "Browse git commit history",
    action = function()
      Snacks.picker.git_log()
    end,
  },
  {
    text = "Search Keymaps",
    cmd = "Search Keymaps",
    desc = "Search all keybindings with descriptions",
    action = function()
      Snacks.picker.keymaps()
    end,
  },
  {
    text = "LSP Symbols",
    cmd = "LSP Symbols",
    desc = "Browse document/workspace symbols",
    action = function()
      Snacks.picker.lsp_symbols()
    end,
  },
  {
    text = "Diagnostics",
    cmd = "Diagnostics",
    desc = "List all diagnostics in the project",
    action = function()
      Snacks.picker.diagnostics()
    end,
  },
  {
    text = "Toggle Terminal",
    cmd = "Toggle Terminal",
    desc = "Open or toggle a floating terminal",
    action = function()
      Snacks.terminal()
    end,
  },
  {
    text = "Help",
    cmd = "Help",
    desc = "Search Neovim help tags",
    action = function()
      Snacks.picker.help()
    end,
  },
  {
    text = "Projects",
    cmd = "Projects",
    desc = "Switch between recent projects",
    action = function()
      Snacks.picker.projects()
    end,
  },
  {
    text = "File Explorer",
    cmd = "File Explorer",
    desc = "Browse files in a tree view",
    action = function()
      Snacks.picker.explorer()
    end,
  },
  {
    text = "Jump to Line",
    cmd = "Jump to Line",
    desc = "Jump to a specific line number",
    action = function()
      Snacks.picker.lines()
    end,
  },
  {
    text = "Undo History",
    cmd = "Undo History",
    desc = "Visualize and jump through undo history",
    action = function()
      Snacks.picker.undo()
    end,
  },
  {
    text = "Command History",
    cmd = "Command History",
    desc = "Browse and re-run previous commands",
    action = function()
      Snacks.picker.command_history()
    end,
  },
  {
    text = "Neovim Commands",
    cmd = "Neovim Commands",
    desc = "Search and execute any Neovim command",
    action = function()
      Snacks.picker.commands()
    end,
  },
  {
    text = "Managed Plugins",
    cmd = "Managed Plugins",
    desc = "List and manage lazy.nvim plugins",
    action = function()
      Snacks.picker.lazy()
    end,
  },
  {
    text = "Scratch Buffer",
    cmd = "Scratch Buffer",
    desc = "Create or open a scratch buffer",
    action = function()
      Snacks.picker.scratch()
    end,
  },
}

function M.open()
  Snacks.picker.pick({
    title = "Command Palette",
    items = actions,
    format = "command",
    layout = { hidden = { "preview" } },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(item.action)
      end
    end,
  })
end

return M
