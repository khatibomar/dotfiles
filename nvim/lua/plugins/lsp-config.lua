return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      auto_install = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local lspconfig = require("lspconfig")

      local lspconfig = require("lspconfig")

      -- Setup for Go language server
      lspconfig.gopls.setup({
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              nilness = true,
              unusedwrite = true,
            },
            staticcheck = true,
          },
        },
      })

      -- Setup for YAML language server
      lspconfig.yamlls.setup({
        capabilities = capabilities,
        settings = {
          yaml = {
            schemas = {
              kubernetes = "/*.yaml",  -- Example schema
            },
            validate = true,
            hover = true,
            completion = true,
          },
        },
      })

      -- Setup for Lua language server
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using
              version = 'LuaJIT', -- for Neovim Lua runtime
            },
            diagnostics = {
              -- Enable Neovim-specific globals like 'vim'
              globals = { 'vim' },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      -- Setup for Bash language server
      lspconfig.bashls.setup({
        capabilities = capabilities,
        settings = {
          bash = {
            enable = true,
            linting = true,
            shellcheck = { enable = true },
            globPattern = "*@(.sh|.inc|.bash|.command)",  
          },
        },
      })

      -- Keymaps for LSP functionality
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
