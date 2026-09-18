# Current status

Release checkpoint: **Kona Desktop V3 — 2026.09.17**

V3 is the current public-main candidate. The installed product and repository include the auto-hiding Quickshell sidebar, Arch terminal workspace, modern Foot/Fish terminal flows, MPRIS media dashboard, cached Open-Meteo Weather dashboard, Wallpaper Engine Workshop adapter, four profiles/scenes, transactional Light/Kona/Dark appearance propagation, Caelestia/end-4 menu integration, a single end-4 notification owner, SwayOSD integration, current-wallpaper Hyprlock continuity and event-driven session state.

The runtime media under `showcase/assets/v3/` was captured from the real compositor on empty workspaces; the repository banner is a clearly decorative illustration rather than runtime evidence. Capture-time public demo data was removed afterward; the user's appearance, Weather configuration/cache, workspaces, focus, audio level and profile were restored. No private application window, notification history, network identity, local IP, username or home path is present in the published media.

## Validation boundary

Portable contracts, native Lua parsing, shell/Python syntax, isolated recovery, appearance propagation, Arch-workspace lifecycle, profile policy, Weather/music lifecycle and repository privacy checks are release gates.

A real post-crash login on 2026-09-17 exposed the remaining Task07 race: `hyprland.start` could invoke `kona-runtime-start` before the new compositor appeared in `hyprctl instances`, so the canonical-owner check exited and left `hyprpolkitagent.service` inactive. V3 now waits up to five seconds only for compositor registration before deciding ownership; the regression is covered in `tests/runtime.py`. The current session was recovered to one healthy systemd-owned agent with no duplicate process.

One fresh PlasmaLogin → Hyprland login after this specific race fix remains the final boundary proof. After the next normal login, run:

```bash
kona-runtime-health polkit
systemctl --user --failed
hyprctl instances -j
```

Expected: one canonical Hyprland instance, one active systemd-owned polkit agent and no failed user units. This open proof is why the repository is not tagged as a stable release yet.

## Scope and support

- Plain Hyprland is canonical; UWSM-managed compositor startup remains optional/deferred.
- The checked-in monitor map is specific to the reference three-display workstation.
- Existing GTK/Qt applications may need a new window to adopt an appearance switch. Explicit application overrides remain application-owned.
- Wallpaper Engine Web projects remain experimental because one validated Web project later triggered a compositor framebuffer crash; Scene and Video defaults retain bounded fallback.
- Hyprlock/PAM remain the only authentication path.
- Original Kona code/config/docs use MIT; artwork and third-party assets retain separate rights.
