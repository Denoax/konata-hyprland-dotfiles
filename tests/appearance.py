#!/usr/bin/env python3
"""System appearance owner contracts in an isolated HOME with fake host adapters."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class AppearanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / "bin"
        self.local_bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.local_bin.mkdir(parents=True)
        for name in ("kona-appearance", "kona-theme", "kona-preferences"):
            shutil.copy2(ROOT / ".local/bin" / name, self.local_bin / name)
        config = self.home / ".config"
        shutil.copytree(ROOT / ".config/kona/theme", config / "kona/theme", symlinks=True)
        shutil.copytree(ROOT / ".config/kona/appearance", config / "kona/appearance")
        for version in ("3.0", "4.0"):
            path = config / f"gtk-{version}/settings.ini"
            path.parent.mkdir()
            path.write_text("[Settings]\ngtk-application-prefer-dark-theme=true\nkept=yes\n")
        (config / "kdeglobals").write_text("[General]\nColorScheme=MateriaManjaro\n")
        self.system = self.home / "system-mode"
        self.qt = self.home / "qt-mode"
        self.system.write_text("prefer-dark")
        self.qt.write_text("MateriaManjaro")
        self.make_fake("gsettings", """
import os,sys
from pathlib import Path
p=Path(os.environ['TEST_SYSTEM_MODE'])
if sys.argv[1]=='get': print(repr(p.read_text().strip()))
elif sys.argv[1]=='set': p.write_text(sys.argv[-1])
else: sys.exit(2)
""")
        self.make_fake("gdbus", """
import os
from pathlib import Path
value=Path(os.environ['TEST_SYSTEM_MODE']).read_text().strip()
if os.environ.get('TEST_PORTAL_STUCK')=='1': value='prefer-dark'
print('(<<uint32 %s>>,)' % (2 if value=='prefer-light' else 1))
""")
        self.make_fake("kreadconfig6", """
import os
from pathlib import Path
print(Path(os.environ['TEST_QT_MODE']).read_text().strip())
""")
        self.make_fake("plasma-apply-colorscheme", """
import os,sys
from pathlib import Path
Path(os.environ['TEST_QT_MODE']).write_text(sys.argv[-1])
print('Applied '+sys.argv[-1])
""")
        self.make_fake("qdbus6", "pass")
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(config),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "XDG_RUNTIME_DIR": str(self.home / "runtime"),
            "PATH": str(self.bin) + ":/usr/bin:/bin",
            "TEST_SYSTEM_MODE": str(self.system),
            "TEST_QT_MODE": str(self.qt),
        }
        self.env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)

    def make_fake(self, name, body):
        path = self.bin / name
        path.write_text("#!/usr/bin/python3\n" + body.strip() + "\n")
        path.chmod(0o755)

    def call(self, *arguments, env=None):
        return subprocess.run(
            [str(self.local_bin / "kona-appearance"), *arguments],
            env=env or self.env, capture_output=True, text=True, timeout=12,
        )

    def assert_mode(self, mode):
        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        value = json.loads(result.stdout)
        self.assertEqual(value["mode"], mode)
        self.assertTrue(value["synchronized"])
        self.assertEqual(value["portal"], 2 if mode == "light" else 1)
        self.assertEqual(value["qt"], "BreezeLight" if mode == "light" else "BreezeDark")
        self.assertEqual(value["theme"], mode)
        published = json.loads((self.home / ".config/kona/appearance/current.json").read_text())
        self.assertEqual(published["mode"], mode)
        expected = "false" if mode == "light" else "true"
        for version in ("3.0", "4.0"):
            source = (self.home / f".config/gtk-{version}/settings.ini").read_text()
            self.assertIn("gtk-application-prefer-dark-theme=" + expected, source)
            self.assertIn("kept=yes", source)

    def test_light_dark_toggle_and_idempotent_status(self):
        light = self.call("light")
        self.assertEqual(light.returncode, 0, light.stderr)
        self.assert_mode("light")
        current = (self.home / ".config/kona/theme/current").readlink()
        again = self.call("light")
        self.assertEqual(again.returncode, 0, again.stderr)
        self.assertEqual((self.home / ".config/kona/theme/current").readlink(), current)
        dark = self.call("toggle")
        self.assertEqual(dark.returncode, 0, dark.stderr)
        self.assert_mode("dark")
        state = json.loads((self.home / ".local/state/kona/appearance.json").read_text())
        self.assertEqual(state, {"schema": 1, "mode": "dark", "source": "manual"})

    def test_portal_failure_rolls_back_system_toolkits_theme_and_state(self):
        self.assertEqual(self.call("dark").returncode, 0)
        before_theme = (self.home / ".config/kona/theme/current").readlink()
        before_kde = (self.home / ".config/kdeglobals").read_bytes()
        failed_env = {**self.env, "TEST_PORTAL_STUCK": "1"}
        result = self.call("light", env=failed_env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("portal did not publish light", result.stderr)
        self.assertEqual(self.system.read_text(), "prefer-dark")
        self.assertEqual(self.qt.read_text(), "BreezeDark")
        self.assertEqual((self.home / ".config/kona/theme/current").readlink(), before_theme)
        self.assertEqual((self.home / ".config/kdeglobals").read_bytes(), before_kde)
        self.assert_mode("dark")


if __name__ == "__main__":
    unittest.main()
