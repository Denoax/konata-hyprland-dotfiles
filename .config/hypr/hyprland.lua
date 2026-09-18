-- Konata Command Center
-- Hyprland 0.56+ Lua configuration for a three-monitor Arch setup.

local terminal = "~/.local/bin/kona-terminal"
local fileManager = "~/.local/bin/kona-file-manager"
local browser = "gtk-launch com.brave.Browser"
local mainMod = "SUPER"
local superTapArmed = false

-- Event/state foundation (Hyprland 0.56.2). Callbacks only arm native timers;
-- external workers own IPC, filesystem writes and locking. A oneshot expires
-- after firing, so rearm it only while pending and create a new one next burst.
local sessionTimer = nil
local sessionDelay = 30000 -- Preserve the startup restore grace period.
local captureTimers = {}
local windowWorkspaces = {}
local windowFloating = {}

local function saveSessionSoon()
    if sessionTimer then
        sessionTimer:set_timeout(sessionDelay)
        return
    end
    sessionTimer = hl.timer(function()
        sessionTimer = nil
        sessionDelay = 1500
        hl.exec_cmd("~/.local/bin/kona-session-save --quiet")
    end, { timeout = sessionDelay, type = "oneshot" })
end

local function captureWorkspaceSoon(id)
    if not id or id < 1 or id > 10 then return end
    if captureTimers[id] then
        captureTimers[id]:set_timeout(1200)
        return
    end
    captureTimers[id] = hl.timer(function()
        captureTimers[id] = nil
        hl.exec_cmd("~/.local/bin/kona-workspace-capture " .. id)
    end, { timeout = 1200, type = "oneshot" })
end

local function visibleWorkspace(window)
    local workspace = window.workspace
    if workspace and workspace.id > 0 then return workspace.id end
    local monitor = window.monitor
    return monitor and monitor.active_workspace and monitor.active_workspace.id
end

local function windowChanged(window)
    -- Unmap can emit fullscreen/rule updates after close. Only open (or the
    -- initial seed) may establish ownership; late events must not recreate it.
    if window and windowFloating[window.address] == nil then return end
    saveSessionSoon()
    if not window then return end
    local id = visibleWorkspace(window)
    captureWorkspaceSoon(windowWorkspaces[window.address])
    captureWorkspaceSoon(id)
    windowWorkspaces[window.address] = id
    windowFloating[window.address] = window.floating
end

-- Seed old workspace ownership once, outside callbacks (needed on reload).
for _, window in ipairs(hl.get_windows()) do
    windowWorkspaces[window.address] = visibleWorkspace(window)
    windowFloating[window.address] = window.floating
end
hl.on("window.open", function(window)
    windowFloating[window.address] = window.floating
    windowChanged(window)
end)
hl.on("window.move_to_workspace", windowChanged)
hl.on("window.fullscreen", windowChanged)
hl.on("window.close", function(window)
    windowChanged(window)
    windowWorkspaces[window.address] = nil
    windowFloating[window.address] = nil
end)
hl.on("window.update_rules", function(window)
    -- Rules also update for focus/title changes; only floating changes matter.
    if windowFloating[window.address] ~= window.floating then windowChanged(window) end
end)
-- No geometry event in this ABI. Focus transitions provide a conservative save
-- fallback for out-of-band geometry changes, without triggering screenshots.
hl.on("window.active", saveSessionSoon)
hl.on("workspace.active", function(workspace)
    saveSessionSoon()
    if workspace then captureWorkspaceSoon(workspace.id) end
end)
hl.on("workspace.special_active", function(_, monitor)
    saveSessionSoon()
    if monitor and monitor.active_workspace then captureWorkspaceSoon(monitor.active_workspace.id) end
end)
local topologyTimer = nil
local function topologyChanged()
    saveSessionSoon()
    if topologyTimer then topologyTimer:set_timeout(1200); return end
    topologyTimer = hl.timer(function()
        topologyTimer = nil
        for _, monitor in ipairs(hl.get_monitors()) do
            if monitor.active_workspace then captureWorkspaceSoon(monitor.active_workspace.id) end
        end
    end, { timeout = 1200, type = "oneshot" })
end
hl.on("monitor.layout_changed", topologyChanged)
hl.on("config.reloaded", function()
    -- --verify-config also emits this event, with no live event loop/monitors.
    if #hl.get_monitors() == 0 then return end
    topologyChanged()
    hl.exec_cmd("~/.local/bin/kona-game-mode reconcile")
end)
hl.on("hyprland.shutdown", function()
    -- Best effort: failed IPC preserves the last valid snapshot in the worker.
    hl.exec_cmd("~/.local/bin/kona-session-save --quiet")
    -- Plain Hyprland has no graphical-session target. Stop the packaged agent
    -- before its Wayland connection breaks; the unit readiness gate also covers
    -- compositor crashes where this orderly callback cannot run.
    hl.exec_cmd("systemctl --user stop hyprpolkitagent.service")
end)

-- Observe geometry at mouse press/release without consuming input or adding a
-- timer that polls during drags. Covers border resizing as well as Kona drags.
local mouseGeometry = {}
local function geometry(window)
    if not window then return nil end
    local at, size = window.at, window.size
    return table.concat({ window.address, at.x, at.y, size.x, size.y, tostring(window.floating) }, ":")
end
for _, button in ipairs({ "mouse:272", "mouse:273" }) do
    hl.bind(button, function()
        local window = hl.get_active_window()
        mouseGeometry[button] = window and { address = window.address, value = geometry(window) }
    end, { transparent = true, non_consuming = true, ignore_mods = true, dont_inhibit = true })
    hl.bind(button, function()
        local window = hl.get_active_window()
        local before = mouseGeometry[button]
        if before and window and before.address == window.address and before.value ~= geometry(window) then windowChanged(window) end
        mouseGeometry[button] = nil
    end, { release = true, transparent = true, non_consuming = true, ignore_mods = true, dont_inhibit = true })
end

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
hl.workspace_rule({ workspace = "special:arch", layout = "master", gaps_in = 8, gaps_out = 12, border_size = 1 })

-- Theme data is two bounded RGB lines, never executable generated Lua. Missing or
-- corrupt data retains the accepted cyan borders, including during clean recovery.
local themePrimary, themeSecondary = "00c8ff", "207cdf"
local themeRoot = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/kona/theme/current/hyprland.colors"
local themeFile = io.open(themeRoot, "r")
if themeFile then
    local data = themeFile:read(15) or ""
    themeFile:close()
    local a, b = data:match("^(%x%x%x%x%x%x)\n(%x%x%x%x%x%x)\n$")
    if a and b then themePrimary, themeSecondary = a, b end
end

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 10,
        border_size = 1,
        extend_border_grab_area = 10,
        hover_icon_on_border = true,
        col = {
            active_border = { colors = { "rgba(" .. themePrimary .. "ff)", "rgba(" .. themeSecondary .. "ff)" }, angle = 45 },
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
    master = {
        mfact = 0.62,
        new_status = "slave",
        new_on_top = false,
        special_scale_factor = 0.98,
    },
    group = {
        auto_group = false,
        drag_into_group = 1,
        merge_groups_on_drag = true,
        merge_groups_on_groupbar = true,
        merge_floated_into_tiled_on_groupbar = true,
        col = {
            border_active = "rgba(" .. themePrimary .. "ff)",
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

-- Generated default translation of .config/kona/motion.json; user/profile
-- overrides are applied by the transient kona-motion owner on reconciliation.
hl.curve("konaSpatial", {type="spring",mass=1,stiffness=400,dampening=40})
hl.curve("konaEffect", {type="bezier",points={{0.22,1},{0.36,1}}})
hl.animation({leaf="global",enabled=true,speed=3.800,spring="konaSpatial"})
hl.animation({leaf="windows",enabled=true,speed=2.600,spring="konaSpatial"})
hl.animation({leaf="windowsIn",enabled=true,speed=2.600,spring="konaSpatial",style="popin 97%"})
hl.animation({leaf="windowsOut",enabled=true,speed=2.000,bezier="konaEffect",style="popin 98%"})
hl.animation({leaf="fade",enabled=true,speed=1.400,bezier="konaEffect"})
hl.animation({leaf="layers",enabled=true,speed=2.600,bezier="konaEffect"})
hl.animation({leaf="workspaces",enabled=true,speed=3.800,spring="konaSpatial",style="slidefade 22%"})
hl.animation({leaf="borderangle",enabled=false})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.local/bin/kona-runtime-start")
    hl.exec_cmd("~/.local/bin/kona-profile startup")
    hl.exec_cmd("~/.local/bin/kona-sidebar show")
    hl.exec_cmd("~/.local/bin/kona-night-light startup")
    hl.exec_cmd("bash -lc 'sleep 2; ~/.local/bin/kona-session-restore --startup'")
    hl.exec_cmd("~/.local/bin/kona-session-save --initialize")
end)

-- Core application controls.
hl.bind("SUPER_L", function()
    superTapArmed = true
end, { transparent = true, non_consuming = true })
hl.bind("SUPER + SUPER_L", function()
    if superTapArmed then
        superTapArmed = false
        hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/kona-sidebar toggle"))
    end
end, { release = true, transparent = true })

bindSuper("RETURN", hl.dsp.exec_cmd(terminal), { description = "App: Terminal" })
hl.bind("ALT + RETURN", hl.dsp.exec_cmd(terminal), { description = "App: Terminal" })
bindSuper("SHIFT + RETURN", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-dashboard"), { description = "Kona: Dashboard" })
bindSuper("SPACE", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview"), { description = "Kona: Search and workspace overview" })
bindSuper("E", hl.dsp.exec_cmd(fileManager), { description = "App: File manager" })
bindSuper("B", hl.dsp.exec_cmd(browser), { description = "App: Browser" })
bindSuper("Q", hl.dsp.window.close(), { description = "Window: Close" })
bindSuper("F", hl.dsp.window.fullscreen(), { description = "Window: Fullscreen" })
bindSuper("SHIFT + SPACE", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    windowChanged(hl.get_active_window())
end, { description = "Window: Toggle floating" })
bindSuper("P", hl.dsp.window.pseudo(), { description = "Window: Toggle pseudotile" })
bindSuper("J", hl.dsp.layout("togglesplit"), { description = "Window: Toggle split direction" })

-- Windows-style desktop controls.
hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview"), { description = "Kona: Workspace and window overview" })
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview"), { description = "Kona: Workspace and window overview" })
bindSuper("R", hl.dsp.exec_cmd("rofi -show run -theme ~/.config/rofi/run.rasi"), { description = "App: Run command" })
bindSuper("L", hl.dsp.exec_cmd("hyprlock"), { description = "Session: Lock" })
bindSuper("D", hl.dsp.exec_cmd("~/.local/bin/kona-show-desktop"), { description = "Window: Show desktop" })
bindSuper("SHIFT + D", hl.dsp.exec_cmd("~/.local/bin/kona-arch-workspace toggle"), { description = "Kona: Arch workspace" })
bindSuper("M", hl.dsp.exec_cmd("~/.local/bin/kona-show-desktop"), { description = "Window: Show desktop" })
local function minimizeActiveWindow()
    local window = hl.get_active_window()
    if window == nil then
        return
    end
    detachWindowFromGroup(window)
    hl.dispatch(hl.dsp.window.tag({ tag = "minimized", window = window }))
    hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", follow = false, window = window }))
end
bindSuper("H", minimizeActiveWindow, { description = "Window: Minimize" })
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
end, { description = "Window: Restore minimized" })
bindSuper("TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/window.rasi"), { description = "Window: Switch windows" })
bindSuper("I", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-settings"), { description = "Kona: Settings" })
bindSuper("A", hl.dsp.exec_cmd("~/.local/bin/kona-end4-surface assistant"), { description = "Kona: Intelligence, translator and anime" })
bindSuper("SHIFT + A", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-audio"), { description = "Kona: Audio mixer and devices" })
bindSuper("CTRL + A", hl.dsp.exec_cmd("~/.local/bin/kona-app-mixer"), { description = "Kona: Application audio mixer" })
bindSuper("W", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview"), { description = "Kona: Search and workspace overview" })
bindSuper("CTRL + P", hl.dsp.exec_cmd("~/.local/bin/kona-profile-menu"), { description = "Kona: Profile picker" })
-- Compatibility chords now route to the selected upstream-backed Kona surfaces.
bindSuper("CTRL + SPACE", hl.dsp.exec_cmd("~/.local/bin/kona-end4-notifications toggle"), { description = "Kona: Notifications" })
bindSuper("CTRL + I", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-settings"), { description = "Kona: Settings" })
bindSuper("F1", hl.dsp.exec_cmd("~/.local/bin/kona-end4-surface cheatsheet"), { description = "Kona: Keybinding cheat sheet" })
bindSuper("CTRL + M", hl.dsp.exec_cmd("~/.local/bin/kona-shell mosaic"), { description = "Kona: Mosaic" })
bindSuper("SHIFT + W", hl.dsp.exec_cmd("~/.local/bin/kona-wallpaper-menu"), { description = "Kona: Wallpaper picker" })
bindSuper("C", hl.dsp.exec_cmd("~/.local/bin/kona-quick-settings"), { description = "Kona: Quick settings" })
bindSuper("G", hl.dsp.exec_cmd("~/.local/bin/kona-game-mode toggle"), { description = "Kona: Gaming mode" })
bindSuper("U", hl.dsp.exec_cmd("~/.local/bin/kona-updates"), { description = "Kona: Updates and recovery" })
bindSuper("UP", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bindSuper("DOWN", hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
bindSuper("CTRL + LEFT", hl.dsp.focus({ workspace = "e-1" }))
bindSuper("CTRL + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
bindSuper("SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/kona-screenshot region-edit"))
bindSuper("SHIFT + R", hl.dsp.exec_cmd("~/.local/bin/kona-record region"))
bindSuper("CTRL + SHIFT + R", hl.dsp.exec_cmd("~/.local/bin/kona-record output"))
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty --class KonaTaskManager btop"), { description = "App: Task manager" })
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-session"), { description = "Session: Power menu" })
bindSuper("X", hl.dsp.exec_cmd("~/.local/bin/kona-desktop-menu --force"))

-- Desktop and Konata controls.
hl.bind("CTRL + mouse:273", hl.dsp.exec_cmd("~/.local/bin/kona-desktop-menu"), { click = true })
bindSuper("CTRL + D", hl.dsp.exec_cmd("~/.local/bin/kona-end4-notifications toggle"))
bindSuper("N", hl.dsp.exec_cmd("~/.local/bin/kona-end4-notifications toggle"))
bindSuper("SHIFT + N", hl.dsp.exec_cmd("~/.local/bin/kona-night-light toggle"))
bindSuper("V", hl.dsp.exec_cmd("~/.local/bin/kona-clipboard"))
bindSuper("CTRL + S", hl.dsp.exec_cmd("~/.local/bin/kona-session-save"))
bindSuper("CTRL + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/kona-session-restore"))
bindSuper("CTRL + L", hl.dsp.exec_cmd("hyprlock"))
bindSuper("ESCAPE", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-session"), { description = "Session: Power menu" })

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

bindSuper("GRAVE", hl.dsp.exec_cmd("~/.local/bin/kona-arch-workspace scratch"))
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
    name = "arch-workspace-terminals",
    match = { class = "^KonaArch(Processes|System|Audio)$" },
    workspace = "special:arch silent",
    tile = true,
    border_size = 1,
    rounding = 8,
    animation = "popin 97%",
})
hl.window_rule({
    name = "kona-terminal",
    match = { class = "^KonaTerminal$" },
    tile = true,
    border_size = 1,
    rounding = 8,
    animation = "popin 97%",
})
hl.window_rule({
    name = "scratch-terminal",
    match = { class = "^KonaScratch$" },
    workspace = "special:scratch silent",
    float = true,
    size = { 1320, 780 },
    center = true,
    border_size = 1,
    rounding = 12,
    animation = "popin 96%",
})
hl.window_rule({
    name = "drag-to-tab-groups",
    match = { float = false },
    group = "new",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
