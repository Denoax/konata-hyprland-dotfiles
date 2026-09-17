# Waybar V3

One Waybar process reads three objects from `config.jsonc` (valid JSON within JSONC).
Each bar targets the accepted connector; connector resilience stays with Task08.
Height 32 plus top margin 6 preserves the existing 38px reserved area. Transparent
outer surfaces contain shared 8px islands without idle glow. Bar IDs distinguish
roles; omit `name` to retain the `waybar` layer namespace and existing Hyprland rules.

| Output / bar ID | Role | Content |
|---|---|---|
| HDMI-A-1 / kona-context | Context | Workspaces 1/4/7; local title, 42-character bound and KONATA@ARCH fallback |
| DP-4 / kona-command | Command | KONA + 2/5/8/10; clock; REC/GAME, audio, network and controls |
| HDMI-A-5 / kona-information | Information | Workspaces 3/6/9; native SYS drawer; tray and notification state |

Clock, hardware, network/audio and tray have one instance. Notifications have one
state stream on the right; the center controls icon opens the same existing panel.

| Surface | Actions |
|---|---|
| KONA | Left: launcher; right: existing quick settings |
| Workspace | Native protocol activation; scrolling has no action |
| Clock | HH:MM; click toggles date/week; tooltip calendar, scroll changes month |
| Audio | Click mute; right pavucontrol; scroll changes volume 5% |
| Network | Click connection editor; tooltip interface/IP/bandwidth |
| Center controls | Left existing SwayNC; right existing quick settings |
| Notification state | Left SwayNC; right DND |
| REC / GAME | Existing recording/gaming commands and tooltips |
| SYS | Hover reveals CPU/RAM/GPU and their existing tooltips |
| Tray | Existing applet menus/actions |

Workspace buttons use native `ext/workspaces`. Installed Waybar 0.15.0's
`hyprland/workspaces` hard-codes legacy IPC dispatch, rejected by this Lua-based
Hyprland. The standard workspace protocol activates correctly without an IPC proxy.
Existing Hyprland persistent rules own bank membership and create empty workspaces.
The module filters by output and hides special workspaces. Coordinate sorting follows
Hyprland's numeric workspace IDs; name sorting becomes lexical when a special workspace
is present and would place 10 before 2. No polling, new daemon or Lua change is needed.

REC/GAME remain startup-plus-signal modules (RTMIN+8/+9), without intervals or duplicate
exec-on-event work. Inactive labels disappear; existing launcher/quick-settings bindings
remain the off-state entrypoints. Clock refreshes every 60s. CPU/RAM retain 3s and GPU 5s;
collapsing the drawer **does not stop polling**. Only one instance of each metric runs.
The drawer reveals immediately, without a new animation controller.

Native MPRIS was evaluated and excluded: the paused/hidden, interval-0 candidate
produced 1579 updates in about two seconds without playback/metadata callbacks.
The clean clock follows the packet's allowed fallback. Existing Kona media-deck/OSD
controls remain; no polling substitute or playerctld is added. The exact upstream
cause is not claimed from this bounded probe.

Colors use Task02's imported semantic aliases; calendar typography inherits them.
CSS-only palette reload preserves modules. SwayNC/Rofi layouts, theme generation,
Hyprland state ownership, dock and profiles are unchanged.

Validation: `python3 tests/waybar.py`, `python3 tests/event-state.py`, recovery smoke,
native startup, GTK parsing and real functional/visual/matched performance evidence.
Source tests establish configuration contracts; real clicks establish activation.
See PROJECT_HANDOFF.md for the current evidence and acceptance status.

Version provenance: installed manuals and upstream Waybar 0.15.0
[native workspace protocol](https://github.com/Alexays/Waybar/blob/0.15.0/src/modules/ext/workspace_manager.cpp),
[legacy workspace click](https://github.com/Alexays/Waybar/blob/0.15.0/src/modules/hyprland/workspace.cpp),
[group implementation](https://github.com/Alexays/Waybar/blob/0.15.0/src/group.cpp).
