# Upstream UI credits

Kona uses upstream Linux desktop work where it is stronger than a local
replacement. Upstream copyright and license terms continue to apply.

- [Caelestia shell](https://github.com/caelestia-dots/shell), GPL-3.0-only:
  dashboard, media, performance, workspace, audio and session presentation,
  plus the expressive spatial motion curves used by Kona's hybrid left rail.
  Kona launches these components transiently from the installed Arch package
  and supplies a derived Konata-blue colour cache. See
  `third_party/licenses/caelestia-shell-GPL-3.0.txt`.
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), GPL-3.0:
  live workspace overview, unified search, notification center and popups,
  Intelligence/Translator/Anime sidebar, and keybinding cheat sheet at revision
  `2f0c8bf42b803f4d597572f2a014d4e78d7d9f26`. The pinned source is installed
  outside the repository and remains GPL-covered. See
  `third_party/licenses/end-4-dots-GPL-3.0.txt`.
- [rounded-polygon-qmljs](https://github.com/end-4/rounded-polygon-qmljs),
  Apache-2.0: Material shape support used by the pinned end-4 overview at
  revision `e31ec4cb4ebf6a46b267f5c42eabf6874916fa16`. See
  `third_party/licenses/rounded-polygon-qmljs-Apache-2.0.txt`.

The Kona left rail keeps its existing application, workspace, music, weather,
quick-control, desktop, system and tools navigation. Caelestia supplies its
visual grouping and motion grammar rather than replacing that information
architecture.

Kona keeps lock, wallpaper, appearance, audio-backend and session ownership.
The pinned end-4 notification service is intentionally the one notification
owner; it does not duplicate SwayNC or another notification history store.
