#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d -t kona-recovery-XXXXXX)"
trap 'gio trash "$sandbox" >/dev/null 2>&1 || true' EXIT
test_home="$sandbox/home"
mkdir -p "$test_home"

# A dry run must describe the real plain-session scope without touching HOME.
dry_home="$sandbox/dry-home"
dry_output="$(HOME="$dry_home" XDG_CONFIG_HOME="$dry_home/.config" \
  XDG_STATE_HOME="$dry_home/.local/state" "$repo_root/install.sh" --dry-run --config-only)"
[[ ! -e "$dry_home" ]]
[[ "$dry_output" == *'PlasmaLogin -> Hyprland'* ]]
[[ "$dry_output" != *'nwg-dock'* && "$dry_output" != *'nwg-drawer'* ]]
mkdir -p "$test_home/.config/systemd/user"
printf 'unrelated user service\n' > "$test_home/.config/systemd/user/unrelated.service"
printf 'old Kona unit\n' > "$test_home/.config/systemd/user/kona-automount.service"

HOME="$test_home" \
XDG_CONFIG_HOME="$test_home/.config" \
XDG_STATE_HOME="$test_home/.local/state" \
  "$repo_root/install.sh" --config-only >/dev/null

required=(
  '.config/hypr/hyprland.lua'
  '.local/bin/kona-wallpaper-menu'
  '.local/bin/kona-profile'
  '.local/bin/kona-shell'
  '.local/bin/kona-preferences'
  '.local/bin/kona-surface-data'
  '.local/bin/kona-motion'
  '.local/bin/kona-appearance'
  '.config/kona/appearance/light.json'
  '.config/kona/appearance/dark.json'
  '.config/kona/motion.json'
  '.config/quickshell/kona/shell.qml'
  '.config/quickshell/kona/Appearance.qml'
  '.config/quickshell/kona/sidebar/Appearance.qml'
  '.config/quickshell/kona/music/Appearance.qml'
  '.local/share/applications/kona-studio.desktop'
  '.local/bin/kona-profile-menu'
  '.local/bin/kona-runtime-start'
  '.config/rofi/shared.rasi'
  '.config/rofi/konata.rasi'
  '.config/rofi/window.rasi'
  '.config/rofi/run.rasi'
  '.config/rofi/clipboard.rasi'
  '.config/rofi/audio.rasi'
  '.config/rofi/list.rasi'
  '.config/rofi/session.rasi'
  '.config/rofi/confirm.rasi'
  '.config/rofi/wallpaper.rasi'
  '.config/rofi/overview.rasi'
  '.config/waybar/config.jsonc'
  '.local/bin/kona-backup'
  '.local/bin/kona-workspace-capture'
  '.local/bin/kona-waybar-refresh'
  '.local/bin/kona-state'
  '.local/bin/kona-theme'
  '.config/kona/theme/current/tokens.json'
  '.config/kona/theme/current/appearance.json'
  '.config/kona/theme/current/waybar.css'
  '.config/kona/theme/current/swaync.css'
  '.config/kona/theme/current/swayosd.css'
  '.config/kona/theme/current/rofi.rasi'
  '.config/kona/theme/current/kitty.conf'
  '.config/kona/theme/current/hyprland.colors'
  '.local/bin/kona-runtime-health'
  '.config/kona/wallpapers/konata-mono-rain/render/konata-mono-rain.gif'
  '.local/share/wallpapers/konata-command-center/v2/selected.png'
)

for relative in "${required[@]}"; do
  [[ -s "$test_home/$relative" ]] || { printf 'missing restored file: %s\n' "$relative" >&2; exit 1; }
done
[[ -x "$test_home/.local/bin/kona-backup" ]]
for command in kona-workspace-capture kona-waybar-refresh kona-state kona-theme kona-appearance kona-wallpaper-menu kona-profile kona-profile-menu kona-runtime-start; do
  [[ -x "$test_home/.local/bin/$command" ]]
  cmp -s "$repo_root/.local/bin/$command" "$test_home/.local/bin/$command"
done
while IFS= read -r unit; do
  cmp -s "$repo_root/.config/systemd/user/$unit" "$test_home/.config/systemd/user/$unit"
done < "$repo_root/packages/kona-user-units.txt"
[[ "$(cat "$test_home/.config/systemd/user/unrelated.service")" == 'unrelated user service' ]]
old_units=("$test_home"/.local/state/kona/pre-restore-*/.config/systemd/user/kona-automount.service)
[[ ${#old_units[@]} == 1 && "$(cat "${old_units[0]}")" == 'old Kona unit' ]]
cmp -s "$repo_root/.config/hypr/hyprland.lua" "$test_home/.config/hypr/hyprland.lua"
[[ "$(cat "$test_home/.config/kona/backup-repo")" == "$repo_root" ]]
[[ ! -e "$test_home/.local/bin/nwg-dock-hyprland-kona" ]]
[[ ! -e "$test_home/.config/nwg-dock-hyprland" ]]
[[ ! -e "$test_home/.config/nwg-drawer" ]]

HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" \
  "$test_home/.local/bin/kona-theme" --default --no-reload >/dev/null
[[ -s "$test_home/.config/kona/appearance/current.json" ]]

HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" Hyprland --verify-config --config "$test_home/.config/hypr/hyprland.lua" >/dev/null
printf 'Recovery smoke test passed in isolated home: %s\n' "$test_home"
