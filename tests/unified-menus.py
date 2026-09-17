#!/usr/bin/env python3
"""Static contracts for the unified transient/menu surface pass."""
import json
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class UnifiedMenus(unittest.TestCase):
    def text(self, relative):
        return (ROOT / relative).read_text()

    def test_frost_tokens_are_shared_by_rofi_swaync_and_osd(self):
        rofi = self.text('.config/rofi/shared.rasi').lower()
        swaync = self.text('.config/swaync/style.css').lower()
        osd = self.text('.config/swayosd/style.css').lower()
        self.assertIn('../kona/theme/current/rofi.rasi', rofi)
        self.assertIn('../kona/theme/current/swaync.css', swaync)
        self.assertIn('../kona/theme/current/swayosd.css', osd)
        for source in (rofi, swaync, osd):
            self.assertIn('@kona_' if source != rofi else '@fg', source)
        dark = json.loads(self.text('.config/kona/appearance/dark.json'))
        light = json.loads(self.text('.config/kona/appearance/light.json'))
        self.assertEqual(dark['accent'], '#7FAEFF')
        self.assertEqual(light['accent'], '#78A9FF')

    def test_command_center_preserves_swaync_as_owner(self):
        dashboard = self.text('.local/bin/kona-dashboard')
        self.assertIn('swaync-client --open-panel --skip-wait', dashboard)
        self.assertNotIn('kona-shell', dashboard)
        bindings = self.text('.config/hypr/hyprland.lua')
        self.assertIn('kona-dashboard', bindings)

    def test_swaync_actions_keep_existing_backend_owners(self):
        config = json.loads(self.text('.config/swaync/config.json'))
        rendered = json.dumps(config)
        for owner in ('nmcli', 'kona-night-light', 'kona-game-mode', 'kona-record',
                      'kona-overview', 'kona-audio-menu', 'kona-session-menu'):
            self.assertIn(owner, rendered)
        self.assertEqual(config['transition-time'], 200)
        self.assertEqual(config['text-empty'], 'No notifications')

    def test_destructive_session_actions_are_cancel_first(self):
        session = self.text('.local/bin/kona-session-menu')
        confirm = self.text('.local/bin/kona-confirm')
        for action in ('hyprctl dispatch', 'systemctl reboot', 'systemctl poweroff'):
            self.assertIn(action, session)
        self.assertGreaterEqual(session.count('kona-confirm'), 3)
        self.assertIn("printf '%s\\n' 'Cancel'", confirm)
        self.assertIn('-selected-row 0', confirm)

    def test_clipboard_clear_and_delete_require_confirmation(self):
        source = self.text('.local/bin/kona-clipboard')
        self.assertIn("-kb-custom-1 'Alt+d'", source)
        self.assertIn("-kb-custom-2 'Alt+c'", source)
        self.assertIn("cliphist delete", source)
        self.assertIn("cliphist wipe", source)
        self.assertGreaterEqual(source.count('kona-confirm'), 2)

    def test_no_new_persistent_owner_for_transient_menus(self):
        manifest = self.text('packages/kona-user-units.txt')
        for forbidden in ('menu', 'rofi', 'network', 'bluetooth', 'sound'):
            self.assertNotIn(forbidden, manifest.casefold())
        sound = self.text('.local/bin/kona-menu-sound')
        self.assertIn('pw-play', sound)
        self.assertNotIn('systemctl', sound)

    def test_pack_assets_are_installed_as_individual_assets(self):
        icon_dir = ROOT / '.config/kona/menus/icons'
        self.assertEqual(len(list(icon_dir.glob('*.svg'))), 25)
        self.assertGreater((ROOT / '.config/kona/menus/bubble-click.wav').stat().st_size, 100)

    def test_reduced_motion_maps_to_swaync_without_a_new_owner(self):
        model = runpy.run_path(str(ROOT / '.local/bin/kona-motion'))
        with tempfile.TemporaryDirectory() as directory:
            config_root = Path(directory) / 'kona'
            swaync = config_root.parent / 'swaync/config.json'
            swaync.parent.mkdir()
            swaync.write_text(json.dumps({
                'transition-time': 200,
                'kept': True,
                'widget-config': {'menubar#system': {'menu#tools': {
                    'animation-type': 'slide_down', 'animation-duration': 190}}}
            }))
            with patch.dict(model['sync_swaync_motion'].__globals__, ROOT=config_root), \
                    patch('subprocess.run') as run:
                model['sync_swaync_motion']('reduced', 'daily')
                reduced = json.loads(swaync.read_text())
                self.assertEqual(reduced['transition-time'], 0)
                self.assertEqual(reduced['widget-config']['menubar#system']['menu#tools']['animation-type'], 'none')
                model['sync_swaync_motion']('full', 'daily')
                restored = json.loads(swaync.read_text())
                self.assertEqual(restored['transition-time'], 200)
                self.assertEqual(restored['widget-config']['menubar#system']['menu#tools']['animation-type'], 'slide_down')
                self.assertEqual(run.call_count, 2)

    def test_small_rofi_text_meets_normal_text_contrast(self):
        def luminance(value):
            channels = [int(value[index:index + 2], 16) / 255 for index in (1, 3, 5)]
            channels = [channel / 12.92 if channel <= .04045
                        else ((channel + .055) / 1.055) ** 2.4 for channel in channels]
            return .2126 * channels[0] + .7152 * channels[1] + .0722 * channels[2]
        def ratio(foreground, background):
            values = sorted((luminance(foreground), luminance(background)))
            return (values[1] + .05) / (values[0] + .05)
        self.assertGreaterEqual(ratio('#5b6b80', '#ffffff'), 4.5)
        self.assertGreaterEqual(ratio('#b73d4b', '#e3edf9'), 4.5)


if __name__ == '__main__':
    unittest.main()
