#!/usr/bin/env python3
"""Startup boundaries: real dispatcher, isolated executables, no user manager changes."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
HEALTH = runpy.run_path(str(ROOT / '.local/bin/kona-runtime-health'))
SHIM = '''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
name=Path(sys.argv[0]).name
with open(os.environ['CALLS'],'a') as f:f.write(json.dumps([name,*sys.argv[1:]])+'\\n')
if name=='uwsm' and sys.argv[1:3]==['check','is-active']:
 sys.exit(0 if os.environ.get('MANAGED')=='1' else 1)
if len(sys.argv)>1 and os.environ.get('FAIL')==name+':'+sys.argv[1]:sys.exit(7)
'''


class Startup(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        for name in ('uwsm', 'systemctl', 'hypridle', 'waybar', 'nm-applet',
                     'blueman-applet', 'udiskie', 'wl-paste'):
            self.fake(self.bin / name)
        self.fake(self.home / '.local/opt/kona-pkgs/swayosd/usr/bin/swayosd-server')
        self.fake(self.home / '.local/bin/kona-runtime-health')
        self.log = self.home / 'calls'

    def fake(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(SHIM)
        path.chmod(0o755)

    def invoke(self, managed=True, fail=''):
        result = subprocess.run([str(ROOT / '.local/bin/kona-runtime-start')],
                                env={**os.environ, 'HOME': str(self.home),
                                     'PATH': str(self.bin) + ':' + os.environ['PATH'],
                                     'CALLS': str(self.log), 'MANAGED': str(int(managed)), 'FAIL': fail,
                                     'WAYLAND_DISPLAY': 'wayland-test',
                                     'HYPRLAND_INSTANCE_SIGNATURE': 'test-signature',
                                     'XDG_CURRENT_DESKTOP': 'Hyprland', 'XDG_SESSION_TYPE': 'wayland'},
                                capture_output=True, text=True, timeout=10)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        return result, calls

    def test_managed_start_finalizes_before_services_and_defers_trays_to_xdg(self):
        result, calls = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[:3], [['kona-runtime-health', 'wait-owner', '--timeout', '5'],
                                    ['uwsm', 'check', 'is-active', 'hyprland.desktop'],
                                    ['uwsm', 'finalize']])
        self.assertIn(['uwsm', 'app', '-s', 's', '-t', 'scope', '-u', 'kona-waybar', '--', 'waybar'], calls)
        services = next(c for c in calls if c[:3] == ['systemctl', '--user', 'start'])
        self.assertEqual(services[:3], ['systemctl', '--user', 'start'])
        self.assertEqual(set(services[3:]), {'hypridle.service', 'swaync.service',
                         'kona-clipboard@text.service',
                         'kona-clipboard@image.service', 'kona-automount.service', 'kona-osd.service'})
        imported = next(c for c in calls if c[:3] == ['systemctl', '--user', 'import-environment'])
        self.assertTrue({'WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE',
                         'XDG_CURRENT_DESKTOP'}.issubset(imported[3:]))
        self.assertIn(['systemctl', '--user', 'reset-failed', 'hyprpolkitagent.service'], calls)
        self.assertIn(['systemctl', '--user', 'restart', 'hyprpolkitagent.service'], calls)

    def test_plain_start_preserves_original_residents_and_clipboard_types(self):
        result, calls = self.invoke(managed=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('plain Hyprland', result.stderr)
        expected_residents = [
            ['hypridle'], ['waybar'],
            ['nm-applet', '--indicator'], ['blueman-applet'], ['udiskie', '--tray'],
            ['wl-paste', '--type', 'text', '--watch', 'cliphist', 'store'],
            ['wl-paste', '--type', 'image', '--watch', 'cliphist', 'store'],
            ['swayosd-server', '--config', str(self.home / '.config/swayosd/config.toml'),
             '--style', str(self.home / '.config/swayosd/style.css')]]
        for expected in expected_residents:
            self.assertIn(expected, calls)
        self.assertIn(['systemctl', '--user', 'reset-failed', 'hyprpolkitagent.service'], calls)
        self.assertIn(['systemctl', '--user', 'restart', 'hyprpolkitagent.service'], calls)
        self.assertEqual(sum(c[0] == 'kona-runtime-health' for c in calls), 3)

    def test_finalization_failure_does_not_start_services_or_fallback_duplicates(self):
        result, calls = self.invoke(fail='uwsm:finalize')
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(calls), 3)

    def test_plain_polkit_failure_does_not_prevent_unrelated_residents(self):
        result, calls = self.invoke(managed=False, fail='systemctl:--user')
        # Legacy Lua launches these independently; one failed owner must not
        # prevent network, Bluetooth, media, clipboard or OSD startup.
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['nm-applet', '--indicator'], calls)
        self.assertIn(['blueman-applet'], calls)
        self.assertIn(['udiskie', '--tray'], calls)
        self.assertEqual(sum(c[0] == 'wl-paste' for c in calls), 2)
        self.assertTrue(any(c[0] == 'swayosd-server' for c in calls))

    def test_noncanonical_hyprland_does_not_launch_duplicate_session_owners(self):
        health = self.home / '.local/bin/kona-runtime-health'
        health.write_text(SHIM + "\nif sys.argv[1:]==['wait-owner','--timeout','5']:sys.exit(1)\n")
        health.chmod(0o755)
        result, calls = self.invoke(managed=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [['kona-runtime-health', 'wait-owner', '--timeout', '5']])
        self.assertIn('skipping duplicate session startup', result.stderr)

    def test_service_failure_remains_failure_without_legacy_duplicate_launches(self):
        result, calls = self.invoke(fail='systemctl:--user')
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(calls), 5)

    def test_recovery_manifest_owns_exactly_the_shipped_unit_files(self):
        units = ROOT / '.config/systemd/user'
        expected = {str(p.relative_to(units)) for p in units.rglob('*') if p.is_file()}
        self.assertEqual(set((ROOT / 'packages/kona-user-units.txt').read_text().splitlines()), expected)

    def test_polkit_unit_has_bounded_session_readiness_gate(self):
        dropin = (ROOT / '.config/systemd/user/hyprpolkitagent.service.d/50-kona.conf').read_text()
        self.assertIn('ExecCondition=%h/.local/bin/kona-runtime-health ready', dropin)
        self.assertIn('Restart=on-failure', dropin)
        self.assertIn('RestartSec=2', dropin)
        self.assertIn('StartLimitIntervalSec=30', dropin)
        self.assertIn('StartLimitBurst=3', dropin)

    def test_plain_shutdown_stops_packaged_polkit_owner(self):
        lua = (ROOT / '.config/hypr/hyprland.lua').read_text()
        shutdown = lua.split('hl.on("hyprland.shutdown"', 1)[1].split('end)', 1)[0]
        self.assertIn('systemctl --user stop hyprpolkitagent.service', shutdown)


class PolkitHealth(unittest.TestCase):
    environment = {'WAYLAND_DISPLAY': 'wayland-1', 'HYPRLAND_INSTANCE_SIGNATURE': 'current'}
    healthy_unit = {
        'LoadState': 'loaded', 'ActiveState': 'active', 'SubState': 'running',
        'Result': 'success', 'MainPID': '42', 'NRestarts': '0',
    }
    healthy_process = [{'pid': 42, 'environment': environment}]

    def evaluate(self, unit=None, processes=None, ready=True):
        return HEALTH['evaluate_polkit'](
            unit or dict(self.healthy_unit),
            self.healthy_process if processes is None else processes,
            self.environment,
            ready,
        )

    def test_healthy_systemd_owned_agent_passes(self):
        self.assertTrue(self.evaluate()['ok'])

    def test_missing_or_duplicate_agent_fails(self):
        self.assertFalse(self.evaluate(processes=[])['ok'])
        duplicate = self.healthy_process + [{'pid': 43, 'environment': self.environment}]
        self.assertFalse(self.evaluate(processes=duplicate)['ok'])

    def test_start_limit_and_owner_disagreement_fail(self):
        failed = dict(self.healthy_unit, ActiveState='failed', SubState='failed',
                      Result='start-limit-hit', MainPID='0')
        self.assertFalse(self.evaluate(unit=failed, processes=[])['ok'])
        mismatch = dict(self.healthy_unit, MainPID='99')
        self.assertFalse(self.evaluate(unit=mismatch)['ok'])

    def test_stale_wayland_environment_fails(self):
        stale = [{'pid': 42, 'environment': dict(self.environment, WAYLAND_DISPLAY='wayland-0')}]
        self.assertFalse(self.evaluate(processes=stale)['ok'])

    def test_start_event_waits_for_hyprland_instance_registration(self):
        ownership = mock.Mock(side_effect=[(False, 'no live Hyprland instance exists'), (True, '')])
        function_globals = HEALTH['wait_for_owner'].__globals__
        with mock.patch.dict(function_globals, {
            'is_canonical_invocation': ownership,
            'canonical_instance': mock.Mock(return_value=None),
        }), mock.patch.object(function_globals['time'], 'sleep'):
            self.assertEqual(HEALTH['wait_for_owner'](1), (True, ''))
        self.assertEqual(ownership.call_count, 2)


if __name__ == '__main__':
    unittest.main()
