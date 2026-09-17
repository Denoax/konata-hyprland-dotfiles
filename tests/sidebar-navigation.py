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


if __name__ == '__main__':
    unittest.main()
