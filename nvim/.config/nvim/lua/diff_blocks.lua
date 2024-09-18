-- Lua function to capture and compare two text blocks in Neovim
local M = {}

-- Capture first selection
M.first_selection = nil
local function get_selection(args)
  return table.concat(vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false),"\n")
end
-- Function to capture the first block of text
M.capture_first_block = function(args)
  -- Get the selected text
  -- M.first_selection = table.concat(vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false),"\n")
  M.first_selection = get_selection(args)
  print("First block of text captured!")
  -- for i, line in ipairs(M.first_selection) do
  --   print("Line " .. i .. ": " .. line)
  -- end
end

-- Function to capture the second block and perform a diff
M.diff_blocks = function(args)
  if not M.first_selection then
    M.capture_first_block(args)
    return
  end

  -- Get the second selected block
  -- local second_selection = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
  local second_selection = get_selection(args)

  -- Perform the diff
  vim.cmd("new")  -- Open a new window for the diff output
  vim.cmd("setlocal buftype=nofile")
  vim.cmd("setlocal bufhidden=wipe")

  local diff_result = vim.diff(M.first_selection, second_selection,{});
  local t = {}
  for str in string.gmatch(diff_result, "([^\n]+)") do
    table.insert(t, str)
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, t);
  
  print("Diff completed!")

  M.first_selection = nil
end

-- Add the commands to your Neovim command palette
-- vim.api.nvim_create_user_command("CaptureFirstBlock", M.capture_first_block, {})
vim.api.nvim_create_user_command("DiffBlocks", M.diff_blocks, {range = true})

return M
