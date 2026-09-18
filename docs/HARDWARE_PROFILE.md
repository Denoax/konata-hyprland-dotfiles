# Reference hardware profile

The checked-in layout describes the workstation where Kona is built and tested.

| Position | Connector | Mode | Workspaces |
| --- | --- | --- | --- |
| Left | `HDMI-A-1` | 1920×1080 at 60 Hz | 1, 4, 7 |
| Center / primary | `DP-4` | 1920×1080 at 240.30 Hz | 2, 5, 8, 10 |
| Right | `HDMI-A-5` | 1920×1080 at 119.98 Hz | 3, 6, 9 |

The profile uses scale 1 and positions the displays at `0x0`, `1920x0` and `3840x0`. A fallback rule places unknown outputs to the right at their preferred mode, but this does not make the complete layout portable.

The original host uses an Intel CPU, NVIDIA graphics and PlasmaLogin. `packages/hardware-mani.txt` records those facts and is not an installation manifest. Choose kernel, firmware, graphics and display-manager packages for your own machine.

Before login on different hardware:

1. run `hyprctl monitors` from a working desktop;
2. update monitor modes, positions and workspace rules in `.config/hypr/hyprland.lua`;
3. review application and GPU packages rather than copying `packages/hardware-mani.txt`;
4. keep a second desktop/session available until the configuration has been verified.
