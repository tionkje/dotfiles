return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",

		"marilari88/neotest-vitest",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-vitest"),
			},
		})

		vim.api.nvim_set_keymap(
			"n",
			"<leader>twr",
			"<cmd>lua require('neotest').run.run({ vitestCommand = 'vitest --watch' })<cr>",
			{ desc = "Run Watch" }
		)

		vim.api.nvim_set_keymap(
			"n",
			"<leader>twf",
			"<cmd>lua require('neotest').run.run({ vim.fn.expand('%'), vitestCommand = 'vitest --watch' })<cr>",
			{ desc = "Run Watch File" }
		)
	end,
}
