# Kona unified menus — visual-review checkpoint

Status: **technical PASS; Mani visual approval pending**.

The Frost foundation is installed across SwayNC, Rofi, and SwayOSD. Existing state
owners remain authoritative: SwayNC owns notifications/control center, Rofi owns
transient selection, cliphist owns history, PipeWire/pactl owns audio, NetworkManager
owns network state, Blueman owns Bluetooth on this host, `kona-profile` owns profiles,
`kona-wallpaper` owns wallpaper policy, and Hyprlock/systemd/Hyprland retain session
actions. No menu daemon, poller, duplicate history, or replacement state store was
added.

## Binding reconciliation

The real command-center bindings were discovered before cutover:

- `Super+Shift+Return` and `Super+Ctrl+D` call `kona-dashboard`.
- `Super+A` and `Super+N` call SwayNC directly.
- The legacy `Super+Ctrl+Space` Deck chord and the old Deck desktop entry now route to
  `kona-dashboard` as compatibility entrypoints.
- `kona-dashboard` opens the existing SwayNC panel. The optional Quickshell Deck is no
  longer exposed as a competing command-center owner.

All other existing chords retain their established owners: Alt+Tab/Rofi window mode,
Super+Space/Rofi drun, Super+R/Rofi run, Super+V/cliphist, the audio/profile/wallpaper/
overview wrappers, and Ctrl+Alt+Delete/Super+Escape session dispatch.

## Implementation

- Shared Frost colors, geometry, focus treatment, typography, and pack icons now style
  launcher, window switcher, command/list surfaces, clipboard, audio, session,
  confirmation, profile, wallpaper, overview, network, and Bluetooth menus.
- SwayNC uses the same Frost surface for toasts, notification history, DND, quick
  controls, MPRIS, audio, system actions, and session entrypoints. Notification actions
  use the supplied bubble sound through a short-lived helper.
- SwayOSD uses the shared Frost surface without changing its server/state owner.
- Clipboard delete and clear require separate cancel-first confirmation; decode still
  completes before replacing clipboard data.
- Log out, restart, and shutdown remain cancel-first and were never executed in QA.
  The existing backup action now discloses its sync, commit, and push effects before it
  can run; it was never executed.
- Network entries use UUIDs as action identity and an escape-aware parser for displayed
  names. Duplicate or colon-containing names remain distinct. Bluetooth honestly
  delegates to Blueman because `bluetoothctl` is not installed.
- Wallpaper previews use a deterministic 480×270 cache derived from the existing
  sources, preventing large/animated assets from blocking Rofi. The existing wallpaper
  backend is unchanged.
- Current profile and wallpaper mode are visibly marked. All ten overview entries fit
  in one keyboard-navigable surface.
- `kona-motion` maps Full to SwayNC's 200 ms native transition and slide-down System
  revealer; Reduced/Off plus Focus/Gaming use zero transition and a `none` revealer.
  Rofi surfaces add no custom animation.
  Bubble sound is suppressed by the existing Focus/Gaming/recording policies and leaves
  no resident player.

## Validation

- Pack manifest: 52/52 files and archive SHA-256 verified before integration.
- Rofi 2.0.0: every installed `.rasi` parsed with `-dump-theme`; actual launcher,
  Alt+Tab, audio, app mixer, session, confirmation, profile, wallpaper, overview,
  network, Bluetooth, clipboard-safe fixture, and command surfaces rendered.
- SwayNC 0.12.6: config and CSS reloaded successfully, then one final scoped restart was
  used because config reload retained the old empty-state widget. Notification count
  stayed `0 → 0`, DND stayed false, the user unit stayed authoritative, and the final
  UI shows “No notifications.” Normal/icon/action/inline-reply/critical/progress/grouped
  test notifications were closed by their exact IDs, restoring the initial zero count.
  One earlier action-notification probe blocked its sender; because the recorded starting
  history was empty and it was the only item, that test-only entry was removed with
  `close-all`. This adverse cleanup is retained in `evidence/notification-qa.txt`.
- SwayOSD: only its server was restarted to load CSS; one server is resident and the
  custom-message render is captured.
- Automated checks: 9 unified-menu contracts, 14 isolated Rofi/backend tests, 8 SwayNC
  action tests, 15 V4 contracts, 11 theme tests (1 environment skip), recovery smoke,
  and the applicable music/lockscreen/Mono Rain/sidebar regressions pass. The sandbox
  lacked `rsync` and Quickshell's host libraries; both affected checks passed on the host.
- Preservation: all 439 hashed sidebar, music-popup, lockscreen, and live-wallpaper
  files match the pre-pass snapshot. No long benchmark was run. Final targeted resource
  sample: SwayNC 93484 KiB PSS / 70524 KiB private, SwayOSD 24019 KiB PSS / 17796 KiB
  private, and the two cliphist watchers 199/203 KiB PSS. No Rofi, menu helper, or sound
  player remains resident.

Small prompt, placeholder, secondary, and destructive-action text meet at least 4.5:1
against their shipped surfaces; the light accent and danger colors remain available for
decorative outlines. A live Reduced→Full translation check recorded top-level `0→200`
and nested `none→slide_down` with the same SwayNC PID and `0→0` notification count.

The active icon theme still logs a nonfatal missing `audio-symbolic.svg` while rendering
MPRIS. SwayNC falls back and remains healthy; the older crash incident remains preserved
rather than being hidden by changing the system-wide icon theme. Workspace and clipboard
captures use safe fixtures to avoid recording private application and clipboard content;
their real owner paths are covered by isolated behavior tests and live `--check` output.

Evidence and exact pre-change rollback copies are under
`/home/mani/.local/state/kona/unified-menus-20260915/`. The motion artifact is
`evidence/motion/swaync-open-close.webm`; rendered surfaces are in
`evidence/screenshots/`. Branch `kona-v3/task01-event-state`, HEAD
`dac844f554e37eef9368fbf26860be65237422de`; accepted dirty work remains uncommitted.
No remote/history operation, UWSM change, compositor restart, application freeze,
idle-ready request, destructive session action, or unrelated module began.
