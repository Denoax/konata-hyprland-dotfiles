# Current status

Release checkpoint: **2026.09.16**

The installed visual baseline represented in `showcase/` is accepted for this checkpoint. The current product includes the Quickshell sidebar/navigation, native music popup, four profiles/scenes, Mono Rain live wallpaper, Mono Rain Hyprlock lock screen, unified menus, system Light/Dark propagation, event-driven session state, and the plain-session runtime ownership correction.

Targeted product tests, isolated recovery, native config parsing, appearance rollback, service ownership and in-session crash/restart checks pass. The retired dock, drawer, terminal media deck and their current-product claims have been removed.

## Known validation item

Runtime ownership has passed in-session crash/restart/authorization validation; one complete real logout/login lifecycle check remains. After the next normal PlasmaLogin → Hyprland login, run:

```bash
kona-runtime-health polkit
systemctl --user --failed
hyprctl instances -j
```

This does not block the checkpoint, but it remains an explicit boundary proof rather than a claimed pass.

## Scope and support

- Plain Hyprland is canonical; UWSM-managed compositor startup is optional/deferred. The `uwsm` command remains installed for bounded app scopes.
- The monitor map and hardware package notes are specific to Mani's workstation.
- Existing GTK/Qt applications may need a new window to pick up a theme switch. Apps with explicit appearance overrides remain app-owned.
- Hyprlock intentionally keeps its approved fixed Mono Rain palette instead of following the unlocked desktop appearance.
- The repository has no project-wide license grant. Third-party materials retain their own terms.
