#!/usr/bin/env python3
"""Static contracts for the unified transient/menu surface pass."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class UnifiedMenus(unittest.TestCase):
    def text(self, relative):
        return (ROOT / relative).read_text()

    def test_frost_tokens_are_shared_by_rofi_terminal_and_osd(self):
        rofi = self.text('.config/rofi/shared.rasi').lower()
        osd = self.text('.config/swayosd/style.css').lower()
        foot = self.text('.config/foot/foot.ini').lower()
        self.assertIn('../kona/theme/current/rofi.rasi', rofi)
        self.assertIn('../kona/theme/current/swayosd.css', osd)
        self.assertIn('@fg', rofi)
        self.assertIn('@kona_', osd)
        self.assertIn('kona/theme/current/foot.ini', foot)
        dark = json.loads(self.text('.config/kona/appearance/dark.json'))
        light = json.loads(self.text('.config/kona/appearance/light.json'))
        kona = json.loads(self.text('.config/kona/appearance/kona.json'))
        self.assertEqual(dark['accent'], '#8EB8FF')
        self.assertEqual(light['accent'], '#78A9FF')
        self.assertEqual(kona['accent'], '#5C8DDC')
        self.assertEqual(kona['surface'], '#B8CCE8')

    def test_notification_entrypoints_use_the_single_end4_owner(self):
        bindings = self.text('.config/hypr/hyprland.lua')
        self.assertIn('kona-end4-notifications toggle', bindings)
        self.assertNotIn('swaync-client', bindings)
        self.assertIn('kona-end4-notifications toggle', self.text('.config/waybar/config.jsonc'))
        self.assertIn('[bin + "kona-end4-notifications", "toggle"]',
                      self.text('.config/quickshell/kona/sidebar/shell.qml'))

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
