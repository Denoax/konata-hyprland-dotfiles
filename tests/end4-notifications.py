#!/usr/bin/env python3
"""Static ownership and integration contracts for end-4 notifications."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
REVISION = "2f0c8bf42b803f4d597572f2a014d4e78d7d9f26"


class NotificationContracts(unittest.TestCase):
    def text(self, relative: str) -> str:
        return (ROOT / relative).read_text()

    def test_exact_end4_surfaces_and_notification_service_are_pinned(self):
        launcher = self.text('.local/bin/kona-end4-notifications')
        shell = self.text('.config/quickshell/kona-end4/notifications-shell.qml')
        installer = self.text('.local/bin/kona-install-upstream-ui')
        self.assertIn(f'PINNED_REVISION = "{REVISION}"', launcher)
        self.assertIn(f'revision="{REVISION}"', installer)
        self.assertIn('services/Notifications.qml', launcher)
        self.assertIn('NotificationPopup {}', shell)
        self.assertIn('Quickshell.shellPath("KonaSidebarRight.qml")', shell)
        self.assertIn('active: GlobalStates.sidebarRightOpen', shell)
        wrapper = self.text('.config/quickshell/kona-end4/KonaSidebarRight.qml')
        self.assertIn('import "modules/ii/sidebarRight"', wrapper)
        self.assertIn('SidebarRight {}', wrapper)

    def test_one_persistent_owner_replaces_swaync(self):
        runtime = self.text('.local/bin/kona-runtime-start')
        manifest = self.text('packages/kona-user-units.txt')
        packages = self.text('packages/pacman.txt')
        self.assertIn('kona-notifications.service', runtime)
        self.assertIn('kona-notifications.service', manifest)
        self.assertNotIn('swaync', runtime.casefold())
        self.assertNotIn('swaync', packages.casefold())
        self.assertFalse((ROOT / '.config/swaync').exists())
        self.assertFalse((ROOT / '.local/bin/kona-dashboard').exists())
        self.assertFalse((ROOT / '.config/systemd/user/swaync.service.d').exists())

    def test_history_and_dnd_remain_owned_by_upstream_notification_service(self):
        launcher = self.text('.local/bin/kona-end4-notifications')
        shell = self.text('.config/quickshell/kona-end4/notifications-shell.qml')
        self.assertIn('end4-xdg', launcher)
        self.assertIn('"XDG_STATE_HOME"', launcher)
        self.assertIn('Notifications.list.length', shell)
        self.assertIn('Notifications.silent', shell)
        self.assertIn('function toggleDnd()', shell)
        self.assertIn('dnd-toggle', launcher)

    def test_routes_and_backend_actions_do_not_bypass_existing_owners(self):
        hyprland = self.text('.config/hypr/hyprland.lua')
        sidebar = self.text('.config/quickshell/kona/sidebar/shell.qml')
        waybar = self.text('.config/waybar/config.jsonc')
        launcher = self.text('.local/bin/kona-end4-notifications')
        for source in (hyprland, sidebar, waybar):
            self.assertIn('kona-end4-notifications', source)
            self.assertNotIn('swaync-client', source)
        self.assertIn('kona-caelestia-settings', launcher)
        self.assertIn('kona-caelestia-session', launcher)
        self.assertIn('pinned end-4 notification action contract changed', launcher)
        self.assertIn('Config.options?.notifications?.forceMonitor?.enable', launcher)

    def test_owner_has_bounded_recovery_and_no_parallel_state_daemon(self):
        launcher = self.text('.local/bin/kona-end4-notifications')
        self.assertIn('value.setdefault("sidebar", {})["keepRightSidebarLoaded"] = False', launcher)
        self.assertIn('def reload_owner(', launcher)
        self.assertIn('state.get("silent")', launcher)
        self.assertIn('state.get("open")', launcher)
        unit = self.text('.config/systemd/user/kona-notifications.service')
        self.assertIn('ExecStart=%h/.local/bin/kona-end4-notifications run', unit)
        self.assertIn('ExecCondition=%h/.local/bin/kona-runtime-health ready', unit)
        self.assertIn('Restart=on-failure', unit)
        self.assertIn('StartLimitBurst=3', unit)
        manifest = self.text('packages/kona-user-units.txt').splitlines()
        self.assertEqual(manifest.count('kona-notifications.service'), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
