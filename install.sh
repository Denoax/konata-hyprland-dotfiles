#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_deps=true
restore_flatpaks=false
dry_run=false

usage() {
  cat <<USAGE
usage: $0 [--config-only] [--skip-deps] [--with-flatpaks] [--dry-run]

Restores Kona-owned configuration into the current user's home directory.
Existing targets are copied to \$XDG_STATE_HOME/kona before replacement.

  --config-only    copy configuration without dependencies or Flatpaks
  --skip-deps      do not install Kona's user-local helper packages
  --with-flatpaks  restore the optional application list
  --dry-run        print the exact scope without writing anything
USAGE
}

for option in "$@"; do
  case "$option" in
    --config-only) install_deps=false; restore_flatpaks=false ;;
    --skip-deps) install_deps=false ;;
    --with-flatpaks) restore_flatpaks=true ;;
    --skip-flatpaks) restore_flatpaks=false ;; # Compatibility with the old CLI.
    --dry-run) dry_run=true ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$option" >&2; usage >&2; exit 2 ;;
  esac
done

required_commands=(cp date find mkdir rsync)
for command in "${required_commands[@]}"; do
  command -v "$command" >/dev/null 2>&1 || {
    printf 'Required command is missing: %s\n' "$command" >&2
    exit 1
  }
done

config_roots=(hypr kitty kona quickshell rofi swaync swayosd systemd waybar xdg-desktop-portal)

print_plan() {
  cat <<PLAN
Kona restore plan
  source: $repo_root
  configuration: ${config_roots[*]}
  executables: .local/bin/kona-*
  shared data: Kona desktop entries and wallpaper assets
  dependencies: $install_deps
  optional Flatpaks: $restore_flatpaks
  session: PlasmaLogin -> Hyprland (plain /usr/bin/start-hyprland)

This profile assumes three 1920x1080 displays. Review docs/HARDWARE_PROFILE.md
and edit .config/hypr/hyprland.lua before logging into it on other hardware.
PLAN
}

print_plan
if [[ "$dry_run" == true ]]; then
  exit 0
fi

backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/kona/pre-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_root" "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"

backup_target() {
  local relative="$1" source="$HOME/$1" destination="$backup_root/$1"
  [[ -e "$source" || -L "$source" ]] || return 0
  mkdir -p "$(dirname "$destination")"
  cp -a -- "$source" "$destination"
}

for config in "${config_roots[@]}"; do
  [[ -d "$repo_root/.config/$config" ]] || continue
  backup_target ".config/$config"
done

while IFS= read -r -d '' source; do
  relative="${source#"$repo_root/"}"
  backup_target "$relative"
done < <(find "$repo_root/.local/bin" "$repo_root/.local/share" -type f -print0)

for config in "${config_roots[@]}"; do
  [[ -d "$repo_root/.config/$config" ]] || continue
  mkdir -p "$HOME/.config/$config"
  rsync -a "$repo_root/.config/$config/" "$HOME/.config/$config/"
done

rsync -a "$repo_root/.local/bin/" "$HOME/.local/bin/"
while IFS= read -r -d '' source; do
  relative="${source#"$repo_root/.local/bin/"}"
  [[ -f "$HOME/.local/bin/$relative" ]] && chmod +x "$HOME/.local/bin/$relative"
done < <(find "$repo_root/.local/bin" -maxdepth 1 -type f -print0)

if [[ -d "$repo_root/.local/share" ]]; then
  rsync -a "$repo_root/.local/share/" "$HOME/.local/share/"
fi

mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/kona"
printf '%s\n' "$repo_root" > "${XDG_CONFIG_HOME:-$HOME/.config}/kona/backup-repo"

if [[ "$install_deps" == true ]]; then
  "$HOME/.local/bin/kona-install-deps"
fi

if [[ "$restore_flatpaks" == true ]]; then
  command -v flatpak >/dev/null 2>&1 || {
    printf 'Flatpak restore requested, but flatpak is not installed.\n' >&2
    exit 1
  }
  while IFS= read -r app; do
    [[ -n "$app" && "$app" != \#* ]] || continue
    flatpak info "$app" >/dev/null 2>&1 || flatpak install -y flathub "$app"
  done < "$repo_root/packages/optional-flatpaks.txt"
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload
fi

printf '\nConfiguration restored. Previous targets are backed up in:\n  %s\n' "$backup_root"
printf 'Log out normally and select Hyprland, not Hyprland (uwsm-managed).\n'
printf 'Review %s/docs/INSTALL.md before the first login.\n' "$repo_root"
