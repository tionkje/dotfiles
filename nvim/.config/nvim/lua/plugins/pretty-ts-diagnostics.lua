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
		local executable = "pretty-ts-errors-markdown"

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

		--- Async-format a single diagnostic and call on_done(formatted_message) when ready
		local function format_async(lsp_diagnostic, on_done)
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
					if code == 0 and #stdout_chunks > 0 then
						local raw = table.concat(stdout_chunks, "\n")
						local cleaned = clean_markdown(raw)
						if cleaned ~= "" then
							on_done(cleaned)
						end
					end
				end,
			})

			if job_id > 0 then
				vim.fn.chansend(job_id, json_str)
				vim.fn.chanclose(job_id, "stdin")
			end
		end

		-- Wrap publishDiagnostics to pre-format TS errors
		local original_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

		vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, params, ctx, config)
			-- Call original handler immediately so diagnostics show up right away
			original_handler(err, params, ctx, config)

			-- Only post-process TS diagnostics
			local client = vim.lsp.get_client_by_id(ctx.client_id)
			if not client or not ts_clients[client.name] then
				return
			end

			local uri = params.uri
			local bufnr = vim.uri_to_bufnr(uri)
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			local pending = 0
			local any_updated = false

			for _, diag in ipairs(params.diagnostics) do
				local cache_key = tostring(diag.code or "") .. (diag.message or "")

				if cache[cache_key] then
					diag.message = cache[cache_key]
					any_updated = true
				else
					pending = pending + 1
					format_async(diag, function(formatted)
						cache[cache_key] = formatted
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

			if pending == 0 and any_updated then
				original_handler(err, params, ctx, config)
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
