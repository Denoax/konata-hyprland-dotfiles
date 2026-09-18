#!/usr/bin/env python3
"""Reuse the transient Quickshell lifecycle contract for weather."""
import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("music_contracts", HERE / "music-popup.py")
contracts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contracts)
contracts.HOST = HERE.parent / ".local/bin/kona-weather-popup"


class WeatherHost(contracts.MusicHost):
    # The shared base also owns music's source-level contract; this host only
    # reuses its transient-process lifecycle checks.
    test_native_surface_preserves_real_backend_controls = None

    def test_weather_surface_preserves_cache_and_owner_boundaries(self):
        root = HERE.parent
        shell = (root / ".config/quickshell/kona/weather/shell.qml").read_text()
        view = (root / ".config/quickshell/kona/weather/WeatherPopupView.qml").read_text()
        self.assertIn('target:"weather"', shell)
        self.assertIn('property var weatherData:', view)
        self.assertNotIn('property var data:', view)
        self.assertIn('Precipitation Chance', view)
        self.assertIn('requestRefresh', view)
        self.assertIn('width: 430', view)
        self.assertIn('height: 560', view)
        self.assertNotIn('weather_shell_', view)
        self.assertIn('Appearance.surfaceElevated', view)
        self.assertIn('art/kona_ledge_mascot.png', view)
        self.assertNotIn('kona-thumbs-up.png', view)
        self.assertIn('function weatherIcon(', view)
        glyph = (root / ".config/quickshell/kona/weather/WeatherGlyph.qml").read_text()
        self.assertIn('"partly_cloudy_day"', glyph)
        self.assertIn('"partly_cloudy_night"', glyph)
        self.assertIn('assets/reconstruction-v3/icons/', glyph)
        self.assertNotIn('JetBrainsMono Nerd Font', glyph)
        assets = root / ".config/quickshell/kona/weather/assets/reconstruction-v3"
        for name in ("clear_day", "clear_night", "partly_cloudy_day", "partly_cloudy_night", "cloudy",
                     "thermometer", "feels_like", "humidity", "wind", "umbrella", "location", "more"):
            self.assertTrue((assets / f"icons/{name}.png").is_file())


if __name__ == "__main__":
    import unittest
    unittest.main(verbosity=2)
