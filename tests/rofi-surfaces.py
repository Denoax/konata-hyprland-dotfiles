#!/usr/bin/env python3
"""Exercise Rofi selection boundaries with isolated clipboard/device/session owners."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SHIM = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
home = Path(os.environ['HOME'])
with (home/'calls').open('a') as log:
    log.write(json.dumps([name, *sys.argv[1:]])+'\n')
if name == 'rofi':
    (home/'rofi-input').write_bytes(sys.stdin.buffer.read())
    state = home/'rofi-call'
    index = int(state.read_text()) if state.exists() else 0
    state.write_text(str(index+1))
    answers = json.loads(os.environ.get('ANSWERS', '[]'))
    if index >= len(answers) or answers[index] is None:
        sys.exit(1)
    answer = answers[index]
    if isinstance(answer, dict):
        print(answer.get('text', ''))
        sys.exit(answer.get('status', 0))
    print(answer)
elif name == 'pactl':
    args = sys.argv[1:]
    if args == ['get-default-sink']: print('first')
    elif args == ['get-default-source']: print('mic')
    elif args[:3] == ['-f', 'json', 'list']:
        values = {
            'sinks': [{'name':'first','description':'Same label'},
                      {'name':'second','description':'Same label'},
                      {'name':'third','description':'Same label'}],
            'sources': [],
            'sink-inputs': [
                {'index':17,'properties':{'application.name':'Player'},
                 'volume':{'mono':{'value_percent':'50%'}},'mute':False},
                {'index':23,'properties':{'application.name':'Player'},
                 'volume':{'mono':{'value_percent':'50%'}},'mute':False}],
            'source-outputs': []}
        print(json.dumps(values[args[3]]))
elif name == 'cliphist':
    if sys.argv[1] == 'list': print('42\tExample preview')
    elif sys.argv[1] == 'decode':
        assert sys.stdin.buffer.read() == b'42\tExample preview'
        if os.environ.get('DECODE_FAIL'): sys.exit(9)
        sys.stdout.buffer.write(b'\x89PNG\r\n\x1a\n\x00binary\n')
    elif sys.argv[1] == 'delete':
        (home/'deleted-item').write_bytes(sys.stdin.buffer.read())
    elif sys.argv[1] == 'wipe':
        (home/'history-wiped').touch()
elif name == 'wl-copy':
    (home/'clipboard').write_bytes(sys.stdin.buffer.read())
elif name == 'kona-confirm':
    sys.exit(int(os.environ.get('CONFIRM_STATUS', '1')))
'''


class RofiActions(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kona rofi qa ')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home/'.local/bin'
        self.bin.mkdir(parents=True)
        self.runtime = self.home/'runtime'
        self.runtime.mkdir()
        self.env = {**os.environ, 'HOME':str(self.home), 'XDG_RUNTIME_DIR':str(self.runtime),
                    'PATH':str(self.bin)+':'+os.environ['PATH']}
        for name in ['rofi', 'pactl', 'cliphist', 'wl-copy', 'kona-osd',
                     'kona-wallpaper', 'kona-menu-sound', 'kona-confirm', 'notify-send',
                     'hyprlock', 'hyprctl', 'systemctl']:
            file = self.bin/name
            file.write_text(SHIM)
            file.chmod(0o755)

    def invoke(self, script, answers, **env):
        return subprocess.run(['bash', str(ROOT/'.local/bin'/script)],
                              env={**self.env, 'ANSWERS':json.dumps(answers), **env},
                              capture_output=True, timeout=10)

    def calls(self, name):
        path = self.home/'calls'
        return [c[1:] for line in path.read_text().splitlines()
                if (c := json.loads(line))[0] == name] if path.exists() else []

    def test_duplicate_device_labels_select_the_original_row(self):
        result = self.invoke('kona-audio-menu', ['6'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['set-default-sink', 'third'], self.calls('pactl'))
        self.assertIn(['move-sink-input', '17', 'third'], self.calls('pactl'))

    def test_duplicate_app_names_target_the_selected_stream(self):
        result = self.invoke('kona-app-mixer', ['1', 'Volume +5%'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['set-sink-input-volume', '23', '+5%'], self.calls('pactl'))

    def test_invalid_device_index_has_no_audio_side_effect(self):
        for answer in ['-1', '999999999999999999999999', 'Same label; reboot']:
            (self.home/'rofi-call').unlink(missing_ok=True)
            result = self.invoke('kona-audio-menu', [answer])
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(c[0].startswith(('set-', 'move-')) for c in self.calls('pactl')))

    def test_clipboard_cancellation_preserves_existing_contents(self):
        (self.home/'clipboard').write_bytes(b'keep')
        self.assertEqual(self.invoke('kona-clipboard', [None]).returncode, 0)
        self.assertEqual((self.home/'clipboard').read_bytes(), b'keep')
        self.assertEqual(list(self.runtime.iterdir()), [])

    def test_failed_decode_does_not_replace_clipboard(self):
        (self.home/'clipboard').write_bytes(b'keep')
        result = self.invoke('kona-clipboard', ['42\tExample preview'], DECODE_FAIL='1')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.home/'clipboard').read_bytes(), b'keep')
        self.assertEqual(list(self.runtime.iterdir()), [])

    def test_binary_clipboard_item_is_preserved_byte_for_byte(self):
        result = self.invoke('kona-clipboard', ['42\tExample preview'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home/'clipboard').read_bytes(), b'\x89PNG\r\n\x1a\n\x00binary\n')
        self.assertEqual(list(self.runtime.iterdir()), [])

    def test_clipboard_delete_and_clear_are_confirmation_gated(self):
        selected = {'text':'42\tExample preview', 'status':10}
        self.assertEqual(self.invoke('kona-clipboard', [selected], CONFIRM_STATUS='1').returncode, 0)
        self.assertFalse((self.home/'deleted-item').exists())
        (self.home/'rofi-call').unlink()
        self.assertEqual(self.invoke('kona-clipboard', [selected], CONFIRM_STATUS='0').returncode, 0)
        self.assertEqual((self.home/'deleted-item').read_bytes(), b'42\tExample preview')
        clear = {'text':'', 'status':11}
        (self.home/'rofi-call').unlink()
        self.assertEqual(self.invoke('kona-clipboard', [clear], CONFIRM_STATUS='1').returncode, 0)
        self.assertFalse((self.home/'history-wiped').exists())
        (self.home/'rofi-call').unlink()
        self.assertEqual(self.invoke('kona-clipboard', [clear], CONFIRM_STATUS='0').returncode, 0)
        self.assertTrue((self.home/'history-wiped').exists())

    def wallpaper_set(self, mode):
        root = self.home/'.local/share/wallpapers/konata-command-center'
        names = {'simple':['v2/selected.png'], 'static':['left.png','center.png','right.png'],
                 'animated':['animated/left.webp','animated/center.webp','animated/right.webp']}
        for name in names[mode]:
            file = root/name
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(b'fixture')

    def test_wallpaper_selection_delegates_to_existing_mode_owner(self):
        for mode in ['simple','static','animated']: self.wallpaper_set(mode)
        result = self.invoke('kona-wallpaper-menu', ['2'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls('kona-wallpaper'), [['animated']])
        self.assertIn(b'\0icon\x1f', (self.home/'rofi-input').read_bytes())

    def test_missing_wallpaper_sets_do_not_shift_selection_to_wrong_mode(self):
        self.wallpaper_set('animated')
        result = self.invoke('kona-wallpaper-menu', ['0'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls('kona-wallpaper'), [['animated']])

    def test_missing_wallpaper_assets_do_not_invoke_backend(self):
        self.assertNotEqual(self.invoke('kona-wallpaper-menu', ['0']).returncode, 0)
        self.assertEqual(self.calls('kona-wallpaper'), [])

    def test_session_cancel_never_runs_power_action(self):
        self.invoke('kona-session-menu', ['Restart'], CONFIRM_STATUS='1')
        self.assertEqual(self.calls('systemctl'), [])
        self.assertEqual(self.calls('hyprctl'), [])

    def test_session_requires_matching_confirmation(self):
        self.invoke('kona-session-menu', ['Restart'], CONFIRM_STATUS='1')
        self.assertEqual(self.calls('systemctl'), [])
        (self.home/'rofi-call').unlink()
        self.invoke('kona-session-menu', ['Restart'], CONFIRM_STATUS='0')
        self.assertEqual(self.calls('systemctl'), [['reboot']])

    def test_network_uses_uuid_and_preserves_escaped_duplicate_names(self):
        nmcli = self.bin/'nmcli'
        nmcli.write_text(r'''#!/usr/bin/env bash
if [[ "$*" == '-t -f WIFI general' ]]; then echo enabled
elif [[ "$*" == '-t -f UUID connection show --active' ]]; then echo u2
elif [[ "$*" == '-t --escape yes -f UUID,NAME,TYPE connection show' ]]; then
  printf '%s\n' 'u1:Office\:Desk:802-11-wireless' 'u2:Office\:Desk:802-11-wireless'
elif [[ "$*" == 'connection up uuid u2' ]]; then echo "$*" > "$HOME/nmcli-action"
else exit 9
fi
''')
        nmcli.chmod(0o755)
        checked = subprocess.run(['bash', str(ROOT/'.local/bin/kona-network-menu'), '--check'],
                                 env=self.env, capture_output=True, text=True, timeout=5)
        self.assertEqual(checked.returncode, 0, checked.stderr)
        self.assertIn('active=u2 saved_connections=2', checked.stdout)
        result = self.invoke('kona-network-menu', ['3'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home/'nmcli-action').read_text().strip(), 'connection up uuid u2')

    def test_new_danger_export_preserves_other_theme_consumers(self):
        model = runpy.run_path(str(ROOT/'.local/bin/kona-theme'))
        base = json.loads((ROOT/'.config/kona/theme/default/appearance.json').read_text())
        rendered = model['render'](base)
        self.assertIn('danger: '+base['danger']+';', rendered['rofi.rasi'])
        for name in ['tokens.json','appearance.json','waybar.css','swaync.css','hyprland.colors']:
            self.assertEqual(rendered[name], (ROOT/'.config/kona/theme/default'/name).read_text())


if __name__ == '__main__':
    unittest.main()
