# Kona Control Center

SwayNC remains the notification and control-center process. The Task04 composition
uses native title, DND, buttons-grid, MPRIS, volume, menubar and notifications widgets.
There is no additional controller, poller or theme daemon.

Open with the existing Super+A / Super+N bindings or Task03 Waybar controls. Super+C
and the Waybar right-click quick-settings actions keep the existing Rofi fallback.
Task03 monitor roles and Waybar source are unchanged.

Frequent controls occupy two rows: Wi-Fi, Bluetooth manager, night light, gaming,
recording and overview. Native DND sits above them. Media hides when absent; volume,
audio devices and the existing per-app mixer remain accessible. System holds updates,
backup, network, Bluetooth, appearance and settings. Lock and session are separate.
Backup explicitly confirms that the existing command may commit and push; session
retains its existing confirmation flow. Neither operation runs just by opening a menu.

Wi-Fi, gaming, recording and night light use native toggle/update-command support.
State refreshes when the panel opens, through existing Kona command/state owners.
External changes while the panel is already open appear on reopening. Native SwayNC
0.12.6 toggles are optimistic if an action fails; no background state monitor was added.
Bluetooth is an action, since the current machine's Bluetooth backend is unavailable.

Colors come exclusively from `../kona/theme/current/swaync.css`. Main surfaces retain
Task02 navy/ice semantics; checked state, focus, slider and urgency carry the emphasis.
Notification grouping, inline replies, code actions, images, critical persistence,
history, clear-all and native action routing remain enabled.

## Command compatibility

Installed SwayNC0.12.6 `Functions.execute_command` wraps each configured command in
**another double-quoted GLib command-line parse** before invoking `/bin/sh -c`.
The embedded quotes and backslashes therefore require escaping for that layer as well
as JSON. Do not validate these strings solely with `sh -c CONFIG_VALUE`.

`python3 tests/control-center.py` exercises the actual GLib parsing layer, including
paths containing spaces, failed operations, matching toggle state and exact backup
confirmation. Revalidate this boundary against the installed build when upgrading
SwayNC; the version-specific parser behavior is not a general shell convention.

## Apply / recover

The product changes are `.config/swaync/config.json` and `style.css`. Save both current
files before applying, then use `swaync-client --reload-config` and
`swaync-client --reload-css`. These retain the running process and notification history.
Restore the saved files and reload to roll back. The Task04 evidence directory contains
separate live and repository backups, including the accepted Task02 style.

Task04 validation and remaining acceptance limits are recorded in PROJECT_HANDOFF.md.
Task05 has not started. No visual approval of Task04 is implied by these checks.
