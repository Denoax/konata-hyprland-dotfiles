-- Exercise actual config callbacks with deterministic native oneshot semantics.
-- Worker contracts are tested separately using real processes/files/flock.
local config = assert(arg[1], 'pass hyprland.lua')
local now, timers, callbacks, bindings, executed = 0, {}, {}, {}, {}
local ws5, ws6 = { id = 5 }, { id = 6 }
local window = { address = '0x1', workspace = ws5, floating = false,
    at = { x = 1, y = 2 }, size = { x = 900, y = 650 }, monitor = { active_workspace = ws5 } }
local active = window
local function noop() end
local dispatcher
local function dispatchTree()
    return setmetatable({}, { __index = function(self, key)
        local value = dispatchTree(); rawset(self, key, value); return value
    end, __call = function() return noop end })
end
hl = setmetatable({
    dsp = dispatchTree(),
    get_windows = function() return { window } end,
    get_active_window = function() return active end,
    get_monitors = function() return { { active_workspace = ws5 }, { active_workspace = ws6 } } end,
    exec_cmd = function(cmd) table.insert(executed, cmd) end,
    on = function(name, fn) callbacks[name] = fn end,
    bind = function(key, fn, flags)
        table.insert(bindings, { key = key, fn = fn, flags = flags or {} })
    end,
    timer = function(fn, opts)
        assert(opts.type == 'oneshot', 'No repeating polling timer is permitted')
        local timer = { fn = fn, deadline = now + opts.timeout }
        function timer:set_timeout(ms) assert(not self.expired); self.deadline = now + ms end
        table.insert(timers, timer)
        return timer
    end,
}, { __index = function() return noop end })
dofile(config)
local function advance(ms)
    now = now + ms
    -- Callbacks can create timers; those newly armed deadlines remain in future.
    for _, timer in ipairs(timers) do
        if not timer.expired and timer.deadline <= now then
            timer.expired = true; timer.fn()
        end
    end
end
local function count(fragment)
    local result = 0
    for _, cmd in ipairs(executed) do if cmd:find(fragment, 1, true) then result = result + 1 end end
    return result
end
for _ = 1, 100 do callbacks['window.open'](window) end
advance(1200)
assert(count('kona-workspace-capture 5') == 1, 'burst must coalesce to one workspace capture')
advance(28800)
assert(count('kona-session-save --quiet') == 1, 'burst must coalesce to one save')
advance(180000)
assert(#executed == 2, 'quiet time must produce no recurring work')
for _ = 1, 100 do callbacks['window.active'](window); callbacks['window.update_rules'](window) end
advance(1500)
assert(count('kona-workspace-capture') == 1, 'focus/title-like rule updates must not capture')
assert(count('kona-session-save --quiet') == 2)
window.workspace = ws6
callbacks['window.move_to_workspace'](window, ws6)
advance(1500)
assert(count('kona-workspace-capture 5') == 2, 'old visible workspace must be refreshed')
assert(count('kona-workspace-capture 6') == 1, 'destination workspace must be refreshed')
window.floating = true
callbacks['window.update_rules'](window)
advance(1500)
assert(count('kona-workspace-capture 6') == 2)
local function mouse(release)
    for _, bind in ipairs(bindings) do
        if bind.key == 'mouse:272' and (bind.flags.release or false) == release then
            assert(bind.flags.non_consuming and bind.flags.ignore_mods)
            bind.fn()
        end
    end
end
mouse(false); window.size.x = 1000; mouse(true); advance(1500)
assert(count('kona-workspace-capture 6') == 3, 'mouse geometry must persist and refresh')
local before = #executed
mouse(false); mouse(true); advance(1500)
assert(#executed == before, 'ordinary click must not capture unchanged geometry')
callbacks['window.close'](window); active = nil; advance(1500)
-- Hyprland unmap emits close before clearing fullscreen. Late close-side
-- events must not resurrect state for a window that is no longer tracked.
before = #executed
callbacks['window.fullscreen'](window); callbacks['window.update_rules'](window)
advance(1500)
assert(#executed == before, 'close-side events must not resurrect closed windows')
before = #executed; advance(180000)
assert(#executed == before, 'closed windows must not leave timers running')
local saves_before_shutdown = count('kona-session-save --quiet')
callbacks['hyprland.shutdown']()
assert(count('kona-session-save --quiet') == saves_before_shutdown + 1,
    'shutdown must save the current session')
assert(count('systemctl --user stop hyprpolkitagent.service') == 1,
    'shutdown must stop the packaged polkit owner before Wayland disconnects')
assert(count('kona-runtime-start') == 0, 'ordinary events must not start resident owners')
callbacks['hyprland.start']()
assert(count('kona-runtime-start') == 1)
callbacks['config.reloaded']()
assert(count('kona-runtime-start') == 1, 'config reload must not duplicate resident owners')
print('Lua event burst, focus filtering, movement, floating, geometry, idle and shutdown contracts passed')
