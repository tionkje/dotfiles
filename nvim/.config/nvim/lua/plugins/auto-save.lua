return {
	"Pocco81/auto-save.nvim",
	config = function()
		require("auto-save").setup({
			-- your config goes here
			-- or just leave it empty :)
			debounce_delay = 135, -- saves the file at most every `debounce_delay` milliseconds
		})
		-- vim.api.nvim_set_keymap("n", "<leader>a", ":ASToggle<CR>", {})
	end,
}
