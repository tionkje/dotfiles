-- Highlight local variable declarations that are referenced exactly once
-- in the current file. A signal that the variable may be inlineable.
--
-- Uses nvim-treesitter's `locals` queries for scope/binding resolution.
-- Pure lexical analysis: no LSP traffic, no cross-file awareness.

local M = {}

local NS = vim.api.nvim_create_namespace("single_use_hl")

local SUPPORTED = {
	typescript = true,
	typescriptreact = true,
	javascript = true,
	javascriptreact = true,
}

-- Skip `for (const x of ...)` / `for (const x in ...)` bindings — loop vars
-- aren't inlining candidates even if referenced once.
local function in_for_in_loop(node)
	local declarator = node:parent()
	if not declarator then
		return false
	end
	local outer = declarator:parent()
	if not outer then
		return false
	end
	return outer:type() == "for_in_statement"
end

-- Walk up parents to find the nearest scope node.
local function find_scope(node, scope_ids)
	local cur = node:parent()
	while cur do
		if scope_ids[cur:id()] then
			return cur
		end
		cur = cur:parent()
	end
	return nil
end

-- Resolve a reference to its binding by walking up the scope chain.
-- Returns the def entry (table) or nil if unbound.
local function resolve_binding(ref_scope, ref_name, defs_by_scope, root_defs, scope_ids)
	local scope = ref_scope
	while scope do
		local defs = defs_by_scope[scope:id()]
		if defs then
			for _, d in ipairs(defs) do
				if d.name == ref_name then
					return d
				end
			end
		end
		scope = find_scope(scope, scope_ids)
	end
	for _, d in ipairs(root_defs) do
		if d.name == ref_name then
			return d
		end
	end
	return nil
end

local function update(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local trees = parser:parse()
	if not trees or not trees[1] then
		return
	end
	local root = trees[1]:root()
	local lang = parser:lang()

	local query = vim.treesitter.query.get(lang, "locals")
	if not query then
		return
	end

	-- Pass 1: collect scope node ids so def lookup can find enclosing scope.
	local scope_ids = {}
	for id, node in query:iter_captures(root, bufnr) do
		if query.captures[id] == "local.scope" then
			scope_ids[node:id()] = true
		end
	end

	-- Pass 2: collect defs (grouped by scope) and refs.
	local defs_by_scope = {}
	local root_defs = {}
	local var_defs = {} -- highlight candidates
	local refs = {}

	for id, node in query:iter_captures(root, bufnr) do
		local cap = query.captures[id]
		if vim.startswith(cap, "local.definition") then
			local kind = cap:match("^local%.definition%.(.+)$") or "default"
			local txt = vim.treesitter.get_node_text(node, bufnr)
			local scope = find_scope(node, scope_ids)
			local entry = { node = node, name = txt, kind = kind, refcount = 0 }
			if scope then
				defs_by_scope[scope:id()] = defs_by_scope[scope:id()] or {}
				table.insert(defs_by_scope[scope:id()], entry)
			else
				table.insert(root_defs, entry)
			end
			if kind == "var" then
				table.insert(var_defs, entry)
			end
		elseif cap == "local.reference" then
			table.insert(refs, { node = node, name = vim.treesitter.get_node_text(node, bufnr) })
		end
	end

	-- Pass 3: resolve each ref to its binding and tally.
	for _, ref in ipairs(refs) do
		local ref_scope = find_scope(ref.node, scope_ids)
		local binding = resolve_binding(ref_scope, ref.name, defs_by_scope, root_defs, scope_ids)
		if binding and ref.node:id() ~= binding.node:id() then
			binding.refcount = binding.refcount + 1
		end
	end

	-- Pass 4: apply highlight to var defs used exactly once.
	for _, def in ipairs(var_defs) do
		if def.refcount == 1 and not in_for_in_loop(def.node) then
			local sr, sc, er, ec = def.node:range()
			vim.api.nvim_buf_set_extmark(bufnr, NS, sr, sc, {
				end_row = er,
				end_col = ec,
				hl_group = "SingleUseVariable",
				priority = 200,
			})
		end
	end
end

local timers = {} -- bufnr -> uv_timer

local function schedule_update(bufnr)
	local t = timers[bufnr]
	if t then
		t:stop()
		t:close()
	end
	t = vim.uv.new_timer()
	timers[bufnr] = t
	t:start(
		200,
		0,
		vim.schedule_wrap(function()
			if timers[bufnr] then
				timers[bufnr]:close()
				timers[bufnr] = nil
			end
			if vim.api.nvim_buf_is_valid(bufnr) then
				update(bufnr)
			end
		end)
	)
end

function M.update_now(bufnr)
	update(bufnr or vim.api.nvim_get_current_buf())
end

function M.setup()
	vim.api.nvim_set_hl(0, "SingleUseVariable", {
		italic = true,
		underline = true,
		sp = "#a78bfa",
		default = true,
	})

	local group = vim.api.nvim_create_augroup("single_use_hl", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
		group = group,
		callback = function(args)
			if SUPPORTED[vim.bo[args.buf].filetype] then
				schedule_update(args.buf)
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(args)
			local t = timers[args.buf]
			if t then
				t:stop()
				t:close()
				timers[args.buf] = nil
			end
		end,
	})

	vim.api.nvim_create_user_command("SingleUseHlRefresh", function()
		M.update_now()
	end, {})
end

return M
