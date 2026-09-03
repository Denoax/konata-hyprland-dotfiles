-- Konata Command Center
-- Hyprland 0.56+ Lua configuration for Mani's three-monitor Arch setup.

local terminal = "kitty"
local launcher = "rofi -show drun -theme ~/.config/rofi/konata.rasi"
local fileManager = "xdg-open ~"
local browser = "gtk-launch com.brave.Browser"
local mainMod = "SUPER"
local superTapArmed = false

-- Preserve Windows-key chords while allowing a tap of Windows/Super alone.
local function bindSuper(keys, dispatcher, flags)
    local combo = mainMod .. " + " .. keys
    hl.bind(combo, function()
        superTapArmed = false
    end, { transparent = true, non_consuming = true })
    return hl.bind(combo, dispatcher, flags)
end

-- Pull only the selected app out of a tab group before moving it. This keeps
-- optional drag-to-tab stacking without making grouped apps travel together.
local function detachWindowFromGroup(window)
    if window ~= nil and window.group ~= nil and window.group.size > 1 then
        hl.dispatch(hl.dsp.window.move({ out_of_group = true, window = window }))
        hl.exec_scheduled_prop_refresh_immediately()
    end
end

-- Physical layout: 60 Hz Samsung | 240 Hz Pixio primary | 120 Hz Acer.
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
hl.monitor({
    output = "DP-4",
    mode = "1920x1080@240.30",
    position = "1920x0",
    scale = 1,
})
hl.monitor({
    output = "HDMI-A-5",
    mode = "1920x1080@119.98",
    position = "3840x0",
    scale = 1,
})
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })

-- Keep a predictable workspace bank on every monitor.
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-4", default = true, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-5", default = true, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-4", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-5", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "DP-4", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-5", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "DP-4", persistent = true })

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 10,
        border_size = 1,
        extend_border_grab_area = 10,
        hover_icon_on_border = true,
        col = {
            active_border = { colors = { "rgba(00c8ffff)", "rgba(207cdfff)" }, angle = 45 },
            inactive_border = "rgba(16486daa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
        snap = {
            enabled = true,
            window_gap = 8,
            monitor_gap = 10,
            respect_gaps = true,
        },
    },
    decoration = {
        rounding = 8,
        rounding_power = 2,
        active_opacity = 0.96,
        inactive_opacity = 0.90,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 16,
            render_power = 3,
            color = "rgba(00aee633)",
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            vibrancy = 0.18,
        },
    },
    animations = { enabled = true },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        precise_mouse_move = true,
    },
    group = {
        auto_group = false,
        drag_into_group = 1,
        merge_groups_on_drag = true,
        merge_groups_on_groupbar = true,
        merge_floated_into_tiled_on_groupbar = true,
        col = {
            border_active = "rgba(00c8ffff)",
            border_inactive = "rgba(16486daa)",
        },
        groupbar = {
            enabled = true,
            disable_when_only = true,
            height = 16,
            font_size = 8,
            gradients = false,
            render_titles = true,
            col = {
                active = "rgba(00c8ffee)",
                inactive = "rgba(16486dcc)",
            },
        },
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",
        touchpad = { natural_scroll = false },
    },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
})

hl.curve("konaEase", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("konaQuick", { type = "bezier", points = { { 0.15, 0 }, { 0.10, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "konaEase" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "konaEase" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "konaEase", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "konaQuick", style = "popin 92%" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "konaQuick" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "konaEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "konaEase", style = "slide" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.local/bin/kona-wallpaper restore")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("waybar")
    hl.exec_cmd("~/.local/bin/kona-dock")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("udiskie --tray")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("~/.local/opt/kona-pkgs/swayosd/usr/bin/swayosd-server --config ~/.config/swayosd/config.toml --style ~/.config/swayosd/style.css")
    hl.exec_cmd("~/.local/bin/kona-night-light startup")
    hl.exec_cmd("bash -lc 'sleep 2; ~/.local/bin/kona-session-restore --startup'")
    hl.exec_cmd("~/.local/bin/kona-session-daemon")
    hl.exec_cmd("~/.local/bin/kona-workspace-history-daemon")
end)

-- Core application controls.
hl.bind("SUPER_L", function()
    superTapArmed = true
end, { transparent = true, non_consuming = true })
hl.bind("SUPER + SUPER_L", function()
    if superTapArmed then
        superTapArmed = false
        hl.dispatch(hl.dsp.exec_cmd("nwg-dock-hyprland"))
    end
end, { release = true, transparent = true })

bindSuper("RETURN", hl.dsp.exec_cmd(terminal))
bindSuper("SHIFT + RETURN", hl.dsp.exec_cmd("~/.local/bin/kona-dashboard"))
bindSuper("SPACE", hl.dsp.exec_cmd(launcher))
bindSuper("E", hl.dsp.exec_cmd(fileManager))
bindSuper("B", hl.dsp.exec_cmd(browser))
bindSuper("Q", hl.dsp.window.close())
bindSuper("F", hl.dsp.window.fullscreen())
bindSuper("SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
bindSuper("P", hl.dsp.window.pseudo())
bindSuper("J", hl.dsp.layout("togglesplit"))

-- Windows-style desktop controls.
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("ALT + TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/konata.rasi"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/konata.rasi"))
bindSuper("R", hl.dsp.exec_cmd("rofi -show run -theme ~/.config/rofi/konata.rasi"))
bindSuper("L", hl.dsp.exec_cmd("hyprlock"))
bindSuper("D", hl.dsp.exec_cmd("~/.local/bin/kona-show-desktop"))
bindSuper("M", hl.dsp.exec_cmd("~/.local/bin/kona-show-desktop"))
local function minimizeActiveWindow()
    local window = hl.get_active_window()
    if window == nil then
        return
    end
    detachWindowFromGroup(window)
    hl.dispatch(hl.dsp.window.tag({ tag = "minimized", window = window }))
    hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", follow = false, window = window }))
end
bindSuper("H", minimizeActiveWindow)
hl.bind("CTRL + H", minimizeActiveWindow)
bindSuper("SHIFT + H", function()
    local window = hl.get_window("tag:minimized")
    local workspace = hl.get_active_workspace()
    if window == nil or workspace == nil then
        return
    end
    hl.dispatch(hl.dsp.window.move({ workspace = workspace, window = window }))
    hl.dispatch(hl.dsp.window.clear_tags({ window = window }))
    hl.dispatch(hl.dsp.focus({ window = window }))
end)
bindSuper("TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/konata.rasi"))
bindSuper("I", hl.dsp.exec_cmd("systemsettings"))
bindSuper("A", hl.dsp.exec_cmd("swaync-client -t -sw"))
bindSuper("SHIFT + A", hl.dsp.exec_cmd("~/.local/bin/kona-audio-menu"))
bindSuper("CTRL + A", hl.dsp.exec_cmd("~/.local/bin/kona-app-mixer"))
bindSuper("W", hl.dsp.exec_cmd("~/.local/bin/kona-overview"))
bindSuper("C", hl.dsp.exec_cmd("~/.local/bin/kona-quick-settings"))
bindSuper("G", hl.dsp.exec_cmd("~/.local/bin/kona-game-mode toggle"))
bindSuper("U", hl.dsp.exec_cmd("~/.local/bin/kona-updates"))
bindSuper("UP", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bindSuper("DOWN", hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
bindSuper("CTRL + LEFT", hl.dsp.focus({ workspace = "e-1" }))
bindSuper("CTRL + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
bindSuper("SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/kona-screenshot region-edit"))
bindSuper("SHIFT + R", hl.dsp.exec_cmd("~/.local/bin/kona-record region"))
bindSuper("CTRL + SHIFT + R", hl.dsp.exec_cmd("~/.local/bin/kona-record output"))
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty --class KonaTaskManager btop"))
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("~/.local/bin/kona-session-menu"))
bindSuper("X", hl.dsp.exec_cmd("~/.local/bin/kona-desktop-menu --force"))

-- Desktop and Konata controls.
hl.bind("CTRL + mouse:273", hl.dsp.exec_cmd("~/.local/bin/kona-desktop-menu"), { click = true })
bindSuper("CTRL + D", hl.dsp.exec_cmd("~/.local/bin/kona-dashboard"))
bindSuper("N", hl.dsp.exec_cmd("swaync-client -t -sw"))
bindSuper("SHIFT + N", hl.dsp.exec_cmd("~/.local/bin/kona-night-light toggle"))
bindSuper("V", hl.dsp.exec_cmd("~/.local/bin/kona-clipboard"))
bindSuper("CTRL + S", hl.dsp.exec_cmd("~/.local/bin/kona-session-save"))
bindSuper("CTRL + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/kona-session-restore"))
bindSuper("CTRL + L", hl.dsp.exec_cmd("hyprlock"))
bindSuper("ESCAPE", hl.dsp.exec_cmd("~/.local/bin/kona-session-menu"))

-- Arrow-key window navigation remains available around the Windows shortcuts.
for _, pair in ipairs({
    { "left", "left" }, { "right", "right" },
}) do
    local direction = pair[2]
    bindSuper(pair[1], hl.dsp.focus({ direction = pair[2] }))
    bindSuper("SHIFT + " .. pair[1], function()
        local window = hl.get_active_window()
        if window == nil then
            return
        end
        detachWindowFromGroup(window)
        hl.dispatch(hl.dsp.window.move({ direction = direction, window = window }))
    end)
end

for i = 1, 10 do
    local key = i % 10
    local workspace = i
    bindSuper(tostring(key), hl.dsp.focus({ workspace = i }))
    bindSuper("SHIFT + " .. key, function()
        local window = hl.get_active_window()
        if window == nil then
            return
        end
        detachWindowFromGroup(window)
        hl.dispatch(hl.dsp.window.move({ workspace = workspace, window = window }))
    end)
end

bindSuper("GRAVE", hl.dsp.workspace.toggle_special("scratch"))
bindSuper("SHIFT + GRAVE", hl.dsp.window.move({ workspace = "special:scratch" }))
bindSuper("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bindSuper("mouse_up", hl.dsp.focus({ workspace = "e-1" }))
-- Mouse dispatchers handle their own press/release state in the Lua API.
-- Keep these compositor gestures available even over apps with shortcut inhibition.
local function resizeWindowWithMouse()
    local window = hl.get_active_window()
    if window ~= nil and not window.floating then
        local visibleTiled = 0
        for _, candidate in ipairs(hl.get_windows({ workspace = window.workspace, floating = false })) do
            if candidate.visible then
                visibleTiled = visibleTiled + 1
            end
        end

        -- A single tile already owns all available space. Float it first so a
        -- right-drag behaves like Windows; split layouts keep tiled resizing.
        if visibleTiled <= 1 then
            hl.dispatch(hl.dsp.window.float({ action = "enable", window = window }))
            hl.exec_scheduled_prop_refresh_immediately()
        end
    end
    hl.dispatch(hl.dsp.window.resize())
end

local function dragWindowIndependently()
    local window = hl.get_active_window()
    detachWindowFromGroup(window)
    hl.dispatch(hl.dsp.window.drag())
end

bindSuper("mouse:272", dragWindowIndependently, { dont_inhibit = true })
bindSuper("mouse:273", resizeWindowWithMouse, { dont_inhibit = true })
hl.bind("ALT + mouse:272", dragWindowIndependently, { dont_inhibit = true })
hl.bind("ALT + mouse:273", resizeWindowWithMouse, { dont_inhibit = true })

-- Media, audio and brightness keys work even while locked.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.local/bin/kona-osd volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.local/bin/kona-osd volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.local/bin/kona-osd volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("~/.local/bin/kona-osd mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.local/bin/kona-brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.local/bin/kona-brightness down"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("~/.local/bin/kona-osd next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("~/.local/bin/kona-osd play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("~/.local/bin/kona-osd play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("~/.local/bin/kona-osd previous"), { locked = true })
hl.bind("CAPS_LOCK", hl.dsp.exec_cmd("~/.local/bin/kona-osd caps-lock"), { release = true, transparent = true, non_consuming = true })
hl.bind("NUM_LOCK", hl.dsp.exec_cmd("~/.local/bin/kona-osd num-lock"), { release = true, transparent = true, non_consuming = true })

-- Screenshots.
hl.bind("PRINT", hl.dsp.exec_cmd("~/.local/bin/kona-screenshot full"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("~/.local/bin/kona-screenshot region-edit"))

-- Useful floating utility windows.
hl.window_rule({
    name = "float-utilities",
    match = { class = "^(pavucontrol|nwg-look|blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name = "satty-editor",
    match = { class = "^io.kona.Satty$" },
    float = true,
    center = true,
    size = { 1380, 820 },
})
hl.window_rule({
    name = "drag-to-tab-groups",
    match = { float = false },
    group = "new",
})
hl.window_rule({
    name = "kona-dashboard-clock-left",
    match = { initial_class = "^KonaDashboard$", initial_title = "^Kona::Clock$" },
    workspace = "1 silent",
    float = true,
    size = { 620, 360 },
    move = { 24, 56 },
})
hl.window_rule({
    name = "kona-dashboard-grid-acer",
    match = { initial_class = "^KonaDashboard$", initial_title = "^Kona::(System|Monitor|Matrix)$" },
    workspace = "3 silent",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
