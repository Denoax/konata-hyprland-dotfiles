#!/usr/bin/env python3
"""Reuse the accepted host lifecycle contracts for the sibling sidebar launcher."""
import importlib.util
from pathlib import Path
import subprocess
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('music_contracts', HERE / 'music-popup.py')
contracts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contracts)
contracts.HOST = HERE.parent / '.local/bin/kona-sidebar'

class SidebarHost(contracts.MusicHost):
    def test_removed_quote_commands_cannot_start_or_modify_sidebar(self):
        for args in [('quote',), ('quote', 'maybe'), ('quote', 'on'), ('quote', 'off'), ('quote', 'on', 'extra')]:
            result = subprocess.run([str(contracts.HOST), *args], env=self.env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'kona/sidebar.lock').exists())

    def test_invalid_gain_does_not_create_state_or_launch(self):
        for value in ('nan', '-1', '0.6', 'invalid'):
            with self.subTest(value=value):
                result = subprocess.run([str(contracts.HOST), 'gain', value], env=self.env, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'state/kona/sidebar.ini').exists())

    def test_sound_change_requires_running_owner(self):
        result = subprocess.run([str(contracts.HOST), 'mute'], env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b'Open the sidebar', result.stderr)

if __name__ == '__main__':
    unittest.main(verbosity=2)
