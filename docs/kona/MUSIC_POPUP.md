# Kona music popup — accepted implementation history

Technical validation and the installed visual checkpoint are accepted in the 2026-09-16 release.
The branch/SHA details below describe the historical implementation checkpoint.

Run `kona-music-popup`, or select **Kona Music** in the application launcher. Running it
again toggles it; `kona-music-popup close` closes it. No bar, shortcut, Studio, profile,
wallpaper, notification, dock or session configuration was changed to expose this entry.

## Final polish — 2026-09-14

Applied the final fix pack in place. Spotify now uses the installed Nerd Font Spotify
glyph in Kona blue; the source row is informational and the old status badge is gone.
The output-device control draws a monitor and foreground speaker, uses slate at rest
and blue on hover/focus, and still opens the existing audio menu. The primary control
has a faint halo and a two-pixel partial ring, rotating linearly once per eight seconds
only during playback. Pause hides the decoration and stops rotation; Reduced/Off
preferences allow the static playing decoration without rotation. No glyph rotation.
The pale surface, border, original drop shadow, layout, art and media owners are retained.

The added halo and perimeter glow use the installed Qt 6.11.2
[RectangularShadow](https://doc.qt.io/qt-6/qml-qtquick-effects-rectangularshadow.html)
(available since Qt 6.9), with static geometry and no extra helper. The perimeter uses
36px blur, 4px spread and 0.20 color alpha; the hero halo uses 0.16 alpha. Reference
artwork was not installed. No packages, launcher, other UI, session or Git history changes.

Final evidence: `~/.local/state/kona/music-polish-20260914-171204/`.

- `live-final/playing.png`, `live-final/paused.png`: real installed Spotify captures.
- `live-final/playing-pause-close.mp4`: 6.283s native recording; temporal frames and
  IPC samples verify arc rotation, paused stop and close. Use PNGs for color assessment;
  the recorder's video conversion differs from the lossless screenshots. Subjective
  normal-speed motion approval belongs to Mani.
- `reduced-motion.json`, `reduced-motion.png`: native playing state with isolated
  Reduced preference input; the global preferences file was not changed.
- `device-hover.png`, `audio-device-menu.png`, `device-check.json`: new icon hover,
  existing menu action and cancellation, output unchanged.
- `launcher-tests.txt`: all three existing launcher tests pass. `art-tests.txt`: the
  existing artwork binding/recovery test passes (expected missing-art warning retained).
  `polish-final-tests.txt`: two focused tests pass for ring state/motion and keyboard
  output-device behavior. Existing tests are unchanged.
- `restoration.json`: same track, playback state, volume, active window, cursor,
  client geometry and workspaces after final QA. `resident-check.json`: empty.
- `ADVERSE.md` preserves the initial test-isolation failure, insufficient first glow
  and interrupted recording. Earlier music/V4 evidence remains intact. No long benchmark.

Changed product files: `MusicPopupView.qml`, `KonaIconButton.qml`, `shell.qml` in
`.config/quickshell/kona/music/`. Added `tests/tst_music_polish.qml`; updated this report
and `PROJECT_HANDOFF.md`. Source/live hashes and the scoped patch are in the evidence.
Pre-polish files are in `backup/`; `rollback.py` previews restoration of only these
three live files, with `--apply` and current-hash guards. Close the popup before rollback.

Technical checks complete; the installed result is accepted in the 2026-09-16 release. The pre-existing Qt AT-SPI
child-tree limitation below remains, without a new screen-reader claim. No next surface.

## Implementation

The four supplied QML files are the implementation base, in
`.config/quickshell/kona/music/`. The thin `shell.qml` host places their1180×420 light
composition at top-center on DP-4,74px below the output edge; it proportionally scales
for smaller outputs. The supplied palette, typography hierarchy,360px art and controls
are retained. Open220ms / close150ms fade-scale motion honors existing Reduced/Off
preferences. No application or wallpaper changes are used to stage this popup.

Native Quickshell MPRIS uses the existing Deck selection policy: playing player first,
then one with track metadata. Optional `KONA_MUSIC_PLAYER` selects an exact MPRIS bus
name. Real art wins; missing/broken art reuses the approved existing Konata image, cropped
to the art tile. If unavailable, the supplied quiet KONA tile remains. No concept PNG
is used as production artwork or permanent song data.

MPRIS capability flags gate previous/play/next, seek, shuffle and playlist-repeat.
Position reads native interpolation once per second only while open and playing;
this is the [documented Quickshell position interface](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Mpris/MprisPlayer/), not periodic metadata polling.
Output volume binds to the existing default PipeWire sink through PwObjectTracker;
it changes system output volume, not a private duplicate volume state. The device
button closes the popup and invokes the unchanged `kona-audio-menu` routing owner.

The existing CAVA binary uses a popup-specific24fps/21-bar raw configuration with the
same PipeWire input as Kona's current CAVA configuration. It starts only while open and
playing and exits on pause/close. Values are real audio samples, not fabricated motion.
It visualizes the default output mix; concurrent applications can contribute audio.
The launcher owns the UI process group and cleans up CAVA after normal close, launcher
termination or UI failure. No boot dependency, permanent player daemon or idle poller.

Supplied-view adaptations: fixed `font.letterSpacing`, removed inherited `enabled`
redeclarations, added keyboard/focus/accessibility labels, preserved slider bindings
while dragging, handled failed/empty Qt art URLs without breaking source bindings and rounded clipping, and replaced the colored
speaker emoji with the existing monochrome icon font. Primary keyboard focus now has
a visible dark outline. These are compatibility/accessibility/integration fixes, not a
replacement composition. Noto Sans is used because Inter is not installed.

Actual Spotify Chinese metadata exposed missing CJK fonts. One upstream Noto Sans CJK SC
Regular font plus its [OFL license](https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE)
was installed locally under `~/.local/share/fonts/kona-music/`; no font binaries are in
the repository. `packages/pacman.txt` records `noto-fonts-cjk` for reproducible installs.
Checksums and provenance are in the evidence manifest. No donor installer was run.

## Validation and evidence

Evidence root:
`~/.local/state/kona/music-popup-20260914-162244`.
Pack extracted separately under `pack/`; all15 supplied manifest hashes pass.

- Real Spotify: metadata/art/spectrum, advancing position, pointer Pause, focused Space
  Play, Next/Previous returning the original track, seek, volume and keyboard volume
  adjustment. `real-qa-brief.log`, `real-brief/real-actions.json`.
- Original track, playback state, output channel volumes, workspace/client geometry,
  focus and cursor restored; playback position within0.006s. Notification count0→0.
  `RESTORATION.json`, `real-brief/real-before.json`, `real-after.json`.
- Bounded native MPRIS fixture: supported shuffle/repeat writes; external seek after
  pointer use followed by keyboard seek from the updated value (binding regression);
  long title/artist elision; broken-art fallback; unsupported controls disabled.
  `fixture-methods.jsonl`, `external-seek-followed.png`, `long-title-missing-art.png`,
  `unsupported-controls.png`. The fixture quit command initially used an unsupported
  playerctl command; completed state cases remain evidenced, and the remaining cases
  passed separately via native DBus Quit (`disappear-qa.log`).
- Player disappearance→honest no-media, outside dismissal, Escape, and repeated open/close.
  Eight focus stops verified in `tab-focus.json`; primary focus screenshot retained.
- Existing device menu opens and cancels without output change (`device-qa.log`).
- Graceful close, wrapper TERM and UI SIGKILL leave no observed descendants
  (`lifecycle-checks.json`). Three isolated launcher tests pass (`launcher-tests.txt`). A native Qt component
  regression also verifies late fallback inputs, failed-art fallback and recovery to real
  art without losing bindings (`art-contract-corrected.txt`).
- Native QML load and final Python/desktop-entry/diff checks pass. Final source/live hash
  match and protected pre-existing product hashes: `final-manifest.json`.

Screenshots: `playing.png` (real Spotify, Chinese glyphs fixed), `real-brief/paused.png`,
`no-media.png`, `keyboard-primary-focus.png`; final fallback crop in
`fallback-verified-live.png`. Actual open→interact→close video:
`real-brief/music-open-interact-close.mp4`. Comparison target remains the approved PNG
inside the extracted pack. Real track artwork and the supplied Unicode controls differ
from the concept's drawn artwork/icons; no extra surfaces were redesigned.

All adverse logs are preserved, including initial QML adaptation errors, an obsolete QA
cursor command, outside-click interruption during normal desktop use, and the unsupported
fixture quit command. A later art capture was invalidated because outside dismissal
left only the desktop in the image; `art-qa.log` is not accepted visual evidence. The
corrected capture waits for decoded artwork and verifies the live process. Offscreen
Qt is used only for the source-binding contract, not as native visual proof. They are not product PASS evidence; corrected results are separate.

No idle-ready or long benchmark loops. Existing core/dock alarms and performance policy
are unchanged. No claim of new aggregate performance gains. Native keyboard and pointer
behavior are proven; the previously documented Qt AT-SPI control-tree limitation is not
claimed resolved. Recorded60fps/temporal samples do not prove240Hz pacing or human motion
approval. Mani should judge final spacing, artwork treatment and motion in the live popup.

## Rollback

Close only this popup with `kona-music-popup close`. The unchanged Deck and audio/Rofi
surfaces remain available. To remove the installed candidate, run:

```sh
python3 ~/.local/state/kona/music-popup-20260914-162244/rollback-music-popup.py --apply
```

The rollback checks final hashes before removing the eight new installed popup files;
it does not overwrite accepted work or reset Git. The optional local font is retained
unless `--include-font` is also passed. Pre-step handoff/package files are saved under
`repository-backup/` for a separate reviewed source rollback; the exact new source list
and diff are in the evidence directory. No rollback was executed during this pass.
