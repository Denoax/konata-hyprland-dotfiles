#!/usr/bin/env python3
"""Validate Steam Workshop discovery and rejection boundaries without live rendering."""

import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / ".local/bin/kona-wallpaper-engine"
POLICY_COMMAND = ROOT / ".local/bin/kona-wallpaper"


class WallpaperEngineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kona wallpaper engine ")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.state = self.home / "state"
        self.runtime = self.home / "runtime"
        self.state.mkdir()
        self.runtime.mkdir()
        self.proc = self.home / "proc"
        self.proc.mkdir()
        self.steam = self.home / ".var/app/com.valvesoftware.Steam/.local/share/Steam"
        (self.steam / "steamapps/common/wallpaper_engine/assets").mkdir(parents=True)
        self.workshop = self.steam / "steamapps/workshop/content/431960"
        self.environment = {
            **os.environ,
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.state),
            "XDG_RUNTIME_DIR": str(self.runtime),
            "KONA_PROC_ROOT": str(self.proc),
        }

    def item(self, item_id, **project):
        directory = self.workshop / item_id
        directory.mkdir(parents=True)
        (directory / "project.json").write_text(json.dumps(project))
        if project.get("file"):
            (directory / project["file"]).write_text("fixture")
        if project.get("preview"):
            (directory / project["preview"]).write_bytes(b"preview")

    def call(self, *args):
        return subprocess.run([str(COMMAND), *args], env=self.environment,
                              capture_output=True, text=True, timeout=10)

    def executable(self, path, source):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source)
        path.chmod(0o755)

    def test_inventory_reports_supported_and_incompatible_projects(self):
        self.item("100", title="Usable\nWeb", type="web", file="index.html", preview="preview.gif")
        self.item("200", title="Preset only", preview="preview.jpg")
        result = self.call("list", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        items = json.loads(result.stdout)
        self.assertEqual([(item["id"], item["title"], item["compatible"]) for item in items],
                         [("100", "Usable Web", True), ("200", "Preset only", False)])
        self.assertEqual(items[1]["reason"], "unsupported project type: unknown")

    def test_scene_package_satisfies_packaged_entry(self):
        self.item("100", title="Packaged Scene", type="scene", file="scene.json")
        directory = self.workshop / "100"
        (directory / "scene.json").unlink()
        (directory / "scene.pkg").write_bytes(b"package")
        result = self.call("list", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        item = json.loads(result.stdout)[0]
        self.assertTrue(item["compatible"])
        self.assertEqual(item["type"], "scene")

    def test_preset_resolves_installed_dependency_and_primitive_properties(self):
        self.item("100", title="Base", type="web", file="index.html")
        self.item("200", title="Preset", dependency="100",
                  preset={"enabled": True, "amount": 12, "label": "Konata", "ignored": None})
        result = self.call("list", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        item = json.loads(result.stdout)[1]
        self.assertTrue(item["compatible"])
        self.assertTrue(item["preset"])
        self.assertEqual(item["dependency"], "100")
        self.assertEqual(item["type"], "web")
        self.assertEqual(item["path"], str((self.workshop / "100").resolve()))
        self.assertEqual(item["properties"],
                         {"enabled": "1", "amount": "12", "label": "Konata"})

    def test_preset_reports_missing_dependency_or_asset(self):
        self.item("200", title="Missing dependency", dependency="100", preset={})
        self.item("300", title="Base", type="web", file="index.html",
                  general={"properties": {"background_image": {"type": "file"}}})
        self.item("400", title="Missing asset", dependency="300",
                  preset={"background_image": "files/missing.png"})
        result = self.call("list", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        items = {item["id"]: item for item in json.loads(result.stdout)}
        self.assertFalse(items["200"]["compatible"])
        self.assertIn("not downloaded", items["200"]["reason"])
        self.assertFalse(items["400"]["compatible"])
        self.assertEqual(items["400"]["reason"],
                         "preset asset missing: files/missing.png")

    def test_preset_file_property_resolves_from_preset_directory(self):
        self.item("100", title="Base", type="web", file="index.html",
                  general={"properties": {"background_image": {"type": "file"}}})
        self.item("200", title="Preset", dependency="100",
                  preset={"background_image": "files/konata.png"})
        image = self.workshop / "200/files/konata.png"
        image.parent.mkdir()
        image.write_bytes(b"image")
        result = self.call("list", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        item = json.loads(result.stdout)[1]
        self.assertTrue(item["compatible"])
        self.assertEqual(item["properties"]["background_image"], str(image.resolve()))

    def test_invalid_or_incompatible_item_never_reaches_renderer(self):
        self.item("200", title="Preset only", preview="preview.jpg")
        invalid = self.call("apply", "../200")
        incompatible = self.call("apply", "200")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertIn("digits only", invalid.stderr)
        self.assertNotEqual(incompatible.returncode, 0)
        self.assertIn("unsupported project type", incompatible.stderr)

    def test_web_wallpaper_requires_explicit_risk_acknowledgement(self):
        self.item("100", title="Web", type="web", file="index.html")
        result = self.call("apply", "100")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("experimental", result.stderr)

    def test_restricted_profile_rejects_live_wallpaper(self):
        self.item("100", title="Usable", type="web", file="index.html")
        profile = self.state / "kona/profile.json"
        profile.parent.mkdir(parents=True)
        profile.write_text(json.dumps({"schema": 1, "profile": "gaming", "return_to": "daily"}))
        result = self.call("apply", "100")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Gaming profile requires a static wallpaper", result.stderr)

    def test_inactive_status_is_explicit(self):
        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"active": False})

    def test_internal_stop_preserves_selected_default_without_active_process(self):
        target = self.state / "kona/wallpaper-engine.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps({"schema": 1, "id": "100", "title": "Selected",
                                      "type": "scene", "processes": [{"pid": 123, "start_ticks": 4}]}))
        result = self.call("stop-worker")
        self.assertEqual(result.returncode, 0, result.stderr)
        saved = json.loads(target.read_text())
        self.assertEqual(saved["id"], "100")
        self.assertEqual(saved["processes"], [])
        status = self.call("status")
        self.assertEqual(json.loads(status.stdout)["active"], False)

    def test_missing_default_fails_once_for_profile_fallback(self):
        result = self.call("restore-default-worker")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no Wallpaper Engine default", result.stderr)

    def test_web_default_is_not_automatically_resumed_after_crash_evidence(self):
        target = self.state / "kona/wallpaper-engine.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps({"schema": 1, "id": "100", "title": "Web",
                                      "type": "web", "processes": []}))
        result = self.call("restore-default-worker")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("manual confirmation", result.stderr)

    def test_profile_worker_attempts_default_before_awww_fallback(self):
        source = (ROOT / ".local/bin/kona-wallpaper").read_text()
        self.assertIn('"$helper" restore-default-worker', source)
        self.assertLess(source.index('restore_wallpaper_engine; then'), source.index('start_awww\n', source.index('else\n')))

    def test_failed_default_restore_uses_awww_once_without_retry_loop(self):
        helper_log = self.home / "helper.log"
        awww_log = self.home / "awww.log"
        helper_log_shell = shlex.quote(str(helper_log))
        awww_log_shell = shlex.quote(str(awww_log))
        helper = self.home / ".local/bin/kona-wallpaper-engine"
        self.executable(helper, f'''#!/bin/sh
printf '%s\\n' "$*" >> {helper_log_shell}
test "$1" != restore-default-worker
''')
        fake_bin = self.home / "bin"
        self.executable(fake_bin / "hyprctl", '''#!/bin/sh
printf '%s\\n' '[{"name":"LEFT","x":0},{"name":"CENTER","x":1920},{"name":"RIGHT","x":3840}]'
''')
        self.executable(fake_bin / "pgrep", "#!/bin/sh\nexit 1\n")
        self.executable(fake_bin / "awww-daemon", "#!/bin/sh\nexit 0\n")
        self.executable(fake_bin / "uwsm", '''#!/bin/sh
while test "$1" != --; do shift; done
shift
exec "$@"
''')
        self.executable(fake_bin / "awww", f'''#!/bin/sh
printf '%s\\n' "$*" >> {awww_log_shell}
exit 0
''')
        assets = self.home / ".local/share/wallpapers/konata-command-center/animated"
        assets.mkdir(parents=True)
        for name in ("left.webp", "center.webp", "right.webp"):
            (assets / name).write_bytes(b"fixture")
        config = self.home / "config"
        config.mkdir()
        environment = {
            **self.environment,
            "XDG_CONFIG_HOME": str(config),
            "PATH": str(fake_bin) + os.pathsep + os.environ.get("PATH", ""),
        }
        result = subprocess.run([str(POLICY_COMMAND), "--apply-policy", "daily", "animated"],
                                env=environment, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        helper_calls = helper_log.read_text().splitlines()
        self.assertEqual(helper_calls.count("restore-default-worker"), 1)
        self.assertEqual(helper_calls[-1], "stop-worker")
        self.assertIn("img --outputs LEFT", awww_log.read_text())


if __name__ == "__main__":
    unittest.main()
