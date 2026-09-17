#!/usr/bin/env python3
"""Task03 composition and retained user-action contracts (JSON subset of JSONC)."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BARS = json.loads((ROOT / '.config/waybar/config.jsonc').read_text())


def leaves(bar, modules):
    for name in modules:
        if name.startswith('group/'):
            yield from leaves(bar, bar[name]['modules'])
        else:
            yield name


class WaybarContracts(unittest.TestCase):
    def test_monitor_banks_and_single_information_owners(self):
        banks = {'HDMI-A-1': [1, 4, 7], 'DP-4': [2, 5, 8, 10], 'HDMI-A-5': [3, 6, 9]}
        self.assertEqual({b['output'] for b in BARS}, set(banks))
        self.assertEqual(len({b['id'] for b in BARS}), 3)
        owners = {}
        for bar in BARS:
            workspace = bar['ext/workspaces']
            self.assertEqual(workspace['on-click'], 'activate')
            self.assertFalse(workspace['all-outputs'])
            self.assertFalse(workspace['active-only'])
            self.assertTrue(workspace['ignore-hidden'])
            self.assertFalse(workspace['sort-by-name'])
            self.assertTrue(workspace['sort-by-coordinates'])
            # Hyprland already owns the persistent banks; do not duplicate writable rules.
            lua = (ROOT / '.config/hypr/hyprland.lua').read_text()
            for number in banks[bar['output']]:
                self.assertIn(f'workspace = "{number}", monitor = "{bar["output"]}"', lua)
            self.assertTrue(bar['reload_style_on_change'])
            self.assertEqual(bar['height'] + bar['margin-top'], 38)
            for side in ['left', 'center', 'right']:
                for name in leaves(bar, bar['modules-' + side]):
                    owners.setdefault(name, []).append(bar['output'])
        for name in ['clock', 'pulseaudio', 'network', 'custom/recording', 'custom/gaming']:
            self.assertEqual(owners[name], ['DP-4'])
        for name in ['tray', 'custom/notifications', 'cpu', 'memory', 'custom/gpu']:
            self.assertEqual(owners[name], ['HDMI-A-5'])
        self.assertEqual(set(owners['ext/workspaces']), set(banks))
        self.assertNotIn('hyprland/workspaces', owners)
        self.assertEqual(owners['hyprland/window'], ['HDMI-A-1'])

    def test_existing_commands_remain_available(self):
        modules = {k: v for b in BARS for k, v in b.items() if isinstance(v, dict)}
        actions = {
            ('custom/kona', 'on-click'): 'rofi -show drun -theme ~/.config/rofi/konata.rasi',
            ('custom/kona', 'on-click-right'): '~/.local/bin/kona-quick-settings',
            ('network', 'on-click'): 'nm-connection-editor',
            ('pulseaudio', 'on-click'): 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle',
            ('pulseaudio', 'on-click-right'): 'pavucontrol',
            ('custom/recording', 'on-click'): '~/.local/bin/kona-record output',
            ('custom/gaming', 'on-click'): '~/.local/bin/kona-game-mode toggle',
            ('custom/notifications', 'on-click'): 'swaync-client -t -sw',
            ('custom/notifications', 'on-click-right'): 'swaync-client -d -sw',
        }
        for (name, action), command in actions.items():
            self.assertEqual(modules[name][action], command)
        self.assertEqual(modules['pulseaudio']['scroll-step'], 5)
        self.assertIn('{calendar}', modules['clock']['tooltip-format'])
        self.assertIn('%V', modules['clock']['format-alt'])
        self.assertEqual(modules['hyprland/window']['rewrite'][''], 'KONATA@ARCH')
        self.assertEqual(modules['hyprland/window']['max-length'], 42)

    def test_hardware_is_native_drawer_with_existing_cadence(self):
        right = next(b for b in BARS if b['output'] == 'HDMI-A-5')
        group = right['group/hardware']
        self.assertIn('drawer', group)
        self.assertEqual(group['modules'][1:], ['cpu', 'memory', 'custom/gpu'])
        self.assertEqual([right[k]['interval'] for k in group['modules'][1:]], [3, 3, 5])
        self.assertNotIn('exec', right[group['modules'][0]])

    def test_clock_does_not_add_fast_polling_or_a_media_proxy(self):
        center = next(b for b in BARS if b['output'] == 'DP-4')
        self.assertEqual(center['clock']['interval'], 60)
        self.assertEqual(center['clock']['format'], '{:%H:%M}')
        self.assertNotIn('mpris', center)
        self.assertEqual(center['group/time']['modules'], ['clock'])

    def test_style_uses_task02_colors_without_a_slab(self):
        style = (ROOT / '.config/waybar/style.css').read_text()
        self.assertIn('@import "../kona/theme/current/waybar.css";', style)
        self.assertNotRegex(style, r'#[0-9a-fA-F]{6}\b')
        outer = style.split('window#waybar > box {', 1)[1].split('}', 1)[0]
        self.assertIn('background: transparent;', outer)
        self.assertNotIn('box-shadow: 0', style)


if __name__ == '__main__':
    unittest.main()
