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
    desc = "Browse symbols in the current document",
    action = function()
      Snacks.picker.lsp_symbols()
    end,
  },
  {
    text = "Workspace Symbols",
    cmd = "Workspace Symbols",
    desc = "Fuzzy-find any function/type/const across the whole project",
    action = function()
      Snacks.picker.lsp_workspace_symbols()
    end,
  },
  {
    text = "Incoming Calls",
    cmd = "Incoming Calls",
    desc = "Who calls the function under the cursor",
    action = function()
      Snacks.picker.lsp_incoming_calls()
    end,
  },
  {
    text = "Outgoing Calls",
    cmd = "Outgoing Calls",
    desc = "What the function under the cursor calls",
    action = function()
      Snacks.picker.lsp_outgoing_calls()
    end,
  },
  {
    text = "Type Definition",
    cmd = "Type Definition",
    desc = "Jump to where the type of the value under the cursor is declared",
    action = function()
      Snacks.picker.lsp_type_definitions()
    end,
  },
  {
    text = "Rename Symbol",
    cmd = "Rename Symbol",
    desc = "Rename the symbol under the cursor, with live preview",
    action = function()
      vim.fn.feedkeys(":IncRename " .. vim.fn.expand("<cword>"), "n")
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

-- Only relevant with a Go buffer focused; appended on top of `actions` in that case.
local go_actions = {
  {
    text = "Go: Test Nearest Function",
    cmd = "Go: Test Nearest Function",
    desc = "Run the test function under the cursor",
    action = function()
      vim.cmd("GoTestFunc")
    end,
  },
  {
    text = "Go: Test File",
    cmd = "Go: Test File",
    desc = "Run all tests in the current file",
    action = function()
      vim.cmd("GoTestFile")
    end,
  },
  {
    text = "Go: Test Package",
    cmd = "Go: Test Package",
    desc = "Run all tests in the current package",
    action = function()
      vim.cmd("GoTestPkg")
    end,
  },
  {
    text = "Go: Toggle Coverage",
    cmd = "Go: Toggle Coverage",
    desc = "Overlay test coverage on the current file",
    action = function()
      vim.cmd("GoCoverage")
    end,
  },
  {
    text = "Go: Switch Test <-> Impl",
    cmd = "Go: Switch Test <-> Impl",
    desc = "Jump between a file and its _test.go counterpart",
    action = function()
      vim.cmd("GoAlt")
    end,
  },
  {
    text = "Go: Generate Interface Stub",
    cmd = "Go: Generate Interface Stub",
    desc = "Generate method stubs for an interface (GoImpl)",
    action = function()
      vim.cmd("GoImpl")
    end,
  },
  {
    text = "Go: Fill Struct",
    cmd = "Go: Fill Struct",
    desc = "Fill the struct literal under the cursor with its fields",
    action = function()
      vim.cmd("GoFillStruct")
    end,
  },
  {
    text = "Go: Add If Err",
    cmd = "Go: Add If Err",
    desc = "Insert an if err != nil block for the call under the cursor",
    action = function()
      vim.cmd("GoIfErr")
    end,
  },
  {
    text = "Go: Add Struct Tags",
    cmd = "Go: Add Struct Tags",
    desc = "Add struct tags (e.g. json) to the struct under the cursor",
    action = function()
      vim.cmd("GoAddTag")
    end,
  },
  {
    text = "Go: Remove Struct Tags",
    cmd = "Go: Remove Struct Tags",
    desc = "Remove struct tags from the struct under the cursor",
    action = function()
      vim.cmd("GoRmTag")
    end,
  },
  {
    text = "Go: Mod Tidy",
    cmd = "Go: Mod Tidy",
    desc = "Run go mod tidy for the current module",
    action = function()
      vim.cmd("GoModTidy")
    end,
  },
  {
    text = "Go: Vet",
    cmd = "Go: Vet",
    desc = "Run go vet on the current package",
    action = function()
      vim.cmd("GoVet")
    end,
  },
  {
    text = "Go: Build",
    cmd = "Go: Build",
    desc = "Build the current package",
    action = function()
      vim.cmd("GoBuild")
    end,
  },
  {
    text = "Go: Run",
    cmd = "Go: Run",
    desc = "Run the current package",
    action = function()
      vim.cmd("GoRun")
    end,
  },
  {
    text = "Go: Doc",
    cmd = "Go: Doc",
    desc = "Show documentation for the symbol under the cursor",
    action = function()
      vim.cmd("GoDoc")
    end,
  },
  {
    text = "Go: Vulncheck",
    cmd = "Go: Vulncheck",
    desc = "Scan the current module for known vulnerabilities",
    action = function()
      vim.cmd("GoVulnCheck")
    end,
  },
  {
    text = "Go: Symbol Outline",
    cmd = "Go: Symbol Outline",
    desc = "Toggle the struct/function outline for the current file",
    action = function()
      require("structrue-go").toggle()
    end,
  },
  {
    text = "Go: Restart gopls",
    cmd = "Go: Restart gopls",
    desc = "Restart gopls (useful after go.mod or build tag changes)",
    action = function()
      vim.cmd("LspRestart gopls")
    end,
  },
}

function M.open()
  local items = actions
  if vim.tbl_contains({ "go", "gomod", "gowork" }, vim.bo.filetype) then
    items = vim.list_extend(vim.deepcopy(actions), go_actions)
  end

  Snacks.picker.pick({
    title = "Command Palette",
    items = items,
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
