# Task07 runtime / login ownership completion — current checkpoint

**READY FOR MANI — TASK07 RUNTIME OWNERSHIP REVIEW**

The authoritative PlasmaLogin → plain Hyprland path now starts exactly one packaged
Hyprland polkit agent only after the canonical compositor's Wayland and IPC endpoints are
usable. The preserved `start-limit-hit` incident was recovered without restarting the
compositor or another desktop component. Restart, forced-crash recovery, environment,
single-owner and non-destructive authorization checks pass. A first-compositor guard also
prevents a nested Hyprland instance from duplicating session owners or replacing the user
manager's canonical display environment.

Task07 remains **PARTIAL only for one manual real logout/login boundary check**. UWSM is
optional/deferred and is no longer the required completion path. See
[RUNTIME.md](RUNTIME.md). Evidence/backups:
`/home/mani/.local/state/kona/task07-runtime-completion-20260916/`.

No visual module, PAM policy, notification history, Git history, remote, boot branding or
unrelated owner was changed.

---

# Kona system Light/Dark appearance — current checkpoint

**READY FOR MANI — KONA SYSTEM LIGHT/DARK THEME REVIEW**

The existing `kona-appearance` / `kona-theme` owners now coordinate one manual Light/Dark
choice across Kona semantic consumers, the host preference, the verified XDG portal, GTK
settings, KDE/Qt schemes and System-following web content. The sidebar supplies the one
normal Appearance control. Transitions are transactional with scoped rollback, leave no
resident helper, and preserve all existing backend owners and UI geometry.

Native Light/Dark renders, the supplied Firefox `prefers-color-scheme` page, installed GTK
and Qt apps, five repeated transitions, forced-failure rollback, recovery, parser and
accepted-feature regression checks pass. Known app-specific live-refresh exceptions and all
adverse evidence are preserved. Hyprlock retains its approved fixed Mono Rain palette, and
real-login persistence is deferred to the next normal login. See
[SYSTEM_APPEARANCE.md](SYSTEM_APPEARANCE.md). Evidence/backups:
`/home/mani/.local/state/kona/system-appearance-20260915/`.

Branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`; accepted dirty work preserved. No Git
history/remote operation, UWSM change, compositor restart, idle request, app freeze, long
benchmark or private application-profile edit occurred. Subjective approval remains Mani's
decision.

---

# Kona unified menus — prior checkpoint

**READY FOR MANI — KONA UNIFIED MENUS VISUAL REVIEW**

The coordinated Frost pass is installed across SwayNC, Rofi, and SwayOSD while retaining
their existing backend owners. Notification/control center, launcher, Alt+Tab, command,
clipboard, audio, power/session, profile, wallpaper, overview, OSD, network, Bluetooth,
and confirmations share one compact visual/action contract. The real command-center
bindings and legacy Deck entry now converge on SwayNC; no competing owner or resident
helper was added.

Native renders and motion, parser/load checks, isolated backend/destructive-boundary
tests, recovery, owner lifecycle, accessibility contrast/focus, and protected-module
hashes pass. SwayNC's final scoped restart preserved count `0 → 0` and DND false. All
439 protected sidebar/music/lockscreen/live-wallpaper files are byte-identical. See
[UNIFIED_MENUS.md](UNIFIED_MENUS.md). Evidence/backups:
`/home/mani/.local/state/kona/unified-menus-20260915/`.

Branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`; accepted dirty work preserved. No Git
history/remote operation, UWSM change, compositor restart, idle request, app freeze,
long benchmark, or destructive session action occurred. No later desktop module began;
subjective approval remains Mani's decision.

---

# Kona Mono Rain lockscreen — prior checkpoint

**READY FOR MANI — KONA MONO RAIN LOCKSCREEN REVIEW**

Only the supplied native Hyprlock module is installed. Hyprlock/PAM remains the sole
authentication owner; the shipped static Konata/flowers, avatar, and deterministic
80-frame downward rain are mapped to native background/image/shape/label/input-field
widgets. Native masked-dot, fade, check/failure color animations and Reduced Motion are
wired without a resident helper. Corrected native screenshot, rain motion, exact backups,
focused tests and live logs pass; subjective visual approval remains Mani's decision.

See [MONO_RAIN_LOCKSCREEN.md](MONO_RAIN_LOCKSCREEN.md). Evidence/backups:
`/home/mani/.local/state/kona/mono-rain-lockscreen-20260915/`. Branch
`kona-v3/task01-event-state`, HEAD `dac844f554e37eef9368fbf26860be65237422de`;
dirty work preserved. No Git history/remote operation, compositor restart, UWSM change,
PAM edit, idle request, app freeze, notification clear, or long benchmark occurred.

---

# Konata Mono Rain live wallpaper — deferred checkpoint

**READY FOR MANI — KONATA MONO RAIN LIVE WALLPAPER REVIEW**

Only the supplied Mono Rain wallpaper was implemented. The exact reference supplies the
static character/flower composition; a deterministic 10-second left-field rain cycle is
rendered reproducibly and displayed by the existing Awww owner. Daily/Showcase animate;
Focus/Gaming use the composition-matched still and release Awww. The accepted theme and
all sidebar/music/launcher/notification/navigation owners remain intact.

The final GIF runtime path measures 7.865% mean Awww CPU and 36.794 MiB PSS, below the
unchanged +10-point / +64 MiB incremental alarms. Higher-cost WebP trials remain preserved
as adverse evidence. Encoded seam, three-loop, native sidebar composition and profile-transition
evidence pass. One stale profile test assertion still omits the already-accepted `return_to`
field; the other 17 profile tests and all wallpaper/preservation checks pass.

See [MONO_RAIN_WALLPAPER.md](MONO_RAIN_WALLPAPER.md). Evidence/backups:
`/home/mani/.local/state/kona/mono-rain-20260915/`. Branch
`kona-v3/task01-event-state`, HEAD `dac844f554e37eef9368fbf26860be65237422de`;
dirty work preserved. No Git history/remote operation, compositor restart, UWSM change,
notification clear, idle request, app freeze, or long benchmark occurred. Visual approval
remains Mani's decision.

---

# Kona sidebar navigation and identity — current checkpoint

**READY FOR MANI — SIDEBAR NAVIGATION + IDENTITY REVIEW**

Mani approved the preceding full desktop redesign as the authoritative visual baseline.
This scoped pass moves useful dock behavior into the existing left sidebar, retires the
bottom dock after parity, adds guarded bare-Super sidebar toggling, and replaces the weak
personal header with a high-resolution KONA system identity and one Reduced-Motion-aware
avatar aura. The approved light blue/white shell, music popup, sections, actions, and
backend owners remain in place.

Native launch/focus/running-state behavior, the existing Super-chord guard, Reduced
Motion, sidebar lifecycle, Hyprland config, recovery, and source/live parity pass. The
controlled sidebar delta is +13.63 MiB PSS against an equivalently warmed same-session
pre-navigation instance, below the unchanged +64 MiB alarm. The dock's historical
44.694 MiB evidence remains preserved, although no dock process is now resident. A failed
Qt `ColorImage` optimization and its decode warnings are retained as adverse evidence;
the validated icon renderer was restored.

See [SIDEBAR_NAVIGATION.md](SIDEBAR_NAVIGATION.md). Evidence/backups:
`/home/mani/.local/state/kona/sidebar-navigation-20260915/`. Branch
`kona-v3/task01-event-state`, HEAD `dac844f554e37eef9368fbf26860be65237422de`;
dirty work preserved. No Git history/remote operation, compositor restart, UWSM change,
notification clear, idle request, app freeze, or long benchmark occurred. Visual approval
for this scoped pass remains Mani's decision.

---

# Kona full desktop redesign — approved baseline

**APPROVED BY MANI — KONA FULL DESKTOP REDESIGN**

The full redesign candidate is installed over the authoritative dirty tree. The complete
native sidebar now consumes real MPRIS, Hyprland workspace, desktop-entry, profile, and
existing action-owner state. Desktop/Settings, Rofi, SwayNC, Kitty, and Hyprlock were
visually normalized; filler copy, orbit graphics, fake telemetry, and the permanently
resident terminal dashboard/CAVA were retired. The approved music popup and all accepted
backend owners remain intact. Native rendered evidence and targeted lifecycle/recovery
tests pass. Mani approved this baseline before authorizing the later sidebar navigation
pass. See [FULL_REDESIGN_REPORT.md](FULL_REDESIGN_REPORT.md).

Branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`; dirty work preserved. Task07 remains
PARTIAL with managed-login validation deferred. No Git history/remote operation, UWSM
change, compositor restart, notification clear, or long benchmark occurred.

Adverse evidence is preserved: SwayNC 0.12.6 crashed once during rendered QA after its
active icon theme failed to resolve `audio-symbolic.svg`. The existing user unit recovered
it automatically (PID 2480 to 1932576, restart count 1), and the recovered control center
rendered successfully. No manual restart or clear command was issued, but the pre-crash
notification count was not captured, so preservation of in-memory history is unverified.
See `evidence/swaync-crash-incident.txt` under the evidence root below.

Evidence/backups: `/home/mani/.local/state/kona/full-redesign-20260915/`.

---

# Historical sidebar checkpoint — edge-hover auto-hide

Implemented and natively validated. Left-edge 2px hotspot reveals the remembered
300/60px sidebar; leaving hides it after 450ms. Keyboard focus holds; Escape hides;
explicit close exits. Same owner, no poller or new startup service. Existing visuals
and header preserved. No later component started; Mani live review remains pending.
See [SIDEBAR_AUTOHIDE.md](SIDEBAR_AUTOHIDE.md) for evidence and exact behavior.

---

# S04/S05 header revision — current checkpoint

**READY FOR MANI — S04/S05 HEADER REVISION LIVE REVIEW**

Quote/encouragement removed. Real profile replaces the third identity line. White shell
has the requested subtle 1px pale-blue outline/glow; geometry and behavior preserved.
Avatar unchanged; quality improvement recorded as a future asset task only.
Targeted tests/native evidence pass; Mani review pending. No later component started.
See [SIDEBAR_HEADER.md](SIDEBAR_HEADER.md). Evidence/backups:
`/home/mani/.local/state/kona/sidebar-header-revision-20260914/`.
HEAD dac844f554e37eef9368fbf26860be65237422de; dirty work preserved; no Git operations.

---

Historical checkpoints (older quote instructions are superseded):

# S04/S05 header — live review checkpoint

**READY FOR MANI — S04/S05 HEADER LIVE REVIEW**

Revision 2 S01–S03 is APPROVED BY MANI and preserved. Directly authorized S04/S05/W03
are now installed from the existing pack: header, exact avatar artwork, real local user
and Kona profile, supplied optional quote (Mani confirmed inclusion). Light shell retained.
Native and isolated checks pass; new header visual approval is pending. No later component.
See [SIDEBAR_HEADER.md](SIDEBAR_HEADER.md) for actions, tests, evidence and limitations.
Evidence: `/home/mani/.local/state/kona/sidebar-header-20260914/`.
HEAD dac844f554e37eef9368fbf26860be65237422de; dirty work and adverse evidence preserved.
No Git history/remote operations. Stop for Mani; S06/S07 and later work NOT STARTED.

---

Historical checkpoints follow:

# Sidebar foundation — revision 2 review checkpoint

**READY FOR MANI — SIDEBAR FOUNDATION REVISION 2**

White/frosted S01–S03 revision installed: flush left, full height, 300/60px states,
centered collapse control, pale right edge. Existing behavior and owners preserved.
Native QML and interaction checks pass; candidate survived the reported PC reboot
and rendered again afterward. Crash evidence is preserved; cause is not established.
Mani's visual review is pending. S04 and all later work remain NOT STARTED.
See [SIDEBAR_FOUNDATION.md](SIDEBAR_FOUNDATION.md) for exact evidence and limitations.
Evidence: `/home/mani/.local/state/kona/sidebar-foundation-r2-20260914/`.
HEAD `dac844f554e37eef9368fbf26860be65237422de`; dirty work preserved; no Git operations.

---

Historical checkpoint below (superseded for sidebar appearance):

# Sidebar foundation — live review checkpoint

**READY FOR MANI — SIDEBAR FOUNDATION LIVE REVIEW**

Mani directly approved C01–C07 and S01–S03 for native implementation. Approval is recorded
in [RAW_ASSET_DECISIONS.json](RAW_ASSET_DECISIONS.json). Only the foundation is installed:
left-edge frame/rail, collapse control, slide transitions, remembered expansion/mute/gain,
supplied glow and bubble sound, keyboard input and Reduced/Off support. No S04 or later
content is implemented. Launch **Kona Sidebar** / `kona-sidebar show`.

Native Quickshell 0.3.1 / Qt 6.11.2 validation passes; candidate visual approval is pending.
See [SIDEBAR_FOUNDATION.md](SIDEBAR_FOUNDATION.md) for evidence, limits and rollback.
Evidence: `/home/mani/.local/state/kona/sidebar-foundation-20260914/`.
Pre-existing source/live product files, including the approved music popup, are unchanged.
HEAD `dac844f554e37eef9368fbf26860be65237422de`; dirty work and adverse evidence preserved.
No bar cutover/autostart, UWSM change, idle-ready, freeze, benchmark loop or Git operation.
Task07 managed-login validation stays deferred/PARTIAL. Stop for Mani's foundation review.

---

# Music popup final polish — review checkpoint (2026-09-14)

**READY FOR MANI — MUSIC POPUP FINAL POLISH REVIEW**

Only the existing music popup was polished from the final fix pack. Installed: blue
Spotify identity without badge/redirect, clear audio-device icon, playback-only slow
ring/halo with Reduced/Off support, and a soft perimeter glow. Existing behavior remains.
Three popup QML files changed; existing tests pass plus two focused polish tests.
Native playing/paused captures, 6.283s motion clip, audio-menu/reduced-motion checks,
restoration and zero-resident evidence are documented in [MUSIC_POPUP.md](MUSIC_POPUP.md).
Evidence/backups: `/home/mani/.local/state/kona/music-polish-20260914-171204/`.

HEAD `dac844f554e37eef9368fbf26860be65237422de`, accepted dirty tree preserved.
No commit/push or remote/history operation. Prior approvals/evidence retained; Task07
remains PARTIAL with managed-login validation deferred. No next UI surface started.
Await Mani's final music-popup visual review; do not infer approval from deployment.

---

# Current step — music popup

**READY FOR MANI — MUSIC POPUP REVIEW**

The supplied music-popup QML is integrated and installed as `kona-music-popup`
(application launcher: **Kona Music**). Only this feature was authorized. Its running
implementation awaits Mani approval; do not begin the next surface. No new V4-wide
approval is inferred. See [MUSIC_POPUP.md](MUSIC_POPUP.md) for wiring, evidence and rollback.

The dirty branch/HEAD and all other surfaces are preserved. No fetch/pull/merge/rebase/
reset/commit/push, compositor restart or notification clearing. Task07 retains its
existing PARTIAL/deferred status. The prior handoff follows unchanged.

---

# Kona V4 reference-supremacy handoff

**READY FOR MANI V4 VISUAL REVIEW — reference-supremacy pass complete; no commit/push performed.**

The live candidate implements Deck, searchable Studio/Wallpaper Studio/Help, shared
motion and opt-in three-monitor Mosaic over the existing owners. Mani's V4 visual
approval is pending. Native Qt screen-reader exposure remains a documented capability
limitation; this is not an unconditional accessibility PASS.

Authority remains the actual dirty repository and installed desktop: accepted Tasks01–06
plus deployed Task07, now with the V4 candidate. Branch `kona-v3/task01-event-state`,
HEAD `dac844f554e37eef9368fbf26860be65237422de` unchanged. No reset/discard, remote Git
operation, commit, compositor restart, GPU environment change or notification clearing.

**Task07 — PARTIAL — managed startup/logout validation deferred.** Deployed changes
remain; plain Hyprland is the working session. The old Task08–10 sequence is suspended.
The 2026-09-14 V4 course correction authorized the reference pack's internal phases A–H,
including refinement of older surfaces while preserving useful behavior and recovery.
Do not request managed login or independently resume the old roadmap.

See [V4_REPORT.md](V4_REPORT.md) for phase decisions, usage, changed-file/evidence index,
validation, resource attribution, exact limitations and scoped rollback. Performance
follows [PERFORMANCE_POLICY.md](PERFORMANCE_POLICY.md); unchanged historical alarms
remain preserved. Aggregate matched-idle measurement deferred.

Evidence/backups: `/home/mani/.local/state/kona/v4-20260914-111330`.
The original Task07 handoff is preserved there as `TASK07_HANDOFF.md`; previous reports,
backups and all adverse evidence remain in place. Final audit: 26 deployed product paths
match source; protected Waybar/SwayNC/Rofi/dock/user-unit hashes match the starting live
files; no V4 surface/theme/Matugen process remains resident after lifecycle recovery.
87 Python contracts, native Lua/config validation, recovery smoke and final syntax/diff
checks pass. Screenshots and real motion recording are indexed in the report.

Next step: **Mani V4 visual review**, with explicit screen-reader/runtime limitations.
No new task, commit or push is authorized by reaching this checkpoint.
