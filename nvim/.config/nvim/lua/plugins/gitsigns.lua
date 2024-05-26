
	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`. This is equivalent to the following Lua:
	--    require('gitsigns').setup({ ... })
	--
	-- See `:help gitsigns` to understand what the configuration keys do
return	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
      current_line_blame = true,

			-- signs = {
			-- 	add = { text = "+" },
			-- 	change = { text = "~" },
			-- 	delete = { text = "_" },
			-- 	topdelete = { text = "‾" },
			-- 	changedelete = { text = "~" },
			-- },
		},
    config = function()
      require("gitsigns").setup()
      vim.keymap.set("n", "<leader>gh", "<cmd>lua require('gitsigns').toggle_current_line_blame()<CR>", { desc = "Toggle [G]it [H]istory" })
      vim.keymap.set("n", "<leader>gs", "<cmd>lua require('gitsigns').stage_hunk()<CR>", { desc = "Stage [S]taging" })
      vim.keymap.set("n", "<leader>gu", "<cmd>lua require('gitsigns').undo_stage_hunk()<CR>", { desc = "[U]ndo [S]taging" })
      vim.keymap.set("n", "<leader>gr", "<cmd>lua require('gitsigns').reset_hunk()<CR>", { desc = "[R]eset [H]unk" })
      -- vim.keymap.set("n", "<leader>gp", "<cmd>lua require('gitsigns').preview_hunk()<CR>", { desc = "[P]review [H]unk" })
      vim.keymap.set("n", "<leader>gp", "<cmd>lua require('gitsigns').preview_hunk_inline()<CR>", { desc = "[P]review [H]unk" })
      vim.keymap.set("n", "<leader>gb", "<cmd>lua require('gitsigns').blame_line(true)<CR>", { desc = "[B]lame [L]ine" })

    end,
	}
