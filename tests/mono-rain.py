#!/usr/bin/env python3
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WALLPAPER = ROOT / '.config/kona/wallpapers/konata-mono-rain'


class MonoRain(unittest.TestCase):
    def test_definition_is_deterministic_downward_and_left_only(self):
        data = json.loads((WALLPAPER / 'layers/rain-definition.json').read_text())
        self.assertEqual(data['duration_seconds'], 10)
        self.assertGreaterEqual(data['fps'], 10)
        self.assertGreaterEqual(len(data['columns']), 12)
        self.assertGreaterEqual(data['stable_from_x'], data['rain_width'])
        self.assertTrue(all(0 <= item['x'] < data['rain_width'] and item['cycles'] >= 1
                            for item in data['columns']))

    def test_runtime_has_profile_static_fallback_without_a_second_owner(self):
        wallpaper = (ROOT / '.local/bin/kona-wallpaper').read_text()
        profile = (ROOT / '.local/bin/kona-profile').read_text()
        scene = json.loads((ROOT / '.config/kona/scene-images.json').read_text())
        self.assertIn("animated_static_fallback", wallpaper)
        self.assertIn("static_fallback_for", profile)
        self.assertIn("preserve_theme_for", profile)
        self.assertTrue(scene['animated'].endswith('/konata-mono-rain.gif'))
        self.assertNotIn('mpvpaper', wallpaper)
        self.assertNotIn('swww', wallpaper)

    def test_reference_provenance_and_renderer_contract_are_present(self):
        readme = (WALLPAPER / 'source/README.md').read_text()
        renderer = (WALLPAPER / 'scripts/render-konata-mono-rain.py').read_text()
        self.assertIn('aab2a5e05dfb89163beed608b46052b219dfe14a638a94edf89d77d1dd4fa73c', readme)
        self.assertIn('character/flower stability invariant failed', renderer)
        self.assertIn('encoded GIF character/flower stability invariant failed', renderer)
        self.assertIn('procedural cycle endpoint does not match', renderer)
        validation = json.loads((WALLPAPER / 'render/validation.json').read_text())
        self.assertIn('konata-mono-rain.gif', validation['outputs'])
        self.assertEqual(validation['runtime_stable_region']['format'], 'gif-rgb24')
        self.assertTrue((WALLPAPER / 'render/konata-mono-rain.preserve-theme').is_file())


if __name__ == '__main__':
    unittest.main()
