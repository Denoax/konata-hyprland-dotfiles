# Kona end-4 overview overlay

This overlay runs the live workspace overview/unified search, the
Intelligence/Translator/Anime sidebar, and the keybinding cheat sheet from
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) at the pinned
revision installed by `kona-install-upstream-ui`.

The upstream QML remains GPL-3.0 and copyright its contributors. Kona supplies
an isolated transient lifecycle and derives its Material colours from
`kona-appearance`. The process exits with the overview and does not load the
upstream notification, lock, wallpaper, bar, audio, or session owners.
The assistant defaults to chat-only mode; model-issued shell/config tools
require an explicit user opt-in. API keys use the host Secret Service through
end-4's upstream keyring integration. Anime search defaults to safe results.
