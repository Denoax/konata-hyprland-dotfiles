# Architecture

Kona is a personal Hyprland configuration with explicit owners at each state boundary. The checked-in dotfiles are source; `~/.local/state/kona/` holds user state and evidence; generated theme output lives under `.config/kona/theme/current/`.

## Runtime owners

| Concern | Owner | Lifecycle |
| --- | --- | --- |
| Compositor and bindings | Hyprland native Lua | PlasmaLogin starts plain `/usr/bin/start-hyprland` |
| Startup orchestration | `kona-runtime-start` | Once from `hyprland.start`; imports and validates the canonical session |
| Polkit authentication UI | packaged `hyprpolkitagent.service` | One systemd-owned process with Kona readiness drop-in |
| Notifications | pinned end-4 `NotificationServer` + Kona host | One persistent owner; upstream popup and right-sidebar presentation |
| Primary navigation | `kona-sidebar` + one Quickshell child | One Hyprland-started host; edge reveal and auto-hide are in-process |
| Top bars | Waybar | One process with per-output configuration |
| Wallpaper | `kona-wallpaper-engine`, Awww or Hyprpaper | Selected transactionally by `kona-profile`; one backend at a time |
| Appearance intent | `kona-appearance` | Transactional, on demand, no daemon |
| Theme rendering | `kona-theme` | Atomic generated fragments, on demand, no daemon |
| Profiles/scenes | `kona-profile` | Transactional, on demand, no daemon |
| Window/workspace state | Hyprland events + bounded Kona workers | Debounced writes; no polling loop |
| Arch workspace | `kona-arch-workspace` + native Kitty windows | Transient; Btop, Fastfetch and CAVA exit on close |
| Dashboard, media, performance and audio UI | upstream Caelestia QML + transient Kona hosts | PipeWire remains the audio backend; hosts exit with their surfaces |
| Weather | `kona-weather` summary + transient Caelestia dashboard | Kona's explicit location/units feed both presentations; no daemon or IP-location fallback |
| Search, overview, assistant and cheat sheet | pinned end-4 QML + `kona-end4-surface` | Transient and XDG-isolated; Hyprland remains workspace/window owner, API keys stay in Secret Service, model tools default off |
| Menus | Rofi, Caelestia/end-4 presentation and small Kona launchers | Transient except the single notification owner; NetworkManager, BlueZ, PipeWire and systemd remain backends |
| Power/session UI | upstream Caelestia QML + `kona-session-action` | Transient presentation; confirmation and Hyprlock/Hyprland/systemd ownership stay in Kona |
| OSD | one SwayOSD server | Direct owner in the plain session; managed unit remains inactive |

The direct clipboard, OSD, automount and idle units are retained for the deferred UWSM path but remain inactive in the canonical plain session. They must never run beside duplicate direct owners.

## Data flow

Hyprland Lua emits window, workspace and topology events. Small workers persist session state or workspace thumbnails after bounded debounce periods. The UI reads current state through existing system APIs and Kona's read-only JSON outputs; it does not create parallel writable stores for NetworkManager, Bluetooth, audio, media or notifications.

`kona-appearance` owns the durable manual Light/Kona/Dark choice. It asks `kona-theme` to validate and render semantic fragments, updates host/portal and toolkit preferences, reloads supported consumers, verifies convergence and commits the state. Kona is a distinct pastel blue palette and maps to the standard Dark preference so websites and ordinary applications remain dark. A failed transaction restores the previous files and preferences. Quickshell watches `.config/kona/appearance/current.json`; Waybar, Rofi, SwayOSD, Foot, Kitty and Hyprland consume generated fragments.

`kona-upstream-theme` derives read-only Caelestia and end-4 colour caches from that same appearance state. It does not accept or persist independent theme intent. The Caelestia hosts deliberately omit their service loader. Transient end-4 surfaces run under isolated XDG paths with a reduced `GlobalStates`; the persistent notification host is the sole notification server and keeps its history in the same isolated state root.

The left sidebar remains Kona's richer primary navigation surface. Its existing sections and actions are unchanged; only its grouping, surface treatment and spatial motion use the credited Caelestia visual grammar. The end-4 assistant surface retains upstream Intelligence, Translate and Anime tabs. Online model keys use end-4's Secret Service integration, its translation tab uses `translate-shell`, Anime starts in safe mode, and model-issued shell/config tools are disabled by default. The cheat sheet reads descriptions from Hyprland's real binding registry. The pinned end-4 notification host is the only notification server, and Kona's profile transaction remains the only wallpaper state owner.

`kona-profile` owns the active Daily, Focus, Showcase or Gaming policy. It switches wallpaper backends and motion/resource policy as one transaction. `kona-wallpaper-engine` is a bounded adapter for downloaded Steam Workshop items: it shares the profile writer lock, replaces Awww/Hyprpaper instead of competing with them, and keeps the selected item in the existing runtime state when a restricted profile stops the renderer. Daily and Showcase make one startup restore attempt, then fall back to the accepted Awww scene. Focus and Gaming continue to require a static wallpaper. Showcase animation is opt-in; it is not represented as a memory-saving mode.

## Source, generated and runtime state

- Safe source inputs: `.config/hypr/hyprland.lua`, `.config/kona/appearance/{light,kona,dark}.json`, `.config/kona/profiles.json`, `.config/kona/scene-images.json`, Rofi/Waybar/Quickshell source files.
- Generated source snapshot: `.config/kona/theme/current/`. Change its inputs and rerun the owner instead of editing fragments by hand.
- Runtime state: `~/.local/state/kona/`. It contains appearance/profile intent, session snapshots, workspace captures, logs and recovery evidence and is never copied into Git.
- Machine-local application state: browsers, editors, Steam and other app profiles remain application-owned.

## Session boundary

The canonical path is PlasmaLogin → plain Hyprland. UWSM-managed compositor startup is optional and deferred; the installed `uwsm` command still supplies bounded application/background scopes. `kona-runtime-start` waits a bounded five seconds for start-event instance registration, accepts only the oldest live compositor, imports its Wayland/Hyprland environment, waits for both endpoints, and then recovers the sole systemd polkit owner. See [Current status](CURRENT_STATUS.md) for the remaining post-fix real-login proof.
