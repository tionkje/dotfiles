return {
	{
		"mistricky/codesnap.nvim",
		build = "make",
		config = function()
			require("codesnap").setup({
				save_path = "~/Pictures/Screenshots/",
				has_breadcrumbs = true,
				show_workspace = true,
				has_line_number = true,
				-- bg_theme = "bamboo",
				bg_color = "#535c68",
				watermark = "",

				mac_window_bar = false,
				title = "",
				code_font_family = "MesloLGS Nerd Font",
				watermark_font_family = "Pacifico",
				bg_theme = "default",
				breadcrumbs_separator = "/",
				min_width = 0,
			})
			vim.keymap.set({"n","v"}, "<leader>chs", ":'<,'>CodeSnapSaveHighlight<CR>", { desc = "{C}apture {H}light {S}ave" })
			vim.keymap.set({"n","v"}, "<leader>chc", ":'<,'>CodeSnapHighlight<CR>", { desc = "{C}apture {H}light {C}lipboard" })
			vim.keymap.set({"n","v"}, "<leader>cc", ":'<,'>CodeSnap<CR>", { desc = "{C}apture {C}lipboard" })
			vim.keymap.set({"n","v"}, "<leader>cs", ":'<,'>CodeSnapSave<CR>", { desc = "{C}apture {S}ave" })
		end,
	},
	-- {	"krivahtoo/silicon.nvim"}
	-- build = './install.sh build',
	-- config = function()
	-- 	require("silicon").setup({
	-- 		{
	-- 			-- Output configuration for the saved image
	-- 			output = {
	-- 				-- (string) The full path of the file to save to.
	-- 				file = "",
	-- 				-- (boolean) Whether to copy the image to clipboard instead of saving to file.
	-- 				clipboard = true,
	-- 				-- (string) Where to save images, defaults to the current directory.
	-- 				--  e.g. /home/user/Pictures
	-- 				path = "~/Pictures/Screenshots/",
	-- 				-- (string) The filename format to use. Can include placeholders for date and time.
	-- 				-- https://time-rs.github.io/book/api/format-description.html#components
	-- 				format = "silicon_[year][month][day]_[hour][minute][second].png",
	-- 			},
	--
	-- 			-- Font and theme configuration for the screenshot.
	-- 			font = "Hack=20", -- (string) The font and font size to use for the screenshot.
	-- 			-- (string) The color theme to use for syntax highlighting.
	-- 			-- It can be a theme name or path to a .tmTheme file.
	-- 			theme = "Dracula",
	--
	-- 			-- Background and shadow configuration for the screenshot
	-- 			background = "#eff", -- (string) The background color for the screenshot.
	-- 			shadow = {
	-- 				blur_radius = 0.0, -- (number) The blur radius for the shadow, set to 0.0 for no shadow.
	-- 				offset_x = 0, -- (number) The horizontal offset for the shadow.
	-- 				offset_y = 0, -- (number) The vertical offset for the shadow.
	-- 				color = "#555", -- (string) The color for the shadow.
	-- 			},
	--
	-- 			pad_horiz = 100, -- (number) The horizontal padding.
	-- 			pad_vert = 80, -- (number) The vertical padding.
	-- 			line_number = false, -- (boolean) Whether to show line numbers in the screenshot.
	-- 			line_pad = 2, -- (number) The padding between lines.
	-- 			line_offset = 1, -- (number) The starting line number for the screenshot.
	-- 			tab_width = 4, -- (number) The tab width for the screenshot.
	-- 			gobble = false, -- (boolean) Whether to trim extra indentation.
	-- 			highlight_selection = false, -- (boolean) Whether to capture the whole file and highlight selected lines.
	-- 			round_corner = true,
	-- 			window_controls = true, -- (boolean) Whether to show window controls (minimize, maximize, close) in the screenshot.
	-- 			window_title = nil, -- (function) A function that returns the window title as a string.
	--
	-- 			-- Watermark configuration for the screenshot
	-- 			watermark = {
	-- 				text = nil, -- (string) The text to use as the watermark, set to nil to disable.
	-- 				color = "#222", -- (string) The color for the watermark text.
	-- 				-- (string) The style for the watermark text, possible values are:
	-- 				-- 'bold', 'italic', 'bolditalic', or anything else defaults to 'regular'.
	-- 				style = "bold",
	-- 			},
	-- 		},
	-- 	})
	-- end,
}
