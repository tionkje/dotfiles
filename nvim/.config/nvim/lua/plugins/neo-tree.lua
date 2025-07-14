return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			"3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		config = function()
			-- vim.g.neo_tree_remove_legacy_commands = true

			require("neo-tree").setup({
				-- auto_open = false,  -- Do not auto open when opening a directory
				filesystem = {
						hijack_netrw_behavior = "disabled",
					filtered_items = {
						visible = true, -- when true, they will just be displayed differently than normal items
						hide_dotfiles = false,
						hide_gitignored = true,
						--   hide_hidden = true, -- only works on Windows for hidden files/directories
						--   hide_by_name = {
						--     --"node_modules"
						--   },
						--   hide_by_pattern = { -- uses glob style patterns
						--     --"*.meta",
						--     --"*/src/*/tsconfig.json",
						--   },
						--   always_show = { -- remains visible even if other settings would normally hide it
						--     --".gitignored",
						--   },
						--   never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
						--     --".DS_Store",
						--     --"thumbs.db"
						--   },
						--   never_show_by_pattern = { -- uses glob style patterns
						--     --".null-ls_*",
						--   },
					},
					follow_current_file = {
						enabled = true, -- This will find and focus the file in the active buffer every time
						--               -- the current file is changed while the tree is open.
						-- leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
					},
					window = {
						-- pos
						mappings = {
							--disable fuzzy finder
							-- ["/"] = "noop"
						},
					},
				},

				close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
			})
			vim.keymap.set("n", "<leader>n", ":Neotree filesystem reveal left<CR>", { desc = "Show [N]eo-tree filesystem" })
			vim.keymap.set("n", "<leader>b", ":Neotree buffers reveal left<CR>", { desc = "Show neo-tree [B]uffers" })
			vim.keymap.set(
				"n",
				"<leader>gn",
				":Neotree git_status reveal left<CR>",
				{ desc = "Show [G]it status [N]eo-tree" }
			)
		end,
	},
	{
		"antosha417/nvim-lsp-file-operations",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-neo-tree/neo-tree.nvim",
		},
		config = function()
			require("lsp-file-operations").setup()
		end,
	},
}
