return { -- Highlight, edit, and navigate code
	{
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({})

		-- Ensure required parsers are installed
		local ensure_installed = { "bash", "c", "html", "lua", "luadoc", "markdown", "typescript", "tsx", "vim", "vimdoc" }
		local installed = require("nvim-treesitter").get_installed()
		local installed_map = {}
		for _, lang in ipairs(installed) do
			installed_map[lang] = true
		end
		local missing = vim.tbl_filter(function(lang)
			return not installed_map[lang]
		end, ensure_installed)
		if #missing > 0 then
			require("nvim-treesitter").install(missing)
		end

		-- Enable treesitter highlighting and indentation for buffers with a parser
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				if not pcall(vim.treesitter.start, args.buf) then
					return
				end
				-- Ruby depends on vim's regex highlighting for indent rules
				if args.match == "ruby" then
					vim.bo[args.buf].syntax = "on"
				else
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
	},
	"nvim-treesitter/nvim-treesitter-context"
}
