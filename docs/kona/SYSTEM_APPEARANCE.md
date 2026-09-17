# Kona system Light/Dark appearance

## Status

Implementation, technical validation and the installed visual checkpoint are accepted for the 2026-09-16 release.
The release capture set verifies both Light and Dark modes.

## Ownership and data flow

`kona-appearance` is the single command and durable-state owner. It preserves its existing
geometry preview/revert/commit API and adds:

```text
kona-appearance light
kona-appearance dark
kona-appearance toggle
kona-appearance status
```

Manual intent is stored once in `~/.local/state/kona/appearance.json`. A change is
transactional: validate and render targets, set the GNOME host preference, verify the XDG
portal, update the existing GTK settings, apply an installed KDE color scheme, atomically
activate generated Kona fragments, reload supported consumers, verify convergence, then
persist intent. Any failed step restores the prior host, GTK, KDE, generated-theme and state
files. `kona-runtime-start` performs one reconciliation at compositor startup and exits.
There is no appearance daemon, timer, polling loop or second state store.

`kona-theme` remains the atomic palette/generation owner. It publishes semantic colors to
Waybar, Rofi, SwayNC, SwayOSD, Kitty and Hyprland borders. Quickshell consumers watch the
stable generated notification file `~/.config/kona/appearance/current.json`; this is a
rendered target, not writable state. The sidebar Quick Controls page exposes one keyboard
accessible `Appearance: Light / Dark` segmented control and routes both actions to
`kona-appearance`.

The pack's Light secondary-text token was corrected from `#637289` to `#5B6B80`: the
supplied value measured 4.13:1 on `surface_pressed`, while the corrected token is 4.60:1.
Geometry, action ownership and the approved lockscreen/live-wallpaper compositions remain
unchanged.

## Verified propagation

| Target | Light | Dark | Refresh behavior |
|---|---:|---:|---|
| Host `color-scheme` | `prefer-light` | `prefer-dark` | immediate |
| XDG portal | `2` | `1` | immediate and read back |
| GTK 3/4 preference | `false` | `true` | new window for tested GTK app |
| KDE color scheme | `BreezeLight` | `BreezeDark` | new window for tested Dolphin build |
| Firefox System web content | `LIGHT` | `DARK` | live, from supplied local test page |
| Quickshell Kona UI | Light palette | Dark palette | live, same sidebar PID |
| SwayNC | Light fragment | Dark fragment | CSS reload, same PID/history/DND |
| SwayOSD | Light fragment | Dark fragment | scoped restart of its existing owner |

Five consecutive `light → dark → light → dark → light` transitions took 203–226 ms each.
SwayNC stayed at PID 2085100 with notification count 2 and DND enabled. The sidebar stayed
at PID 2118484 across live palette changes. No `kona-appearance` or `kona-theme` process
remains resident.

The plain-Hyprland session runs SwayOSD directly rather than through its installed user
unit. The reload path detects that exact command, stops it, and starts one replacement with
the same config/style arguments. Live verification observed `2082937 → 2129168 → 2129273`
across Dark then Light with exactly one owner after each transition; it does not activate a
second unit or change the deferred UWSM work.

GTK Network Connections and Qt/KDE Dolphin follow the system choice after opening a new
window. Their already-open windows do not repaint in place. Pavucontrol remained dark under
verified Light GTK settings, and KDE System Settings' Automatic page showed a stale Light
palette during one Dark probe; these are preserved as application-specific compatibility
exceptions. Kona does not edit private Brave, Firefox, Electron or VS Code profiles, and an
application manually forced to a theme remains application-owned.

## Validation and evidence

Evidence and exact pre-change backups are under
`~/.local/state/kona/system-appearance-20260915/`.

- `tests/appearance.py`: command, idempotence, persistence, portal verification and complete
  rollback on a forced portal failure.
- `tests/theme.py`, `tests/unified-menus.py`, `tests/sidebar-navigation.py`,
  `tests/music-popup.py`: affected consumer and accepted-feature regression coverage.
- `tests/recovery-smoke.sh`: clean config-only recovery includes the owner, semantic sources,
  generated fragments and Quickshell readers.
- Native Light/Dark sidebar renders prove the switch and same-owner live update.
- The supplied browser page was rendered in an isolated Firefox test profile; no private
  browser profile was changed.
- Native GTK and Qt applications were opened on temporary workspace 9, closed afterward,
  and the prior workspace/focus arrangement was restored.
- Adverse first-apply, stale compositor-signature, Qt readback, GTK live-refresh and
  application-exception evidence is retained rather than discarded.

Hyprlock remains on its approved fixed Mono Rain palette for the next lock. Enrolling it in
global appearance would change a locked reference/security surface and requires a separate
approved visual pass. Persistence across a real login is deferred until the next normal
login; no logout was forced for this module.

## Rollback

Use the exact file backups under `backup/home-config`, `backup/repo` and
`backup/live-product`, plus the captured host/toolkit baseline in `evidence/`. Restore only
the listed touched files and prior host `color-scheme`; do not reset or replace the dirty
repository. The owner itself automatically performs this scoped rollback when a switch
fails.
