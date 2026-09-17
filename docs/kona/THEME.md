# Kona theme ownership

Task02 separates colors from the existing four consumer layouts. The semantic
source is `.config/kona/theme/palette.json`. Its curated midnight surfaces, ice
text and success/warning/danger colors remain fixed during image generation.
`kona-theme` runs once per successful wallpaper operation and exits. There is no
theme service, timer, watcher or frame inspection.

|Tokens|Meaning|
|---|---|
|`bg.0`, `bg.1`, `bg.2`, `bg.translucent`|Deepest, normal, elevated and glass surfaces|
|`text.primary`, `text.secondary`, `text.disabled`|Ice text, muted text, disabled text|
|`accent.primary`, `accent.secondary`, `accent.on`|Interactive accent, secondary highlight, selection text|
|`accent.border`|Second focused-border gradient stop; preserves legacy blue in cyan fallback|
|`line.subtle`, `line.active`|Translucent outline and active outline|
|`state.success`, `state.warning`, `state.danger`|Stable semantic state colors|
|`shadow.soft`, `glow.active`|Shadow and active-state glow colors|

Colors are `#rrggbb` or `#rrggbbaa`. Required text/base and selection contrast is
at least 4.5:1; active accent/elevated surface at least 3:1. Disabled text is not
presented as normal readable content. Dynamic accents retain the extracted hue,
constrain HLS saturation/lightness, then enforce selection contrast and at least
1.5:1 against white. That last bound is not a claim of universal border visibility:
existing one-pixel borders must also be inspected on actual dark/bright wallpapers.

Matugen supplies only candidate primary/secondary colors. Its Material surfaces,
state colors, user templates, hooks and wallpaper actions are never activated.
The helper uses the existing Python standard library (explicit `python` manifest
entry for recovery). The official Arch package is `matugen` in `packages/pacman.txt`; no AUR/Cargo/vendor
installation or fallback extractor is included. The installed Matugen4.2.0 interface was verified with five distinct real image inputs:

```sh
matugen image /absolute/wallpaper --config ~/.config/kona/theme/matugen.toml \
  --dry-run --source-color-index 0 --mode dark --json hex
```

Modern JSON is read from `colors.primary.dark.color` and
`colors.secondary.dark.color`. Kona renders its own small application adapters
from constrained tokens, so no obsolete Matugen template syntax is involved.
Interface provenance: [upstream CLI source](https://github.com/InioX/matugen/blob/main/src/util/arguments.rs)
and [JSON serializer](https://github.com/InioX/matugen/blob/main/src/util/color.rs).
Matugen4.2 requires an explicit empty `[templates]` table even for dry-run JSON;
this is covered by the installed-Matugen regression test.

`kona-wallpaper simple` uses `v2/selected.png`; static/animated use the center image
of the three-output set. Outputs retain their current ordering and Awww behavior.
A wallpaper-operation lock serializes the whole operation; every output must
succeed before the mode is persisted and exactly one theme call runs. Animated
frames cause no extra theme work. Theme failure returns a diagnostic but leaves
the successful wallpaper operation usable.

```sh
kona-theme --image /path/to/image.png   # explicit regeneration / wallpaper hook
kona-theme --default                   # restore curated cyan
kona-theme --default --no-reload       # offline/recovery use
```

The helper serializes generation with a bounded flock wait, gives Matugen 30s,
and validates the entire candidate before activation. Five files are written and
fsynced in a staging directory, renamed to a complete generation, then one `current`
symlink is atomically replaced. Consumers never read partially written fragments.
Current and previous generations are retained; older owned generations are removed.
Readers needing multiple files as a snapshot should resolve `current` once.

- `current/tokens.json`: active constrained semantic palette.
- `current/waybar.css`: GTK named-color aliases; existing layout imports it.
- `current/rofi.rasi`: shared Rasi color aliases; next invocation reads it.
- `current/swaync.css`: existing SwayNC CSS color variables.
- `current/hyprland.colors`: two RGB lines, never executable generated Lua.

`default/` is a checked-in, test-verified rendering of `palette.json`; the shipped
`current -> default` link works before Matugen has ever run. Missing image, missing
Matugen, timeout, malformed/empty palette, invalid contrast or generation failure
retain a complete known-good theme, otherwise install the cyan fallback. Failed
commands return nonzero and explain the failure. Hyprland independently rejects
missing/corrupt border data and uses the accepted cyan/blue borders. Manual damage
to imported CSS is repaired by the next helper invocation; application imports
are not an autonomous repair service.

Only changed consumer fragments reload. Waybar already has `reload_style_on_change`
enabled in the accepted config. The helper rewrites identical bytes to its stable
stylesheet to trigger the native GIO modify/changes-done event after atomic
activation. This CSS-only reload preserves its module instances and layer surfaces;
a symlink swap alone cannot update the watched old generation inode. SIGUSR2 is
not used: testing Waybar0.15.0 found about1.7MiB retained per full module reload.
No watcher process or polling is added. SwayNC uses `--skip-wait --reload-css`, Hyprland uses
`hyprctl eval` to apply only general/group active border colors. Rofi has no resident
reload. Identical generated output does not activate another generation or reload.
Waybar style notification confirms the filesystem event, not an application-level
acknowledgment; actual default/generated rendered cases validate the consumer.
Failed consumer reloads are recorded for retry on the next helper invocation; valid
files remain active. `--no-reload` explicitly suppresses reloads for offline work.

Installer/recovery copies the fallback and backs up existing Kona config. The backup
helper copies source/default material, excluding runtime generations, locks, active
pointer and reload retry state. It preserves the repository's default pointer.
Do not invoke `kona-backup` merely to test theme installation: its pre-existing Git
commit/push behavior is unrelated to theme generation.

Optional dock/OSD/Kitty/CAVA styles and static calendar markup remain unchanged.
Task01 event/state workers, module cadence, layouts, monitors and gaming/recording
behavior remain owned by their existing implementations. No Task03 work is included.

Tests: `python3 tests/theme.py`, `python3 tests/wallpaper-theme.py`, existing Task01
worker tests and `./tests/recovery-smoke.sh`. Native CSS/Rasi parsing and real-image,
rendered desktop, contrast and idle-resource evidence are separate acceptance steps.
