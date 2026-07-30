-- Pre-formats TypeScript diagnostics via pretty-ts-errors-markdown CLI
-- so that ]d / vim.diagnostic.open_float shows readable type errors
-- with syntax-highlighted TypeScript code blocks.
return {
	dir = ".",
	config = function()
		-- Client names (ts_ls = mason typescript LSP) and diagnostic source names
		local ts_clients = { ts_ls = true, tsserver = true, ["deno-ls"] = true, custom_ts_lsp = true }
		local ts_sources = { tsserver = true, ts = true, typescript = true, ["deno-ts"] = true }
		local cache = {}
		local executable = vim.g.pretty_ts_errors_executable or "pretty-ts-errors-markdown"
		-- Each invocation is a full node startup (~175ms, more under load).
		-- Without a cap + in-flight dedup, rapid tsserver publishes while typing
		-- spawn hundreds of node processes and hang the machine.
		local MAX_JOBS = 4
		local active_jobs = 0
		local job_queue = {}
		local in_flight = {} -- cache_key -> list of on_done callbacks

		--- Strip bloat from CLI output, keep markdown code fences for syntax highlighting
		local function clean_markdown(text)
			-- Remove the title line (emoji + long URLs that wrap and are unclickable)
			text = text:gsub("^[^\n]*Error %b()[^\n]*\n", "")
			-- Remove markdown links [text](url) -> text
			text = text:gsub("%[([^%]]-)%]%(.-%)","  %1")
			-- Remove bold **text** -> text
			text = text:gsub("%*%*(.-)%*%*", "%1")
			-- Collapse 3+ blank lines to 2
			text = text:gsub("\n\n\n+", "\n\n")
			return vim.trim(text)
		end

		--- Resolve all waiters for a key. result is nil on failure so the
		--- publish still goes through with the original message.
		local function resolve(cache_key, result)
			local waiters = in_flight[cache_key]
			in_flight[cache_key] = nil
			for _, cb in ipairs(waiters or {}) do
				cb(result)
			end
		end

		local run_job
		run_job = function(lsp_diagnostic, cache_key)
			active_jobs = active_jobs + 1
			local json_str = vim.fn.json_encode(lsp_diagnostic)
			local stdout_chunks = {}

			local job_id = vim.fn.jobstart({ executable }, {
				on_stdout = function(_, data)
					if data then
						for _, chunk in ipairs(data) do
							if chunk ~= "" then
								table.insert(stdout_chunks, chunk)
							end
						end
					end
				end,
				on_exit = function(_, code)
					active_jobs = active_jobs - 1
					local next_job = table.remove(job_queue, 1)
					if next_job then
						run_job(next_job.diag, next_job.key)
					end

					local result = nil
					if code == 0 and #stdout_chunks > 0 then
						local cleaned = clean_markdown(table.concat(stdout_chunks, "\n"))
						if cleaned ~= "" then
							result = cleaned
						end
					else
						vim.schedule(function()
							vim.notify(executable .. " failed (exit " .. code .. ")", vim.log.levels.WARN)
						end)
					end
					resolve(cache_key, result)
				end,
			})

			if job_id > 0 then
				vim.fn.chansend(job_id, json_str)
				vim.fn.chanclose(job_id, "stdin")
			else
				active_jobs = active_jobs - 1
				vim.schedule(function()
					vim.notify("failed to start " .. executable, vim.log.levels.WARN)
				end)
				resolve(cache_key, nil)
			end
		end

		--- Async-format a single diagnostic and call on_done(formatted_message) when ready.
		--- Dedups concurrent requests for the same cache_key and caps concurrent jobs.
		local function format_async(lsp_diagnostic, cache_key, on_done)
			if in_flight[cache_key] then
				table.insert(in_flight[cache_key], on_done)
				return
			end
			in_flight[cache_key] = { on_done }

			if active_jobs >= MAX_JOBS then
				table.insert(job_queue, { diag = lsp_diagnostic, key = cache_key })
			else
				run_job(lsp_diagnostic, cache_key)
			end
		end

		-- Wrap publishDiagnostics to pre-format TS errors
		local original_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

		vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, params, ctx, config)
			local client = vim.lsp.get_client_by_id(ctx.client_id)

			-- Non-TS clients: pass through immediately
			if not client or not ts_clients[client.name] then
				return original_handler(err, params, ctx, config)
			end

			-- Check if all TS diagnostics are already cached
			local all_cached = true
			for _, diag in ipairs(params.diagnostics) do
				local cache_key = tostring(diag.code or "") .. (diag.message or "")
				if cache[cache_key] then
					diag.message = cache[cache_key]
				else
					all_cached = false
				end
			end

			if all_cached then
				return original_handler(err, params, ctx, config)
			end

			-- Some need formatting: wait for all to complete, then publish once
			local pending = 0
			for _, diag in ipairs(params.diagnostics) do
				local cache_key = tostring(diag.code or "") .. (diag.message or "")
				if not cache[cache_key] then
					pending = pending + 1
					format_async(diag, cache_key, function(formatted)
						if formatted then
							cache[cache_key] = formatted
						end
						pending = pending - 1
						if pending == 0 then
							vim.schedule(function()
								for _, d in ipairs(params.diagnostics) do
									local key = tostring(d.code or "") .. (d.message or "")
									if cache[key] then
										d.message = cache[key]
									end
								end
								original_handler(err, params, ctx, config)
							end)
						end
					end)
				end
			end
		end

		-- Post-process the diagnostic float to enable markdown rendering
		-- with treesitter syntax highlighting for TypeScript code blocks.
		-- Uses winhighlight to neutralize DiagnosticFloatingError red so
		-- treesitter colors show through. Does not change ]d flow at all.
		local original_open_float = vim.diagnostic.open_float

		vim.diagnostic.open_float = function(opts, ...)
			local float_bufnr, winnr = original_open_float(opts, ...)
			if not float_bufnr or not winnr then
				return float_bufnr, winnr
			end

			-- Check if current line has any TS diagnostics
			local cur_bufnr = vim.api.nvim_get_current_buf()
			local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
			local diagnostics = vim.diagnostic.get(cur_bufnr, { lnum = lnum })
			local has_ts = false
			for _, d in ipairs(diagnostics) do
				if ts_sources[d.source] then
					has_ts = true
					break
				end
			end

			if has_ts then
				-- Clear ALL extmarks (ns=-1) on the float buffer. The diagnostic
				-- highlights have priority 4096 which overrides treesitter (100).
				vim.api.nvim_buf_clear_namespace(float_bufnr, -1, 0, -1)
				-- Enable markdown treesitter for code fence syntax highlighting
				vim.bo[float_bufnr].filetype = "markdown"
				vim.treesitter.start(float_bufnr)
				vim.wo[winnr].conceallevel = 2
				vim.wo[winnr].concealcursor = ""
			end

			return float_bufnr, winnr
		end
	end,
}
