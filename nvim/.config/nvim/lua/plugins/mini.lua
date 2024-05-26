return { -- Collection of various small independent plugins/modules
	"echasnovski/mini.nvim",
	config = function()
		-- Better Around/Inside textobjects
		--
		-- Examples:
		--  - va)  - [V]isually select [A]round [)]paren
		--  - yinq - [Y]ank [I]nside [N]ext [']quote
		--  - ci'  - [C]hange [I]nside [']quote
		require("mini.ai").setup({ n_lines = 500 })

		-- Add/delete/replace surroundings (brackets, quotes, etc.)
		--
		-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
		-- - sd'   - [S]urround [D]elete [']quotes
		-- - sr)'  - [S]urround [R]eplace [)] [']
		require("mini.surround").setup()

		-- Simple and easy statusline.
		--  You could remove this setup call if you don't like it,
		--  and try some other statusline plugin
		local statusline = require("mini.statusline")

		local original_section_git = statusline.section_git -- Keep the original function

		statusline.section_git = function(args)
			if not vim.b.gitsigns_head then
				return original_section_git(args)
			end

			-- print("statusline " .. (vim.b.gisigns_head or '-'));
			-- print(ori_result);
			local function truncate_string(str, max_len)
				if #str > max_len then
					return str:sub(1, max_len - 3) .. "..."
				end
				return str
			end

			-- Truncate the branch name if it exists
			local original_head = vim.b.gitsigns_head
			if original_head then
				vim.b.gitsigns_head = truncate_string(original_head, 15) -- Adjust the '10' as needed
			end

			-- Call the original function with possibly modified `gitsigns_head`
			local result = original_section_git(args)

			-- Restore the original `gitsigns_head` to avoid side effects
			vim.b.gitsigns_head = original_head

			return result
		end

		-- set use_icons to true if you have a Nerd Font
		statusline.setup({ use_icons = vim.g.have_nerd_font })

		-- You can configure sections in the statusline by overriding their
		-- default behavior. For example, here we set the section for
		-- cursor location to LINE:COLUMN
		---@diagnostic disable-next-line: duplicate-set-field
		statusline.section_location = function()
			return "%2l:%-2v"
		end

		-- ... and there is more!
		--  Check out: https://github.com/echasnovski/mini.nvim
	end,
}
