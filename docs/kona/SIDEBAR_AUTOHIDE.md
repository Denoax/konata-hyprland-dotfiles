# Sidebar edge-hover auto-hide

Implemented for the current sidebar only. The 300/60px white shell, header, avatar,
outline, sound and backend owners are unchanged.

The same PanelWindow exposes a 2px hotspot on the left edge of the center monitor.
Hover reveals the remembered expanded/collapsed state. Leaving waits 450ms before
sliding away; returning cancels that timeout. Keyboard focus keeps the panel open.
Escape hides and leaves the hotspot armed. `kona-sidebar show` briefly summons it
(2.5s when neither hovered nor keyboard-focused); `close` exits/disarms it entirely.
The existing launcher still prevents duplicate instances. No new startup registration.

Auto-hide requires the existing sidebar process to remain running while hidden;
it no longer exits merely because it slides away. No added service, cursor poller or
resident input helper. The layer remains below fullscreen windows. Reduced/Off still
uses the existing no-animation policy. Show/hide itself makes no click sound.

Validation: four new visibility behavior tests plus six existing QML behavior tests
pass. Native Wayland tests pass for edge reveal, pointer hold, leave hide, re-entry,
collapsed rail hover, bubble/collapse click-through, Tab focus, Escape/rearm and full
close. Native log has no new QML warnings. Motion clip inspected. Scope/source-live audit
passes; no other product paths changed. QA input corrections are in ADVERSE.md.

Evidence/backups: `~/.local/state/kona/sidebar-autohide-20260915/`.
Review hover-autohide.mp4; state/log/test/audit/patch evidence is alongside it.
Changed product files: sidebar/shell.qml and new qml/SidebarVisibility.qml.
Added tests/tst_sidebar_visibility.qml. Docs updated. Source/live backups retained;
rollback after close restores shell.qml and removes only the new visibility component
if deployed hashes still match. Existing Settings and accepted work remain intact.
HEAD dac844f554e37eef9368fbf26860be65237422de; no Git history/remote operations.
No later component or avatar-improvement task started. Live human review remains Mani's.
