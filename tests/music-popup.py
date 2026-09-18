#!/usr/bin/env python3
"""Music host lifecycle contracts; no desktop or real media manipulation."""
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
HOST = ROOT / '.local/bin/kona-music-popup'

class MusicHost(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='kona-music-test-')
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.env = dict(os.environ, HOME=str(self.root), XDG_RUNTIME_DIR=str(self.root),
                        XDG_STATE_HOME=str(self.root / 'state'), PATH='/usr/bin:/bin')

    def test_close_is_noop_when_no_popup_or_optional_quickshell_exists(self):
        result = subprocess.run([str(HOST), 'close'], env=self.env, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / 'state/kona/music-popup.log').exists())

    def test_invalid_action_cannot_start_a_surface(self):
        result = subprocess.run([str(HOST), 'invalid'], env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b'usage:', result.stderr)
        self.assertFalse((self.root / 'kona/music-popup.lock').exists())

    def test_terminating_launcher_releases_its_ui_and_owned_child(self):
        fake = self.root / 'quickshell'
        fake.write_text('#!/usr/bin/env python3\nimport subprocess,os,time\nfrom pathlib import Path\nchild=subprocess.Popen(["sleep","30"])\nPath(os.environ["HOME"],"pids").write_text(str(os.getpid())+" "+str(child.pid))\ntry:time.sleep(30)\nfinally:child.terminate();child.wait()\n')
        fake.chmod(0o755)
        self.env['PATH'] = str(self.root) + ':/usr/bin:/bin'
        host = subprocess.Popen([str(HOST)], env=self.env)
        try:
            end = time.monotonic() + 3
            while not (self.root / 'pids').exists() and time.monotonic() < end:
                time.sleep(.01)
            pids = [int(x) for x in (self.root / 'pids').read_text().split()]
            host.terminate();host.wait(timeout=6)
            end = time.monotonic() + 2
            while time.monotonic() < end:
                alive = []
                for pid in pids:
                    try:
                        state = Path(f'/proc/{pid}/stat').read_text().rsplit(')',1)[1].split()[0]
                        if state != 'Z':alive.append(pid)
                    except FileNotFoundError:pass
                if not alive:break
                time.sleep(.01)
            self.assertEqual(alive, [])
        finally:
            if host.poll() is None:host.terminate();host.wait(timeout=6)

    def test_native_surface_preserves_real_backend_controls(self):
        view = (ROOT / '.config/quickshell/kona/music/MusicPopupView.qml').read_text()
        shell = (ROOT / '.config/quickshell/kona/music/shell.qml').read_text()
        self.assertIn('width: 1260', view)
        self.assertIn('height: 252', view)
        self.assertNotIn('music_shell_', view)
        self.assertIn('radius: 30', view)
        self.assertIn('maskSource: albumMask', view)
        self.assertIn('requestSeek', view)
        self.assertIn('requestVolume', view)
        self.assertIn('requestDeviceMenu', view)
        self.assertIn('values: root.spectrumValues', view)
        self.assertIn('running: root.opened && !!root.player && root.player.isPlaying', shell)
        self.assertIn('Pipewire.defaultAudioSink', shell)
        for asset in ('shuffle', 'previous', 'play', 'pause', 'next', 'repeat', 'device'):
            self.assertTrue((ROOT / f'.config/quickshell/kona/music/assets/light/{asset}.svg').is_file())
            self.assertTrue((ROOT / f'.config/quickshell/kona/music/assets/dark/{asset}.svg').is_file())
        self.assertIn('root.icon("shuffle")', view)
        self.assertIn('root.icon(root.playing ? "pause" : "play")', view)
        self.assertNotIn('ui/seek_slider.png', view)
        self.assertNotIn('ui/volume_slider.png', view)
        self.assertNotIn('ui/waveform.png', view)

if __name__ == '__main__':
    unittest.main(verbosity=2)
