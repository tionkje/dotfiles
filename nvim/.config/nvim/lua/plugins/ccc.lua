return {
	"uga-rosa/ccc.nvim",
	cmd = { "CccPick", "CccConvert", "CccHighlighterToggle" },
	keys = {
		{ "<leader>cp", "<cmd>CccPick<cr>", desc = "Color picker" },
	},
	config = function()
		local ccc = require("ccc")
		ccc.setup({
			default_color = "#565f89",
			inputs = {
				ccc.input.hsl, -- HSL first → opens with HSL sliders
				ccc.input.rgb,
				ccc.input.hsv,
			},
		})
	end,
}
