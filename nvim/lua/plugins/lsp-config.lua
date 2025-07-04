local fn = vim.fn

local function buildTags()
  local cwd = fn.getcwd()
  if string.find(cwd, "repositories") then
    return { "-tags=build integration && !unit" }
  end

  return { "-tags=" }
end

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
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "clangd",
          "bashls",
          "yamlls",
          "taplo",
          "buf_ls",
          -- NOTE: gopls excluded - using system installation
        },
        auto_install = false, -- Disable auto install to prevent duplicates
        handlers = {
          -- Default handler for servers not explicitly configured
          function(server_name)
            if server_name ~= "gopls" and server_name ~= "lua_ls" and server_name ~= "yamlls" then -- Skip manually configured servers
              require("lspconfig")[server_name].setup({
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
              })
            end
          end,
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")

      -- Setup for Clangd language server
      lspconfig.clangd.setup({
        capabilities = capabilities,
        cmd = { "clangd", "--background-index" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
      })

      -- Setup for Go language server (using system gopls, not Mason)
      lspconfig.gopls.setup({
        capabilities = capabilities,
        cmd = { "gopls" }, -- Use gopls from PATH
        single_file_support = true,
        settings = {
          gopls = {
            buildFlags = buildTags(),
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
        on_attach = function(client, bufnr)
          print("LSP attached: " .. client.name .. " (id: " .. client.id .. ") to buffer " .. bufnr)

          -- Check for duplicate gopls clients
          local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
          local gopls_count = 0
          for _, c in pairs(clients) do
            if c.name == "gopls" then
              gopls_count = gopls_count + 1
            end
          end

          if gopls_count > 1 then
            print("WARNING: Multiple gopls clients detected (" .. gopls_count .. ")")
          end
        end,
      })

      -- YAML server custom setup (has special codegen.yaml handling)
      lspconfig.yamlls.setup({
        capabilities = capabilities,
        on_attach = function(client, _)
          -- Check if the current buffer is a codegen.yaml or codegen.yml
          local filename = vim.fn.expand("%:t")

          if filename == "codegen.yaml" or filename == "codegen.yml" then
            local codegen_schema_path = vim.fn.expand("%:p:h") .. "/.schema.json"
            -- Ensure the schema file exists before adding it
            if vim.fn.filereadable(codegen_schema_path) == 1 then
              client.config.settings.yaml.schemas[codegen_schema_path] = { "codegen.yaml", "codegen.yml" }
              client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
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

      -- Lua language server custom setup (needs special Neovim configuration)
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

      -- Keymaps for LSP functionality
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "Go to References" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

      -- Enhanced LSP mappings with new tools
      vim.keymap.set("n", "gD", function()
        require("glance").open("definitions")
      end, { desc = "Peek Definitions" })

      vim.keymap.set("n", "gR", function()
        require("glance").open("references")
      end, { desc = "Peek References" })

      vim.keymap.set("n", "gI", function()
        require("glance").open("implementations")
      end, { desc = "Peek Implementations" })

      vim.keymap.set("n", "gy", function()
        require("glance").open("type_definitions")
      end, { desc = "Peek Type Definitions" })
    end,
  },
}
