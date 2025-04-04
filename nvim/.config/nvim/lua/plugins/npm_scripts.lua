return {
	"antonk52/npm_scripts.nvim",
	config = function()

		require("npm_scripts").setup({})

		vim.keymap.set("n", "<leader>rs", require("npm_scripts").run_from_all, { desc = "[R]un npm [s]cript" })

	end,
}
