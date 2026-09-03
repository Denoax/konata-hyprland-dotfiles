# Konata Command Center

This bundle implements the selected dark-blue Konata Hyprland direction for
Mani's three-monitor Arch Linux setup. KDE Plasma remains installed and is the
fallback session.

## Monitor map

- Left: Samsung `HDMI-A-1`, 1920x1080 at 60 Hz, workspaces 1/4/7.
- Center: `DP-4`, 1920x1080 at 240.30 Hz, workspaces 2/5/8/10.
- Right: Acer `HDMI-A-5`, 1920x1080 at 119.98 Hz, workspaces 3/6/9.

## First login

At Plasma Login Manager, select **Hyprland (uwsm-managed)** and sign in. The
desktop starts clear for normal use; open the optional command dashboard with
`Super + Shift + Return`. Plasma is still available from the same session chooser.

## Keybindings

| Keys | Action |
| --- | --- |
| Tap `Windows/Super` | Show / hide compact app dock |
| `Super + Return` | Terminal |
| `Super + Shift + Return` | Toggle three-screen terminal command center |
| `Super + Space` | App launcher |
| `Super + E` | Files |
| `Super + B` | Browser |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + Shift + Space` | Toggle floating |
| `Super + 1..0` | Switch workspace |
| `Super + Shift + 1..0` | Move window to workspace |
| `Super + Left/Right` | Move focus |
| `Super + Shift + Left/Right` | Move window |
| `Alt + Tab` / `Alt + Shift + Tab` | Global visual window switcher |
| `Alt + F4` | Close window |
| `Super + D` or `Super + M` | Show / restore desktop |
| `Ctrl + H` or `Super + H` | Minimize active app |
| `Super + Shift + H` | Restore a minimized app |
| `Super + R` | Run command dialog |
| `Super + L` | Lock PC |
| `Super + I` | System Settings |
| `Super + A` | Notification center |
| `Super + Tab` | Window switcher |
| `Super + Up` / `Super + Down` | Maximize / restore window |
| `Super + Ctrl + Left/Right` | Previous / next workspace |
| `Super + Shift + S` | Region screenshot with annotation editor |
| `Super + Shift + R` | Start/stop region recording |
| `Super + Ctrl + Shift + R` | Start/stop active-monitor recording |
| `Super + W` | Thumbnail workspace overview |
| `Super + Shift + A` | Audio input/output picker |
| `Super + Shift + N` | Toggle warm night light / schedule |
| `Super + Ctrl + S` | Save the current app session |
| `Super + Ctrl + Shift + S` | Restore the saved app session |
| `Ctrl + Shift + Escape` | Task manager |
| `Ctrl + Alt + Delete` | Session menu |
| `Super + Ctrl + D` | Toggle command dashboard |
| `Super + N` | Notification center |
| `Super + V` | Clipboard history |
| `Super + Ctrl + L` | Lock |
| `Super + Escape` | Session menu |
| `Print` | Full screenshot |
| `Shift + Print` | Region screenshot with annotation editor |

The command-center clock opens on Samsung workspace 1. Its terminal grid opens
on Acer workspace 3, leaving the center Pixio workspace free for normal apps.
The clock is a compact floating media widget with Spotify album art, playback
progress, clickable transport controls, and a live CAVA spectrum. Inside the
widget, use `B`, `Space`, and `N` for previous, play/pause, and next. Drag a
window with `Alt + left mouse`. `Alt + right mouse` resizes a split tile; when
the app is the only tile on its workspace, it automatically floats first so it
can be freely resized. Floating windows snap to monitor and window edges.
Open the desktop actions menu with `Ctrl + right mouse`; regular right-click is
left entirely to applications and dock context menus.
When moving a grouped/tabbed app, the selected app is detached first so every
window moves independently. Dragging one app onto another can still create tabs.
Minimize the selected app with `Ctrl + H` or `Super + H`; grouped apps are
detached first so only the selected window is minimized.
The bundled `nwg-dock-hyprland-kona` build adds a direct `Close app` action at
the top of every running app's right-click menu. Multiple-window apps show
`Close all windows` and retain individual `Close window` submenu actions.
Drag a window with `Alt + left mouse` directly over another window to combine
them into a tabbed stack; the cyan drop target follows the hovered window, and
single-window tab bars stay hidden. Use `Alt + right mouse` to resize.

Right-click an empty part of the desktop (or press `Super + X`) for system,
display, network, sound, mouse, appearance, wallpaper, and session controls.
The selected Konata wallpaper is the default. Use `Restore Wallpaper` if it
ever needs to be reapplied across all three monitors.

Move the pointer against the bottom edge of any monitor to reveal the app
dock. It follows the active monitor, shows open apps, and hides one second
after the pointer leaves. The magnifying-glass button opens app search; the
Arch button opens the full application drawer.

## Added desktop utilities

- Volume, microphone, media, brightness, Caps Lock, and Num Lock use the compact
  blue Kona on-screen display.
- The audio picker changes the default input/output and moves active audio
  streams to the selected device.
- Night light follows a 07:00 clear, 20:00 soft, and 23:00 warm schedule. The
  shortcut temporarily toggles a warm manual mode.
- Screenshots are stored in `~/Pictures/Screenshots`; edited captures open in
  Satty. Recordings are stored in `~/Videos/Kona Captures` and include audio.
- `Super + W` shows live thumbnails for the three visible workspaces and clean
  cards for the remaining workspace bank.
- Brave, VS Code, Spotify, Discord, Slack, Telegram, Steam, and normal Kitty
  windows are saved every 30 seconds and restored to their workspaces at login.
- PipeWire, WirePlumber, and the Hyprland ScreenCast portal are configured for
  browser, Discord, OBS, and Flatpak screen sharing.

## Backup and restore

Run `kona-backup` to copy the live configuration into this repository, refresh
the package manifests, make a Git commit, and push to the private GitHub backup
when GitHub CLI is logged in. The desktop menu also has **Backup Now**.

On a fresh Arch installation, clone the private repository and run:

```bash
./install.sh
```

The restore script saves the replaced configuration under
`~/.local/state/kona/pre-restore-*`, installs the four extra UI tools locally
without sudo, restores Flatpak apps, and leaves system packages listed in
`packages/pacman.txt` for review.

## Recovery

Log out with `Super + Escape`, choose Plasma at the login screen, and sign in.
The original Plasma configuration is not modified by this bundle.
