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

## Monitors, input and windows

Edit `.config/hypr/hyprland.lua`. Its monitor names and workspace map are intentionally hardware-specific. Preserve the event callbacks and owner boundaries when changing bindings or window rules: callbacks should schedule bounded workers, not perform slow filesystem or IPC work on the compositor thread.

## Sidebar and menus

The sidebar source is `.config/quickshell/kona/sidebar/`. Shared primitives and semantic token readers live under its `qml/components/` tree. Menu geometry belongs to each Rofi/SwayNC/SwayOSD surface; color roles come from the generated semantic fragments. Do not create a second palette or appearance state for one menu.

## Local state

`~/.local/state/kona/` is machine-local. It includes saved sessions, workspace captures, current profile/appearance intent, logs and validation evidence. Do not copy it into the repository.
