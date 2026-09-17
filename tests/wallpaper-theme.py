#!/usr/bin/env python3
"""Wallpaper success/failure and representative-image contract; no live IPC."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallpaperThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / '.local/bin'
        self.bin.mkdir(parents=True)
        (self.bin/'kona-profile').symlink_to(ROOT/'.local/bin/kona-profile')
        (self.bin/'kona-wallpaper').symlink_to(ROOT/'.local/bin/kona-wallpaper')
        from profile_fixture import assets
        assets(self.home)
        self.log = self.home / 'calls.jsonl'
        self.env = {**os.environ, 'HOME': str(self.home), 'XDG_RUNTIME_DIR': str(self.home / 'run'),
                    'XDG_STATE_HOME': str(self.home / 'state'), 'PATH': str(self.bin) + ':/usr/bin:/bin',
                    'KONA_TEST_LOG': str(self.log)}
        common = '''#!/usr/bin/python3
import json,os,sys
from pathlib import Path
name=Path(sys.argv[0]).name
with open(os.environ['KONA_TEST_LOG'],'a') as f:f.write(json.dumps([name,*sys.argv[1:]])+'\\n')
'''
        programs = {'pgrep': "sys.exit(0 if sys.argv[-1]=='awww-daemon' else 1)", 'pkill': '', 'notify-send': '',
                    'hyprctl': "print('[]')", 'jq': "print('LEFT\\nCENTER\\nRIGHT')",
                    'awww': "sys.exit(1 if os.environ.get('KONA_TEST_FAIL')=='wallpaper' and sys.argv[1]=='img' else 0)",
                    'kona-theme': "sys.exit(1 if os.environ.get('KONA_TEST_FAIL')=='theme' else 0)"}
        for name, code in programs.items():
            p = self.bin / name
            p.write_text(common + code + '\n')
            p.chmod(0o755)

    def call(self, mode):
        return subprocess.run(['bash', str(ROOT / '.local/bin/kona-wallpaper'), mode],
                              env=self.env, capture_output=True, text=True, timeout=8)

    def calls(self):
        return [json.loads(x) for x in self.log.read_text().splitlines()]

    def test_each_mode_generates_once_after_all_outputs(self):
        for mode, suffix, count in [('simple','v2/selected.png',1),('static','center.png',3),('animated','animated/center.webp',3)]:
            with self.subTest(mode=mode):
                self.log.write_text('')
                result = self.call(mode)
                self.assertEqual(result.returncode, 0, result.stderr)
                calls = self.calls()
                images = [i for i,c in enumerate(calls) if c[:2] == ['awww','img']]
                theme = [(i,c) for i,c in enumerate(calls) if c[0]=='kona-theme']
                self.assertEqual(len(images), count)
                self.assertEqual(len(theme), 1)
                self.assertGreater(theme[0][0], max(images))
                self.assertEqual(theme[0][1][1], '--image')
                self.assertTrue(theme[0][1][2].endswith(suffix))

    def test_wallpaper_failure_does_not_theme_or_persist_new_mode(self):
        self.env['KONA_TEST_FAIL']='wallpaper'
        for mode in ['simple','static','animated','toggle','restore']:
            with self.subTest(mode=mode):
                self.log.write_text('')
                self.assertNotEqual(self.call(mode).returncode, 0)
                self.assertFalse(any(c[0]=='kona-theme' for c in self.calls()))
                self.assertFalse((self.home/'state/kona-wallpaper-mode').exists())

    def test_theme_failure_keeps_wallpaper_success(self):
        self.env['KONA_TEST_FAIL']='theme'
        result=self.call('simple')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('theme generation/reload failed',result.stderr)
        self.assertEqual((self.home/'state/kona-wallpaper-mode').read_text(),'simple\n')

    def test_status_never_generates(self):
        self.assertEqual(self.call('status').returncode,0)
        self.assertFalse(self.log.exists())


if __name__=='__main__':unittest.main()
