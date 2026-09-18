# Kona Desktop V3

V3 moves Kona from a themed desktop checkpoint to an Arch-first Hyprland workstation while preserving one owner for every system boundary.

## Highlights

- `Super + Shift + D` opens a native `special:arch` composition with Btop, Fastfetch and CAVA; closing it releases every child.
- Kitty/Fish terminal and scratch workflows share Kona semantic colors and history-based command autosuggestions.
- The auto-hiding Quickshell sidebar replaces the retired dock and centralizes navigation without duplicating backend state.
- One Light/Dark command coordinates Kona surfaces, XDG portal preference, GTK and Qt.
- Weather uses explicit-location Open-Meteo data with bounded caching and no resident poller.
- The music popup keeps MPRIS/PipeWire ownership and one transient CAVA lifecycle.
- Wallpaper Engine Workshop items integrate with the existing profile policy and preserve static Focus/Gaming behavior.
- Hyprlock uses the current Kona backdrop and shared avatar while PAM remains the only authentication owner.
- Rofi, SwayNC and SwayOSD share semantic tokens, focus treatment, motion and sound feedback.

## Runtime and recovery

- Plain Hyprland remains the canonical session.
- Session owners start once from `hyprland.start`; bounded helpers replace polling daemons.
- Appearance and profile changes are transactional and retain rollback state.
- The installer backs up every replaced path and supports a no-write dry-run.
- V3 fixes the polkit login race discovered by the first real post-crash boundary check; one fresh post-fix login remains to close the final stable-tag gate.

## Compatibility boundary

Kona is developed on Arch Linux with Hyprland's native Lua configuration and a three-monitor reference layout. Adapt monitors, input and hardware packages before first login. Wallpaper Engine Web projects remain experimental on the tested NVIDIA stack.

## History

The immediate pre-V3 main is preserved at `legacy/pre-arch-first-v3-2026.09.17`. The older dock/media-deck desktop remains at `legacy/pre-kona-2026.09`.
