Auto-hide update: see [SIDEBAR_AUTOHIDE.md](SIDEBAR_AUTOHIDE.md). The visual revision below is preserved; Escape now hides while keeping the edge trigger armed, and `close` exits.

# S04/S05 header revision — live review

**READY FOR MANI — S04/S05 HEADER REVISION LIVE REVIEW**

Installed requested revision only: header identity lines are local `mani`, time-aware
`Good evening.` and the real `Daily profile` label. The encouragement and quote are
removed. No replacement text or duplicate status row. The quote rendering, IPC/CLI
control and unused installed copy.json were removed; original pack and backups retained.
Any old quoteVisible Settings key is inert; remembered expansion/mute/gain remain intact.

The frosted white shell now has a soft #B8D2F5 1px perimeter border and a faint supplied
PNG glow on its exposed right edge. At the display boundary, outer glow is naturally
clipped. Flush (0,0), full height, 300/60px, corners, avatar positions, collapse control,
motion, sound, reduced/off support and backend owners are unchanged.

Native Quickshell 0.3.1 / Qt 6.11.2: six QML behavior tests pass (eight including
setup/cleanup), six launcher tests pass, and whitespace checks pass. Tests cover real
profile-label binding, long names, absent status, no quote element, rejected removed
quote commands, keyboard/disabled controls, ownership, centering and reduced/interrupted
motion. Existing profile watcher was not changed; its prior native validation remains.
Native screenshots and 7.15s interaction clip inspected. Current native log is clean.
Source/live scope audit passes; avatar, music popup and other product paths are unchanged.

Evidence: `/home/mani/.local/state/kona/sidebar-header-revision-20260914/`.
Review expanded.png, collapsed.png and expand-collapse.mp4 (silent). Native state,
layer geometry, tests, audit, patch and backups are alongside them. User focus/cursor
activity during capture was preserved; client geometry/workspaces/reservations match.
No idle benchmark, app freezing, owner/service cutover or Git history/remote operations.

Changed product files: sidebar/shell.qml, qml/SidebarView.qml,
qml/sections/ProfileHeader.qml, qml/components/KSurface.qml and .local/bin/kona-sidebar;
removed sidebar/assets/marks/copy.json. Tests, review decisions and handoff updated.
HEAD dac844f554e37eef9368fbf26860be65237422de; accepted dirty work preserved.
Rollback: close sidebar, verify deployed.json hashes (null means absent), then restore
listed files from backup/live. Source backups are retained separately. Keep user Settings.

Deferred asset-improvement task — W03 avatar quality: current exact 84x84 source crop
remains unchanged (82px expanded, 32px rail). A future separately approved source/asset
improvement may replace it; no regeneration, upscaling claim or implementation now.

Only this header revision is ready for Mani review; no visual approval is inferred.
S06/S07 and all later components remain NOT STARTED.
