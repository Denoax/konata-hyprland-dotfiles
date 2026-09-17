# Kona V4 reference-supremacy pass

Candidate implemented and ready for Mani's visual review, 2026-09-14. Visual approval
is **not** claimed. Native Qt screen-reader exposure remains a capability limitation.
No commit/push or other remote Git operation was performed.

Authority: actual dirty branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`, accepted Tasks01–06 plus deployed
Task07. Historical HEAD alone does not reproduce this desktop. Task07 remains
**PARTIAL — managed startup/logout validation deferred**. Plain Hyprland continues;
old Task08–10 are suspended, not started by this pass.

Evidence root (abbreviated `E` below):
`/home/mani/.local/state/kona/v4-20260914-111330`.
The ZIP was extracted separately under `E/pack/`. Original dirty-tree/live backups,
Task07 handoff, adverse results and previous task evidence remain preserved.

## Reference decisions and internal phases

| Phase / reference observation | Kona implementation and reason | Deliberately omitted |
| --- | --- | --- |
| A: actual product exceeds the historical SHA | Reused theme, profile, event-state, wallpaper, capture, notification and recovery owners; inspected native versions before wiring | Rebuilding accepted foundations or waiting for UWSM |
| B: Haku directional workspaces; Caelestia composed entry/exit | Shared motion intent, native spring workspace movement, one progress driving Deck/Studio opacity and position, reversible exit, Full/Reduced/Off | Perpetual border animation, cursor spectacle, arbitrary independent entrance effects |
| C: Caelestia dashboard hierarchy and contextual media | On-demand Kona Deck: clock/context, real profile/scene, conditional MPRIS hero, three resource gauges, notification count and useful entrypoints | Empty media panel, fake telemetry, duplicate notification history |
| D: Haku live wallpaper browsing; Caelestia integrated settings | Searchable nine-page Studio, transactional wallpaper/finish preview, favorites, preset import/export, generated shortcut help | Copying their palette/layout or exposing unsupported display/dock writes |
| E: Haku live workspace overview | Evaluated installed compositor/plugin compatibility; retained the working ten-card Rofi overview and Super+W | No compatible hyprexpo in the pinned official plugin manifest; no experimental plugin loaded |
| F: Haku composed showcase and negative space | Explicit Super+Ctrl+M three-monitor Mosaic: Chronicle / Deck / Constellation, one clock and restrained orbital motif; prior policy/scene/palette restored on exit | Starting terminal/CAVA/lavat demos or moving/hiding user applications to stage screenshots |
| G: Caelestia consistent surface grammar | Shared Kona midnight/ice/accent palette, focus/hover/pressed states, compact corner geometry; existing bars, Control Center, Rofi and canonical dock checked in rendered use | No unnecessary Task03–05 stylesheet changes; no copied shell replacement |
| H: comparable dashboard, settings, wallpaper and showcase states | Real screenshots on all three outputs and a recorded enter/exit/reversal sequence; references inspected as frames and temporal samples | No claim of human approval, superiority as a measured fact, or GPU/frame-pacing proof |

All 24 curated reference frames and all six supplied motion clips were inspected via
contact sheets/temporal samples, including both 11-second clip tails. This environment
does not provide normal-speed video viewing. The retained recordings are for Mani's
playback review. The pack's content hashes pass; its SHA256SUMS self-entry fails, a
self-hash defect rather than a reason to overwrite repository contents.

## Using the candidate

| Shortcut | Surface |
| --- | --- |
| Super+Ctrl+Space | Kona Deck |
| Super+Ctrl+I | Kona Studio |
| Super+F1 | Searchable shortcut help |
| Super+Ctrl+M | Enter/exit Showcase Mosaic |

Escape or the outside backdrop closes the surface after its exit transition. Existing
launcher, ten-card overview, audio, capture, wallpaper picker, dashboard and notification
shortcuts remain. The desktop menu and three application entries expose the new surfaces.

Studio has Appearance, Motion, Profiles, Wallpaper Studio, Bars & Dock, Displays,
Shortcuts, System & Recovery and About. Displays is read-only. Wallpaper selection
alone changes nothing; Preview changes the live image/palette temporarily, Apply commits
the current scene's image, Revert/close restores it. Finish changes have the same explicit
preview/apply/revert boundary. Profiles show Gaming's actual saved return target.
Imported presets are validated and staged before Apply; favorites remain local.
Backup copies a clearly labeled command; Studio does not run the existing commit/push
backup helper. Update entrypoints preserve the existing confirmation workflow.

Motion intent lives in `.config/kona/motion.json`: 70/140/200/280 ms effect tiers,
260/380/520 ms spatial tiers, critically damped native spring, 22% workspace travel.
Reduced uses 3% native workspace travel and shortened surface travel; Off disables
motion. Focus/Gaming retain their restricted policy. Studio's pace is bounded 0.75–1.25.
Showcase animation exists only during explicit opt-in; it is not a DAILY-mode saving.

## Ownership, dependencies and recovery

QML presents state and sends bounded actions. `kona-profile` still owns profile/scene,
wallpaper preview and Mosaic return transactions. `kona-theme` owns validated fragment
activation. `kona-preferences` is the atomic, locked preference storage boundary;
`kona-appearance` journals temporary native finish. `kona-motion` translates intent.
`kona-state` remains read-only (additive `return_to` field); `kona-surface-data` adapts
these owners. No second profile/theme authority was added.

`kona-shell` owns one locked, optional Quickshell process group. It retains the UI through
exit, releases all subscriptions, and reverts outstanding preview/Mosaic transactions.
Discrete state uses inotify, SwayNC and NetworkManager streams, plus native MPRIS events.
Only visible analog resource gauges have a ten-second cadence; the clock updates by minute.
Closing leaves no Quickshell, Matugen, theme helper or surface subscriber resident.
The inotify subscriber also watches its consumer pipe lifetime to survive abrupt UI death.
Launched user applications deliberately have separate sessions and are not cleaned up.

Optional Quickshell **0.3.1-1**, Qt Wayland **6.11.2-1**, libdwarf **2.3.2-1** and
cpptrace **1.0.4-2** were extracted locally from signature-verified Arch packages into
`~/.local/opt/kona-pkgs/quickshell-0.3.1/usr`. Qt's installed base is 6.11.2.
Package archives, signatures and verification output are in `E/packages/`; supplied
licenses remain in the extracted tree. No privileged package installation occurred.
Launch-specific library/QML/plugin paths select this extraction; no GPU environment was
changed. Its package desktop entry is installed at
`~/.local/share/applications/org.quickshell.desktop`. `packages/pacman.txt` documents
Quickshell for future normal installs. Missing Quickshell falls back to existing Rofi.

Recovery commands, if needed: `kona-shell close`, `kona-profile preview-revert`,
`kona-appearance revert`, `kona-profile mosaic-end`, then `kona-profile reconcile`.
Palette recovery remains `kona-theme --default`. Mosaic now holds a full validated
palette copy outside Matugen generation GC, so repeated accent generation cannot delete
its return palette. Failed preset application restores preferences and exact Gaming
return intent, reporting any incomplete rollback.

Rollback is **not executed**. Close surfaces/revert transactions first. Extract
`E/pre-v4-live.tar.gz` and `E/pre-v4-repo.tar.gz` into separate temporary directories;
restore only paths listed in `E/V4_CHANGED_FILES.txt` that existed before V4. Remove only
new V4 paths whose current hashes still match `E/final-manifest.json`; preserve any later
user edits. `E/deployment-backup/` also contains scoped installed originals. Never apply
an entire archive over the current dirty tree. Remove optional extracted dependencies
only after no surface uses them. Reload configuration after restoring its V4 changes;
do not restart the compositor or unrelated services. Existing live-only dock differences
must be restored from live evidence, not repository HEAD.

## Validation and adverse evidence

**87 Python contract tests pass** across profiles18, event-state9, theme11,
wallpaper-theme4, Waybar5, Control Center7, Rofi12, runtime6 and V4 contracts15.
Native Lua contracts, native Hyprland config verification, isolated recovery smoke,
Python/Bash syntax and `git diff --check` also pass. Evidence: `regressions-final.txt`
(profiles), `regressions-corrected.txt`, `state-projection-corrected.txt`,
`v4-lifecycle-final.txt`, `lua-final.txt`, `recovery-final.txt`,
`hyprland-verify-corrected.txt` and `final-manifest.json`.

Live checks covered three distinct real Matugen image previews with exact reverts,
Apply, appearance preview/commit/revert, cyan/wallpaper accent, Full/Reduced/Off,
preset roundtrip, native MPRIS Play/Pause/Next/Previous via a bounded silent fixture,
real keyboard entry/Tab/Escape, rapid reverse with one PID, all nine Studio pages,
three outputs, Mosaic return, SwayNC/Rofi entrypoints and existing Waybar composition.
No notification history was cleared. Final comprehensive QA recorded 6→7 notifications
(the return notification added one). Window geometry/workspaces/focus/cursor were restored
exactly (`RESTORATION.json`, `latest-restoration.json`); ordinary later user activity is
not overwritten by an old snapshot. The canonical dock and Task07 user units hash-match
the starting live versions. No compositor/Waybar/dock/SwayNC restart was performed.

A final process audit found one orphan event subscriber from the earlier wrapper-TERM
case. Its identity/maps/private/PSS evidence is `orphan-event-subscriber.json`.
Only that V4-created orphan was terminated. The launcher now owns the UI process group,
and the subscriber exits on consumer pipe closure. A regression test and real graceful,
wrapper-TERM and UI-SIGKILL cases pass with every observed descendant released
(`lifecycle-corrected.json`). Earlier resource windows are retained, not relabeled clean.
Other adverse findings and corrections are indexed in `E/ADVERSE.md`.

## Resource observations and limits

Normal-use 20-second / 5-second observations reuse Task07's 22-process core cohort.
The same core identities remain. Original before/after median PSS was **718.616→765.971
MiB (+47.354)**; the latter window preceded the orphan-subscriber correction. That
subscriber was outside the historical core classifier and is separately disclosed.
The corrected closed-surface observation is **767.115 MiB (+48.499 versus before)**,
with no V4 resident helper. The unchanged incremental +64 MiB alarm is not crossed.
The original increase was predominantly SwayNC +34.188 MiB and Hyprland +9.146 MiB,
with the same start identities; attribution to process is not proof of a V4 causal leak.

Absolute **core613.65234375 MiB / dock44.694 MiB** alarms remain breached, preserved and
attributed; no threshold was recalibrated and no unrelated component was restarted.
Original dock median126.058→127.410 MiB is retained. CPU medians were29.440→42.339%
(original) /42.906% (corrected), with substantial changing application workload.
These are **rejected as idle comparators**, not a causal CPU pass or fail:
**aggregate matched-idle measurement deferred**. See `PERFORMANCE_POLICY.md` and
`E/PERFORMANCE_PLAN.md`; no routine idle-ready or application freezing was used.

Open Studio's earlier 10-second measurement was239.035 MiB /0% median CPU; opt-in
Mosaic254.604 MiB /18.768% median CPU. These scopes include wrapper, Quickshell and
named Kona helpers but omit native nmcli/SwayNC subscription children; they are not
complete process-tree totals. A later fully loaded wallpaper gallery ancestry snapshot
includes all five descendants/owner processes: **314.500 MiB PSS**, including11.163 MiB
event adapter,2.613 MiB nmcli and0.650 MiB SwayNC stream (`open-full-ancestry.json`).
This open Qt cost is explicit. No closed DAILY RAM-saving claim is made.

## Review evidence and remaining limitations

- Deck: `E/final-120604/deck.png`; real media controls: `E/deck-media.png`.
- Studio: `E/final-120604/Appearance.png`, `Motion.png`, `Shortcuts.png`, etc.
- Fully loaded gallery: `E/gallery-loaded-final.png` (earlier 250 ms capture showed pending images).
- Saved profile return view: `E/profiles-final.png`.
- Three-monitor Showcase: `E/final-120604/mosaic-three-monitors.png`.
- Motion: `E/final-120604/kona-v4-motion.mp4`; sampled sequence `E/motion-enter-sequence.jpg`.
- Preserved existing surfaces: `E/final-120604/{waybar-all,control-center,rofi-drun,rofi-window}.png`.
- Exact V4-only file list: `E/V4_CHANGED_FILES.txt`; installed/repository hashes: `E/final-manifest.json`.

**Accessibility capability gap:** keyboard/pointer and focus indication work, but the
native Qt AT-SPI application exposes no control children. The same defect reproduces
with a minimal standard Qt window, independent of Deck. Explicit Accessible roles and
Qt accessibility activation did not resolve it. Existing GTK accessibility remains
healthy. No global accessibility/session changes were attempted. Full screen-reader
support is not accepted or claimed (`surface-accessibility.json`, `a11y-probe/`).

A compatible live overview plugin is unavailable for this installed Hyprland pin;
Super+W retains the accepted ten-card overview. Native API differences (`dampening`,
`Variants.model`, `Qt.quit`) were resolved against the actual runtime. No plugin or UWSM
migration is pending as a V4 prerequisite. Screenshot/video sampling proves delivered
states, not subjective normal-speed quality or 240 Hz stutter absence; 60 fps recording
is not GPU timing. Mani must review native motion and aesthetics. No higher-fidelity
screen-reader or frame-pacing claim is made.

Next human decision: review the native Deck, Studio, wallpaper preview/revert and Mosaic,
and approve or request specific V4 refinements. Do not automatically resume old Task08–10.
