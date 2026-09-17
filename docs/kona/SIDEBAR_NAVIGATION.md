# Sidebar navigation and system identity — 2026-09-15

Status: technically validated, installed and accepted in the 2026-09-16 release checkpoint.
The release approval supersedes this report's historical visual-review gate.

## Scope and ownership

The existing left sidebar is now the primary app and window navigation owner. Its
Applications section provides five compact pinned apps, running and focused state,
window counts, focus of an existing app, right-click launch of another instance, an
All Apps entry backed by the existing Rofi launcher, and a Windows entry backed by the
existing Rofi switcher. The app model comes from Quickshell `DesktopEntries` and native
Hyprland toplevel events; the one-shot refresh timer only follows open, close, and move
events. No poller, daemon, or second launcher was added.

The retired dock exposed ordinary running-window buttons plus two cached pins:
`kona-power` and `kona-search`. Power/session remains in the sidebar, search/application
launch is covered by All Apps, and running/focused windows are now represented directly.
Existing Hyprland controls continue to own floating, fullscreen, close, move, and other
window operations. After launch/focus parity was proven, `nwg-dock-hyprland` PID 1854828
was stopped. Hyprland startup now starts the sidebar instead of the dock. The dock binary,
style, cache, launcher script, and the historical 44.694 MiB alarm remain intact for
evidence and rollback; no dock process remains in normal DAILY runtime.

A bare Super press/release toggles the existing sidebar latch. Every existing Super chord
continues through the established `bindSuper` guard, which disarms the bare-key action as
soon as a chord fires. Live Hyprland bind inspection confirms the non-consuming Super_L
press, Super+Super_L release, and representative guarded Super+Return and Super+Space
bindings. The direct toggle endpoint passed. No physical key-injection utility was
available, so the final human key press remains part of Mani's live review.

The identity block now reads `KONA`, `Arch Linux / Hyprland`, and the live Kona profile.
It uses a lossless 720x720 crop from the existing 1920x1080 Konata wallpaper; it is not an
upscale or generated replacement. One slow blue-purple avatar aura supplies the signature
motion and becomes a static low-opacity ring under Reduced Motion.

## Validation

- Native Quickshell 0.3.1 / Qt 6.11.2 loaded the installed sidebar without QML errors.
- QML sidebar suite: 9 passed; visibility suite: 7 passed; sidebar policy matrix passed.
- Python/smoke validation: sidebar navigation 4, sidebar host 6, music popup 3, Rofi 12,
  control center 7, Waybar 5, runtime 6, V4 15, and recovery smoke passed.
- Hyprland config verification and live reload passed; `hyprctl configerrors` is empty.
- Pinned Kitty launch, running/active update, Spotify focus, All Apps/Windows entrypoints,
  expanded/collapsed state, auto-hide, Reduced Motion, and restored focus/workspaces passed.
- Final runtime has one sidebar host and one Quickshell child, no dock, and no leftover
  sidebar QA app. Waybar, SwayNC, wallpaper, notification history, music, profiles, and
  other backend owners were not restarted or replaced.

The historical full-redesign snapshot was 247,993 KiB sidebar PSS, but it is not a matched
comparison with the current runtime. A short same-session, same-host, same-warmup isolated
comparison measured the pre-navigation sidebar at 305,045 KiB PSS / 272,652 KiB private
and the final navigation candidate at 319,006 KiB PSS / 286,468 KiB private. The
attributable delta is +13,961 KiB PSS (+13.63 MiB) and +13,816 KiB private (+13.49 MiB),
below the unchanged +64 MiB incremental alarm. Installed-process snapshots after restart
are retained as opportunistic values, not substituted for the controlled pair.

An attempted switch from the validated SVG tint path to Qt's internal `ColorImage` was
rejected during validation: Qt refused the SVG decodes under its 256 MiB image allocation
limit, blanking icons. The attempt, warnings, and measurements remain in evidence, and the
validated `Image` plus `MultiEffect` renderer was restored before the final screenshot.

## Evidence and rollback

Evidence and pre-change source/live backups are under
`~/.local/state/kona/sidebar-navigation-20260915/`. The review set is:

- `evidence/clean-desktop-no-dock.png`
- `evidence/sidebar-expanded-final.png`
- `evidence/identity-header-closeup.png`
- `evidence/sidebar-collapsed-final.png`
- `evidence/sidebar-navigation-motion.mp4`
- `evidence/app-focus-runtime.txt`
- `evidence/app-launch-runtime.txt`
- `evidence/reduced-motion-runtime.txt`
- `evidence/navigation-baseline-compare-memory.txt`
- `evidence/navigation-candidate-final-memory.txt`
- `evidence/final-runtime-post-fix.txt`

Rollback restores the corresponding `backup/repo` and `backup/live` paths, reloads the
Hyprland config, and restarts only the sidebar. The retained `kona-dock` launcher can then
be started if the navigation pass itself is rolled back. No compositor or unrelated
service restart is required.

Branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`; the accepted dirty tree is preserved. No
fetch, pull, merge, rebase, reset, commit, push, UWSM change, compositor restart,
notification clear, application freeze, or long benchmark was performed.
