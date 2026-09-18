#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]


def load_script(name):
    path = ROOT / ".local/bin" / name
    loader = importlib.machinery.SourceFileLoader(name.replace("-", "_"), str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


WORKSPACE = load_script("kona-arch-workspace")
SCRATCH = load_script("kona-scratch-shell")


class ArchWorkspace(unittest.TestCase):
    def test_classes_bindings_and_native_workspace_are_deterministic(self):
        self.assertEqual(len(set(WORKSPACE.ARCH_CLASSES.values())), 3)
        self.assertNotIn("identity", WORKSPACE.ARCH_CLASSES)
        hyprland = (ROOT / ".config/hypr/hyprland.lua").read_text()
        self.assertIn('bindSuper("SHIFT + D", hl.dsp.exec_cmd("~/.local/bin/kona-arch-workspace toggle"))', hyprland)
        self.assertIn('workspace = "special:arch silent"', hyprland)
        self.assertIn('workspace = "special:arch", layout = "master"', hyprland)
        self.assertIn('kona-arch-workspace scratch', hyprland)

    def test_dynamic_btop_theme_consumes_current_semantic_tokens(self):
        tokens = {
            "background": "#010203", "surface": "#040506", "text": "#f0f1f2",
            "text_secondary": "#c0c1c2", "text_muted": "#707172", "accent": "#4488ff",
            "outline": "#334455", "focus": "#77aaff",
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            appearance = root / "config/kona/theme/current/appearance.json"
            appearance.parent.mkdir(parents=True)
            appearance.write_text(json.dumps(tokens))
            runtime = root / "runtime"
            runtime.mkdir()
            with mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": str(root / "config"), "XDG_RUNTIME_DIR": str(runtime)}):
                theme = WORKSPACE.render_btop_theme() / "kona-arch.theme"
                rendered = theme.read_text()
        self.assertIn('theme[main_fg]="#f0f1f2"', rendered)
        self.assertIn('theme[cpu_end]="#4488ff"', rendered)
        self.assertIn('theme[div_line]="#334455"', rendered)

    def test_fastfetch_uses_real_safe_modules_only(self):
        config = json.loads((ROOT / ".config/fastfetch/kona-arch.jsonc").read_text())
        self.assertEqual(
            config["logo"]["source"],
            "~/.config/fastfetch/assets/kona-arch-laptop-terminal.png",
        )
        self.assertEqual(config["logo"]["type"], "kitty-direct")
        self.assertLessEqual(config["logo"]["width"], 32)
        self.assertLessEqual(config["logo"]["height"], 20)
        self.assertTrue((ROOT / ".config/fastfetch/assets/kona-wink-thumb.png").is_file())
        modules = {value if isinstance(value, str) else value["type"] for value in config["modules"]}
        self.assertTrue({"os", "kernel", "wm", "shell", "terminal", "cpu", "gpu", "memory", "disk", "packages"} <= modules)
        shell = next(value for value in config["modules"] if isinstance(value, dict) and value["type"] == "shell")
        self.assertNotIn("format", shell)
        self.assertFalse({"localip", "publicip", "host"} & modules)
        status = (ROOT / ".local/bin/kona-arch-system-shell").read_text()
        self.assertIn("pacman -Qq", status)
        self.assertIn("hyprctl monitors -j", status)

    def test_scratch_shell_has_native_prediction_and_semantic_prompt(self):
        rendered = SCRATCH.render_config({
            "accent": "112233", "text": "445566", "secondary": "778899",
            "muted": "AABBCC", "success": "22CC88", "danger": "FF5566",
        })
        self.assertIn("fish_color_autosuggestion AABBCC --dim", rendered)
        self.assertIn("set -g fish_history kona_scratch", rendered)
        self.assertIn("╰─❯", rendered)
        terminal = SCRATCH.render_config({
            "accent": "112233", "text": "445566", "secondary": "778899",
            "muted": "AABBCC", "success": "22CC88", "danger": "FF5566",
        }, "terminal")
        self.assertIn("set -g fish_history kona_terminal", terminal)
        hyprland = (ROOT / ".config/hypr/hyprland.lua").read_text()
        self.assertIn('match = { class = "^KonaScratch$" }', hyprland)
        self.assertIn('match = { class = "^KonaTerminal$" }', hyprland)
        self.assertIn('hl.bind("ALT + RETURN", hl.dsp.exec_cmd(terminal))', hyprland)
        self.assertIn("float = true", hyprland)

    def test_process_group_survives_launcher_exit_and_remains_attributable(self):
        process = __import__("subprocess").Popen(
            ["sh", "-c", "sleep 30 &"], start_new_session=True
        )
        record = {
            "pid": process.pid,
            "pgid": os.getpgid(process.pid),
            "start_ticks": WORKSPACE.process_start_ticks(process.pid),
        }
        process.wait(timeout=2)
        try:
            self.assertTrue(WORKSPACE.process_group_alive(record))
        finally:
            WORKSPACE.terminate_record(record, force=True)

    def test_closed_design_has_no_service_or_daemon(self):
        units = (ROOT / "packages/kona-user-units.txt").read_text()
        self.assertNotIn("arch-workspace", units)
        self.assertNotIn("daemon", (ROOT / ".local/bin/kona-arch-workspace").read_text().lower())
        packages = set((ROOT / "packages/pacman.txt").read_text().splitlines())
        self.assertTrue({"btop", "fastfetch", "cava", "kitty", "fish"} <= packages)


if __name__ == "__main__":
    unittest.main()
