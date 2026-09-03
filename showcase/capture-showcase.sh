#!/usr/bin/env bash
set -euo pipefail

asset_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assets"
runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
history_root="$runtime_root/kona-overview"
history_backup="$runtime_root/kona-overview-pre-showcase-$$"
history_showcase="$runtime_root/kona-overview-showcase-$$"
mkdir -p "$asset_root"

monitors="$(hyprctl monitors -j)"
mapfile -t outputs < <(jq -r 'sort_by(.x)[].name' <<< "$monitors")
mapfile -t original_workspaces < <(jq -r 'sort_by(.x)[].activeWorkspace.id' <<< "$monitors")
original_focus="$(jq -r '.[] | select(.focused == true) | .activeWorkspace.id' <<< "$monitors")"
(( ${#outputs[@]} >= 3 )) || { printf 'Three monitors are required for this showcase capture.\n' >&2; exit 1; }

close_showcase_windows() {
  while read -r address; do
    [[ -n "$address" ]] || continue
    hyprctl dispatch "hl.dsp.window.close({ window = \"address:$address\" })" >/dev/null || true
  done < <(hyprctl clients -j | jq -r '.[] | select(.title | startswith("KONA //")) | .address')
}

restore_desktop() {
  pkill -TERM -x rofi >/dev/null 2>&1 || true
  close_showcase_windows
  for workspace in "${original_workspaces[@]}"; do
    hyprctl dispatch "hl.dsp.focus({ workspace = $workspace })" >/dev/null || true
  done
  hyprctl dispatch "hl.dsp.focus({ workspace = $original_focus })" >/dev/null || true

  if [[ -d "$history_backup" ]]; then
    [[ -d "$history_root" ]] && mv "$history_root" "$history_showcase"
    mv "$history_backup" "$history_root"
  fi
  uwsm app -- "$HOME/.local/bin/kona-workspace-history-daemon" >/tmp/kona-workspace-history.log 2>&1 &
}
trap restore_desktop EXIT INT TERM

while read -r pid; do
  [[ -n "$pid" ]] && kill -TERM "$pid" 2>/dev/null || true
done < <(pgrep -f '^bash .*/kona-workspace-history-daemon$' || true)
sleep 0.2
[[ -d "$history_root" ]] && mv "$history_root" "$history_backup"
mkdir -p "$history_root"

for workspace in 7 8 9; do
  hyprctl dispatch "hl.dsp.focus({ workspace = $workspace })" >/dev/null
done
hyprctl dispatch 'hl.dsp.focus({ workspace = 8 })' >/dev/null
sleep 0.6
grim "$asset_root/desktop-clean.png"

hyprctl dispatch 'hl.dsp.focus({ workspace = 7 })' >/dev/null
uwsm app -- kitty --class kitty --title 'KONA // SYSTEM' bash -lc \
  'fastfetch --structure OS:Kernel:Uptime:Packages:Shell:Display:WM:Theme:Icons:Font:Terminal:TerminalFont:CPU:GPU:Memory:Disk:Locale; printf "\n  command deck ready // konata@arch\n"; exec bash' >/dev/null 2>&1 &
sleep 0.5

hyprctl dispatch 'hl.dsp.focus({ workspace = 8 })' >/dev/null
uwsm app -- kitty --override font_size=9.5 --class kitty --title 'KONA // SIGNAL' \
  cmatrix -b -C blue -u 8 >/dev/null 2>&1 &
sleep 0.5

hyprctl dispatch 'hl.dsp.focus({ workspace = 9 })' >/dev/null
uwsm app -- kitty --override font_size=9.5 --class kitty --title 'KONA // MONITOR' \
  btop >/dev/null 2>&1 &
sleep 3
hyprctl dispatch 'hl.dsp.focus({ workspace = 8 })' >/dev/null
grim "$asset_root/command-center-panorama.png"

capture_menu() {
  local name="$1"
  shift
  "$@" >/tmp/kona-showcase-menu.log 2>&1 &
  menu_pid=$!
  for _ in {1..50}; do
    pgrep -x rofi >/dev/null 2>&1 && break
    sleep 0.1
  done
  sleep 0.7
  grim -o "${outputs[1]}" "$asset_root/$name.png"
  pkill -TERM -x rofi >/dev/null 2>&1 || true
  wait "$menu_pid" 2>/dev/null || true
  sleep 0.3
}

capture_menu quick-settings "$HOME/.local/bin/kona-quick-settings"
capture_menu app-mixer "$HOME/.local/bin/kona-app-mixer"
capture_menu workspace-overview "$HOME/.local/bin/kona-overview"

signal_address="$(hyprctl clients -j | jq -r '.[] | select(.title == "KONA // SIGNAL") | .address' | tail -n1)"
[[ -n "$signal_address" ]] && hyprctl dispatch "hl.dsp.window.close({ window = \"address:$signal_address\" })" >/dev/null || true
hyprctl dispatch 'hl.dsp.focus({ workspace = 8 })' >/dev/null
uwsm app -- kitty --class kitty --title 'KONA // MEDIA' "$HOME/.local/bin/kona-clock" >/dev/null 2>&1 &
for _ in {1..50}; do
  media_address="$(hyprctl clients -j | jq -r '.[] | select(.title == "KONA // MEDIA") | .address' | tail -n1)"
  [[ -n "$media_address" ]] && break
  sleep 0.1
done
center_x="$(jq -r 'sort_by(.x)[1].x' <<< "$monitors")"
center_y="$(jq -r 'sort_by(.x)[1].y' <<< "$monitors")"
center_width="$(jq -r 'sort_by(.x)[1].width' <<< "$monitors")"
center_height="$(jq -r 'sort_by(.x)[1].height' <<< "$monitors")"
media_x=$((center_x + (center_width - 960) / 2))
media_y=$((center_y + (center_height - 560) / 2))
hyprctl dispatch "hl.dsp.window.float({ action = \"enable\", window = \"address:$media_address\" })" >/dev/null
hyprctl dispatch "hl.dsp.window.resize({ x = 960, y = 560, relative = false, window = \"address:$media_address\" })" >/dev/null
hyprctl dispatch "hl.dsp.window.move({ x = $media_x, y = $media_y, relative = false, window = \"address:$media_address\" })" >/dev/null
sleep 2
grim -o "${outputs[1]}" "$asset_root/media-deck.png"

grim -o "${outputs[0]}" "$asset_root/system-monitor.png"
grim -o "${outputs[1]}" "$asset_root/signal-monitor.png"
grim -o "${outputs[2]}" "$asset_root/performance-monitor.png"

printf 'Captured showcase assets in %s\n' "$asset_root"
