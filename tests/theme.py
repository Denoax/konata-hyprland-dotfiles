#!/usr/bin/env python3
"""Theme public CLI contracts in isolated HOME; real Matugen is tested separately."""
import concurrent.futures
import json
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODEL = runpy.run_path(str(ROOT / '.local/bin/kona-theme'))


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.theme = self.home / '.config/kona/theme'
        shutil.copytree(ROOT / '.config/kona/theme', self.theme, symlinks=True)
        shutil.copytree(ROOT / '.config/kona/appearance', self.home / '.config/kona/appearance')
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.env = {**os.environ, 'HOME': str(self.home), 'XDG_CONFIG_HOME': str(self.home / '.config'),
                    'XDG_RUNTIME_DIR': str(self.home / 'runtime'),
                    'PATH': str(self.bin) + ':/usr/bin:/bin'}
        Path(self.env['XDG_RUNTIME_DIR']).mkdir()
        self.env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
        self.image = self.home / 'image.png'
        self.image.write_bytes(b'fixture for fake Matugen boundary')
        self.fake("print(json.dumps({'colors': {'primary': {'dark': {'color': '#fb91d6'}}, 'secondary': {'dark': {'color': '#cba8ed'}}}}))")

    def fake(self, code):
        p = self.bin / 'matugen'
        p.write_text('#!/usr/bin/python3\nimport json,sys,time\n' + code + '\n')
        p.chmod(0o755)

    def call(self, *args):
        return subprocess.run(['/usr/bin/python3', str(ROOT / '.local/bin/kona-theme'), *args, '--no-reload'],
                              env=self.env, capture_output=True, text=True, timeout=45)

    def active(self):
        files = MODEL['complete'](self.theme / 'current')
        self.assertIsNotNone(files, 'active generation must be complete and semantically valid')
        return files

    @unittest.skipUnless(shutil.which('matugen'), 'official Matugen not installed')
    def test_installed_matugen_config_and_modern_image_schema(self):
        (self.bin / 'matugen').unlink()
        (self.bin / 'matugen').symlink_to(shutil.which('matugen'))
        image = ROOT / '.local/share/wallpapers/konata-command-center/v2/selected.png'
        result = self.call('--image', str(image))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(json.loads(result.stdout)['fallback_reason'])
        self.active()

    def test_shipped_fallback_matches_source_and_is_usable_without_generation(self):
        self.assertEqual(self.active(), MODEL['render'](MODEL['appearance_tokens'](self.theme, 'dark')))
        self.assertEqual(self.call('--default').returncode, 0)

    def test_image_changes_only_accent_family_and_identical_input_does_not_activate_again(self):
        old = json.loads(self.active()['tokens.json'])
        first = self.call('--image', str(self.image))
        self.assertEqual(first.returncode, 0, first.stderr)
        new = json.loads(self.active()['tokens.json'])
        self.assertNotEqual(old['accent.primary'], new['accent.primary'])
        dynamic = {'accent.primary', 'accent.secondary', 'line.active', 'glow.active'}
        self.assertEqual({k:v for k,v in old.items() if k not in dynamic}, {k:v for k,v in new.items() if k not in dynamic})
        target = (self.theme / 'current').readlink()
        second = self.call('--image', str(self.image))
        self.assertEqual(json.loads(second.stdout)['changed'], [])
        self.assertEqual((self.theme / 'current').readlink(), target)

    def test_missing_image_retains_known_good(self):
        self.call('--image', str(self.image))
        before = self.active()
        self.assertNotEqual(self.call('--image', str(self.home / 'missing')).returncode, 0)
        self.assertEqual(self.active(), before)

    def test_absent_matugen_retains_pack_fallback(self):
        self.env['PATH'] = str(self.home / 'no-programs')
        result = self.call('--image', str(self.image))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('FileNotFoundError', result.stderr)
        self.assertEqual(json.loads(self.active()['tokens.json'])['accent.primary'], '#7FAEFF')

    def test_failed_empty_malformed_or_invalid_palette_preserves_known_good(self):
        self.call('--image', str(self.image))
        before = self.active()
        for code in ['sys.exit(9)', 'print("")', 'print("invalid")',
                     "print(json.dumps({'colors': {'primary': {'dark': {'color': 'bad'}}, 'secondary': {'dark': {'color': '#ffffff'}}}}))"]:
            with self.subTest(code=code):
                self.fake(code)
                self.assertNotEqual(self.call('--image', str(self.image)).returncode, 0)
                self.assertEqual(self.active(), before)

    def test_missing_or_corrupt_current_recovers_semantic_fallback_on_failed_generation(self):
        (self.theme / 'current').unlink()
        self.assertNotEqual(self.call('--image', str(self.home / 'missing')).returncode, 0)
        (self.theme / 'current/waybar.css').write_text('')
        self.assertNotEqual(self.call('--image', str(self.home / 'missing')).returncode, 0)
        self.assertEqual(json.loads(self.active()['tokens.json'])['accent.primary'], '#7FAEFF')

    def test_parallel_requests_expose_complete_sets(self):
        self.fake("time.sleep(.1)\nprint(json.dumps({'colors': {'primary': {'dark': {'color': '#fb91d6'}}, 'secondary': {'dark': {'color': '#cba8ed'}}}}))")
        with concurrent.futures.ThreadPoolExecutor() as pool:
            futures = [pool.submit(self.call, '--image', str(self.image)), pool.submit(self.call, '--default')]
            while not all(f.done() for f in futures):
                # Resolve the generation once, as a consumer does when opening its
                # single fragment. A reader spanning pointer swaps is not a snapshot.
                self.assertIsNotNone(MODEL['complete']((self.theme / 'current').resolve()))
            for future in futures:
                result = future.result()
                self.assertEqual(result.returncode, 0, result.stderr)
        self.active()

    def test_reload_only_changed_consumer_and_retry_failed_reload(self):
        log = self.home / 'reloads'
        self.env['HYPRLAND_INSTANCE_SIGNATURE'] = 'test'
        socket = Path(self.env['XDG_RUNTIME_DIR']) / 'hypr/test/.socket.sock'
        socket.parent.mkdir(parents=True)
        socket.touch()
        for name in ['pkill', 'swaync-client', 'hyprctl', 'systemctl']:
            p = self.bin / name
            p.write_text('#!/usr/bin/python3\nfrom pathlib import Path\nimport sys\n'
                         + f'with Path({str(log)!r}).open("a") as f:f.write(Path(sys.argv[0]).name+"\\n")\n')
            p.chmod(0o755)
        base = json.loads((self.home / '.config/kona/appearance/dark.json').read_text())
        base['text_muted'] = '#8b9bb2'
        (self.home / '.config/kona/appearance/dark.json').write_text(json.dumps(base))
        def apply():
            return subprocess.run(['/usr/bin/python3', str(ROOT / '.local/bin/kona-theme'), '--default'],
                                  env=self.env, capture_output=True, text=True)
        result = apply()
        self.assertEqual(result.returncode, 0, result.stderr)
        expected = ['hyprctl', 'swaync-client', 'systemctl', 'systemctl', 'pkill']
        self.assertEqual(log.read_text().splitlines(), expected)
        self.assertEqual(apply().returncode, 0)
        self.assertEqual(log.read_text().splitlines(), expected)
        pending = self.theme / 'reload-pending.json'
        pending.write_text(json.dumps(['swaync.css']))
        self.assertEqual(apply().returncode, 0)
        self.assertEqual(log.read_text().splitlines(), expected + ['hyprctl', 'swaync-client'])
        self.assertFalse(pending.exists())

    def test_contrast_constraints_for_distinct_extreme_accents(self):
        base = json.loads(self.active()['appearance.json'])
        for c in ['#000000', '#ffffff', '#ff0000', '#00ff00', '#0000ff', '#ff00ff']:
            color = MODEL['constrain'](c, base['surface_alt'])
            self.assertGreaterEqual(MODEL['contrast'](color, base['surface_alt']), 3)

    def test_waybar_style_reload_preserves_content_and_retries_missing_style(self):
        self.env['HYPRLAND_INSTANCE_SIGNATURE'] = 'test'
        socket = Path(self.env['XDG_RUNTIME_DIR']) / 'hypr/test/.socket.sock'
        socket.parent.mkdir(parents=True)
        socket.touch()
        for name in ['swaync-client', 'hyprctl', 'systemctl']:
            p = self.bin / name
            p.write_text('#!/bin/sh\nexit 0\n')
            p.chmod(0o755)
        log = self.home / 'unexpected-full-reload'
        p = self.bin / 'pkill'
        p.write_text(f'#!/bin/sh\n[ "$1" = "-USR1" ] || touch "{log}"\nexit 0\n')
        p.chmod(0o755)
        def apply():
            return subprocess.run(['/usr/bin/python3', str(ROOT / '.local/bin/kona-theme'),
                                   '--image', str(self.image)], env=self.env,
                                  capture_output=True, text=True)
        result = apply()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)['reload_failed'], ['waybar.css'])
        self.active()
        style = self.home / '.config/waybar/style.css'
        style.parent.mkdir()
        content = b'/* existing layout must remain byte-identical */\n'
        style.write_bytes(content)
        result = apply()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(style.read_bytes(), content)
        self.assertFalse(log.exists(), 'palette changes must not rebuild Waybar modules')
        self.assertFalse((self.theme / 'reload-pending.json').exists())


if __name__ == '__main__':
    unittest.main()
