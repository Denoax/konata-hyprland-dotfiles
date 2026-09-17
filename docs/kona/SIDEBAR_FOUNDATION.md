# Sidebar foundation — revision 2

**Revision 2 — APPROVED BY MANI.**

Mani requested geometry corrections and superseded the navy shell with frosted white.
Only S01–S03 changed. Mani approved this running foundation before authorizing the S04/S05 header.

Installed shell: monitor-local (0, 0), full 1080px height on DP-4, 300px expanded /
60px collapsed, flush left corners and 14px right corners. White-to-icy-blue gradient,
95% surface opacity, subtle right border and supplied PNG glow restricted to that edge.
This is a lightly translucent finish; no new compositor backdrop-blur rule was added.
The 32px control has a centered 16px supplied SVG, tinted slate, and centers at x=30
in the collapsed rail. Shared dark primitives remain unchanged unless the shell opts in.

Slide/collapse timing, state owner, Settings persistence, bubble WAV, keyboard activation,
Reduced/Off policy and fullscreen layer policy remain intact. No content or new owner.
Existing music popup, Waybar, services and wallpaper configuration remain untouched.
The on-demand overlay reserves no work area; it overlays existing surfaces at its edge.
Launch **Kona Sidebar** or `kona-sidebar show`; Escape / `kona-sidebar close` dismisses it.

Validation on native Quickshell 0.3.1 / Qt 6.11.2:
- Five QML behavior tests pass (seven including setup/cleanup), including exact icon/control
  centering, intent ownership, keyboard/disabled behavior and reduced/interrupted motion.
- Native pointer/keyboard collapse, one bubble activation per action, remembered collapse
  and Escape pass. Native sound loaded Ready. No new QML runtime errors observed.
- Expanded/collapsed rendered screenshots inspected at native scale; 6.9s pre-reboot
  transition clip decoded and inspected through entry, collapse, expand and exit.
- Reboot recovery: unchanged source/live hashes; fresh native render/capture succeeds.
  Post-reboot media is under `post-reboot/`; previous evidence is retained.
- Original fullscreen checks remain valid for the unchanged layer policy. An extra fixture
  attempt aborted on its own geometry precondition before test input; see ADVERSE.md.
- Scope audit identifies only the three intended product QML files, in source and live.
  Existing client geometry was restored after interaction QA. Noninteractive capture saw
  normal user movement / Steam startup; no attempt was made to undo those user changes.

Changed product files: `sidebar/shell.qml`, `sidebar/qml/SidebarView.qml`,
`sidebar/qml/components/KSurface.qml` under `.config/quickshell/kona/`.
Also changed: `tests/tst_sidebar.qml`, review decisions, this report and project handoff.
HEAD `dac844f554e37eef9368fbf26860be65237422de`; accepted dirty tree retained.

Evidence/backups: `~/.local/state/kona/sidebar-foundation-r2-20260914/`.
Review `post-reboot/expanded.png`, `post-reboot/collapsed.png`,
`post-reboot/expand-collapse.mp4`. This clip is silent. Human aesthetic/audio approval
belongs to Mani; no native screen-reader certification or new touch gesture is claimed.
Pre-reboot system errors are preserved; reboot cause is not established.

Rollback: close only the sidebar, verify current live hashes against `deployed.json`,
then restore the three corresponding files from `backup/live/`. Source backups are in
`backup/repo/`. Do not run the original R1 removal rollback for this in-place revision.
Prior R1 report and adverse evidence remain in the backup and original evidence directory.
No Git history/remote operations, owner cutover, UWSM changes or later components.
