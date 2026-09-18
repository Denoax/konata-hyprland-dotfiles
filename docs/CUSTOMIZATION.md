# Customization

Kona has three different kinds of configuration. Edit the source layer, let the owners render generated output, and leave runtime state outside Git.

## Appearance

Edit semantic roles in:

```text
.config/kona/appearance/light.json
.config/kona/appearance/dark.json
```

Apply and verify with:

```bash
kona-appearance light
kona-appearance dark
kona-appearance status
```

`kona-theme` validates contrast and atomically renders fragments for Waybar, Rofi, SwayNC, SwayOSD, Kitty, Hyprland and Quickshell. `.config/kona/theme/current/` is generated and should not be hand-edited.

The switch also updates the host color preference, verifies the XDG portal, and configures supported GTK and Qt apps. Apps manually forced to a theme remain application-owned. Kona does not edit private Brave, Firefox, Electron or VS Code profiles.

## Profiles and wallpaper

Profile policy lives in `.config/kona/profiles.json`; scene-to-file mappings live in `.config/kona/scene-images.json`. Paths beginning with `~/` are expanded by the owner. Keep wallpaper files under `.config/kona/wallpapers/` or `.local/share/wallpapers/` so recovery can reproduce them.

Daily and Showcase may use animation; Focus and Gaming use a composition-matched still and release the animated backend. Reduced Motion is a separate accessibility policy and is consumed by Kona UI components.

When Steam Wallpaper Engine and `linux-wallpaperengine` are installed, `Super + Shift + W` also inventories downloaded Workshop projects. The same menu opens Steam for browsing and restores the previous Kona scene. Supported Scene, Web and Video projects run through one renderer process across the active Hyprland outputs. Scene entries inside `scene.pkg` or `gifscene.pkg` are recognized without requiring a loose JSON file. Presets resolve an installed dependency and pass their primitive property overrides to the renderer; bundled file properties are normalized to their installed absolute path. Missing dependencies, assets and unsupported project types remain visible with their reason instead of failing silently. Runtime selection and logs live in `~/.local/state/kona/wallpaper-engine.json` and `wallpaper-engine.log`. The selected item is the Daily/Showcase startup default; Focus and Gaming stop it without forgetting the selection.

Web rendering is experimental on this Hyprland/NVIDIA stack and requires a confirmation in the wallpaper menu. A Web wallpaper was visible and animated during validation, but the compositor later crashed in its framebuffer render path while it was active. Scene and Video defaults receive one bounded startup attempt; there is no retry loop, and an ordinary renderer failure falls through to the accepted Awww scene. Web projects remain manual because a compositor crash would prevent the fallback from running. The explicit Web warning remains in place.

Arch package revision r627 needs the tracked `patches/linux-wallpaperengine-r627-web-texture.patch` plus a CEF preload for Web projects. `kona-wallpaper-engine` supplies the preload, uses the Wayland background layer and disables threaded GL optimizations on NVIDIA as recommended upstream. Remove the local package patch only after upstream resolves issues 628 and 629 and a real Web render passes.

## Weather

Copy `.config/kona/weather.example.json` to `~/.config/kona/weather.json` and set an explicit display name, region, latitude and longitude. `units` accepts `metric` or `imperial`; `refresh_minutes` accepts 15–120. The sidebar reads the cached summary once when it starts, and the Weather surface refreshes on demand through Open-Meteo. No location service, API key or resident weather process is used.

```bash
kona-weather status
kona-weather refresh
```

The Arch system terminal uses `.config/fastfetch/kona-arch.jsonc` and the tracked Kitty image asset under `.config/fastfetch/assets/`. Terminals without Kitty graphics support fall back to Fastfetch's normal text behavior.

## Monitors, input and windows

Edit `.config/hypr/hyprland.lua`. Its monitor names and workspace map are intentionally hardware-specific. Preserve the event callbacks and owner boundaries when changing bindings or window rules: callbacks should schedule bounded workers, not perform slow filesystem or IPC work on the compositor thread.

## Sidebar and menus

The sidebar source is `.config/quickshell/kona/sidebar/`. Shared primitives and semantic token readers live under its `qml/components/` tree. Menu geometry belongs to each Rofi/SwayNC/SwayOSD surface; color roles come from the generated semantic fragments. Do not create a second palette or appearance state for one menu.

## Local state

`~/.local/state/kona/` is machine-local. It includes saved sessions, workspace captures, current profile/appearance intent, logs and validation evidence. Do not copy it into the repository.
