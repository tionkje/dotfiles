local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

local M = {}

local live_multigrep = function(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.fn.getcwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local pieces = vim.split(prompt, "  ")
			local args = { "rg" }

			-- First part is the search pattern
			if pieces[1] then
				table.insert(args, "-e")
				table.insert(args, pieces[1])
			end

			-- Second part is the path filter
			if pieces[2] then
				-- Enhanced path filtering with multiple patterns support
				local path_patterns = vim.split(pieces[2], " ")
				for _, pattern in ipairs(path_patterns) do
					if pattern and pattern ~= "" then
						-- Support both inclusion and exclusion patterns
						if pattern:sub(1, 1) == "!" then
							-- Exclusion pattern: !pattern
							table.insert(args, "-g")
							table.insert(args, pattern)
						else
							-- Inclusion pattern: pattern or *pattern*
							table.insert(args, "-g")
							-- Auto-wrap with wildcards if not already present and not a regex
							if not pattern:match("[*?]") and not pattern:match("^/.*/$") then
								table.insert(args, "*" .. pattern .. "*")
							else
								table.insert(args, pattern)
							end
						end
					end
				end
			end

			return vim.iter({
				args,
				{ "--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
				"--hidden" },
			}):flatten():totable()
		end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
	})

	pickers
		.new(opts, {
      debounce = 100,
      prompt_title = "Live Multi Grep (search  path_filter)",
			finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require("telescope.sorters").empty(),
		})
		:find()
end

M.setup = function()
	vim.keymap.set("n", "<leader>sG", live_multigrep, { desc = "[S]earch by [G]rep with path filter" })
end

return M
