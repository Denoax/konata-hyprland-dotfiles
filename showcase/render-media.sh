#!/usr/bin/env bash
set -euo pipefail

asset_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assets"
font_regular='/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf'
font_bold='/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf'
work_root="$(mktemp -d -t kona-media-XXXXXX)"
trap 'gio trash "$work_root" >/dev/null 2>&1 || true' EXIT

for required in hero-konata-source.png quick-settings.png app-mixer.png workspace-overview.png system-monitor.png signal-monitor.png performance-monitor.png; do
  [[ -s "$asset_root/$required" ]] || { printf 'Missing capture: %s\n' "$required" >&2; exit 1; }
done

ffmpeg -hide_banner -loglevel error -y \
  -i "$asset_root/hero-konata-source.png" \
  -vf "crop=1672:752:0:72,scale=1600:720:flags=lanczos,
       drawbox=x=0:y=0:w=900:h=720:color=black@0.24:t=fill,
       drawbox=x=70:y=84:w=2:h=505:color=0x00c8ff@0.85:t=fill,
       drawtext=fontfile=${font_regular}:text='KONA // 01':fontcolor=0x00c8ff:fontsize=18:x=94:y=90,
       drawtext=fontfile=${font_bold}:text='KONATA':fontcolor=0xf2f7ff:fontsize=72:x=94:y=145,
       drawtext=fontfile=${font_regular}:text='COMMAND CENTER':fontcolor=0xaec6d9:fontsize=38:x=98:y=231,
       drawbox=x=96:y=304:w=500:h=1:color=0x00c8ff@0.55:t=fill,
       drawtext=fontfile=${font_regular}:text='ARCH LINUX  x  HYPRLAND':fontcolor=0xd9f7ff:fontsize=20:x=98:y=330,
       drawtext=fontfile=${font_regular}:text='THREE DISPLAYS / ONE SYSTEM / ZERO CLUTTER':fontcolor=0x6f93ab:fontsize=15:x=98:y=370,
       drawtext=fontfile=${font_regular}:text='WAYLAND':fontcolor=0x65dcff:fontsize=14:x=98:y=620,
       drawtext=fontfile=${font_regular}:text='LUA CONFIG':fontcolor=0x65dcff:fontsize=14:x=240:y=620,
       drawtext=fontfile=${font_regular}:text='240 HZ':fontcolor=0x65dcff:fontsize=14:x=416:y=620,
       drawbox=x=98:y=654:w=500:h=1:color=0x16486d@0.9:t=fill" \
  -frames:v 1 "$asset_root/hero.png"

ffmpeg -hide_banner -loglevel error -y -loop 1 -i "$asset_root/hero.png" \
  -vf "zoompan=z='min(zoom+0.00022,1.008)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1200x540:fps=8,format=yuv420p" \
  -t 3.6 -c:v libx264 -preset slow -crf 19 -movflags +faststart "$asset_root/hero-motion.mp4"

make_gif() {
  local source="$1"
  local target="$2"
  ffmpeg -hide_banner -loglevel error -y -i "$source" \
    -vf "fps=8,scale=960:-1:flags=lanczos,palettegen=max_colors=128:stats_mode=diff" \
    "$work_root/palette.png"
  ffmpeg -hide_banner -loglevel error -y -i "$source" -i "$work_root/palette.png" \
    -lavfi "fps=8,scale=960:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
    -loop 0 "$target"
}

make_gif "$asset_root/hero-motion.mp4" "$asset_root/hero-motion.gif"

ffmpeg -hide_banner -loglevel error -y \
  -loop 1 -t 1.5 -i "$asset_root/quick-settings.png" \
  -loop 1 -t 1.5 -i "$asset_root/app-mixer.png" \
  -loop 1 -t 1.5 -i "$asset_root/workspace-overview.png" \
  -loop 1 -t 1.5 -i "$asset_root/media-deck.png" \
  -filter_complex "
    [0:v]scale=960:540:flags=lanczos,setsar=1[v0];
    [1:v]scale=960:540:flags=lanczos,setsar=1[v1];
    [2:v]scale=960:540:flags=lanczos,setsar=1[v2];
    [3:v]scale=960:540:flags=lanczos,setsar=1[v3];
    [v0][v1]xfade=transition=fade:duration=0.35:offset=1.15[x1];
    [x1][v2]xfade=transition=fade:duration=0.35:offset=2.30[x2];
    [x2][v3]xfade=transition=fade:duration=0.35:offset=3.45,format=yuv420p[out]
  " -map '[out]' -t 4.95 -r 12 -c:v libx264 -preset slow -crf 20 -movflags +faststart \
  "$asset_root/interface-tour.mp4"
make_gif "$asset_root/interface-tour.mp4" "$asset_root/interface-tour.gif"

ffmpeg -hide_banner -loglevel error -y \
  -loop 1 -t 1.6 -i "$asset_root/system-monitor.png" \
  -loop 1 -t 1.6 -i "$asset_root/signal-monitor.png" \
  -loop 1 -t 1.6 -i "$asset_root/performance-monitor.png" \
  -filter_complex "
    [0:v]scale=960:540:flags=lanczos,setsar=1[v0];
    [1:v]scale=960:540:flags=lanczos,setsar=1[v1];
    [2:v]scale=960:540:flags=lanczos,setsar=1[v2];
    [v0][v1]xfade=transition=fade:duration=0.35:offset=1.25[x1];
    [x1][v2]xfade=transition=fade:duration=0.35:offset=2.50,format=yuv420p[out]
  " -map '[out]' -t 4.1 -r 12 -c:v libx264 -preset slow -crf 20 -movflags +faststart \
  "$asset_root/terminal-tour.mp4"
make_gif "$asset_root/terminal-tour.mp4" "$asset_root/terminal-tour.gif"

printf 'Rendered hero and motion assets in %s\n' "$asset_root"

