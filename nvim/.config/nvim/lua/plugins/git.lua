-- Here is a more advanced example where we pass configuration
-- options to `gitsigns.nvim`. This is equivalent to the following Lua:
--    require('gitsigns').setup({ ... })
--
-- See `:help gitsigns` to understand what the configuration keys do
return { -- Adds git related signs to the gutter, as well as utilities for managing changes
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,

				-- signs = {
				-- 	add = { text = "+" },
				-- 	change = { text = "~" },
				-- 	delete = { text = "_" },
				-- 	topdelete = { text = "‾" },
				-- 	changedelete = { text = "~" },
				-- },
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <abbrev_sha> - <summary>",
				-- current_line_blame_formatter_opts = {
				-- 	relative_time = true,
				-- },
				-- status_formatter = function(status)
				-- 	local added, changed, removed = status.added, status.changed, status.removed
				-- 	local status_txt = {}
				-- 	if added and added > 0 then
				-- 		table.insert(status_txt, "+" .. added)
				-- 	end
				-- 	if changed and changed > 0 then
				-- 		table.insert(status_txt, "~" .. changed)
				-- 	end
				-- 	if removed and removed > 0 then
				-- 		table.insert(status_txt, "-" .. removed)
				-- 	end
				-- 	return table.concat(status_txt, " ")
				-- end,
				-- status_formatter = function()
				-- 	return "blablabalbal"
				-- end,
			})
			vim.keymap.set(
				"n",
				"<leader>gh",
				"<cmd>lua require('gitsigns').toggle_current_line_blame()<CR>",
				{ desc = "Toggle [G]it [H]istory" }
			)
			-- vim.keymap.set("n", "<leader>gs", "<cmd>lua require('gitsigns').stage_hunk()<CR>", { desc = "Stage [S]taging" })
			-- vim.keymap.set( "n", "<leader>gu", "<cmd>lua require('gitsigns').undo_stage_hunk()<CR>", { desc = "[U]ndo [S]taging" })
			-- vim.keymap.set("n", "<leader>gr", "<cmd>lua require('gitsigns').reset_hunk()<CR>", { desc = "[R]eset [H]unk" })
			-- vim.keymap.set("n", "<leader>gp", "<cmd>lua require('gitsigns').preview_hunk()<CR>", { desc = "[P]review [H]unk" })
			-- vim.keymap.set( "n", "<leader>gp", "<cmd>lua require('gitsigns').preview_hunk_inline()<CR>", { desc = "[P]review [H]unk" })
			-- vim.keymap.set( "n", "<leader>gb", "<cmd>lua require('gitsigns').blame_line(true)<CR>", { desc = "[B]lame [L]ine" })
		end,
	},
	{
		"tpope/vim-fugitive",
		config = function()
			vim.keymap.set("n", "<leader>gs", "<cmd>Git<CR>", { desc = "[G]it [S]tatus (fugitive)" })
			vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", { desc = "[G]it [D]iff current file" })
			vim.keymap.set("n", "<leader>gB", "<cmd>Git blame<CR>", { desc = "[G]it [B]lame file" })
			vim.keymap.set("n", "<leader>gL", "<cmd>Git log --oneline -20<CR>", { desc = "[G]it [L]og recent" })
			vim.keymap.set("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "[G]it [p]ush" })
			vim.keymap.set("n", "<leader>gP", "<cmd>Git pull --rebase<CR>", { desc = "[G]it [P]ull rebase" })
		end,
	},
}
