#!/usr/bin/env bash

set -euo pipefail
trap 'notify-send -u critical "Error: $(basename "$0")" "Line $LINENO failed (exit $?)"' ERR

MONITORS_LUA="$HOME/.config/hypr/monitors.lua"
# Write through the stow symlink: replacing the symlink itself would unstow it
MONITORS_TARGET=$(realpath "$MONITORS_LUA")
LAPTOP="eDP-1"

# Find external monitor — `all` includes disabled monitors, so a disabled
# output can be re-enabled from here
EXT=$(hyprctl -j monitors all | jq -r ".[] | select(.name != \"$LAPTOP\") | .name" | head -1)

if [[ -z "$EXT" ]]; then
  echo "No external monitor detected"
  exit 1
fi

# Read current entry for this monitor by evaluating monitors.lua (it returns a
# plain data table, see hyprland.lua)
entry=$(lua - "$MONITORS_TARGET" "$EXT" <<'EOF'
local path, out = ...
local monitors = assert(dofile(path))
for _, m in ipairs(monitors) do
  if m.output == out then
    print(table.concat({
      m.mode or "unknown",
      m.position or "auto-center-up",
      tostring(m.scale or 1),
      m.disabled and "true" or "false",
    }, "\t"))
    return
  end
end
print(table.concat({ "unknown", "auto-center-up", "1", "false" }, "\t"))
EOF
)
IFS=$'\t' read -r current_res current_pos current_scale current_disabled <<<"$entry"

# Query available modes: keep highest frequency per resolution, sort highest resolution first
modes=$(hyprctl -j monitors all | jq -r ".[] | select(.name == \"$EXT\") | .availableModes[]" \
  | sort -t'@' -k2,2rn \
  | awk -F'@' '!seen[$1]++' \
  | awk -F'[x@]' '{printf "%010d %010d %s\n", $1, $2, $0}' \
  | sort -rn \
  | awk '{print $3}')

# Find line number of current resolution for fzf cursor position
# grep exits 1 when no match — not an error here, just means current res isn't in the list
current_idx=$(echo "$modes" | grep -n "^${current_res}$" | head -1 | cut -d: -f1 || true)
fzf_pos=()
if [[ -n "$current_idx" ]]; then
  fzf_pos=(--bind "start:pos($current_idx)")
fi

# Show fzf picker
selected=$(echo "$modes" \
  | fzf --no-info --prompt "resolution ($EXT) > " \
    --header "current: $current_res" "${fzf_pos[@]}") || exit 0

# Save previous resolution for revert
old_res="$current_res"

# Apply immediately (not persisted yet)
hyprctl keyword monitor "$EXT,$selected,$current_pos,$current_scale"

# Confirmation countdown — terminal stays open
TIMEOUT=10
confirmed=false
for ((i=TIMEOUT; i>0; i--)); do
  printf "\rKeep %s? ENTER=confirm, reverting in %2d..." "$selected" "$i"
  if read -t 1 -r; then
    confirmed=true
    break
  fi
done
echo ""

if [[ "$confirmed" == true ]]; then
  # Persist: evaluate monitors.lua, update/insert this output's entry (clearing
  # disabled — picking a resolution re-enables it), serialize the whole table
  # back, parse-check the result before replacing the file.
  lua - "$MONITORS_TARGET" "$EXT" "$selected" <<'EOF'
local path, out, mode = ...
local monitors = assert(dofile(path))
assert(type(monitors) == "table", path .. " did not return a table")

local entry
for _, m in ipairs(monitors) do
  if m.output == out then entry = m break end
end
if entry then
  entry.mode = mode
  entry.disabled = nil
else
  monitors[#monitors + 1] = { output = out, mode = mode, position = "auto-center-up", scale = 1 }
end

-- Serialize: known keys in stable order first, any other keys after, sorted
local KNOWN = { "output", "mode", "position", "scale", "disabled" }
local function value(v)
  if type(v) == "string" then return string.format("%q", v) end
  return tostring(v)
end
local function serialize(m)
  local parts, seen = {}, {}
  for _, k in ipairs(KNOWN) do
    if m[k] ~= nil then
      seen[k] = true
      parts[#parts + 1] = k .. " = " .. value(m[k])
    end
  end
  local rest = {}
  for k in pairs(m) do
    if not seen[k] then rest[#rest + 1] = k end
  end
  table.sort(rest)
  for _, k in ipairs(rest) do
    parts[#parts + 1] = k .. " = " .. value(m[k])
  end
  return "    { " .. table.concat(parts, ", ") .. " },"
end

local tmp = path .. ".tmp"
local fh = assert(io.open(tmp, "w"))
fh:write("-- Monitor data only — no code. hyprland.lua dofile()s this and calls\n")
fh:write("-- hl.monitor() per entry. monitor-resolution.sh rewrites this file by\n")
fh:write("-- evaluating and re-serializing it, so hand-written comments here WILL be\n")
fh:write("-- lost on the next resolution change.\n")
fh:write("return {\n")
for _, m in ipairs(monitors) do
  fh:write(serialize(m), "\n")
end
fh:write("}\n")
assert(fh:close())

assert(type(dofile(tmp)) == "table", "serialized " .. tmp .. " failed to parse")
assert(os.rename(tmp, path))
EOF
  echo "Saved to $MONITORS_LUA"
else
  # Revert: back to disabled if it was disabled, else old resolution
  if [[ "$current_disabled" == true ]]; then
    hyprctl keyword monitor "$EXT,disable"
    echo "Reverted: $EXT disabled again"
  else
    [[ "$old_res" == "unknown" ]] && old_res="preferred"
    hyprctl keyword monitor "$EXT,$old_res,$current_pos,$current_scale"
    echo "Reverted to $old_res"
  fi
fi
