#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SidebarNavigation(unittest.TestCase):
    def test_bare_super_targets_sidebar_and_chords_keep_guard(self):
        source = (ROOT / '.config/hypr/hyprland.lua').read_text()
        self.assertIn('hl.bind("SUPER_L"', source)
        self.assertIn('hl.bind("SUPER + SUPER_L"', source)
        self.assertIn('superTapArmed = false', source)
        self.assertIn('~/.local/bin/kona-sidebar toggle', source)
        self.assertIn('local function bindSuper(keys, dispatcher, flags)', source)

    def test_sidebar_replaces_dock_at_startup(self):
        source = (ROOT / '.config/hypr/hyprland.lua').read_text()
        startup = source[source.index('hl.on("hyprland.start"'):source.index('-- Core application controls.')]
        self.assertIn('kona-sidebar show', startup)
        self.assertNotIn('kona-dock', startup)

    def test_sidebar_owns_app_presentation_without_second_launcher(self):
        shell = (ROOT / '.config/quickshell/kona/sidebar/shell.qml').read_text()
        section = (ROOT / '.config/quickshell/kona/sidebar/qml/sections/ApplicationSection.qml').read_text()
        self.assertIn('Hyprland.toplevels.values', shell)
        self.assertIn('lastActiveAddress', shell)
        self.assertIn('Hyprland.refreshToplevels()', shell)
        self.assertIn('application.activate', shell)
        self.assertIn('function launch(desktopId: string)', shell)
        self.assertIn('function activate(address: string)', shell)
        self.assertIn('hl.dsp.focus({window = hl.get_window', shell)
        self.assertIn('runningApplications', section)
        self.assertIn('applications.open', section)
        self.assertIn('windows.open', section)

    def test_file_manager_pin_does_not_select_dolphin_emulator(self):
        shell = (ROOT / '.config/quickshell/kona/sidebar/shell.qml').read_text()
        self.assertIn('id === "org.kde.dolphin" || name === "dolphin"', shell)

    def test_missing_application_art_uses_neutral_kona_line_icon(self):
        shell = (ROOT / '.config/quickshell/kona/sidebar/shell.qml').read_text()
        section = (ROOT / '.config/quickshell/kona/sidebar/qml/sections/ApplicationSection.qml').read_text()
        fallback = (ROOT / '.config/quickshell/kona/sidebar/qml/components/AppIcon.qml').read_text()
        module = (ROOT / '.config/quickshell/kona/sidebar/qml/components/qmldir').read_text()
        self.assertIn('!resolved.includes("image-missing")', shell)
        self.assertIn('AppIcon {', section)
        self.assertIn('name: "apps"', fallback)
        self.assertIn('AppIcon 1.0 AppIcon.qml', module)

    def test_sidebar_exposes_the_transactional_kona_appearance_mode(self):
        mode = (ROOT / '.config/quickshell/kona/sidebar/qml/sections/AppearanceMode.qml').read_text()
        shell = (ROOT / '.config/quickshell/kona/sidebar/shell.qml').read_text()
        appearance = (ROOT / '.config/quickshell/kona/sidebar/Appearance.qml').read_text()
        self.assertIn('text: "Kona"', mode)
        self.assertIn('actionId: "appearance.kona"', mode)
        self.assertIn('"appearance.kona"', shell)
        self.assertIn('["light", "kona", "dark"]', appearance)

    def test_hybrid_visual_pass_keeps_kona_sections_and_caelestia_motion(self):
        view = (ROOT / '.config/quickshell/kona/sidebar/qml/SidebarView.qml').read_text()
        tokens = (ROOT / '.config/quickshell/kona/sidebar/qml/components/Tokens.qml').read_text()

        for section in ('ApplicationSection', 'WorkspaceSection', 'CompactMusic',
                        'WeatherCompact', 'Quick controls', 'Desktop', 'System', 'Tools'):
            self.assertIn(section, view)
        self.assertIn('[0.42, 1.67, 0.21, 0.9, 1, 1]', tokens)
        self.assertIn('[0.38, 1.21, 0.22, 1, 1, 1]', tokens)
        self.assertIn('Easing.BezierSpline', view)


if __name__ == '__main__':
    unittest.main()
