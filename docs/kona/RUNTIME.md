# Kona session runtime

Task07 runtime ownership is installed for the authoritative PlasmaLogin → plain
Hyprland session. UWSM remains optional and deferred. The current implementation does
not require a session migration.

## Polkit incident and owner

The packaged `hyprpolkitagent.service` is the sole authentication-agent owner. Before
this correction, it had `Restart=on-failure` and only
`ConditionEnvironment=WAYLAND_DISPLAY`. The persistent user manager retained the old
display variables after the previous compositor disconnected, while plain Hyprland did
not own `graphical-session.target`. Systemd therefore restarted the agent six times
against a non-listening Wayland socket before the next login was ready, reached
`start-limit-hit`, and the later `systemctl start` could not recover it.

`kona-runtime-start` now runs from Hyprland's native `hyprland.start` event and:

1. proves that the invoking compositor is the oldest live Hyprland instance for the
   login session, preventing nested/manual compositors from duplicating session owners;
2. imports that compositor's display and instance identity into the user manager;
3. waits on actual Wayland and Hyprland IPC readiness, with a five-second bound;
4. clears any previous start limit and restarts the packaged agent exactly once;
5. verifies unit ownership, one live PID and matching Wayland/Hyprland environment.

The unit drop-in repeats the readiness check as `ExecCondition`. A real in-session crash
uses the packaged `Restart=on-failure` policy with a two-second delay and a limit of three
starts per 30 seconds. During logout or compositor failure, the condition observes that
the canonical IPC endpoint is gone and skips the restart cleanly. An orderly Hyprland
shutdown also stops the unit explicitly. No watcher, polling daemon or second agent was
added.

Use the bounded diagnostic directly:

```sh
kona-runtime-health ready
kona-runtime-health polkit
```

The polkit check fails for an absent or duplicate process, failed/start-limited unit,
systemd/MainPID disagreement, stale service environment, or unavailable canonical
Hyprland session. Its JSON output identifies the declared owner and every failed check.

## Plain-session owner map

| Component | Classification | Concrete owner / lifecycle |
|---|---|---|
| Hyprland | EXTERNAL DESKTOP OWNER | PlasmaLogin runs `/usr/bin/start-hyprland`; session scope owns teardown |
| Polkit agent | SYSTEMD OWNED | Packaged `hyprpolkitagent.service` plus Kona readiness/restart drop-in |
| SwayNC / notification server | SYSTEMD OWNED | Packaged `swaync.service`; one notification owner |
| Wallpaper backend | SYSTEMD OWNED | One Awww or Hyprpaper UWSM scope, selected transactionally by `kona-profile` |
| Waybar | HYPRLAND STARTUP OWNED | One process with three configured output surfaces |
| Sidebar | HYPRLAND STARTUP OWNED | One `kona-sidebar` host and its one Quickshell child |
| SwayOSD | HYPRLAND STARTUP OWNED | One direct plain-session server; managed unit stays inactive |
| Text/image clipboard | HYPRLAND STARTUP OWNED | One `wl-paste` watcher per MIME class; managed units stay inactive |
| Network/Bluetooth applets | HYPRLAND STARTUP OWNED | One `nm-applet` and one `blueman-applet` |
| Hypridle and Udiskie | HYPRLAND STARTUP OWNED | One process each in the login session scope |
| Theme, appearance, profile and event workers | TRANSIENT / ON DEMAND | Commands exit after applying state; no daemon owner |
| Rofi, music popup, settings and menus | TRANSIENT / ON DEMAND | Existing launchers retain their bounded lifecycle |

The managed units for clipboard, automount, OSD and Hypridle remain available for the
deferred UWSM path, but they are inactive in a plain session and do not duplicate the
direct owners. Config reload does not run `hyprland.start`.

## Validation and remaining proof

Live recovery cleared the preserved `start-limit-hit` state and produced one active
systemd-owned agent. An explicit unit restart retained one process. A forced `SIGKILL`
was recovered once after two seconds with one replacement PID and `NRestarts=1`. A
non-destructive `pkexec /usr/bin/true` authorization completed successfully. Current
owner inspection found no failed user units or duplicate Kona owners.

One manual PlasmaLogin logout/login remains required to prove the complete real-session
boundary. Do not automate that logout. After the next normal login, run:

```sh
kona-runtime-health polkit
systemctl --user --failed
hyprctl instances -j
```

Expected results are one canonical Hyprland instance, one healthy agent and no failed
user unit. Evidence and pre-change copies are under
`~/.local/state/kona/task07-runtime-completion-20260916/`.

## Rollback

Restore the saved repository/live `kona-runtime-start`, unit drop-in and Hyprland Lua
files from the evidence directory; remove `~/.local/bin/kona-runtime-health`; run
`systemctl --user daemon-reload`; then restart only `hyprpolkitagent.service` with a known
good current session environment. Rollback restores the old race and should be used only
for diagnosis.

Task06 resource approvals and the historical 613.65234375 MiB core, 44.694 MiB dock,
+10% CPU and +64 MiB incremental alarms remain unchanged. This pass used targeted owner,
journal, environment and lifecycle checks; no long benchmark was run.
