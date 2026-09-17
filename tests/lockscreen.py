#!/usr/bin/env python3
"""Security and integration checks for the native Kona Hyprlock surface."""

from __future__ import annotations

import hashlib
import html
import json
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / ".config/hypr/hyprlock.conf"
ASSETS = ROOT / ".config/kona/lockscreen/mono-rain"
FRAMES = ASSETS / "frames"
HELPER = ASSETS / "kona-lock-rain-frame"


class LockscreenTests(unittest.TestCase):
    def test_approved_production_assets_are_unchanged(self) -> None:
        expected = {
            "avatar/konata-avatar-512.png": "97b3f6ed0d1a77a71c18af7fea273b910dc576c683eb82f13617d343fd17fab4",
            "background/konata-lock-base.png": "507480487cf7181ad57fcb71791b33dd732cb5599edfa356554e80ee14df86e5",
            "background/konata-lock-static-fallback.png": "68058a1cd2105705deee7747890276c7033811a4ad3d401aa99466cc1f724f6c",
        }
        for relative, digest in expected.items():
            actual = hashlib.sha256((ASSETS / relative).read_bytes()).hexdigest()
            self.assertEqual(digest, actual, relative)

    def test_rain_cycle_is_complete_and_downward(self) -> None:
        definition = json.loads((ASSETS / "rain-definition.json").read_text())
        frames = sorted(FRAMES.glob("frame-*.txt"))
        self.assertEqual(80, definition["frames"])
        self.assertEqual(125, definition["update_ms"])
        self.assertEqual(10.0, definition["loop_seconds"])
        self.assertEqual(80, len(frames))
        self.assertTrue(all(speed > 0 for speed in definition["speeds_rows_per_frame"]))
        for frame in frames:
            # Installed frames escape Pango control characters without changing
            # the approved visible stream.
            rows = html.unescape(frame.read_text()).splitlines()
            self.assertEqual(35, len(rows), frame.name)
            self.assertEqual({43}, {len(row) for row in rows}, frame.name)

    def test_rain_helper_is_decorative_only(self) -> None:
        source = HELPER.read_text()
        code = "\n".join(
            line for line in source.splitlines() if not line.lstrip().startswith("#")
        )
        self.assertNotRegex(code, r"\bread\s")
        self.assertNotRegex(code.lower(), r"\b(key|password|pam|stdin|socket)\b")
        self.assertIn("EPOCHREALTIME", source)
        self.assertIn("exec cat", source)
        self.assertIn("(reduced|off)", source)

    def test_reduced_motion_is_a_static_frame(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8") as prefs:
            prefs.write('{"motion":"reduced"}\n')
            prefs.flush()
            result = subprocess.run(
                [str(HELPER)],
                check=True,
                capture_output=True,
                text=True,
                env={
                    "HOME": str(Path.home()),
                    "PATH": "/usr/bin:/bin",
                    "KONA_LOCK_RAIN_DIR": str(FRAMES),
                    "KONA_PREFERENCES": prefs.name,
                },
            )
        self.assertEqual((FRAMES / "frame-000.txt").read_text(), result.stdout)

    def test_hyprlock_owns_authentication_and_native_masking(self) -> None:
        config = CONFIG.read_text()
        self.assertEqual(1, len(re.findall(r"^input-field\s*\{", config, re.M)))
        self.assertIn("hide_input = false", config)
        self.assertIn("animation = inputFieldDots", config)
        self.assertIn("animation = inputFieldColors", config)
        self.assertIn("check_color =", config)
        self.assertIn("fail_color =", config)
        self.assertIn("capslock_color =", config)
        self.assertIn("placeholder_text = Enter password", config)
        self.assertNotIn('foreground="#', config)
        self.assertNotRegex(config.lower(), r"qml|quickshell|password.*cmd")

    def test_single_primary_rain_surface_and_primary_auth_card(self) -> None:
        config = CONFIG.read_text()
        self.assertEqual(1, config.count("cmd[update:125]"))
        self.assertEqual(1, config.count("kona-lock-rain-frame"))
        self.assertIn("monitor = DP-4", config)
        self.assertEqual(3, len(re.findall(r"^background\s*\{", config, re.M)))
        self.assertIn("konata-lock-base.png", config)
        self.assertIn("konata-lock-static-fallback.png", config)


if __name__ == "__main__":
    unittest.main(verbosity=2)
