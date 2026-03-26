local git_status_cache = {}
local git_status_cache_dir = nil

local function get_git_status(dir)
	if git_status_cache_dir == dir then
		return git_status_cache
	end

	git_status_cache = {}
	git_status_cache_dir = dir

	local handle = io.popen(
		"git -C " .. vim.fn.shellescape(dir) .. " status --porcelain --ignored . 2>/dev/null"
	)
	if not handle then
		return git_status_cache
	end

	local result = handle:read("*a")
	handle:close()

	for line in result:gmatch("[^\n]+") do
		local status = line:sub(1, 2)
		local name = line:sub(4)
		-- Strip trailing / from directories
		name = name:gsub("/$", "")
		-- Only keep the first path component (immediate child of current dir)
		local entry_name = name:match("^([^/]+)")
		if entry_name then
			-- Don't overwrite a "stronger" status (modified > ignored)
			if not git_status_cache[entry_name] or git_status_cache[entry_name] == "!!" then
				git_status_cache[entry_name] = status
			end
		end
	end

	return git_status_cache
end

return {

	{
		"stevearc/oil.nvim",
		-- opts = {
		-- },
		-- Optional dependencies
		-- dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
				default_file_explorer = true,
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
					-- ["<C-v>"] = { "actions.select", opts = { vertical = true } },
					-- ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
					["<C-x>"] = { "actions.select", opts = { horizontal = true } },
					["<C-t>"] = { "actions.select", opts = { tab = true } },
					["<C-p>"] = "actions.preview",
					["<C-c>"] = { "actions.close", mode = "n" },
					-- ["<C-l>"] = "actions.refresh",
					["R"] = "actions.refresh",
					["-"] = { "actions.parent", mode = "n" },
					["_"] = { "actions.open_cwd", mode = "n" },
					["`"] = { "actions.cd", opts = { scope = "win" }, mode = "n" },
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
					-- This function defines what is considered a "hidden" file
					-- Return false to prevent dotfiles from being dimmed
					is_hidden_file = function(name, bufnr)
						local oil = require("oil")
						local dir = oil.get_current_dir()
						if not dir then
							return false
						end
						local status = get_git_status(dir)[name] or ""
						return status == "!!"
					end,
					-- Customize the highlight group for the file name based on git status
					highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
						if entry.type ~= "file" and entry.type ~= "directory" then
							return nil
						end

						local oil = require("oil")
						local dir = oil.get_current_dir()
						if not dir then
							return nil
						end

						local status = get_git_status(dir)[entry.name]
						if not status then
							return nil
						end

						if status:match("M") then
							return entry.type == "directory" and "OilDirModified" or "OilFileModified"
						end
						if status:match("%?") then
							return entry.type == "directory" and "OilDirUntracked" or "OilFileUntracked"
						end

						return nil
					end,
					-- -- Original dotfile detection (commented out):
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

			-- No need to override OilHidden since is_hidden_file returns false for dotfiles

			-- Create custom highlight groups for git-ignored files (dimmed like Comment)
			vim.api.nvim_set_hl(0, "OilFileIgnored", { link = "Comment" })
			vim.api.nvim_set_hl(0, "OilDirIgnored", { link = "Comment" })

			-- Create custom highlight groups for modified files (use DiagnosticWarn color)
			vim.api.nvim_set_hl(0, "OilFileModified", { link = "DiagnosticWarn" })
			vim.api.nvim_set_hl(0, "OilDirModified", { link = "DiagnosticWarn" })

			-- Create custom highlight groups for untracked files (use DiagnosticInfo color)
			vim.api.nvim_set_hl(0, "OilFileUntracked", { link = "DiagnosticInfo" })
			vim.api.nvim_set_hl(0, "OilDirUntracked", { link = "DiagnosticInfo" })

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

			-- Keep git status symbols at normal brightness (reverted)

			-- for _, hl_group in pairs(require("oil-git-status").highlight_groups) do
			-- 	if hl_group.index then
			-- 		vim.api.nvim_set_hl(0, hl_group.hl_group, { fg = "#ff0000" })
			-- 	else
			-- 		vim.api.nvim_set_hl(0, hl_group.hl_group, { fg = "#00ff00" })
			-- 	end
			-- end
		end,
	},
}
