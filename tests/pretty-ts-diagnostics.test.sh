#!/usr/bin/env bash
# Regression test for the pretty-ts-diagnostics spawn storm: drives the real
# publishDiagnostics wrapper in headless nvim with a stub formatter, firing
# 4 rapid publishes x 10 diagnostics (as tsserver does while typing), and
# asserts in-flight dedup (10 spawns total, not 40), the concurrency cap,
# and that a failing formatter doesn't drop the publish.
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Stub formatter: log the spawn, hold briefly so publishes overlap, echo markdown
cat >"$tmp/fake-formatter" <<'EOF'
#!/usr/bin/env bash
echo x >>"${SPAWN_LOG:?}"
input=$(cat)
sleep 0.2
if [[ "${FAIL_MODE:-}" == 1 ]]; then exit 1; fi
echo "formatted: $input"
EOF
chmod +x "$tmp/fake-formatter"
export SPAWN_LOG="$tmp/spawns.log"

cat >"$tmp/repro.lua" <<'EOF'
vim.g.pretty_ts_errors_executable = vim.env.FAKE_FORMATTER
local spec = dofile(vim.env.PLUGIN_FILE)

local published = 0
vim.lsp.get_client_by_id = function() return { name = "ts_ls" } end
vim.lsp.handlers["textDocument/publishDiagnostics"] = function() published = published + 1 end
spec.config()
local handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

local diags = {}
for i = 1, 10 do
	diags[i] = {
		code = 2322,
		message = "Type 'string" .. i .. "' is not assignable to type 'number'.",
		range = { start = { line = i, character = 0 }, ["end"] = { line = i, character = 1 } },
		severity = 1,
		source = "typescript",
	}
end

for _ = 1, 4 do
	handler(nil, { uri = "file:///tmp/x.ts", diagnostics = vim.deepcopy(diags) }, { client_id = 1 }, {})
end

-- sample concurrent formatter processes while jobs drain
local max_concurrent = 0
vim.wait(8000, function()
	local n = tonumber(vim.fn.system("pgrep -fc fake-formatter 2>/dev/null")) or 0
	max_concurrent = math.max(max_concurrent, n)
	return published == 4
end, 25)

print(string.format("RESULT published=%d max_concurrent=%d", published, max_concurrent))
vim.cmd("qa!")
EOF

export FAKE_FORMATTER="$tmp/fake-formatter"
export PLUGIN_FILE="$HOME/.dotfiles/nvim/.config/nvim/lua/plugins/pretty-ts-diagnostics.lua"

echo "-- happy path: dedup + cap"
out=$(nvim --headless --clean -l "$tmp/repro.lua" 2>&1)
echo "$out"
spawns=$(wc -l <"$SPAWN_LOG")
read -r published max_concurrent < <(echo "$out" | grep -o 'published=[0-9]* max_concurrent=[0-9]*' | tr -dc '0-9 \n')
[[ $spawns -eq 10 ]] || { echo "FAIL: expected 10 spawns (dedup), got $spawns"; exit 1; }
[[ $max_concurrent -le 4 ]] || { echo "FAIL: concurrency cap exceeded: $max_concurrent"; exit 1; }
[[ $published -eq 4 ]] || { echo "FAIL: expected 4 publishes, got $published"; exit 1; }

echo "-- failure path: formatter exit 1 must not drop the publish"
: >"$SPAWN_LOG"
export FAIL_MODE=1
out=$(nvim --headless --clean -l "$tmp/repro.lua" 2>&1)
echo "$out"
echo "$out" | grep -q "published=4" || { echo "FAIL: publish dropped when formatter fails"; exit 1; }

echo "PASS"
