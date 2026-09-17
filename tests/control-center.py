#!/usr/bin/env python3
"""Run configured toggle commands against isolated device/state boundaries."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from gi.repository import GLib

ROOT = Path(__file__).resolve().parents[1]
CONFIG = Path(os.environ.get('KONA_CONTROL_CONFIG', ROOT / '.config/swaync/config.json'))


class ControlActions(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kona control qa ")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / '.local/bin'
        self.bin.mkdir(parents=True)
        self.log = self.home / 'calls'
        self.env = {**os.environ, 'HOME': str(self.home), 'XDG_STATE_HOME': str(self.home / 'state'),
                    'PATH': str(self.bin) + ':' + os.environ['PATH'], 'CALLS': str(self.log)}
        self.actions = json.loads(CONFIG.read_text())['widget-config']['buttons-grid#quick']['actions']

    def fake(self, name, body):
        p = self.bin / name
        p.write_text('#!/bin/sh\n' + body + '\n')
        p.chmod(0o755)

    def action(self, word):
        return next(a for a in self.actions if word.casefold() in a['label'].casefold())

    def run_action(self, word, state, field='command'):
        return subprocess.run(GLib.shell_parse_argv('/bin/sh -c "' + self.action(word)[field] + '"')[1],
                              env={**self.env, 'SWAYNC_TOGGLE_STATE': state},
                              capture_output=True, text=True, timeout=5)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_wifi_uses_requested_state_and_propagates_failure(self):
        self.fake('nmcli', 'printf "%s\\n" "$*" >> "$CALLS"')
        self.assertEqual(self.run_action('WI-FI', 'true').returncode, 0)
        self.assertEqual(self.run_action('WI-FI', 'false').returncode, 0)
        self.assertEqual(self.calls(), ['radio wifi on', 'radio wifi off'])
        self.fake('nmcli', 'exit 7')
        self.assertEqual(self.run_action('WI-FI', 'true').returncode, 7)
        self.assertNotEqual(self.run_action('WI-FI', 'true', 'update-command').returncode, 0)

    def test_invalid_native_toggle_state_has_no_side_effect(self):
        for name in ['nmcli', 'kona-night-light', 'kona-game-mode', 'kona-record', 'kona-record-status']:
            self.fake(name, 'echo unexpected >> "$CALLS"')
        for word in ['WI-FI', 'NIGHT', 'GAMING', 'RECORD']:
            self.assertEqual(self.run_action(word, 'invalid').returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_night_light_does_not_invert_an_already_matching_state(self):
        self.fake('kona-night-light', 'echo "$*" >> "$CALLS"')
        self.assertEqual(self.run_action('NIGHT', 'false').returncode, 0)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.run_action('NIGHT', 'true').returncode, 0)
        marker = self.home / 'state/kona/night-light-manual'
        marker.parent.mkdir(parents=True)
        marker.touch()
        self.assertEqual(self.run_action('NIGHT', 'true').returncode, 0)
        self.assertEqual(self.run_action('NIGHT', 'false').returncode, 0)
        self.assertEqual(self.calls(), ['toggle', 'toggle'])

    def test_gaming_uses_existing_owner_for_both_transitions(self):
        self.fake('kona-game-mode', 'echo "$*" >> "$CALLS"')
        self.assertEqual(self.run_action('GAMING', 'true').returncode, 0)
        self.assertEqual(self.run_action('GAMING', 'false').returncode, 0)
        self.assertEqual(self.calls(), ['on', 'off'])

    def test_recording_respects_current_identity_and_status_failure(self):
        self.fake('kona-record', 'echo "$*" >> "$CALLS"')
        self.fake('kona-record-status', 'echo \'{"class":"idle"}\'')
        self.assertEqual(self.run_action('RECORD', 'false').returncode, 0)
        self.assertEqual(self.run_action('RECORD', 'true').returncode, 0)
        self.fake('kona-record-status', 'echo \'{"class":"recording"}\'')
        self.assertEqual(self.run_action('RECORD', 'true').returncode, 0)
        self.assertEqual(self.run_action('RECORD', 'false').returncode, 0)
        self.assertEqual(self.calls(), ['output', 'output'])
        self.fake('kona-record-status', 'exit 9')
        self.assertEqual(self.run_action('RECORD', 'true').returncode, 9)
        self.assertEqual(self.calls(), ['output', 'output'])

    def test_queries_reflect_external_changes_without_background_worker(self):
        self.fake('nmcli', 'echo enabled')
        self.assertEqual(self.run_action('WI-FI', '', 'update-command').stdout.strip(), 'true')
        self.fake('nmcli', 'echo disabled')
        self.assertEqual(self.run_action('WI-FI', '', 'update-command').stdout.strip(), 'false')
        self.fake('kona-game-mode', 'echo on')
        self.assertEqual(self.run_action('GAMING', '', 'update-command').stdout.strip(), 'true')
        self.fake('kona-game-mode', 'echo off')
        self.assertEqual(self.run_action('GAMING', '', 'update-command').stdout.strip(), 'false')

    def test_new_device_routes_survive_glib_and_shell_parsing(self):
        self.fake('swaync-client', 'exit 0')
        self.fake('kona-network-menu', 'echo network >> "$CALLS"')
        self.fake('kona-bluetooth-menu', 'echo bluetooth >> "$CALLS"')
        config = json.loads(CONFIG.read_text())
        commands = [self.action('BLUETOOTH')['command']]
        tools = config['widget-config']['menubar#system']['menu#tools']['actions']
        commands += [next(a for a in tools if a['label'].startswith(word))['command']
                     for word in ('Network', 'Bluetooth')]
        for command in commands:
            argv = GLib.shell_parse_argv('/bin/sh -c "' + command + '"')[1]
            result = subprocess.run(argv, env=self.env, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ['bluetooth', 'network', 'bluetooth'])


    def test_backup_requires_exact_confirmation_under_native_parser(self):
        config = json.loads(CONFIG.read_text())
        action = next(a for a in config['widget-config']['menubar#system']['menu#tools']['actions']
                      if a['label'].casefold() == 'backup…')
        self.fake('swaync-client', 'exit 0')
        self.fake('kona-confirm', 'exit "${CONFIRM_STATUS:-1}"')
        self.fake('kona-backup', 'echo backup >> "$CALLS"')
        argv = GLib.shell_parse_argv('/bin/sh -c "' + action['command'] + '"')[1]
        for status, expected in [('1', []), ('0', ['backup'])]:
            result = subprocess.run(argv, env={**self.env, 'CONFIRM_STATUS': status},
                                    capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.calls(), expected)


if __name__ == '__main__':
    unittest.main()
