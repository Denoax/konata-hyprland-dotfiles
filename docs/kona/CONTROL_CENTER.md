# Kona Notification Center

SwayNC remains the sole notification daemon, history store, DND owner, and
control-center process. The authored presentation uses native SwayNC widgets for
the hero, quick controls, notification list, quick actions, and footer. It does
not introduce a resident controller or another notification data model.

The four quick controls route to the existing owners:

- Do Not Disturb: SwayNC
- Focus Mode: `kona-profile`
- Screen Record: `kona-record` and `kona-record-status`
- Screenshot: `kona-screenshot`

Open Settings uses the existing system settings surface. Power Menu and Log Out
open `kona-session-menu`, so its cancel-first confirmations remain authoritative.
Lock Screen uses Hyprlock. Native notification app icons, titles, bodies,
timestamps, grouping, images, inline replies, action buttons, urgency, and clear
semantics remain enabled.

Colors still come exclusively from
`../kona/theme/current/swaync.css`. The matching Light/Dark character and icon
assets live under `assets/light` and `assets/dark`. `kona-dashboard` selects
the artwork for the current authoritative appearance mode and writes the current
clock, date, and real SwayNC count immediately before opening. That work is
one-shot and exits before the panel is shown.

## Command compatibility

Installed SwayNC 0.12.6 parses configured commands through GLib before invoking
the shell. Embedded double quotes therefore retain a literal backslash in the
JSON value. `python3 tests/control-center.py` exercises this installed parsing
contract and owner routing.

## Apply and recover

Install `.config/swaync/` and `.local/bin/kona-dashboard`, then run:

```sh
kona-dashboard --sync-only
swaync-client --reload-config --skip-wait
swaync-client --reload-css --skip-wait
```

These operations retain the running SwayNC process and notification history.
Restore the previous config, stylesheet, assets, and dashboard entrypoint, then
reload config and CSS to roll back.
