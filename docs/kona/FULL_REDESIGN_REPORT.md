# Kona full desktop redesign candidate — 2026-09-15

Status: technically validated, installed, and visually approved by Mani as the baseline
for the later sidebar-navigation pass. Task07 remains PARTIAL because managed-login/logout
validation is still deferred. No commit,
push, compositor restart, intentional notification-history clear, UWSM change, or long
benchmark was performed. SwayNC did crash once during rendered QA and systemd recovered
it; preservation of its pre-crash in-memory history cannot be proven.

## Adopted research

- Quickshell 0.3.1 native `Mpris`, `DesktopEntries`, and `Hyprland` models feed one
  resident sidebar. Presentation components remain pure QML and test without a live
  compositor.
- The sidebar remains an overlay `PanelWindow` with a narrow hot edge and no animated
  exclusive zone. A keyboard-opened surface stays independent of hover state.
- Waybar, SwayNC, Rofi, PipeWire/WirePlumber, NetworkManager, BlueZ, cliphist, Awww,
  Hyprlock/Hypridle, SwayOSD, recording, profiles, wallpaper, and session recovery retain
  ownership. No Quickshell notification server or second system-state store was added.
- Compositor plugins were rejected for this candidate because Hyprland plugins share the
  compositor process and require an exact compatible build. The current native overview
  and Rofi fallbacks remain.

## Product changes

- The 300/60px flush-left auto-hide sidebar is now the complete primary shell surface:
  recognizable Konata identity, current profile, native MPRIS card, actual workspace
  occupancy/focus, actual installed desktop entries, quick controls, desktop tools,
  system actions, power/session access, keyboard focus, reduced motion, and one shared
  bubble sound service.
- The former all-white shell is now a restrained navy foundation with medium/light blue
  interaction states and icy highlights. The approved bright music popup is unchanged.
- Deck/Studio presentation language was replaced by normal Desktop/Settings language.
  Motivational copy, fake signal labels, telemetry cards, and orbit graphics were removed.
- The old permanent Kitty dashboard and CAVA visualizer were retired. Its shortcut now
  opens the transient Kona desktop surface, so it adds no idle visualizer process.
- Rofi, SwayNC, Kitty, and Hyprlock now share the same navy/blue/ice hierarchy and human
  labels. SwayNC was asked to reload config/CSS in place. It subsequently crashed once
  while opening the control center and was automatically recovered by its existing user
  unit; no manual restart or history-clear command was issued.
- The dock remains its accepted auto-hide owner. It was not duplicated or replaced.

## Owner map

| Responsibility | Owner |
|---|---|
| Sidebar / compact media / native workspace and app presentation | One Quickshell sidebar process |
| Bar | Waybar |
| Notifications and history | SwayNC |
| Launcher / switcher / large pickers | Rofi |
| Audio | PipeWire and WirePlumber |
| Network / Bluetooth | NetworkManager / BlueZ |
| Wallpaper / profiles / theme | Existing Kona coordinators with Awww currently active |
| Clipboard | Existing `wl-paste` + cliphist watchers |
| Lock / idle / OSD | Hyprlock / Hypridle / SwayOSD |
| Recording / session / power | Existing Kona lifecycle scripts |

No new dependency or persistent daemon was installed.

## Validation

- Native Quickshell 0.3.1 loaded the installed sidebar and settings without QML errors.
- QML: 14 sidebar foundation/auto-hide tests passed.
- Python/shell: sidebar policy and host, music lifecycle, Rofi actions, V4 transactions,
  SwayNC controls, Waybar, runtime, and recovery smoke passed (55 unittest/smoke cases,
  plus the sidebar policy transition matrix). JSON, shell syntax, and `git diff --check`
  passed.
- Native evidence verified expanded/collapsed sidebar, real media and apps, launcher,
  window switcher, quick controls, SwayNC, workspace overview, wallpaper browser,
  settings, three-output placement, and reversible workspace switching.
- SwayNC recovery evidence records old PID 2480, a GTK4 crash at 17:48:47 after the
  active icon theme could not resolve `audio-symbolic.svg`, and automatic recovery as
  PID 1932576 with restart count 1. The recovered service is active; notification count
  is 0 and DND is false. The pre-crash count was not captured, so history preservation
  is unverified rather than claimed.
- Runtime: one Waybar, one SwayNC, one dock, one sidebar host/Quickshell, one SwayOSD,
  one Awww, and the accepted two clipboard watchers. No transient Kona helper, Rofi,
  music popup, surface-data process, or CAVA remained after QA. Two unrelated historical
  `zypak-sandbox` zombies remain.

One short active-use snapshot, not a matched regression benchmark: sidebar Quickshell
247,993 KiB PSS plus 7,329 KiB host, Waybar 32,927 KiB, SwayNC 78,601 KiB after opening
the control center, SwayOSD 62,951 KiB, Awww 483 KiB, and dock 62,260 KiB. The sidebar is
about 51.6 MiB above the pre-redesign 196.4 MiB snapshot, below the existing +64 MiB
incremental alarm. The dock remains above the accepted 44.694 MiB absolute alarm and is
still attributed to the unchanged canonical dock. Aggregate matched-idle measurement is
deferred under `PERFORMANCE_POLICY.md`.

## Evidence and rollback

Evidence and pre-change source/live backups are under
`~/.local/state/kona/full-redesign-20260915/`. The concise rendered set is in
its `evidence/` directory, including `clean-primary-desktop.png`,
`sidebar-expanded-final.png`, `sidebar-collapsed.png`, `launcher.png`,
`window-switcher.png`, `music-popup.png`, `quick-controls.png`,
`notifications-panorama.png`, `workspace-overview.png`, `wallpaper-browser.png`,
`settings.png`, `desktop-surface.png`, `multi-monitor-panorama-final.png`, and
`showcase-sidebar-motion.mp4`. The adverse notification-daemon evidence is preserved as
`swaync-crash-incident.txt` in the same directory.

Rollback uses the corresponding `backup/repo` and `backup/live` trees, followed by a
sidebar-only restart and SwayNC config/CSS reload. Hyprland, Waybar, the dock, and other
owners do not need a restart.

The replacement avatar is a recognizable Lucky Star frame sourced from
`https://i.pinimg.com/736x/5f/26/02/5f26024e7e4f4e31d62bf06a3e033c73.jpg`
on 2026-09-15 for this personal desktop. Its original artist and redistribution license
were not verified; this project makes no license or redistribution claim. Existing
wallpaper source limits in the raw asset pack remain unchanged.

## Known limitations

- Bluetooth exposed no controller during QA, so the existing manager entrypoint was
  checked as an honest unavailable path rather than with a fabricated device.
- Hyprlock visuals were statically validated and left on the existing authentication
  backend; an automated lock/unlock was intentionally not performed.
- SwayNC 0.12.6 crashed once in GTK4 while resolving a missing `audio-symbolic.svg` from
  the existing `Breeze-Noir-White-Blue-V-2` icon theme. Its user unit recovered without
  intervention and a later control-center open logged the same missing icon without a
  second crash. The incident is not reproducible enough to attribute to the CSS/label
  redesign, and broad icon-theme mutation was kept out of this pass.
- File-manager behavior and ownership are unchanged; new Kitty windows receive the new
  palette, while already-open terminals keep their current colors until reloaded.
- The later sidebar-navigation/identity pass is accepted in the 2026-09-16 release checkpoint.
