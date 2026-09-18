<div align="center">

<img src="showcase/assets/v3/kona-v3-banner.webp" alt="Kona Desktop V3 — Arch Linux and Hyprland" width="100%">

# Kona Desktop V3

**Konata energy. Arch discipline.**<br>
A calm Hyprland desktop with a full Linux workstation one gesture away.

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58E1FF?style=for-the-badge&logo=wayland&logoColor=082032)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-A9C8FF?style=for-the-badge)](https://quickshell.org/)
[![Status](https://img.shields.io/badge/status-release_candidate-8EB8FF?style=for-the-badge)](docs/CURRENT_STATUS.md)
[![License](https://img.shields.io/badge/Kona_code-MIT-7AA8F8?style=for-the-badge)](LICENSE)

[Showcase](#the-desktop) · [Features](#built-in) · [Controls](#controls) · [Install](#install) · [Architecture](#system-map)

<br>

<img src="showcase/assets/v3/desktop-kona.webp" alt="Kona V3 desktop" width="100%">

*Quiet by default. Powerful on demand.*

</div>

> [!IMPORTANT]
> Kona is an opinionated configuration for a real Arch workstation. It is not an ISO or a universal installer. Read the [hardware boundary](docs/HARDWARE_PROFILE.md) and run the installer dry-run before applying it.

## The desktop

Kona keeps the idle desktop simple. The shell appears from the edges, native tools do the work, and every transient process leaves when its surface closes.

| Interface layer | Terminal layer |
|:---:|:---:|
| <img src="showcase/assets/v3/shell-tour.gif" alt="Kona sidebar and dashboard motion" width="100%"> | <img src="showcase/assets/v3/terminal-tour.gif" alt="Kona terminal and Arch workspace tour" width="100%"> |
| Quickshell navigation, dashboard, media, audio and session surfaces | Foot/Fish, Fastfetch, Btop, CAVA and the command center |

The GIFs use fixed compositor geometry. There is no simulated camera movement, fake telemetry or screenshot-based functional UI.

## Dashboard

<img src="showcase/assets/v3/dashboard-kona.webp" alt="Kona dashboard" width="100%">

One surface brings together real desktop state without turning the wallpaper into a permanent telemetry board.

| Media | Performance |
|:---:|:---:|
| <img src="showcase/assets/v3/media-dashboard-kona.webp" alt="Kona media dashboard" width="100%"> | <img src="showcase/assets/v3/performance-dashboard-kona.webp" alt="Kona performance dashboard" width="100%"> |

| Weather | Music popup |
|:---:|:---:|
| <img src="showcase/assets/v3/weather-dashboard-kona.webp" alt="Kona weather dashboard" width="100%"> | <img src="showcase/assets/v3/music-kona.webp" alt="Kona music popup" width="100%"> |

- **Media** uses real MPRIS metadata and PipeWire/WirePlumber controls.
- **Performance** renders live system data without adding a resident telemetry daemon.
- **Weather** uses configured, cached Open-Meteo data with bounded on-demand refresh.
- **Music** owns one CAVA visualizer only while its popup is visible.

## Navigation from every edge

| Left: primary navigation | Right: notifications |
|:---:|:---:|
| <img src="showcase/assets/v3/sidebar-kona.webp" alt="Expanded Kona sidebar" width="100%"> | <img src="showcase/assets/v3/notifications-kona.webp" alt="Kona notification center" width="100%"> |

The auto-hiding left rail keeps Kona's broad navigation: profile, running apps, workspaces, media, Weather, appearance, audio, network, Bluetooth, system tools and power. The right edge has one notification owner with real history, actions and DND. The top bar connects workspaces, time and concise system state.

<img src="showcase/assets/v3/menu-tour.gif" alt="Kona assistant, cheat sheet and menu motion" width="100%">

<details>
<summary><strong>Open the complete surface gallery</strong></summary>

### Intelligence and live controls

| Intelligence · Translate · Anime | Keybinding cheat sheet |
|:---:|:---:|
| <img src="showcase/assets/v3/assistant-kona.webp" alt="Kona intelligence and translation surface" width="100%"> | <img src="showcase/assets/v3/cheatsheet-kona.webp" alt="Kona live shortcut cheat sheet" width="100%"> |

### Settings and audio

| Kona settings | Devices and volume |
|:---:|:---:|
| <img src="showcase/assets/v3/settings-kona.webp" alt="Kona settings" width="100%"> | <img src="showcase/assets/v3/audio-kona.webp" alt="Kona audio menu" width="100%"> |

### Commands and session

| Desktop command center | Power and session |
|:---:|:---:|
| <img src="showcase/assets/v3/command-menu-kona.webp" alt="Kona command center" width="100%"> | <img src="showcase/assets/v3/session-kona.webp" alt="Kona power and session controls" width="100%"> |

### Profiles and wallpapers

| Profile picker | Wallpaper picker |
|:---:|:---:|
| <img src="showcase/assets/v3/profile-picker-kona.webp" alt="Kona profile picker" width="100%"> | <img src="showcase/assets/v3/wallpaper-picker-kona.webp" alt="Kona Wallpaper Engine picker" width="100%"> |

</details>

## Arch workspace

<img src="showcase/assets/v3/arch-workspace-dark.webp" alt="Native Arch workspace with Btop, Fastfetch and CAVA" width="100%">

`Super + Shift + D` toggles a dedicated `special:arch` workspace composed by Hyprland from three real terminal windows:

- **Btop** — CPU, GPU, memory and storage;
- **Fastfetch + Fish** — a concise machine summary and an interactive shell;
- **CAVA** — the active PipeWire output.

Every window has a deterministic class, repeated toggles do not duplicate it, and closing the workspace terminates only its own children. A closed Arch workspace has zero Arch-workspace processes. `Super + Grave` separately owns one scratch terminal, while `Alt + Return` and `Super + Return` open the normal Foot/Fish workflow with history-based autosuggestions.

## Three appearances

<p align="center">
  <img src="showcase/assets/v3/sidebar-light-modern.webp" alt="Kona Light appearance" width="32%">
  <img src="showcase/assets/v3/sidebar-kona.webp" alt="Kona pastel appearance" width="32%">
  <img src="showcase/assets/v3/sidebar-dark-modern.webp" alt="Kona Dark appearance" width="32%">
</p>

| Light dashboard | Dark dashboard |
|:---:|:---:|
| <img src="showcase/assets/v3/dashboard-light.webp" alt="Kona dashboard in Light mode" width="100%"> | <img src="showcase/assets/v3/dashboard-dark.webp" alt="Kona dashboard in Dark mode" width="100%"> |

`kona-appearance` is the only durable appearance owner.

- **Light** — icy white and pale blue, with the system Light preference.
- **Kona** — pastel blue desktop surfaces while websites and ordinary applications remain on system Dark.
- **Dark** — the deeper midnight counterpart using the same geometry and semantic contract.

The transaction renders and validates generated fragments, updates supported GTK/Qt and XDG portal state, reloads consumers, verifies convergence and rolls back on failure.

```bash
kona-appearance light
kona-appearance kona
kona-appearance dark
kona-appearance toggle
kona-appearance status
```

## Profiles, wallpaper and lock

<img src="showcase/assets/v3/lockscreen.webp" alt="Kona Hyprlock screen using the active wallpaper" width="100%">

| Profile | Desktop policy |
| --- | --- |
| **Daily** | Balanced effects and the selected daily wallpaper |
| **Focus** | Static, restrained and distraction-light |
| **Gaming** | Static wallpaper and the cleanest runtime policy |
| **Showcase** | Explicit opt-in motion and presentation effects |

The wallpaper transaction selects exactly one backend: Wallpaper Engine, Awww or Hyprpaper. Workshop Scene and Video projects can become the Daily/Showcase wallpaper; Focus and Gaming retain their static policy. Hyprlock receives the active backdrop and shared avatar while PAM remains the only authentication owner.

> [!WARNING]
> Wallpaper Engine **Web** projects remain experimental on the tested Hyprland/NVIDIA stack because one validated project later triggered a compositor framebuffer crash. Scene and Video projects use bounded fallback; Web projects require explicit confirmation.

## Built in

| Area | Current capability |
| --- | --- |
| **Shell** | Connected top bar, auto-hiding sidebar, workspace rail, running apps, profile state and Reduced Motion |
| **Dashboard** | Media, performance, Weather, audio state, calendar and session entrypoints |
| **Navigation** | Live application search, workspace/window overview, Alt+Tab, show desktop and scratch terminal |
| **Menus** | Command palette, clipboard, audio devices, per-app mixer, network, Bluetooth, profiles, wallpapers and confirmations |
| **Assistance** | Intelligence, translation, anime search and a live shortcut cheat sheet |
| **Notifications** | One end-4 owner, real history/actions, DND, popups and the right-edge center |
| **Terminal** | Foot + Fish + Starship, completions, autosuggestions, Fastfetch, Kitty image support and Yazi fallback |
| **Arch tools** | Btop, Fastfetch and CAVA in a transient native Hyprland workspace |
| **Appearance** | Transactional Light/Kona/Dark propagation across Kona, GTK, Qt and the XDG portal |
| **Profiles** | Daily, Focus, Gaming and Showcase scenes with one wallpaper backend at a time |
| **Capture** | Full/region screenshots, annotation, region/output recording and SwayOSD feedback |
| **Lock and recovery** | Hyprlock/PAM, current-wallpaper continuity, installer backups and focused recovery tools |

## System map

Kona keeps one authoritative owner at every mutable boundary.

| Boundary | Owner | Lifetime |
| --- | --- | --- |
| Session and windows | plain Hyprland | session |
| Primary navigation | Kona Quickshell sidebar | one session host |
| Dashboard/settings/audio/session | Caelestia QML + narrow Kona adapters | transient |
| Overview/assistant/notifications | pinned end-4 components | transient / one notification service |
| Appearance | `kona-appearance` + `kona-theme` | transactional, no daemon |
| Profiles/scenes | `kona-profile` | transactional, no daemon |
| Audio | PipeWire + WirePlumber | upstream services |
| OSD | SwayOSD | one session owner |
| Workspace state | Hyprland events | event-driven, no poller |
| Weather | `kona-weather` cache | on demand |
| Arch workspace | Hyprland + terminal tools | zero children when closed |
| Authentication | Hyprlock + PAM | lock lifetime |
| Wallpaper | Wallpaper Engine adapter, Awww or Hyprpaper | exactly one backend |

The adapters preserve upstream behavior, pin integration revisions and fail when an expected contract changes instead of silently drifting. See the full [architecture and ownership map](docs/ARCHITECTURE.md).

## Controls

| Shortcut | Action |
| --- | --- |
| Tap `Super` / hover left edge | Pin or reveal the sidebar |
| `Super + Space` / `Super + W` / `Alt + Tab` | Live apps, workspaces and windows |
| `Super + Shift + Return` | Dashboard |
| `Super + Ctrl + Space` | Notification center |
| `Super + A` | Intelligence, Translate and Anime |
| `Super + I` | Kona settings |
| `Super + F1` | Live shortcut cheat sheet |
| `Super + Shift + D` | Arch workspace |
| `Super + Return` / `Alt + Return` | Kona terminal |
| `Super + Grave` | Scratch terminal |
| `Super + V` | Clipboard history |
| `Super + Shift + A` | Audio devices and mixer |
| `Super + Ctrl + P` | Profile picker |
| `Super + Shift + W` | Wallpaper picker |
| `Print` / `Super + Shift + S` | Full / annotated region screenshot |
| `Super + Shift + R` | Region recording |
| `Super + L` | Lock |
| `Ctrl + Alt + Delete` | Power and session |

The complete current map lives in [Keybinds](docs/KEYBINDS.md).

## Install

```bash
git clone https://github.com/Denoax/konata-hyprland-dotfiles.git
cd konata-hyprland-dotfiles
./install.sh --dry-run
```

Before applying anything:

1. Read [Installation](docs/INSTALL.md) and [Hardware profile](docs/HARDWARE_PROFILE.md).
2. Adapt the checked-in monitors, inputs and workspace map in `.config/hypr/hyprland.lua`.
3. Review `packages/pacman.txt`; the installer does not install system packages or GPU drivers.
4. Keep a Plasma session or TTY available as a repair path.

```bash
./install.sh
```

The installer copies only Kona-owned paths and backs up every replaced target under `~/.local/state/kona/pre-restore-<timestamp>/`. Optional personal Flatpaks remain excluded unless `--with-flatpaks` is passed.

## Repository anatomy

```text
.config/            desktop configuration and semantic theme sources
.local/bin/         explicit launchers, transactions and recovery tools
.local/share/kona/  shipped artwork, sounds and runtime assets
packages/           reviewed package manifests
patches/            pinned upstream integration patches
third_party/        upstream source and license records
tests/              portable contracts and focused runtime regressions
showcase/           sanitized public screenshots and motion
docs/               install, ownership, customization and recovery
```

| Change | Source of truth |
| --- | --- |
| Semantic colors | `.config/kona/appearance/{light,kona,dark}.json` |
| Monitor/input/window policy | `.config/hypr/hyprland.lua` |
| Profiles and scenes | `.config/kona/profiles.json` + `.config/kona/scene-images.json` |
| Weather location | `~/.config/kona/weather.json` from the checked-in example |
| Generated theme | `.config/kona/theme/current/` — do not hand-edit |
| Runtime state | `~/.local/state/kona/` — never copied into Git |

See [Customization](docs/CUSTOMIZATION.md), [Recovery](docs/RECOVERY.md) and [Current status](docs/CURRENT_STATUS.md).

## Release status

Kona V3 is a **release candidate**. Portable contracts, syntax/parsing, appearance propagation, profile policy, Arch-workspace lifecycle, Weather/music lifecycle, recovery and privacy checks pass. One fresh PlasmaLogin → Hyprland login remains the final proof for the latest startup-race fix before a stable tag. The exact evidence boundary is maintained in [Current status](docs/CURRENT_STATUS.md).

The previous checkpoints remain available at [`legacy/pre-arch-first-v3-2026.09.17`](https://github.com/Denoax/konata-hyprland-dotfiles/tree/legacy/pre-arch-first-v3-2026.09.17) and [`legacy/pre-kona-2026.09`](https://github.com/Denoax/konata-hyprland-dotfiles/tree/legacy/pre-kona-2026.09).

## Credits

Kona reuses strong upstream work openly:

- [Caelestia shell](https://github.com/caelestia-dots/shell) — dashboard, media, performance, audio/session presentation and motion grammar.
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — overview/search, notifications, Intelligence/Translate/Anime and cheat sheet.
- [rounded-polygon-qmljs](https://github.com/end-4/rounded-polygon-qmljs) — Material shape support used by the pinned end-4 overview.
- Arch Linux, Hyprland, Quickshell, Waybar, Rofi, SwayOSD, Hyprlock, PipeWire, WirePlumber, Btop, Fastfetch, CAVA, Foot, Kitty, Fish, Starship, Awww and Hyprpaper.

Each upstream component keeps its own copyright and license. Original Kona code, configuration and documentation are available under the [MIT License](LICENSE).

Konata Izumi, *Lucky Star*, character artwork, Workshop content and other third-party visual/audio assets are **not** relicensed by MIT. This unofficial fan project is not affiliated with the respective rights holders, Arch Linux, Hyprland or the upstream projects. Read [Third-party notices](THIRD_PARTY_NOTICES.md) and [Upstream UI credits](docs/kona/UPSTREAM_UI_CREDITS.md).

<div align="center">

**Built for a real workstation. Styled for Konata. Maintained like software.**

`Arch Linux` · `Hyprland` · `Wayland` · `Kona blue`

</div>
