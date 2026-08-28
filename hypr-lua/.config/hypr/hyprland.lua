-- Hyprland config, lua engine (Hyprland >=0.55). Activate with `hypr-engine lua`.
-- API stubs: /usr/share/hypr/stubs/hl.meta.lua ; example: /usr/share/hypr/hyprland.lua


------------------
---- MONITORS ----
------------------
-- monitors.lua (stowed, hypr-lua package) is data-only: it returns a list of
-- monitor tables, serialized/rewritten by monitor-resolution.sh. Existence
-- check, not pcall: a broken monitors.lua must fail loudly under
-- --verify-config rather than silently booting with zero monitors configured.
local monitors_lua = os.getenv("HOME") .. "/.config/hypr/monitors.lua"
local f = io.open(monitors_lua)
if f then
    f:close()
    for _, m in ipairs(dofile(monitors_lua)) do hl.monitor(m) end
else
    hl.monitor({ output = "", mode = "preferred", position = "auto-center-up", scale = "auto" })
end


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "alacritty"
local fileManager = "nautilus"
local menu        = os.getenv("HOME") .. "/.config/rofi/launchers/type-2/launcher.sh"
local slack_team  = "T021KJ15Q84"
local mainMod     = "SUPER"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or ""))
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- `silent` is part of the workspace rule value, not a rule key:
    -- a separate `silent = true` throws `unknown effect 'silent'` and kills this callback
    hl.exec_cmd([[alacritty --class term-tmux -e zsh -c "tmux a || tmux"]], { workspace = "name:edit silent" })
    hl.exec_cmd("google-chrome-stable --class=chrome-work",                  { workspace = "name:work silent" })
    hl.exec_cmd("google-chrome-beta --class=chrome-private",                 { workspace = "name:read silent" })
    hl.exec_cmd([[xdg-open "slack://open?team=]] .. slack_team .. [["]],     { workspace = "name:talk silent" })
    hl.exec_cmd("brave --class=brave-youtube",                               { workspace = "name:youtube silent" })
    hl.exec_cmd("spotify",                                                   { workspace = "name:spotify silent" })
    hl.exec_cmd("hyprpaper")
    -- Export the session env to systemd, then start the user session target.
    -- This starts every WantedBy=graphical-session.target service (hypridle,
    -- etc.) exactly once — do NOT also launch hypridle directly.
    -- monitor-handler must be `restart` (not `start`) and chained AFTER the env
    -- import: a handler surviving a Hyprland restart would keep the dead
    -- instance's HYPRLAND_INSTANCE_SIGNATURE and fight the new one over the bars.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP && systemctl --user start hyprland-session.target && systemctl --user restart monitor-handler.service")
end)


-------------------------------------
---- WINDOW PLACEMENT & RULES ------
-------------------------------------

hl.window_rule({ sync_fullscreen = false })

-- Send autostarted apps to their workspaces

hl.window_rule({ match = { class = "term-tmux" },                            workspace = "name:edit silent" })
hl.window_rule({ match = { class = "chrome-work" },                          workspace = "name:work silent" })
hl.window_rule({ match = { class = "chrome-private" },                       workspace = "name:read silent" })
hl.window_rule({ match = { class = "Slack" },                                workspace = "name:talk silent" })
hl.window_rule({ match = { class = "brave-youtube" },                        workspace = "name:youtube silent" })
hl.window_rule({ match = { class = "brave-youtube" },                        fullscreen_state = "0 2" }) -- fake fullscreen
hl.window_rule({ match = { class = "brave-youtube" },                        sync_fullscreen = false })
hl.window_rule({ match = { class = "^Spotify$" },                            workspace = "name:spotify silent" })
hl.window_rule({ match = { class = "^Spotify$" },                            group = "set always" })
hl.window_rule({ match = { class = [[^chrome-ma\.bastiaandeknudt\.be.*]] },  workspace = "name:spotify silent" })
hl.window_rule({ match = { class = [[^chrome-ma\.bastiaandeknudt\.be.*]] },  group = "set always" })
hl.window_rule({ match = { workspace = "name:read" },                        group = "set always" })
hl.window_rule({
    match = { initial_title = "^New Private Tab - Brave|Untitled - Brave$" },
    workspace = "name:incognito",
    fullscreen_state = "0 2", -- fake fullscreen
})

-- pavucontrol floating
hl.window_rule({ match = { class = "^.*vucontrol.*$" }, float = true })

-- Chrome/Brave notification popups: float, pin, don't steal focus
hl.window_rule({
    match       = { class = [[^([Gg]oogle-chrome|[Cc]hromium|[Bb]rave).*$]], initial_title = [[.*[Nn]otification.*]] },
    float            = true,
    pin              = true,
    no_initial_focus = true,
})

-- No borders on workspaces with only 1 visible tiled window
hl.window_rule({ match = { workspace = "w[vt1]" }, border_size = 0 })

-- satty (screenshot annotator)
hl.window_rule({ match = { class = "com.gabm.satty" }, float = true, group = "deny" })

-- Fuzzy launcher floating overlay
hl.window_rule({
    name  = "fzl-launcher",
    match = { class = "fzl-launcher" },
    float      = true,
    size       = "800 500",
    center     = true,
    pin        = true,
    dim_around = true,
})

---- Workspace rules ----
-- Equal-size grid layout for incognito (registers "lua:equal")
dofile(os.getenv("HOME") .. "/.config/hypr/equal-layout.lua")
dofile(os.getenv("HOME") .. "/.config/hypr/aspect-layout.lua")
-- NOTE: original used multiple `monitor:` clauses as fallbacks (`monitor:DP-3, monitor:HDMI-A-1`).
-- Lua stub types `monitor` as a single string. Comma-separated may or may not be supported —
-- if it isn't, fall back to using monitor-handler.sh to reassign at runtime (you already do that).
local multi_monitor = "DP-3, HDMI-A-1"
hl.workspace_rule({ workspace = "name:work",         monitor = multi_monitor, persistent = true })
hl.workspace_rule({ workspace = "name:edit",         monitor = multi_monitor, persistent = true })
hl.workspace_rule({ workspace = "name:read",         monitor = multi_monitor, persistent = true })
hl.workspace_rule({ workspace = "name:talk",         monitor = multi_monitor, persistent = true })
hl.workspace_rule({ workspace = "name:youtube",      monitor = multi_monitor, persistent = true })
hl.workspace_rule({ workspace = "name:spotify",      monitor = "eDP-1",       persistent = true })
hl.workspace_rule({ workspace = "name:meet",         monitor = "eDP-1",       persistent = true })
-- gaps_in = 0: aspect169 applies the global gaps itself (see aspect-layout.lua)
hl.workspace_rule({ workspace = "name:incognito",    monitor = multi_monitor, persistent = true, layout = "lua:aspect169", gaps_in = 0 })
hl.workspace_rule({ workspace = "name:presentation", monitor = multi_monitor })

---- Layer rules ----
hl.layer_rule({ match = { namespace = "eww-sidebar" }, blur = true })
hl.layer_rule({ match = { namespace = "eww-sidebar" }, ignore_alpha = 0.3 })


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 0,
        border_size = 1,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 3,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.98,
        shadow = {
            enabled      = false,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
        blur = {
            enabled  = true,
            size     = 5,
            passes   = 3,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },

    group = {
        groupbar = {
            enabled             = true,
            font_size           = 17,
            height              = 1,
            text_offset         = -10,
            indicator_height    = 20,
            text_color_inactive = "rgba(ffffff44)",
            col = {
                active   = "rgba(0E161955)",
                inactive = "rgba(00ff9911)",
            },
            blur = true,
        },
    },

    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

-- Animations
hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = false, speed = 4.79, bezier = "easeOutQuint" })
-- hl.animation({ leaf = "windowsIn",   enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
-- hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = false, speed = 1.01, bezier = "almostLinear", style = "fade" })


----------------------
---- PER-DEVICE -----
----------------------

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

-- Non-interactive bind commands: wrap in err-run so a failure raises a
-- notification instead of vanishing into the compositor log. Interactive
-- apps (terminal, hyprlock) and self-notifying scripts stay unwrapped.
local function shq(cmd) return "'" .. cmd:gsub("'", [['\'']]) .. "'" end
local function nexec(cmd, rules) return hl.dsp.exec_cmd("err-run " .. shq(cmd), rules) end

-- Group manipulation
hl.bind(mainMod .. " + G",           hl.dsp.group.toggle(), { description = "toggle group" })
hl.bind(mainMod .. " + Tab",         hl.dsp.group.next(),   { description = "next in group" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev(),   { description = "prev in group" })

-- Webapp launches
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd([[launch-webapp "https://claude.ai/"]]),
    { description = "ClaudeAI" })
hl.bind(mainMod .. " + SHIFT + V",
    hl.dsp.exec_cmd([[launch-webapp "https://meet.google.com/"]], { workspace = "name:meet" }),
    { description = "meet (claude-shift-v)" })

-- Workspace shortcuts (1-4 are app launchers per old config; 5/7 are workspace switchers)
hl.bind(mainMod .. " + 1",         hl.dsp.focus({ workspace = "name:edit" }),                                    { description = "tmux" })
hl.bind(mainMod .. " + 2",         hl.dsp.exec_cmd("launch-or-focus slack slack"),                               { description = "slack" })
hl.bind(mainMod .. " + 3",         hl.dsp.exec_cmd([[launch-or-focus --workspace meet meet "launch-webapp https://meet.google.com/"]]),
    { description = "meet" })
hl.bind(mainMod .. " + 4",         hl.dsp.focus({ workspace = "name:spotify" }),                                 { description = "spotify workspace" })
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = "name:spotify" }),                           { description = "move to spotify workspace" })

-- App / window basics
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind("ALT + F4",                hl.dsp.window.close())
hl.bind(mainMod .. " + CTRL + SHIFT + C",
    nexec("kill -9 $(hyprctl activewindow -j | jq '.pid')"))

hl.bind(mainMod .. " + M",         hl.dsp.exit())
hl.bind(mainMod .. " + F",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))

-- Fuzzy launcher
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd("fzl --launch"), { description = "Fuzzy Launcher" })

-- Presentation mode
hl.bind(mainMod .. " + P",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/presentation-mode.sh"),
    { description = "Presentation mode" })

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.focus({ direction = "down" }))

-- Named-workspace switchers and movers
local namedWorkspaces = {
    { key = "5", name = "youtube" },
    { key = "7", name = "meet" },
    { key = "W", name = "work" },
    { key = "E", name = "edit" },
    { key = "R", name = "read" },
    { key = "T", name = "talk" },
    { key = "Y", name = "youtube" },
    { key = "I", name = "incognito" },
}
for _, ws in ipairs(namedWorkspaces) do
    hl.bind(mainMod .. " + " .. ws.key,           hl.dsp.focus({ workspace = "name:" .. ws.name }))
    hl.bind(mainMod .. " + SHIFT + " .. ws.key,   hl.dsp.window.move({ workspace = "name:" .. ws.name }))
end

-- Reload helper
hl.bind(mainMod .. " + CTRL + R",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/reload.sh"))

-- Special (scratchpad) workspace
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Window cycling (legacy script)
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("hypr-cycle-or-group f"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("hypr-cycle-or-group b"))

-- Fullscreen + lock
-- fullscreen() ignores its arg and does real fullscreen (client told, covers layers);
-- maximize like old `fullscreen, 1` = internal-only state 1, toggled
hl.bind(mainMod .. " + space", hl.dsp.window.fullscreen_state({ internal = 1, client = -1, action = "toggle" }))
hl.bind(mainMod .. " + F11", hl.dsp.window.fullscreen_state({ internal = 2, client = 2, action = "toggle" }))

hl.bind(mainMod .. " + L",     hl.dsp.exec_cmd("hyprlock"))

-- Workspace scroll / arrow nav
hl.bind(mainMod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + right",hl.dsp.focus({ workspace = "e+1" }))

-- Drag/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys (volume / brightness — bindel = repeating + locked)
hl.bind("XF86AudioRaiseVolume",  nexec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  nexec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         nexec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      nexec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   nexec("brightnessctl s 10%+"),                          { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", nexec("brightnessctl s 10%-"),                          { locked = true, repeating = true })

-- Media keys (bindl = locked only)
hl.bind("XF86AudioNext",  nexec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", nexec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  nexec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  nexec("playerctl previous"),   { locked = true })

-- Screenshots — deliberately NOT nexec-wrapped: cancelling the region picker
-- (ESC) exits non-zero and would raise a notification on every cancel.
local screenshotDir = os.getenv("HOME") .. "/Pictures/Screenshots"
hl.bind("PRINT",
    hl.dsp.exec_cmd("hyprshot -m region -z -r - | satty -f - --output-filename " .. screenshotDir ..
        "/$(date '+%Y%m%d-%H%M%S').png --copy-command wl-copy --save-after-copy --early-exit --initial-tool brush"))
hl.bind("SHIFT + PRINT",
    hl.dsp.exec_cmd("hyprshot -m active -m output -z -r - | satty -f - --output-filename " .. screenshotDir ..
        "/$(date '+%Y%m%d-%H%M%S').png --copy-command wl-copy --save-after-copy --early-exit --initial-tool brush"))
