#!/usr/bin/env python3
"""Contracts for the transient Caelestia/end-4 UI integration."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
END4_REVISION = "2f0c8bf42b803f4d597572f2a014d4e78d7d9f26"
SHAPES_REVISION = "e31ec4cb4ebf6a46b267f5c42eabf6874916fa16"


class UpstreamUiContracts(unittest.TestCase):
    def test_entrypoints_replace_only_the_selected_presentations(self):
        hyprland = (ROOT / ".config/hypr/hyprland.lua").read_text()
        sidebar = (ROOT / ".config/quickshell/kona/sidebar/shell.qml").read_text()

        self.assertIn('bindSuper("SHIFT + RETURN", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-dashboard")', hyprland)
        self.assertIn('bindSuper("SPACE", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview")', hyprland)
        self.assertIn('bindSuper("W", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview")', hyprland)
        self.assertIn('bindSuper("I", hl.dsp.exec_cmd("~/.local/bin/kona-caelestia-settings")', hyprland)
        self.assertIn('hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview")', hyprland)
        self.assertIn('hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("~/.local/bin/kona-end4-overview")', hyprland)
        self.assertIn('"music.open": [bin + "kona-caelestia-dashboard", "media"]', sidebar)
        self.assertIn('"weather.open": [bin + "kona-caelestia-dashboard", "weather"]', sidebar)
        self.assertIn('"applications.open": [bin + "kona-end4-overview"]', sidebar)
        self.assertIn('"notifications.open": [bin + "kona-end4-notifications", "toggle"]', sidebar)
        self.assertIn('"assistant.open": [bin + "kona-end4-surface", "assistant"]', sidebar)
        self.assertIn('"cheatsheet.open": [bin + "kona-end4-surface", "cheatsheet"]', sidebar)
        self.assertIn('"settings.open": [bin + "kona-caelestia-settings"]', sidebar)
        self.assertIn('"shortcuts.open": [bin + "kona-end4-surface", "cheatsheet"]', sidebar)

    def test_caelestia_host_omits_the_upstream_service_loader(self):
        shell = (ROOT / ".config/quickshell/kona-caelestia/shell.qml").read_text()
        window = (ROOT / ".config/quickshell/kona-caelestia/KonaDashboardWindow.qml").read_text()
        audio_shell = (ROOT / ".config/quickshell/kona-caelestia/audio-shell.qml").read_text()
        audio_window = (ROOT / ".config/quickshell/kona-caelestia/KonaAudioWindow.qml").read_text()

        self.assertIn("KonaDashboardWindow {}", shell)
        self.assertNotIn("ServiceLoader", shell)
        self.assertIn("KonaAudioWindow {}", audio_shell)
        self.assertNotIn("ServiceLoader", audio_shell)
        self.assertNotIn("NotificationServer", shell + window + audio_shell + audio_window)
        self.assertIn("Qt.callLater(Qt.quit)", window)
        self.assertIn("Qt.callLater(Qt.quit)", audio_window)
        self.assertIn('function status(): string { return "ready"; }', window)

    def test_caelestia_weather_uses_kona_location_without_legacy_popup(self):
        launcher = (ROOT / ".local/bin/kona-caelestia-dashboard").read_text()
        window = (ROOT / ".config/quickshell/kona-caelestia/KonaDashboardWindow.qml").read_text()

        self.assertIn('config_path = config_home / "kona/weather.json"', launcher)
        self.assertIn('environment["KONA_WEATHER_LOCATION"]', launcher)
        self.assertIn('environment["KONA_WEATHER_DISABLE_IP"] = "1"', launcher)
        self.assertIn('required=action == "weather"', launcher)
        self.assertIn('GlobalConfig.services.weatherLocation = weatherLocation', window)
        self.assertFalse((ROOT / ".local/bin/kona-weather-popup").exists())
        self.assertFalse((ROOT / ".config/quickshell/kona/weather").exists())

    def test_audio_uses_transient_caelestia_pipewire_surface(self):
        launcher = (ROOT / ".local/bin/kona-caelestia-audio").read_text()
        window = (ROOT / ".config/quickshell/kona-caelestia/KonaAudioWindow.qml").read_text()
        sidebar = (ROOT / ".config/quickshell/kona/sidebar/shell.qml").read_text()

        self.assertIn('return Path.home() / ".cache/kona/caelestia-audio"', launcher)
        self.assertIn("fcntl.LOCK_EX", launcher)
        self.assertIn("BarPopouts.AudioPopout", window)
        self.assertNotIn("Nexus {", window)
        self.assertIn('"audio.open": [bin + "kona-caelestia-audio"]', sidebar)

    def test_session_ui_routes_actions_through_kona_owner(self):
        launcher = (ROOT / ".local/bin/kona-caelestia-session").read_text()
        owner = (ROOT / ".local/bin/kona-session-action").read_text()
        window = (ROOT / ".config/quickshell/kona-caelestia/KonaSessionWindow.qml").read_text()
        sidebar = (ROOT / ".config/quickshell/kona/sidebar/shell.qml").read_text()

        self.assertIn("Session.Content", window)
        self.assertIn('"XDG_CONFIG_HOME"', launcher)
        self.assertIn("fcntl.LOCK_EX", launcher)
        for action in ("logout", "poweroff", "hibernate", "reboot"):
            self.assertIn(f'[owner, "{action}"]', launcher)
        self.assertIn("kona-confirm", owner)
        self.assertIn('"session.open": [bin + "kona-caelestia-session"]', sidebar)

    def test_nexus_replaces_legacy_settings_without_loading_caelestia_services(self):
        launcher = (ROOT / '.local/bin/kona-caelestia-settings').read_text()
        shell = (ROOT / '.config/quickshell/kona-caelestia/settings-shell.qml').read_text()
        page = (ROOT / '.config/quickshell/kona-caelestia/KonaAppearancePage.qml').read_text()
        legacy = (ROOT / '.local/bin/kona-shell').read_text()
        self.assertIn('modules/nexus/PageCompRegistry.qml', launcher)
        self.assertIn('KonaAppearancePage {}', launcher)
        self.assertIn('WallpaperSelect {}', launcher)
        self.assertIn('WallpaperCategory {}', launcher)
        self.assertIn('kona-wallpaper-select', launcher)
        self.assertIn('CAELESTIA_WALLPAPERS_DIR', launcher)
        self.assertIn('KonaSettingsWindow {}', shell)
        self.assertNotIn('ServiceLoader', shell)
        for owner in ('kona-appearance', 'kona-profile-menu', 'kona-wallpaper-menu', 'kona-preferences'):
            self.assertIn(owner, page)
        self.assertIn("if page == 'studio':", legacy)
        self.assertIn('kona-caelestia-settings', legacy)

    def test_caelestia_wallpaper_picker_uses_kona_transaction_owner(self):
        owner = (ROOT / '.local/bin/kona-wallpaper-select').read_text()
        page = (ROOT / '.config/quickshell/kona-caelestia/KonaAppearancePage.qml').read_text()
        self.assertIn('[PROFILE, "preview", wallpaper]', owner)
        self.assertIn('[PROFILE, "preview-apply"]', owner)
        self.assertIn('[PROFILE, "preview-revert"]', owner)
        self.assertIn('root.nState.openSubPage(1)', page)
        self.assertIn('kona-wallpaper-menu', page)

    def test_end4_host_is_pinned_isolated_and_transient(self):
        launcher = (ROOT / ".local/bin/kona-end4-surface").read_text()
        shell = (ROOT / ".config/quickshell/kona-end4/shell.qml").read_text()
        global_states = (ROOT / ".config/quickshell/kona-end4/GlobalStates.qml").read_text()
        installer = (ROOT / ".local/bin/kona-install-upstream-ui").read_text()

        self.assertIn(f'PINNED_REVISION = "{END4_REVISION}"', launcher)
        self.assertIn(f'revision="{END4_REVISION}"', installer)
        self.assertIn(f'shapes_revision="{SHAPES_REVISION}"', installer)
        for variable in ("XDG_CONFIG_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME"):
            self.assertIn(variable, launcher)
        self.assertIn("Overview {}", shell)
        self.assertIn("Qt.callLater(Qt.quit)", shell)
        self.assertIn("integrate_overview_app_launch(runtime)", launcher)
        self.assertIn('Quickshell.execDetached(["gtk-launch"', launcher)
        self.assertIn('"applications-other-symbolic"', launcher)
        selection = launcher.split('item_new = """', 1)[1].split('"""', 1)[0]
        self.assertIn("root.itemExecute()", selection)
        self.assertNotIn("GlobalStates.overviewOpen = false", selection)
        self.assertNotIn("NotificationServer", shell + global_states)
        self.assertIn('"ai": {"tool": "none"}', launcher)
        self.assertIn('"translator": {"enable": True', launcher)
        self.assertIn('"allowNsfw": False', launcher)
        self.assertIn("fcntl.LOCK_EX", launcher)
        self.assertIn("function status(): string", shell)

    def test_nexus_uses_kona_system_palette_and_an_opaque_surface(self):
        window = (ROOT / '.config/quickshell/kona-caelestia/KonaSettingsWindow.qml').read_text()
        self.assertIn('color: Colours.palette.m3surfaceContainerLow', window)
        self.assertIn('blobColour: Colours.palette.m3surfaceContainerLow', window)
        self.assertIn('color: Colours.palette.m3scrim', window)

    def test_file_manager_uses_installed_native_or_flatpak_owner(self):
        launcher = (ROOT / ".local/bin/kona-file-manager").read_text()
        self.assertIn("for manager in dolphin nautilus nemo thunar", launcher)
        self.assertIn("flatpak run org.kde.dolphin", launcher)
        self.assertIn("kitty --class KonaFiles -e yazi", launcher)

    def test_upstream_colours_are_derived_from_kona_appearance(self):
        with tempfile.TemporaryDirectory(prefix="kona-upstream-theme-") as directory:
            home = Path(directory)
            appearance = home / ".config/kona/appearance/current.json"
            appearance.parent.mkdir(parents=True)
            tokens = json.loads((ROOT / ".config/kona/appearance/dark.json").read_text())
            appearance.write_text(json.dumps(tokens))
            end4_state = home / "isolated-end4-state"
            environment = os.environ.copy()
            environment.update({"HOME": str(home), "KONA_END4_STATE_HOME": str(end4_state)})

            subprocess.run([str(ROOT / ".local/bin/kona-upstream-theme")], env=environment, check=True)

            caelestia = json.loads((home / ".local/state/caelestia/scheme.json").read_text())
            end4 = json.loads((end4_state / "user/generated/colors.json").read_text())
            self.assertEqual(caelestia["mode"], "dark")
            self.assertEqual(caelestia["colours"]["primary"], tokens["accent"].removeprefix("#"))
            self.assertEqual(end4["primary"], tokens["accent"])
            self.assertEqual(end4["surface_container"], tokens["surface_alt"])
            self.assertFalse(any(name.startswith('term') for name in end4))

    def test_kona_palette_maps_to_standard_dark_upstream_mode(self):
        with tempfile.TemporaryDirectory(prefix="kona-upstream-theme-") as directory:
            home = Path(directory)
            appearance = home / ".config/kona/appearance/current.json"
            appearance.parent.mkdir(parents=True)
            tokens = json.loads((ROOT / ".config/kona/appearance/kona.json").read_text())
            appearance.write_text(json.dumps(tokens))
            environment = {**os.environ, "HOME": str(home),
                           "KONA_END4_STATE_HOME": str(home / "end4-state")}
            subprocess.run([str(ROOT / ".local/bin/kona-upstream-theme")], env=environment, check=True)
            caelestia = json.loads((home / ".local/state/caelestia/scheme.json").read_text())
            self.assertEqual(caelestia["mode"], "dark")
            self.assertEqual(caelestia["colours"]["surfaceContainerLow"], tokens["surface"].removeprefix("#"))

    def test_upstream_licenses_and_credit_are_explicit(self):
        credits = (ROOT / "docs/kona/UPSTREAM_UI_CREDITS.md").read_text()
        for name in (
            "caelestia-shell-GPL-3.0.txt",
            "end-4-dots-GPL-3.0.txt",
            "rounded-polygon-qmljs-Apache-2.0.txt",
        ):
            self.assertTrue((ROOT / "third_party/licenses" / name).is_file())
            self.assertIn(name, credits)
        self.assertIn(END4_REVISION, credits)
        self.assertIn(SHAPES_REVISION, credits)


if __name__ == "__main__":
    unittest.main(verbosity=2)
