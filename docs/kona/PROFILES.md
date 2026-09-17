# Profiles and scenes

Use **Super+Ctrl+P** or **Profiles** in the Desktop/quick-settings menu.
The menu reuses Task05's approved list surface. Super+Shift+W remains the wallpaper picker.

| Profile | Wallpaper backend | Effects and bar | Background work |
|---|---|---|---|
| daily | Awww, selected scene | Restores normal animation/blur/shadow, VRR/tearing and bar state | Existing event-driven history |
| focus | Hyprpaper, static scene equivalent | Animation/blur/shadow off; bar hidden | Existing CAVA paused |
| gaming | Hyprpaper, static scene equivalent | Effects off; bar hidden; VRR 1, tearing master enabled | Awww stopped, CAVA paused, background thumbnails gated |
| showcase | Awww, selected scene | Animation/blur/shadow enabled; normal bar | Selected animation allowed |

The normal daily wallpaper is still the accepted simple image. Daily retains explicit
animated selections; showcase does not silently change the selected scene. CAVA is not
installed or launched by this task. Only an already running instance is paused, and only
the same PID/start identity is resumed. A previously stopped instance is left stopped.
Explicit recording is never stopped by a profile transition. The explicit ten-card
overview stays available in gaming; only background history captures are gated.
Existing SwayNC fullscreen notification policy remains authoritative; DND is not changed.
Tearing/VRR master settings do not prove game eligibility, frame pacing or latency gains.

## State and compatibility

`kona-profile status` is read-only. `kona-state` retains schema 1 and its existing nested
fields, with separate `profile` and `scene` fields. Profile intent is stored in
`$XDG_STATE_HOME/kona/profile.json`; existing `$XDG_STATE_HOME/kona-wallpaper-mode`
remains the sole selected-scene owner. Scene names are aliases for accepted assets:

| Scene | Existing mode | Focus/gaming rendering |
|---|---|---|
| midnight | simple | Same approved simple image |
| constellation | static | Three existing static monitor images |
| constellation-motion | animated | Corresponding static images; animated selection retained |

Commands: `kona-profile set {daily,focus,gaming,showcase}`,
`kona-profile scene {midnight,constellation,constellation-motion}`.
Existing `kona-wallpaper {simple,static,animated,toggle,restore,status}` and
`kona-game-mode {on,off,toggle,status,waybar,reconcile}` remain compatible.
Gaming retains the accepted OSD enabled/disabled feedback, once per real state change.
Gaming `off` restores the profile that preceded gaming, including focus or showcase.
Selecting daily restores the captured normal session policy. Repeated profile selections
and gaming on/off do not repeat effects, signals or durable writes.

The Task03 gaming module is intentionally empty while inactive. Gaming hides the bar;
use the profile shortcut or the Task04 Control Center to leave it. If the bar is manually
shown, its existing active gaming action still works.

## Ownership and recovery

One transient coordinator serializes profile and scene changes using the existing
`$XDG_RUNTIME_DIR/kona-wallpaper.lock`. The existing wallpaper script applies the backend;
no new daemon or polling loop is introduced. A replacement backend is populated before
the previous wallpaper backend is stopped. Installed Hyprpaper 0.8.4 uses its current
`wallpaper`/`listactive` IPC, including explicit detection of hyprctl's exit-zero error text.

Normal effects/bar/CAVA identities and an unfinished transaction live under
`$XDG_RUNTIME_DIR/kona/`. Intent commits after runtime application. A failure attempts
rollback; incomplete rollback retains the journal and returns an actionable error.
After repairing the reported backend/IPC problem, run `kona-profile reconcile` to retry
recovery and apply durable intent. Do not delete the journal to hide a failed transition.
The Hyprland reload callback reconciles through the existing gaming entrypoint.
At login, a bounded startup helper waits for Waybar, restores the saved profile and scene,
and regenerates the selected scene's palette. No session-restart test or login timing
claim is made by Task06; startup contracts are covered in isolated recovery tests.

Task06 rollback copies, the accepted dirty-tree baseline, adverse runs and validation
live in `~/.local/state/kona/task06-20260913-215052`.
Task01–Task05 approvals remain authoritative. Task07 is not started.

## Measurement limits

On the current NVIDIA desktop with the same simple image on three outputs, Hyprpaper
raises aggregate PSS relative to static Awww. The required backend policy is preserved;
focus/gaming reduce rendered effects and background work, with no blanket claim of
lower measured idle memory or CPU. Animated-scene cost is reported separately and
returns to static cost without an Awww restart when the normal image is restored.
See the Task06 evidence report for raw windows, component attribution and unchanged
absolute core/dock alarms. No game frametime or GPU-time claim is made.
