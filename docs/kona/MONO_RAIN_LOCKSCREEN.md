# Kona lock screen

Status: **current V3 implementation**

This checkpoint changes only the Hyprlock surface. Hyprlock remains the session-lock and
input owner, and the system PAM stack remains the authentication path. No QML password UI,
key forwarder, custom authenticator, resident animation daemon, or PAM change was added.

## Native composition

- All outputs render the tracked native-resolution snapshot of Kona's selected Wallpaper
  Engine scene. Hyprlock 0.9.6 cannot use the live renderer as a background, so the lock
  keeps an opaque captured frame rather than exposing the unlocked session.
- DP-4 adds one deterministic 80-frame rain label, a native Hyprlock card, real time/date,
  the shared profile avatar, `KONA`, the real `$USER`, and one native masked `input-field`.
- HDMI-A-1 and HDMI-A-5 keep the shared backdrop without duplicating the authentication card.
- Rain updates every 125 ms through one transient command surface. Konata and the flowers
  never animate.
- `fadeIn`, `fadeOut`, `inputFieldDots`, and `inputFieldColors` are native Hyprlock 0.9.6
  animations. Check, failure, and Caps Lock colors are owned by the native input field.
- Kona `reduced`/`off` motion returns frame 000; `full` follows the deterministic cycle.

The shipped frames contain `<` and `>` characters. Hyprlock treats all label text as Pango
markup, so the installed frame copies entity-escape those two control characters. Decoding
every installed frame reproduces the shipped visible stream exactly.

The pack mentioned `dots_fade_time`, which is not an option in installed Hyprlock 0.9.6.
The supported `inputFieldDots` animation is used instead. The old live config also contained
`general:grace`, which 0.9.6 reported as nonexistent and ignored; removing that invalid line
does not shorten a grace period that was never active.

## Files

- `.config/hypr/hyprlock.conf`
- `.config/kona/lockscreen/current-wallpaper/konata-workshop-3569997458.png`
- `.config/kona/lockscreen/current-wallpaper/PROVENANCE.md`
- `.config/kona/lockscreen/mono-rain/background/konata-lock-base.png`
- `.config/kona/lockscreen/mono-rain/background/konata-lock-static-fallback.png`
- `.config/kona/lockscreen/mono-rain/avatar/konata-avatar-512.png`
- `.config/kona/lockscreen/mono-rain/frames/frame-000.txt` through `frame-079.txt`
- `.config/kona/lockscreen/mono-rain/kona-lock-rain-frame`
- `.config/kona/lockscreen/mono-rain/rain-definition.json`
- `tests/lockscreen.py`

## Validation

- Pack manifest: 95/95 declared files and ZIP SHA-256 verified before integration.
- Pack rain validator: 80 frames, 10.0-second loop, 125 ms update — PASS.
- Focused lockscreen suite: 6/6 — PASS.
- Hyprlock 0.9.6 config parser: no config errors — PASS.
- Production image SHA-256 values match the pack manifest — PASS.
- All installed Pango-safe frames decode to the supplied frame characters — PASS.
- Live/repository config, helper, and asset parity — PASS.
- `/etc/pam.d/hyprlock` remained SHA-256
  `f4f8c269ef8a2ad86d1ab42bb4ca7b719663e632b12ce21ac9aee19bf6e1272d`.
- Controlled native lock, PAM authentication, unlock fade, and return to the existing
  session — PASS. The final run logged 51 live rain-label updates and no config warnings.
- Post-unlock process check: no Hyprlock or rain helper remained resident — PASS.
- 32 native DP-4 captures contain 26 distinct frames; the final corrected screenshot and
  a four-second rain-only motion clip are preserved.

The first native run found a real defect: `#` inside Pango color spans was parsed as a
Hyprlock comment and exposed partial markup in the placeholder. That full run is retained
as adverse evidence. The spans were removed, a regression assertion was added, and the
second native render shows the corrected `Enter password` field.

Wrong-password and Caps Lock colors are wired to native Hyprlock properties and covered by
the config contract. They were not captured because the completed real unlock attempts did
not include a failed password or Caps Lock activation; their subjective transition remains
part of Mani's live review. No authentication input was captured.

## Transient helper cost

Method: same session and frame data, stdout discarded, 10 warmups plus 100 invocations.

| Helper | median | p95 | max |
|---|---:|---:|---:|
| Shipped reference | 6.599 ms | 10.795 ms | 12.168 ms |
| Installed candidate | 4.380 ms | 7.642 ms | 8.558 ms |

The candidate is well below the 125 ms update interval. This is a transient lock-only
measurement, not aggregate desktop CPU or GPU timing.

## Evidence and rollback

Evidence and exact pre-change configs:
`~/.local/state/kona/mono-rain-lockscreen-20260915/`

Key evidence:

- `evidence/lockscreen-final.png`
- `evidence/rain-motion-live.webm`
- `evidence/hyprlock-live-final.log`
- `evidence/live-log-summary.json`
- `evidence/rain-helper-latency.json`
- `backup/live-hyprlock.conf`
- `backup/repo-hyprlock.conf`

Rollback is scoped to restoring the matching backed-up Hyprlock config. The new lockscreen
asset directory is isolated under `.config/kona/lockscreen/mono-rain`; no other Kona owner
depends on it.

The original implementation evidence remains historical; `docs/CURRENT_STATUS.md` is the
authoritative release state.
