# Kona Caelestia visual overlays

This directory contains Kona's small integration overlay for the upstream
[Caelestia shell](https://github.com/caelestia-dots/shell). The dashboard,
media, performance, workspace components, and their supporting QML are loaded
from the installed `caelestia-shell` package. They remain GPL-3.0-only and
copyright their upstream contributors.

Kona supplies only the transient window lifecycle and a derived colour cache.
The dashboard, audio and session surfaces each exit when closed. The audio
surface is a transient PipeWire client. Session buttons call
`kona-session-action`, which retains Kona's confirmations and delegates to
Hyprlock, Hyprland or systemd. These overlays do not replace Kona's
notification, appearance, wallpaper, lock, audio-backend or session owners.
