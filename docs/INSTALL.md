# Installation

Kona targets Arch Linux and Hyprland's native Lua configuration. It comes from a real three-monitor workstation, so inspect the hardware assumptions before logging into it.

## 1. Inspect the scope

```bash
git clone https://github.com/Denoax/konata-hyprland-dotfiles.git
cd konata-hyprland-dotfiles
./install.sh --dry-run
```

The installer copies these Kona-owned trees: Hyprland, Foot, Kitty, Kona, Quickshell, Rofi, SwayOSD, systemd user configuration, Waybar, XDG portal configuration, Kona executables, desktop entries and wallpaper assets. Every existing target is copied to `~/.local/state/kona/pre-restore-<timestamp>/` before replacement. Obsolete SwayNC configuration is backed up and retired during migration.

It does not install packages from `packages/pacman.txt`, choose GPU drivers, edit a display manager, or start background services. Optional personal Flatpaks are installed only with `--with-flatpaks`.

## 2. Adapt the machine boundary

Run `hyprctl monitors` from a working session. Edit monitor modes, positions and workspace rules in `.config/hypr/hyprland.lua`. Review `packages/pacman.txt` and install only the dependencies appropriate to your system. `packages/hardware-mani.txt` documents the reference workstation and must not be installed blindly.

## 3. Install

```bash
./install.sh
```

Options:

| Option | Effect |
| --- | --- |
| `--dry-run` | Print the exact scope and perform no writes |
| `--config-only` | Restore source configuration without helper downloads or Flatpaks |
| `--skip-deps` | Do not install user-local helper packages |
| `--with-flatpaks` | Install missing apps from the optional personal list |

The helper downloader uses Arch package URLs to unpack SwayOSD, Satty, wf-recorder, Hyprsunset and Kona's pinned Quickshell runtime below `~/.local/opt/kona-pkgs/`. It also downloads the pinned end-4 overview source into `~/.local/share/kona/upstream/end4/`. System package installation remains the user's responsibility.

Kona's dashboard, media and performance presentation loads the real upstream Caelestia components from the `caelestia-shell` AUR package. Install `caelestia-shell` through a normal full-system Arch upgrade before using those surfaces; its dependency replaces the repository `quickshell` package with `quickshell-git`. Existing Kona surfaces continue to use the pinned user-local Quickshell runtime. Upstream source, pinned revisions and licenses are documented in [Upstream UI credits](kona/UPSTREAM_UI_CREDITS.md).

The `uwsm` command remains a runtime dependency for bounded application/background scopes. Kona does not require an UWSM-managed compositor session.

## 4. First login

Log out normally and select **Hyprland** in PlasmaLogin. Do not select an UWSM-managed entry for the canonical configuration. A Plasma session is useful as a repair fallback.

After login:

```bash
kona-runtime-health polkit
systemctl --user --failed
kona-appearance status
```

The expected state is one Hyprland instance, one systemd-owned polkit agent, no failed user units and a synchronized Light/Dark status.

## Recovery install

For a local source checkout that already has dependencies:

```bash
./install.sh --config-only
./tests/recovery-smoke.sh
```

The smoke test uses an isolated temporary home; it does not replace the live desktop.
