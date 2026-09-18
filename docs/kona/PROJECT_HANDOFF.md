# Current engineering handoff

Kona Desktop V3 is the current public-main candidate and is represented by the privacy-reviewed captures under `showcase/assets/v3/`. Public orientation lives in the root README and `docs/`; this directory retains subsystem reports and adverse evidence as engineering history.

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

A real post-crash login exposed an early `hyprland.start` owner-check race and left the packaged polkit agent inactive. The owner check now waits a bounded five seconds for compositor registration, the current session is recovered to one systemd-owned agent, and a regression test covers the startup ordering. One fresh PlasmaLogin logout/login after this fix remains before a stable tag. After that login, run `kona-runtime-health polkit`, `systemctl --user --failed` and `hyprctl instances -j`.

UWSM remains optional/deferred. Do not migrate the canonical session merely to close this validation item.

## Evidence boundary

Runtime evidence and exact rollback copies remain under `~/.local/state/kona/` and are intentionally excluded from Git. Each subsystem report names its evidence directory and preserves relevant negative results. Current user-facing truth is in `docs/CURRENT_STATUS.md`; Git history preserves the longer chronological handoff this file replaced.
