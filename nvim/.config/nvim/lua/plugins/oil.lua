return {

	{
		"stevearc/oil.nvim",
		-- opts = {
		-- },
		-- Optional dependencies
		-- dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
				default_file_explorer = false,
				lsp_file_methods = {
					-- Enable or disable LSP file operations
					-- enabled = true,
					-- Time to wait for LSP file operations to complete before skipping
					-- timeout_ms = 1000,
					-- Set to true to autosave buffers that are updated with LSP willRenameFiles
					-- Set to "unmodified" to only save unmodified buffers
					autosave_changes = true,
				},
				-- Set to true to watch the filesystem for changes and reload oil
				watch_for_changes = true,
				win_options = {
					signcolumn = "yes:2",
				},

				-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
				-- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
				-- Additionally, if it is a string that matches "actions.<name>",
				-- it will use the mapping at require("oil.actions").<name>
				-- Set to `false` to remove a keymap
				-- See :help oil-actions for a list of all available actions
				keymaps = {
					["g?"] = { "actions.show_help", mode = "n" },
					["<CR>"] = "actions.select",
					["<C-s>"] = { "actions.select", opts = { vertical = true } },
					["<C-v>"] = { "actions.select", opts = { vertical = true } },
					["<C-h>"] = { "actions.select", opts = { horizontal = true } },
					["<C-x>"] = { "actions.select", opts = { horizontal = true } },
					["<C-t>"] = { "actions.select", opts = { tab = true } },
					["<C-p>"] = "actions.preview",
					["<C-c>"] = { "actions.close", mode = "n" },
					-- ["<C-l>"] = "actions.refresh",
					["R"] = "actions.refresh",
					["-"] = { "actions.parent", mode = "n" },
					["_"] = { "actions.open_cwd", mode = "n" },
					["`"] = { "actions.cd", mode = "n" },
					["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
					["gs"] = { "actions.change_sort", mode = "n" },
					["gx"] = "actions.open_external",
					["g."] = { "actions.toggle_hidden", mode = "n" },
					["g\\"] = { "actions.toggle_trash", mode = "n" },
				},
				-- Set to false to disable all of the above keymaps
				use_default_keymaps = false,

				view_options = {
					-- Show files and directories that start with "."
					show_hidden = true,
					-- -- This function defines what is considered a "hidden" file
					-- is_hidden_file = function(name, bufnr)
					-- 	local m = name:match("^%.")
					-- 	return m ~= nil
					-- end,
					-- -- This function defines what will never be shown, even when `show_hidden` is set
					-- is_always_hidden = function(name, bufnr)
					-- 	return false
					-- end,
					-- -- Sort file names with numbers in a more intuitive order for humans.
					-- -- Can be "fast", true, or false. "fast" will turn it off for large directories.
					-- natural_order = "fast",
					-- -- Sort file and directory names case insensitive
					-- case_insensitive = false,
					-- sort = {
					-- 	-- sort order can be "asc" or "desc"
					-- 	-- see :help oil-columns to see which columns are sortable
					-- 	{ "type", "asc" },
					-- 	{ "name", "asc" },
					-- },
					-- -- Customize the highlight group for the file name
					-- highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
					-- 	return nil
					-- end,
				},
			})

			vim.keymap.set("n", "-", ":Oil<CR>", { desc = "Open Oil" })
		end,
	},
	{
		"refractalize/oil-git-status.nvim",

		dependencies = {
			"stevearc/oil.nvim",
		},

		config = function()
			require("oil-git-status").setup({
				show_ignored = true, -- show files that match gitignore with !!
				symbols = { -- customize the symbols that appear in the git status columns
					index = {
						["!"] = "!",
						["?"] = "?",
						["A"] = "A",
						["C"] = "C",
						["D"] = "D",
						["M"] = "M",
						["R"] = "R",
						["T"] = "T",
						["U"] = "U",
						[" "] = " ",
					},
					working_tree = {
						["!"] = "!",
						["?"] = "?",
						["A"] = "A",
						["C"] = "C",
						["D"] = "D",
						["M"] = "M",
						["R"] = "R",
						["T"] = "T",
						["U"] = "U",
						[" "] = " ",
					},
				},
			})

			for _, hl_group in pairs(require("oil-git-status").highlight_groups) do
				if hl_group.index then
					vim.api.nvim_set_hl(0, hl_group.hl_group, { fg = "#ff0000" })
				else
					vim.api.nvim_set_hl(0, hl_group.hl_group, { fg = "#00ff00" })
				end
			end
		end,
	},
}
