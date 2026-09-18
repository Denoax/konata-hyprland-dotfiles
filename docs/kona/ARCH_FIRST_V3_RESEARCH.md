# Arch-first V3 research

Reviewed 2026-09-16: the three supplied TikTok clips, Serpantinum `40df5d3`, Caelestia Shell `9245237`, end-4 dots `2f0c8bf`, current Kona V2, and `legacy/pre-kona-2026.09`.

## Why the references read as Linux/Hyprland

The Linux identity comes from visible composition and control: real applications remain distinct windows, layouts transform through compositor motion, terminals expose recognizable upstream tools, and information appears only when summoned. Small gaps, thin borders, modest rounding, translucent backgrounds, monospaced type, and large quiet areas make those mechanics legible. The desktop does not hide its window manager behind a permanent dashboard or imitate system data in custom cards.

## Direction selected

- Keep V2 quiet; make the Arch layer a transient `special:arch` workspace.
- Use three real Kitty windows: Btop, Fastfetch with the classic Arch mark plus an interactive shell, and CAVA. The single right-side system pane keeps identity and machine facts together without a decorative fourth terminal.
- Let Hyprland provide the reveal and window composition. Use 6–10 px spacing, 1 px semantic borders, 8 px rounding, restrained opacity/blur, and the existing JetBrainsMono Nerd Font.
- Give CAVA a wide, short region and leave deliberate negative space inside every terminal. Prefer muted semantic accent and text over multicolour graphs.
- Keep the regular terminal equally native: a focused Kitty window, Fish history autosuggestions, and a sparse semantic prompt. Both `Alt+Enter` and the established `Super+Enter` entrypoint open it.
- Reuse `kona-appearance` output through Kitty; do not add palette state or a resident manager.
- Keep identity hierarchy candidate A: `KONA` / `Arch Linux · Hyprland` / active profile. Arch is proven by behavior and tools; one existing Waybar glyph is enough branding.

## Rejected carry-over

- Legacy dashboard orchestration and shader collection: useful inventory, obsolete composition.
- Permanent telemetry, large shell-owned cards, fake terminal content, stock green Matrix styling, and arbitrary sleep-based placement.
- Copying Serpantinum, Caelestia, or end-4 shell structures: they validate restraint, token consistency, and smooth transitions, but Kona's existing owners remain authoritative.
