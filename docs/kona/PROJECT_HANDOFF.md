# Current engineering handoff

The accepted 2026-09-16 Kona implementation is checkpointed in Git and represented by the live captures under `showcase/`. Public orientation now lives in the root README and `docs/`; this directory retains subsystem reports and adverse evidence as engineering history.

## Current architecture

- Canonical session: PlasmaLogin → plain Hyprland using native Lua configuration.
- Primary navigation: one auto-hiding Quickshell sidebar; the old dock/drawer are retired.
- Appearance: one transactional `kona-appearance` owner plus atomic `kona-theme` rendering.
- Profiles/scenes: one transactional `kona-profile` owner selecting Awww or Hyprpaper.
- Notifications: one packaged SwayNC service.
- Authentication agent: one packaged systemd-owned Hyprpolkitagent with readiness validation.
- Music, menus and policy commands: transient; existing MPRIS, PipeWire, NetworkManager, BlueZ and systemd backends remain authoritative.

The current visuals are accepted for the release checkpoint. Do not reopen aesthetics without a reported defect or an explicitly authorized new pass.

## Outstanding proof

Task07 remains partial only for one manual real PlasmaLogin logout/login lifecycle check. In-session recovery, forced-crash restart, environment, single-owner and non-destructive authorization checks pass. After the next normal login, run `kona-runtime-health polkit`, `systemctl --user --failed` and `hyprctl instances -j`.

UWSM remains optional/deferred. Do not migrate the canonical session merely to close this validation item.

## Evidence boundary

Runtime evidence and exact rollback copies remain under `~/.local/state/kona/` and are intentionally excluded from Git. Each subsystem report names its evidence directory and preserves relevant negative results. Current user-facing truth is in `docs/CURRENT_STATUS.md`; Git history preserves the longer chronological handoff this file replaced.
