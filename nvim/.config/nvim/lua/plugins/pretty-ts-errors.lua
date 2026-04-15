-- pretty-ts-errors.lua
return {
	{
		"youyoumu/pretty-ts-errors.nvim",
		config = function()
			require("pretty-ts-errors").setup({
				executable = "pretty-ts-errors-markdown", -- Path to the executable
				float_opts = {
					border = "rounded", -- Border style for floating windows
					max_width = 120, -- Maximum width of floating windows
					max_height = 20, -- Maximum height of floating windows
					wrap = true, -- Whether to wrap long lines
				},
				auto_open = false, -- Automatically show errors on hover
			})
			-- Show error under cursor
			vim.keymap.set("n", "<leader>te", function()
				require("pretty-ts-errors").show_formatted_error()
			end, { desc = "Show TS error" })

			-- Show all errors in file
			vim.keymap.set("n", "<leader>tE", function()
				require("pretty-ts-errors").open_all_errors()
			end, { desc = "Show all TS errors" })

			-- Toggle auto-display
			vim.keymap.set("n", "<leader>tt", function()
				require("pretty-ts-errors").toggle_auto_open()
			end, { desc = "Toggle TS error auto-display" })
		end,
	},
}
