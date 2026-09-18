#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / ".local/bin/kona-weather"
loader = importlib.machinery.SourceFileLoader("kona_weather", str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
weather = importlib.util.module_from_spec(spec)
loader.exec_module(weather)


FIXTURE = {
    "current": {"time": "2026-09-16T14:00", "temperature_2m": 18.4,
                "apparent_temperature": 17.2, "relative_humidity_2m": 62,
                "weather_code": 2, "wind_speed_10m": 12.3,
                "wind_direction_10m": 46, "precipitation": 0.1},
    "hourly": {"time": [f"2026-09-16T{hour:02d}:00" for hour in range(12, 24)],
               "temperature_2m": list(range(16, 28)), "weather_code": [0, 1, 2, 3] * 3,
               "precipitation_probability": list(range(0, 60, 5))},
    "daily": {"temperature_2m_max": [23], "temperature_2m_min": [11],
              "precipitation_probability_max": [35], "weather_code": [2]},
}


class Response:
    def __enter__(self): return self
    def __exit__(self, *args): return False
    def read(self): return json.dumps(FIXTURE).encode()


class WeatherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kona-weather-")
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.config = root / "weather.json"
        self.cache = root / "cache.json"
        self.config.write_text(json.dumps({"schema": 1, "name": "Edmonton", "region": "Alberta",
                                           "latitude": 53.5461, "longitude": -113.4938,
                                           "units": "metric", "refresh_minutes": 30}))

    def test_real_response_is_normalized_without_fake_copy(self):
        result = weather.status(config_path=self.config, cache_path=self.cache,
                                opener=lambda request, timeout: Response(), now=1000)
        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["location"], {"name": "Edmonton", "region": "Alberta"})
        self.assertEqual(result["current"]["condition"], "Partly cloudy")
        self.assertEqual(result["current"]["wind_direction"], "NE")
        self.assertEqual(result["current"]["high"], 23)
        self.assertGreaterEqual(len(result["hourly"]), 3)
        self.assertTrue(self.cache.is_file())

    def test_fresh_cache_avoids_network(self):
        first = weather.status(config_path=self.config, cache_path=self.cache,
                               opener=lambda request, timeout: Response(), now=1000)
        result = weather.status(config_path=self.config, cache_path=self.cache,
                                opener=lambda *args: self.fail("fresh cache fetched network"), now=1100)
        self.assertEqual(result["current"], first["current"])
        self.assertTrue(result["cached"])
        self.assertFalse(result["stale"])

    def test_stale_cache_survives_network_failure_honestly(self):
        weather.status(config_path=self.config, cache_path=self.cache,
                       opener=lambda request, timeout: Response(), now=1000)
        def unavailable(*args, **kwargs):
            raise OSError("offline")
        result = weather.status(config_path=self.config, cache_path=self.cache,
                                opener=unavailable, now=4000)
        self.assertEqual(result["status"], "stale")
        self.assertTrue(result["stale"])
        self.assertIn("offline", result["error"])

    def test_missing_config_produces_setup_state_without_network(self):
        self.config.unlink()
        result = weather.status(config_path=self.config, cache_path=self.cache,
                                opener=lambda *args: self.fail("setup state fetched network"), now=1000)
        self.assertEqual(result["status"], "setup")
        self.assertEqual(result["config_path"], str(self.config))

    def test_invalid_location_is_rejected_at_boundary(self):
        self.config.write_text(json.dumps({"schema": 1, "name": "Invalid", "region": "",
                                           "latitude": 100, "longitude": 0,
                                           "units": "metric", "refresh_minutes": 30}))
        result = weather.status(config_path=self.config, cache_path=self.cache, now=1000)
        self.assertEqual(result["status"], "setup")
        self.assertIn("latitude", result["message"])

    def test_refresh_policy_has_no_service_or_loop(self):
        units = (ROOT / "packages/kona-user-units.txt").read_text()
        self.assertNotIn("weather", units.lower())
        source = SOURCE.read_text()
        self.assertNotIn("while True", source)
        self.assertEqual(weather.DEFAULT_TTL, 1800)

    def test_sidebar_summary_and_caelestia_surface_share_configured_location(self):
        sidebar = (ROOT / ".config/quickshell/kona/sidebar/qml/SidebarView.qml").read_text()
        sidebar_shell = (ROOT / ".config/quickshell/kona/sidebar/shell.qml").read_text()
        dashboard = (ROOT / ".local/bin/kona-caelestia-dashboard").read_text()
        self.assertIn('WeatherCompact {', sidebar)
        self.assertIn('"weather.open": [bin + "kona-caelestia-dashboard", "weather"]', sidebar_shell)
        self.assertIn('config_path = config_home / "kona/weather.json"', dashboard)
        self.assertIn('KONA_WEATHER_DISABLE_IP', dashboard)
        self.assertFalse((ROOT / ".local/bin/kona-weather-popup").exists())


if __name__ == "__main__":
    unittest.main()
