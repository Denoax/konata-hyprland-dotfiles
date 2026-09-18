#!/usr/bin/env python3
"""Behavior contracts for the native SwayNC notification-center controls."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from gi.repository import GLib

ROOT = Path(__file__).resolve().parents[1]
CONFIG = Path(os.environ.get("KONA_CONTROL_CONFIG", ROOT / ".config/swaync/config.json"))


class ControlActions(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kona control qa ")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.log = self.home / "calls"
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.home / "state"),
            "PATH": str(self.bin) + ":" + os.environ["PATH"],
            "CALLS": str(self.log),
        }
        config = json.loads(CONFIG.read_text())
        self.actions = config["widget-config"]["buttons-grid#quick"]["actions"]
        self.session = config["widget-config"]["buttons-grid#actions"]["actions"]

    def fake(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def action(self, word):
        return next(action for action in self.actions if word.casefold() in action["label"].casefold())

    def run_action(self, word, state="", field="command"):
        command = self.action(word)[field]
        argv = GLib.shell_parse_argv('/bin/sh -c "' + command + '"')[1]
        return subprocess.run(
            argv,
            env={**self.env, "SWAYNC_TOGGLE_STATE": state},
            capture_output=True,
            text=True,
            timeout=5,
        )

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_dnd_uses_native_swaync_state_without_another_store(self):
        self.fake("swaync-client", 'printf "%s\\n" "$*" >> "$CALLS"; [ "$1" != "-D" ] || echo true')
        self.fake("kona-menu-sound", "exit 0")
        self.assertEqual(self.run_action("DISTURB", "true").returncode, 0)
        self.assertEqual(self.run_action("DISTURB", "false").returncode, 0)
        self.assertEqual(self.calls(), ["-dn", "-df"])
        query = self.run_action("DISTURB", field="update-command")
        self.assertEqual(query.stdout.strip(), "true")

    def test_focus_routes_both_transitions_through_profile_owner(self):
        self.fake("kona-profile", 'printf "%s\\n" "$*" >> "$CALLS"; [ "$1" != status ] || echo \'{"profile":"focus"}\'')
        self.fake("kona-menu-sound", "exit 0")
        self.assertEqual(self.run_action("FOCUS", "true").returncode, 0)
        self.assertEqual(self.run_action("FOCUS", "false").returncode, 0)
        self.assertEqual(self.calls(), ["set focus", "set daily"])
        self.assertEqual(self.run_action("FOCUS", field="update-command").stdout.strip(), "true")

    def test_invalid_toggle_state_has_no_side_effect(self):
        for name in ("swaync-client", "kona-profile", "kona-record", "kona-record-status", "kona-menu-sound"):
            self.fake(name, 'echo unexpected >> "$CALLS"')
        for word in ("DISTURB", "FOCUS", "RECORD"):
            self.assertEqual(self.run_action(word, "invalid").returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_recording_respects_existing_status_and_record_owners(self):
        self.fake("kona-menu-sound", "exit 0")
        self.fake("kona-record", 'echo "$*" >> "$CALLS"')
        self.fake("kona-record-status", 'echo \'{"class":"idle"}\'')
        self.assertEqual(self.run_action("RECORD", "false").returncode, 0)
        self.assertEqual(self.run_action("RECORD", "true").returncode, 0)
        self.fake("kona-record-status", 'echo \'{"class":"recording"}\'')
        self.assertEqual(self.run_action("RECORD", "true").returncode, 0)
        self.assertEqual(self.run_action("RECORD", "false").returncode, 0)
        self.assertEqual(self.calls(), ["output", "output"])

    def test_quick_actions_preserve_existing_system_owners(self):
        rendered = json.dumps(self.session)
        for owner in ("systemsettings", "kona-session-menu", "hyprlock"):
            self.assertIn(owner, rendered)
        logout = next(action for action in self.session if action["label"] == "Log Out")
        self.assertIn("kona-session-menu", logout["command"])
        self.assertNotIn("hyprctl dispatch", logout["command"])
        self.assertNotIn("systemctl", logout["command"])


if __name__ == "__main__":
    unittest.main()
