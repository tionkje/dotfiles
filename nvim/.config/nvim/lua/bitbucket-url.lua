
local function get_relative_path()
	local current_file = vim.api.nvim_buf_get_name(0)
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if git_root and current_file:sub(1, #git_root) == git_root then
		return current_file:sub(#git_root + 2) -- +2 to skip "/" after root
	end
end

local function open_bitbucket_url()
	local remote_url = vim.fn.systemlist("git config --get remote.origin.url")[1]
	-- print("Remote URL: " .. remote_url)
	-- local remote_url = get_remote_url()
	-- local current_file = vim.api.nvim_buf_get_name(0)
  local current_file = get_relative_path()
	-- local ref = get_ref()

	local ref = vim.fn.systemlist("git rev-parse HEAD 2>/dev/null")[1]
	local line_number = vim.api.nvim_win_get_cursor(0)[1]
	
	-- print("Current file: " .. current_file)
	-- print("Ref: " .. ref)

	local file_url
	if string.match(remote_url, "^https") then
		local base_url, common_part = string.match(remote_url, "(https://.+/)(.+)%.git")

		base_url = base_url:gsub("/scm/", "/projects/") .. "repos/"
		local file_url_part = string.match(current_file, ".+/" .. common_part .. "/(.+)")
		file_url = base_url .. common_part .. "/browse/" .. file_url_part .. "?at=" .. ref
	else
		-- Try SSH format: git@bitbucket.org:user/repo.git
		local workspace, repo = string.match(remote_url, "git@bitbucket.org:([^/]+)/([^.]+)%.git")
		file_url = "https://bitbucket.org/"
			.. workspace
			.. "/"
			.. repo
			.. "/src/"
			.. ref
			.. "/"
			.. current_file
			.. "#lines-"
			.. line_number
	end


	-- vim.cmd('!open "' .. file_url .. '"')
    vim.fn.setreg('"', file_url)
    vim.fn.setreg('+', file_url)
	print("Copied to clipboard Bitbucket URL: " .. file_url)
end


vim.keymap.set("n", "<leader>bb", open_bitbucket_url, {})
