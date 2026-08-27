return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		lazy = false,
		config = function()
			-- START: Neovim 0.12 compatibility patch for nvim-treesitter
			local query = require("vim.treesitter.query")
			local old_add_dir = query.add_directive
			local old_add_pred = query.add_predicate

			local function unwrap(match)
				local res = {}
				for k, v in pairs(match) do
					res[k] = type(v) == "table" and v[1] or v
				end
				return res
			end

			query.add_directive = function(name, handler, opts)
				old_add_dir(name, function(match, pattern, bufnr, pred, metadata)
					return handler(unwrap(match), pattern, bufnr, pred, metadata)
				end, opts)
			end

			query.add_predicate = function(name, handler, opts)
				old_add_pred(name, function(match, pattern, bufnr, pred)
					return handler(unwrap(match), pattern, bufnr, pred)
				end, opts)
			end
			
			-- This require will now register nvim-treesitter's directives using our wrapped functions
			local ts = require("nvim-treesitter")
			
			-- Restore the original functions to avoid breaking Neovim core
			query.add_directive = old_add_dir
			query.add_predicate = old_add_pred
			-- END: patch

			-- Specify which parsers to ensure are installed
			ts.install({
				"go",
				"gomod",
				"gowork",
				"gosum",
				"lua",
				"bash",
				"cpp",
				"proto",
				"diff",
				"markdown",
				"typespec",
			})

			-- Automatically enable highlighting and indentation for any
			-- filetype that has an installed parser (replaces the old
			-- auto_install/highlight.enable/indent.enable options).
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(args.match) or args.match
					if vim.treesitter.language.add(lang) then
						vim.treesitter.start()
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
}
