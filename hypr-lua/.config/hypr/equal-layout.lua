-- Equal-size grid layout: every tiled window gets the identical cell size,
-- all windows visible. Registered as "lua:equal".
--
-- Same placement contract as aspect-layout.lua: the workspace_rule using this
-- layout must set gaps_in = 0 (Hyprland's per-side gaps_in trim skips sides
-- within 2px of the workarea edge — STICKS — so edge windows would end up
-- bigger than interior ones, breaking the equal-size guarantee). The layout
-- applies the global general.gaps_in itself: adjacent windows sit 2*gaps_in
-- apart, like other layouts. ctx.area already excludes gaps_out.

local function gaps_in()
    local v = hl.get_config("general.gaps_in")
    if type(v) == "table" then
        return v.top or 0 -- ponytail: per-side css gaps collapsed to top value; handle sides if ever used
    end
    return tonumber(v) or 0
end

hl.layout.register("equal", {
    recalculate = function(ctx)
        local n = #ctx.targets
        if n == 0 then return end
        local G = 2 * gaps_in()
        local aw, ah = ctx.area.w, ctx.area.h

        -- pick the column count whose cells have the largest short side
        -- (most-square usable cells; handles portrait monitors too)
        local cols, best = 1, -1
        for c = 1, n do
            local r = math.ceil(n / c)
            local s = math.min((aw - (c - 1) * G) / c, (ah - (r - 1) * G) / r)
            if s > best then best, cols = s, c end
        end
        local rows = math.ceil(n / cols)
        -- integer size AND integer origins: per-window CBox.round() rounds the
        -- two x edges independently, so a .5 origin makes widths differ by 1px
        local fw = math.floor(math.max(1, (aw - (cols - 1) * G) / cols))
        local fh = math.floor(math.max(1, (ah - (rows - 1) * G) / rows))
        local ox = math.floor(ctx.area.x + (aw - cols * fw - (cols - 1) * G) / 2)
        local oy = math.floor(ctx.area.y + (ah - rows * fh - (rows - 1) * G) / 2)

        for i, t in ipairs(ctx.targets) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local inrow = math.min(cols, n - row * cols)
            -- center a short last row
            local rx = ox + math.floor((cols - inrow) * (fw + G) / 2)
            t:place({
                x = rx + col * (fw + G),
                y = oy + row * (fh + G),
                w = fw,
                h = fh,
            })
        end
    end,
})
