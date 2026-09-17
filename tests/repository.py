#!/usr/bin/env python3
"""Portable public-tree integrity checks; no live desktop is required."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class RepositoryIntegrity(unittest.TestCase):
    def test_all_json_sources_parse(self):
        for path in ROOT.rglob("*.json"):
            if ".git" not in path.parts:
                with self.subTest(path=path.relative_to(ROOT)):
                    json.loads(path.read_text())

    def test_current_public_docs_do_not_advertise_retired_runtime(self):
        current = "\n".join(
            (ROOT / name).read_text()
            for name in (
                "README.md", "docs/ARCHITECTURE.md", "docs/INSTALL.md",
                "docs/CURRENT_STATUS.md", "docs/KEYBINDS.md",
            )
        ).lower()
        for retired in ("auto-hiding dock", "nwg-drawer", "uwsm-managed wayland session"):
            self.assertNotIn(retired, current)

    def test_retired_product_paths_are_absent(self):
        for relative in (
            ".config/nwg-dock-hyprland", ".config/nwg-drawer",
            ".local/bin/nwg-dock-hyprland-kona", ".local/bin/kona-dock",
            ".local/bin/kona-clock", ".local/share/applications/kona-search.desktop",
        ):
            self.assertFalse((ROOT / relative).exists(), relative)

    def test_public_tree_has_no_private_home_path(self):
        text_suffixes = {"", ".conf", ".css", ".desktop", ".ini", ".json", ".jsonc", ".lua", ".md", ".provenance", ".py", ".qml", ".rasi", ".sh", ".txt", ".yml"}
        private_home = b"/home/" + b"mani"
        for path in ROOT.rglob("*"):
            if path.is_file() and ".git" not in path.parts and "__pycache__" not in path.parts and path.suffix in text_suffixes:
                with self.subTest(path=path.relative_to(ROOT)):
                    self.assertNotIn(private_home, path.read_bytes())

    def test_config_only_wins_regardless_of_option_order(self):
        with tempfile.TemporaryDirectory() as directory:
            rsync = Path(directory) / "rsync"
            rsync.write_text("#!/bin/sh\nexit 0\n")
            rsync.chmod(0o755)
            result = subprocess.run(
                [str(ROOT / "install.sh"), "--with-flatpaks", "--config-only", "--dry-run"],
                cwd=ROOT, capture_output=True, text=True, check=True,
                env={"PATH": f"{directory}:/usr/bin:/bin", "HOME": str(Path.home())},
            )
        self.assertIn("dependencies: false", result.stdout)
        self.assertIn("optional Flatpaks: false", result.stdout)


if __name__ == "__main__":
    unittest.main()
