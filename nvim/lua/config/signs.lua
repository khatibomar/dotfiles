-- Define unified styles for LSP and Neo-tree
local unified_styles = {
  default = {
    icons = {
      folder_closed = "", -- Default closed folder
      folder_open = "", -- Default open folder
      file = "", -- Default file icon
      symlink = "" -- Default symlink icon
    },
    diagnostics = {
      Error = "󰅚", -- Cross mark
      Warn = "󰀪", -- Warning symbol
      Hint = "󰌶", -- Hint icon
      Info = "󰋼", -- Info icon
      Deprecated = "", -- Strikethrough or prohibition
      Trace = "󰎝" -- Trace (debugging or log trace icon)
    }
  },
  geometric = {
    icons = {
      folder_closed = "◆", -- Geometric closed folder
      folder_open = "◇", -- Geometric open folder
      file = "▸", -- Geometric file icon
      symlink = "➤" -- Geometric symlink icon
    },
    diagnostics = {
      Error = "◆", -- Diamond
      Warn = "▲", -- Triangle
      Hint = "●", -- Dot
      Info = "◈", -- Diamond
      Deprecated = "⬦", -- Hollow diamond
      Trace = "⬤" -- Filled circle
    }
  },
  expressive = {
    icons = {
      folder_closed = "📁", -- Emoji closed folder
      folder_open = "📂", -- Emoji open folder
      file = "📄", -- Emoji file icon
      symlink = "🔗" -- Emoji symlink icon
    },
    diagnostics = {
      Error = "✗", -- Bold X
      Warn = "⚡", -- Lightning
      Hint = "💡", -- Light bulb
      Info = "ℹ", -- Info
      Deprecated = "❌", -- Cross mark
      Trace = "🐞" -- Bug icon
    }
  },
  playful = {
    icons = {
      folder_closed = "😎", -- Fun closed folder
      folder_open = "🤩", -- Fun open folder
      file = "🎵", -- Fun file icon
      symlink = "🌀" -- Fun symlink icon
    },
    diagnostics = {
      Error = "😡", -- Angry emoji
      Warn = "⚠️", -- Warning sign
      Hint = "🤔", -- Thinking emoji
      Info = "💬", -- Speech bubble
      Deprecated = "👎", -- Thumbs down
      Trace = "🔍" -- Magnifying glass
    }
  }
}

-- Apply LSP diagnostic signs
local function apply_lsp_diagnostic_signs(diagnostics)
  for type, icon in pairs(diagnostics) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end

-- Apply Neo-tree styles
local function apply_neotree_styles(style)
  require('neo-tree').setup({
    default_component_configs = {
      icon = {
        folder_closed = style.icons.folder_closed,
        folder_open = style.icons.folder_open,
        file = style.icons.file,
        symlink = style.icons.symlink
      },
      diagnostics = {
        symbols = {
          error = style.diagnostics.Error,
          warn = style.diagnostics.Warn,
          hint = style.diagnostics.Hint,
          info = style.diagnostics.Info,
          deprecated = style.diagnostics.Deprecated,
          trace = style.diagnostics.Trace
        }
      }
    }
  })
end

-- Unified function to apply a style for both LSP and Neo-tree
local function apply_unified_style(style_name)
  local style = unified_styles[style_name]
  if not style then return end
  apply_lsp_diagnostic_signs(style.diagnostics)
  apply_neotree_styles(style)
end

-- Apply the default style on startup (choose one)
apply_unified_style("playful")

