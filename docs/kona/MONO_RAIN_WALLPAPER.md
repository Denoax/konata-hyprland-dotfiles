# Konata Mono Rain live wallpaper

## Status

**READY FOR MANI — KONATA MONO RAIN LIVE WALLPAPER REVIEW**

This scoped pass implements only the supplied Konata Mono Rain wallpaper. The approved
reference remains the static authority; procedural motion is confined to the left rain
field. The character and flowers are unchanged by every generated frame.

## Production asset and ownership

- Source: `.config/kona/wallpapers/konata-mono-rain/source/KONATA_MONO_RAIN_REFERENCE.png`
- Source SHA-256: `aab2a5e05dfb89163beed608b46052b219dfe14a638a94edf89d77d1dd4fa73c`
- Definition: 1920x1080, 10-second deterministic cycle, 10 fps, 100 frames, 15 independently phased downward columns.
- Protected region: every pre-encode pixel at `x >= 700` has the same SHA-256 at frame 0, midpoint and the synthetic seam endpoint: `44ccb9bbe1a652fa38e58def614876bb2c121dd0f9c15c0e0a5f07330e4d8d00`. Decoded GIF frames 0, 50 and 99 also share the same RGB SHA-256: `0544ede31e2434823498872b8ecd8054e0bc476b24b1e6be42131e57c5c99f14`.
- Runtime: the existing single Awww owner displays `konata-mono-rain.gif` on all three outputs.
- Deliverables: GIF runtime asset, animated WebP, MP4, and a composition-matched PNG still. The renderer regenerates all four and records hashes in `render/validation.json`.
- Focus and Gaming derive `konata-mono-rain-static.png` from the custom animated path. They run one Hyprpaper owner and release Awww completely.
- Daily and Showcase run the animated asset through Awww. Returning from Focus/Gaming restores it.
- The `.preserve-theme` sidecar keeps the accepted Kona theme unchanged when this supplied wallpaper is selected.

Awww's animated-WebP path breached the unchanged CPU alarm even after cadence reduction.
The preserved trials measured 14.798% at 30 fps, 16.399% at 20 fps, 11.199% in the
12 fps short window, and 15.132% over 15 seconds at 10 fps. Encoding the same 10 fps
frames as Awww's native animated GIF path reduced the final warm 15-second mean to
7.865% (median 7.998%, range 6.998–8.998%). The higher-cost trials remain under the
evidence root and were not hidden or used as the candidate.

## Resource result

The accepted pre-change static Awww baseline was 501 KiB PSS / 428 KiB private memory.
The final GIF candidate is 37,677 KiB PSS with 12,916 KiB private clean+dirty and no swap:
+37,176 KiB / +36.305 MiB PSS. CPU is +7.865 percentage points by the component-local
15-second trace. Both remain below the unchanged +64 MiB and +10-point incremental
alarms. There is one Awww process in Daily and zero Hyprpaper processes. No renderer,
recorder, helper, second wallpaper daemon, or resident poller remains. Aggregate
matched-idle measurement deferred.

Focus's composition-matched static state measured 69,911 KiB Hyprpaper PSS during the
transition evidence. That is the already-documented static Hyprpaper architecture cost;
the live animation process was absent in that state.

## Validation

- Exact source checksum, deterministic downward-only left-field definition and provenance checks pass.
- Synthetic frame 100 equals frame 0 byte-for-byte; frame 99 is the terminal encoded frame, so the endpoint is not duplicated.
- GIF: 100 frames, 10 fps, 10 seconds, infinite loop. WebP: 100 frames, 10 fps, infinite loop. MP4: 100 frames, 10 seconds.
- The protected character/flower crop is identical before encoding and in decoded runtime GIF frames; an earlier GIF derived from the lossy MP4 failed this gate and is preserved as adverse evidence.
- The final runtime played more than three consecutive loops. A clean 16-second decode of the exact installed GIF crosses a loop boundary without a visible jump; native compositor stills separately prove live integration.
- Native expanded, collapsed and unobscured captures show the subject and flowers remain visible and the left composition remains intentional under the sidebar.
- Daily -> Focus -> Daily recording proves animated GIF -> exact static sibling -> animated GIF, with one owner at each stage.
- Gaming proves static sibling plus zero Awww owners; Showcase proves the animated GIF; final state is Daily.
- Waybar, SwayNC, sidebar and music-host identities remained stable during the profile transition.
- Theme hashes and protected sidebar/music/Waybar/SwayNC source hashes match the pre-change baseline.
- `tests/mono-rain.py`: 3 pass.
- `tests/wallpaper-theme.py`: 4 pass.
- `tests/theme.py`: 10 pass, 1 skipped.
- `tests/sidebar-navigation.py`: 4 pass.
- `tests/music-popup.py`: 3 pass.
- `tests/runtime.py`: 6 pass.
- Renderer `--check`, Python compilation, Bash syntax and `git diff --check` pass.
- `tests/profiles.py`: 17 pass, 1 pre-existing stale assertion fails because it omits the accepted `return_to` status field. This task did not change the status schema.

## Evidence and recovery

Evidence and backups: `/home/mani/.local/state/kona/mono-rain-20260915/`.

Review artifacts:

- `evidence/live/sidebar-expanded.png`
- `evidence/live/sidebar-collapsed.png`
- `evidence/live/wallpaper-unobscured.png`
- `evidence/live/mono-rain-loop-16s.mp4`
- `evidence/live/loop-contact-sheet.png`
- `evidence/live/daily-focus-daily.mp4`
- `evidence/live/profile-transition.txt`
- `evidence/live/gaming-showcase.txt`
- `evidence/live/final-owner-metrics.txt`

The `backup/` directory contains the pre-change scripts/configuration and `baseline/`
contains owner identity, memory, runtime state and protected hashes. The rejected
30/20/12 fps WebP trials and the rejected lossy-source GIF are retained under
`evidence/adverse-*`.

Branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`; accepted dirty work preserved. No Git
history/remote operation, compositor restart, UWSM change, notification clear, idle request,
application freeze, or long benchmark occurred. Visual approval remains Mani's decision.
