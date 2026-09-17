# Rofi surfaces

Task05 reuses native Rofi 2.0, the Task02 semantic palette, and the existing action
owners. No new service, timer, polling loop or persistent selector is installed.
Task01–Task04 remain accepted; the current Control Center is Mani-approved.

| Surface | Entry point | Purpose |
|---|---|---|
| Apps | Super+Space; Waybar KONA | Two-column icon grid, app name and available generic description |
| Windows | Alt+Tab; Alt+Shift+Tab; Super+Tab | One-column app/title recognition and native focus |
| Commands | Super+R | Compact command entry |
| Clipboard | Super+V | Wide literal text previews; IDs hidden visually; original entry decoded |
| Audio | Super+Shift+A | Filter output/input devices and existing audio actions |
| App mixer | Super+Ctrl+A | Filter streams; operate on the selected stream identity |
| Wallpapers | Super+Shift+W; Desktop → Wallpapers | Three thumbnail cards for installed simple/static/animated sets |
| Session | Super+Escape; Ctrl+Alt+Delete | Lock plus explicitly labelled destructive actions and cancellation-first confirmation |
| Searchable actions | Super+C; desktop menu; updates | Keyboard-filterable fallback using existing action owners |
| Overview | Super+W | Existing ten-card thumbnail UX, frozen theme and capture behavior |

`shared.rasi` owns common geometry and reads `kona/theme/current/rofi.rasi`.
Purpose-specific themes set only their layout, prompts and footers. `konata.rasi`
remains the launcher/generic compatibility path, preserving Waybar's accepted
entrypoint. Native mode cycling remains available. `overview.rasi` is the exact
pre-Task05 shared theme; its helper changes only the theme path. This deliberately
preserves the accepted overview, including its existing tall layout on 1080p.

The wallpaper selector lists only complete installed sets and delegates to
`kona-wallpaper`; it does not own wallpaper state or implement arbitrary-image
profiles. It reuses Rofi's installed glycin thumbnailer/cache with a direct-image
fallback. At this Task05 checkpoint, category navigation in `nwg-drawer` was still a
unique dock workflow, so both were retained. The later sidebar-navigation pass and
2026-09-16 release superseded that decision: the sidebar/Rofi now provide the behavior,
and the dock/drawer product paths are retired.

Audio selectors use Rofi's original row index, avoiding ambiguity between repeated
device descriptions or app names. Clipboard selection uses a private temporary
directory and completes decoding before replacing clipboard contents; cancellation
or decode failure preserves the clipboard. Session confirmation defaults to CANCEL;
only exact matching destructive labels reach the existing power commands.

Task02 exports one additional existing semantic token (`danger`) to Rofi. The
palette schema and other consumer fragments are unchanged. Generation remains
transient, atomic and owned by `kona-theme`.

Validation: `python3 tests/rofi-surfaces.py`, existing event/state/theme/wallpaper/
Waybar/Control Center tests, and `bash tests/recovery-smoke.sh`. Use installed
`rofi -no-config -theme FILE -dump-theme` plus actual rendered interaction checks:
this machine's `-rasi-validate` crashes even on the unchanged reference. The host
also lacks a font covering the tested CJK glyph U+96EA; byte preservation is tested,
but complete CJK glyph rendering is not claimed.

Evidence and rollback copies: `~/.local/state/kona/task05-20260913-183043/`.
See its report and performance plan for raw before/after observations, unchanged
absolute core/dock alarms, adverse runs, restore checks and review status.
