-- Fixed-aspect grid layout: every tiled window keeps RATIO, cells shrink as
-- window count grows. Registered as "lua:aspect169".
--
-- The workspace_rule using this layout must also set gaps_in = 0: Hyprland
-- post-processes placed boxes with per-side gaps_in trims (skipped within 2px
-- of the workarea edge — STICKS in src/macros.hpp), which would distort the
-- ratio. With the trim zeroed for the workspace, this layout applies the
-- global general.gaps_in itself: adjacent windows sit 2*gaps_in apart (the
-- same visual gap other layouts produce) and leftover space from the fixed
-- ratio becomes symmetric outer margins. ctx.area already excludes gaps_out.

local RATIO = 16 / 9 -- the single place to change the aspect

local function gaps_in()
    local v = hl.get_config("general.gaps_in")
    if type(v) == "table" then
        return v.top or 0 -- ponytail: per-side css gaps collapsed to top value; handle sides if ever used
    end
    return tonumber(v) or 0
end

hl.layout.register("aspect169", {
    recalculate = function(ctx)
        local n = #ctx.targets
        if n == 0 then return end
        local G = 2 * gaps_in() -- what two adjacent tiled windows get in other layouts
        local aw, ah = ctx.area.w, ctx.area.h

        -- pick the column count that maximizes window width at fixed RATIO
        local cols, best = 1, -1
        for c = 1, n do
            local r = math.ceil(n / c)
            local fw = math.min((aw - (c - 1) * G) / c, (ah - (r - 1) * G) / r * RATIO)
            if fw > best then best, cols = fw, c end
        end
        local rows = math.ceil(n / cols)
        -- integer size so per-window box rounding can't skew the ratio
        local fw = math.floor(math.max(1, math.min((aw - (cols - 1) * G) / cols, (ah - (rows - 1) * G) / rows * RATIO)))
        local fh = math.floor(fw / RATIO + 0.5)
        local ox = ctx.area.x + (aw - cols * fw - (cols - 1) * G) / 2
        local oy = ctx.area.y + (ah - rows * fh - (rows - 1) * G) / 2

        for i, t in ipairs(ctx.targets) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            t:place({
                x = ox + col * (fw + G),
                y = oy + row * (fh + G),
                w = fw,
                h = fh,
            })
        end
    end,
})
