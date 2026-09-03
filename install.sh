#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/kona/pre-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_root/config" "$backup_root/bin" "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"

configs=(cava hypr kitty nwg-dock-hyprland nwg-drawer rofi swaync swayosd uwsm waybar xdg-desktop-portal)
for config in "${configs[@]}"; do
  if [[ -d "$HOME/.config/$config" ]]; then
    cp -a "$HOME/.config/$config" "$backup_root/config/"
  fi
done

if [[ -d "$repo_root/.local/bin" ]]; then
  rsync -a "$repo_root/.local/bin/" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/"*
fi
rsync -a "$repo_root/.config/" "$HOME/.config/"
if [[ -d "$repo_root/.local/share" ]]; then
  rsync -a "$repo_root/.local/share/" "$HOME/.local/share/"
fi

"$HOME/.local/bin/kona-install-deps"

if command -v flatpak >/dev/null 2>&1 && [[ -s "$repo_root/packages/flatpak.txt" ]]; then
  while read -r app; do
    flatpak info "$app" >/dev/null 2>&1 || flatpak install -y flathub "$app"
  done < "$repo_root/packages/flatpak.txt"
fi

printf '\nConfiguration restored. Previous files are backed up in:\n  %s\n' "$backup_root"
printf 'Log out and select Hyprland (uwsm-managed) to finish the restore.\n'
printf 'Optional system packages are listed in %s/packages/pacman.txt.\n' "$repo_root"
