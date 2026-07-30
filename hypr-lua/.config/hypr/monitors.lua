-- Monitor data only — no code. hyprland.lua dofile()s this and calls
-- hl.monitor() per entry. monitor-resolution.sh rewrites this file by
-- evaluating and re-serializing it, so hand-written comments here WILL be
-- lost on the next resolution change.
return {
    { output = "", mode = "preferred", position = "auto-center-up", scale = "auto" },
    { output = "DP-3", mode = "2560x1440@59.95Hz", position = "auto-center-up", scale = 1 },
    { output = "DP-5", mode = "2560x1440@74.97Hz", position = "auto-center-up", scale = 1 },
    { output = "eDP-1", mode = "preferred", position = "auto-center-down", scale = 1 },
    { output = "HDMI-A-1", mode = "2560x1440@59.95Hz", position = "auto-center-up", scale = 1 },
    { output = "DP-1", mode = "2560x1440@59.95Hz", position = "auto-center-up", scale = 1 },
    { output = "DVI-I-1", mode = "2560x1440@59.95Hz", position = "auto-center-up", scale = 1 },
}
