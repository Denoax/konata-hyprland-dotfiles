#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d -t kona-recovery-XXXXXX)"
trap 'gio trash "$sandbox" >/dev/null 2>&1 || true' EXIT
test_home="$sandbox/home"
mkdir -p "$test_home"

HOME="$test_home" \
XDG_CONFIG_HOME="$test_home/.config" \
XDG_STATE_HOME="$test_home/.local/state" \
  "$repo_root/install.sh" --config-only >/dev/null

required=(
  '.config/hypr/hyprland.lua'
  '.config/waybar/config.jsonc'
  '.local/bin/kona-backup'
  '.local/bin/nwg-dock-hyprland-kona'
  '.local/share/wallpapers/konata-command-center/v2/selected.png'
)

for relative in "${required[@]}"; do
  [[ -s "$test_home/$relative" ]] || { printf 'missing restored file: %s\n' "$relative" >&2; exit 1; }
done
[[ -x "$test_home/.local/bin/kona-backup" ]]
cmp -s "$repo_root/.config/hypr/hyprland.lua" "$test_home/.config/hypr/hyprland.lua"
cmp -s "$repo_root/.local/bin/nwg-dock-hyprland-kona" "$test_home/.local/bin/nwg-dock-hyprland-kona"
[[ "$(cat "$test_home/.config/kona/backup-repo")" == "$repo_root" ]]

Hyprland --verify-config --config "$test_home/.config/hypr/hyprland.lua" >/dev/null
printf 'Recovery smoke test passed in isolated home: %s\n' "$test_home"

