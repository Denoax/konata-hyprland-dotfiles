# Recovery

Kona keeps recovery local and scoped. Do not reset the repository to repair one runtime owner.

## Use the Plasma fallback

If Hyprland cannot start, log into the unchanged Plasma session, open a terminal and use a clean Kona checkout:

```bash
./install.sh --dry-run
./install.sh --config-only
```

The installer backs up the exact targets it will replace under `~/.local/state/kona/pre-restore-<timestamp>/`.

## Check the canonical runtime

```bash
hyprctl instances -j
kona-runtime-health ready
kona-runtime-health polkit
systemctl --user --failed
```

The expected result is one canonical Hyprland instance and one active packaged polkit agent. The health check reports duplicate ownership, stale session environment, unavailable endpoints, failed/start-limited state and MainPID disagreement.

## Recover appearance

```bash
kona-appearance status
kona-appearance light   # or kona / dark
```

Appearance changes are transactional. A failed portal/toolkit/theme step restores the prior host preference, toolkit settings, generated fragments and durable intent. Do not edit `.config/kona/theme/current/` to repair a source token; fix the matching file in `.config/kona/appearance/` and apply again.

## Recover profiles and wallpaper

```bash
kona-profile status
kona-profile daily
```

Daily is the conservative recovery profile. Profile changes preserve one wallpaper backend and roll back failed scene transitions. Generated wallpaper assets remain in `.config/kona/wallpapers/`; runtime selection state remains under `~/.local/state/kona/`.

If a Steam Workshop wallpaper fails, restore the prior Kona scene with:

```bash
kona-wallpaper-engine stop
```

The command starts the profile's normal backend before stopping the Workshop renderer. Renderer diagnostics are recorded in `~/.local/state/kona/wallpaper-engine.log`.
The selected Workshop item remains in `~/.local/state/kona/wallpaper-engine.json` after the renderer stops. Daily and Showcase attempt a Scene or Video item once during policy restoration; if startup fails, the policy continues to the accepted Awww scene without retrying. Web items require manual confirmation after login because the recorded compositor crash can prevent in-process recovery. Focus and Gaming always keep their static policy.

## Restore a previous live file

Use the newest matching `pre-restore-*` directory and restore only the affected file or subtree. Keep ownership and executable bits. Then use a scoped reload:

```bash
systemctl --user daemon-reload
hyprctl reload config-only
```

Restart only the affected service. Do not restart the compositor, notification server or unrelated applications to mask a component failure.

Kona masks the packaged `swaync.service` because its D-Bus activation can race the selected notification owner even when the unit is disabled. A deliberate rollback to SwayNC must first restore its backed-up config and then run `systemctl --user unmask swaync.service`; never run both notification servers together.

## Validate an isolated restore

```bash
./tests/recovery-smoke.sh
```

This creates a temporary home, invokes the installer in configuration-only mode, checks current product paths and removes the temporary tree.
