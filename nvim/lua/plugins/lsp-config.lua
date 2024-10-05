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
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

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
        on_attach = function(client, bufnr)
          -- Check if the current buffer is a codegen.yaml or codegen.yml
          local filename = vim.fn.expand("%:t")
          local schema_path = vim.fn.expand("%:p:h") .. "/.schema.json" -- Full path to .schema.json

          if filename == "codegen.yaml" or filename == "codegen.yml" then
            -- Ensure the schema file exists before adding it
            if vim.fn.filereadable(schema_path) == 1 then
              client.config.settings.yaml.schemas[schema_path] = { "codegen.yaml", "codegen.yml" }
              client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
              vim.notify("Loaded schema from " .. schema_path)
            end
          end
        end,
        settings = {
          yaml = {
            schemaStore = {
              enable = false,
              url = "",
            },
            schemas = {},
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
              version = "LuaJIT", -- for Neovim Lua runtime
            },
            diagnostics = {
              -- Enable Neovim-specific globals like 'vim'
              globals = { "vim" },
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
