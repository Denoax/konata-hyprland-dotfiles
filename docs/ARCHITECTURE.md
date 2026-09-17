# Architecture

Kona is a personal Hyprland configuration with explicit owners at each state boundary. The checked-in dotfiles are source; `~/.local/state/kona/` holds user state and evidence; generated theme output lives under `.config/kona/theme/current/`.

## Runtime owners

| Concern | Owner | Lifecycle |
| --- | --- | --- |
| Compositor and bindings | Hyprland native Lua | PlasmaLogin starts plain `/usr/bin/start-hyprland` |
| Startup orchestration | `kona-runtime-start` | Once from `hyprland.start`; imports and validates the canonical session |
| Polkit authentication UI | packaged `hyprpolkitagent.service` | One systemd-owned process with Kona readiness drop-in |
| Notifications | packaged `swaync.service` | One systemd-owned notification server |
| Primary navigation | `kona-sidebar` + one Quickshell child | One Hyprland-started host; edge reveal and auto-hide are in-process |
| Top bars | Waybar | One process with per-output configuration |
| Wallpaper | Awww or Hyprpaper | Selected transactionally by `kona-profile`; one backend at a time |
| Appearance intent | `kona-appearance` | Transactional, on demand, no daemon |
| Theme rendering | `kona-theme` | Atomic generated fragments, on demand, no daemon |
| Profiles/scenes | `kona-profile` | Transactional, on demand, no daemon |
| Window/workspace state | Hyprland events + bounded Kona workers | Debounced writes; no polling loop |
| Music popup | `kona-music-popup` + Quickshell | Transient; MPRIS/PipeWire remain data owners |
| Menus | Rofi, SwayNC and small Kona launchers | Transient; NetworkManager, BlueZ, PipeWire and systemd remain backends |
| OSD | one SwayOSD server | Direct owner in the plain session; managed unit remains inactive |

The direct clipboard, OSD, automount and idle units are retained for the deferred UWSM path but remain inactive in the canonical plain session. They must never run beside duplicate direct owners.

## Data flow

Hyprland Lua emits window, workspace and topology events. Small workers persist session state or workspace thumbnails after bounded debounce periods. The UI reads current state through existing system APIs and Kona's read-only JSON outputs; it does not create parallel writable stores for NetworkManager, Bluetooth, audio, media or notifications.

`kona-appearance` owns the durable manual Light/Dark choice. It asks `kona-theme` to validate and render semantic fragments, updates host/portal and toolkit preferences, reloads supported consumers, verifies convergence and commits the state. A failed transaction restores the previous files and preferences. Quickshell watches `.config/kona/appearance/current.json`; Waybar, Rofi, SwayNC, SwayOSD, Kitty and Hyprland consume generated fragments.

`kona-profile` owns the active Daily, Focus, Showcase or Gaming policy. It switches wallpaper backends and motion/resource policy as one transaction. Showcase animation is opt-in; it is not represented as a memory-saving mode.

## Source, generated and runtime state

- Safe source inputs: `.config/hypr/hyprland.lua`, `.config/kona/appearance/{light,dark}.json`, `.config/kona/profiles.json`, `.config/kona/scene-images.json`, Rofi/SwayNC/Waybar/Quickshell source files.
- Generated source snapshot: `.config/kona/theme/current/`. Change its inputs and rerun the owner instead of editing fragments by hand.
- Runtime state: `~/.local/state/kona/`. It contains appearance/profile intent, session snapshots, workspace captures, logs and recovery evidence and is never copied into Git.
- Machine-local application state: browsers, editors, Steam and other app profiles remain application-owned.

## Session boundary

The canonical path is PlasmaLogin → plain Hyprland. UWSM-managed compositor startup is optional and deferred; the installed `uwsm` command still supplies bounded application/background scopes. `kona-runtime-start` accepts only the oldest live compositor instance, imports its Wayland/Hyprland environment, waits for both endpoints, and then recovers the sole systemd polkit owner. See [Current status](CURRENT_STATUS.md) for the remaining real-login proof.
