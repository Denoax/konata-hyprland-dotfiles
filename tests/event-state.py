#!/usr/bin/env python3
"""Offline contracts: real shell workers/flock/files, controlled IPC and recorder."""
import fcntl
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest
from profile_fixture import install as install_profile_fakes, assets as profile_assets

REPO = Path(__file__).resolve().parents[1]

class EventState(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kona-event-test-')
        self.root = Path(self.temp.name)
        self.home = self.root / 'home'
        self.bin = self.home / '.local/bin'
        self.bin.mkdir(parents=True)
        for source in (REPO / '.local/bin').glob('kona-*'):
            (self.bin / source.name).symlink_to(source)
        config = self.home / '.config/kona'
        config.mkdir(parents=True)
        (config / 'motion.json').write_bytes((REPO / '.config/kona/motion.json').read_bytes())
        self.fake = self.root / 'fake'
        self.fake.mkdir()
        self.runtime = self.root / 'runtime'
        self.state = self.root / 'state'
        self.runtime.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), XDG_RUNTIME_DIR=str(self.runtime),
                        XDG_STATE_HOME=str(self.state), FIXTURE=str(self.root),
                        PATH=str(self.fake)+':'+os.environ['PATH'])
        self.clients = [dict(mapped=True, initialClass='kitty', **{'class':'kitty'},
                             workspace={'id':5},floating=True,fullscreen=0,at=[2000,100],size=[900,650])]
        self.monitors = [dict(name='DP-4',activeWorkspace={'id':5},specialWorkspace={'id':0},focused=True)]
        self.write('clients.json', self.clients)
        self.write('monitors.json', self.monitors)
        self.command('hyprctl', '''#!/usr/bin/env python3
import os,json,sys,time
from pathlib import Path
p=Path(os.environ['FIXTURE'])
with (p/'ipc.log').open('a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')
if (p/'ipc-fail').exists():sys.exit(1)
if sys.argv[1] in ['clients','monitors']:
 print((p/(sys.argv[1]+'.json')).read_text())
else: print('ok')
''')
        self.command('grim', '''#!/usr/bin/env python3
import os,sys,time
from pathlib import Path
p=Path(os.environ['FIXTURE'])
with (p/'grim.log').open('a') as f:f.write('capture\\n')
with open(sys.argv[-1],'wb') as f:
 f.write(b'partial'); f.flush()
 if (p/'slow-grim').exists():time.sleep(.15)
 if (p/'grim-fail').exists():sys.exit(1)
 f.write(b'-complete')
if (p/'disappear').exists():(p/'monitors.json').write_text('[]')
''')
        self.command('pkill', '''#!/usr/bin/env python3
import os,json,sys
from pathlib import Path
p=Path(os.environ['FIXTURE'])
with (p/'signals.log').open('a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')
sys.exit(1 if (p/'waybar-absent').exists() else 0)
''')
        self.command('notify-send', '#!/bin/sh\nexit 0\n')
        # Preserve the real record worker but avoid OSD processes in this fixture.
        (self.bin/'kona-osd').unlink()
        (self.bin/'kona-osd').write_text('#!/bin/sh\nexit 0\n')
        (self.bin/'kona-osd').chmod(0o755)
        install_profile_fakes(self.fake, self.root)
        profile_assets(self.home)

    def tearDown(self):
        pidfile=self.runtime/'kona-record/pid'
        if pidfile.exists():
            try:os.kill(int(pidfile.read_text()), signal.SIGTERM)
            except (ProcessLookupError,ValueError):pass
        self.temp.cleanup()

    def write(self,name,data):
        (self.root/name).write_text(json.dumps(data))

    def command(self,name,text):
        p=self.fake/name;p.write_text(text);p.chmod(0o755)

    def run_worker(self,name,*args,ok=True):
        p=subprocess.run([str(self.bin/name),*args],env=self.env,text=True,capture_output=True,timeout=15)
        if ok:self.assertEqual(p.returncode,0,p.stdout+p.stderr)
        return p

    def test_signal_mapping_and_absent_waybar(self):
        for name,offset in [('recording',8),('gaming',9)]:
            self.run_worker('kona-waybar-refresh',name)
            args=json.loads((self.root/'signals.log').read_text().splitlines()[-1])
            self.assertEqual(args,[f'-RTMIN+{offset}','-u',str(os.getuid()),'-x','waybar'])
        (self.root/'waybar-absent').touch()
        self.run_worker('kona-waybar-refresh','recording')
        self.assertEqual(self.run_worker('kona-waybar-refresh','invalid',ok=False).returncode,2)
        config=json.loads((REPO/'.config/waybar/config.jsonc').read_text())
        bars=config if isinstance(config,list) else [config]
        for name,offset in [('recording',8),('gaming',9)]:
            modules=[bar['custom/'+name] for bar in bars if 'custom/'+name in bar]
            self.assertEqual(len(modules),1)
            module=modules[0]
            self.assertEqual(module['signal'],offset)
            self.assertNotIn('interval',module)
            self.assertFalse(module['exec-on-event'])
        gpu=[bar['custom/gpu'] for bar in bars if 'custom/gpu' in bar]
        self.assertEqual(len(gpu),1)
        self.assertEqual(gpu[0]['interval'],5)

    def test_session_legacy_format_atomic_idempotence_and_failure(self):
        self.run_worker('kona-session-save','--quiet')
        p=self.state/'kona/session.json'
        data=json.loads(p.read_text())
        self.assertEqual(data,[dict(**{'class':'kitty'},command=['kitty'],workspace=5,
                                   floating=True,fullscreen=0,x=2000,y=100,width=900,height=650)])
        before=(p.stat().st_ino,p.stat().st_mtime_ns,p.read_bytes())
        self.run_worker('kona-session-save','--quiet')
        self.assertEqual(before,(p.stat().st_ino,p.stat().st_mtime_ns,p.read_bytes()))
        (self.root/'ipc-fail').touch()
        self.assertNotEqual(self.run_worker('kona-session-save','--quiet',ok=False).returncode,0)
        self.assertEqual(p.read_bytes(),before[2])
        self.assertEqual(list(p.parent.glob('.session.*')),[])
        (self.root/'ipc-fail').unlink()
        self.write('clients.json', {})
        self.assertNotEqual(self.run_worker('kona-session-save','--quiet',ok=False).returncode,0)
        self.assertEqual(p.read_bytes(),before[2])

    def test_session_lock_serializes_concurrent_writers(self):
        parent=self.state/'kona';parent.mkdir(parents=True)
        with (parent/'session.lock').open('w') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            workers=[subprocess.Popen([str(self.bin/'kona-session-save'),'--quiet'],env=self.env,
                                     stdout=subprocess.PIPE,stderr=subprocess.PIPE) for _ in range(8)]
            time.sleep(.15)
            self.assertFalse((self.root/'ipc.log').exists(),'IPC must occur under the shared writer lock')
            fcntl.flock(lock,fcntl.LOCK_UN)
            for worker in workers:
                out,err=worker.communicate(timeout=10)
                self.assertEqual(worker.returncode,0,err)
        self.assertEqual(len(json.loads((parent/'session.json').read_text())),1)
        self.assertEqual(list(parent.glob('.session.*')),[])

    def test_capture_atomic_failure_disappearance_and_args(self):
        self.run_worker('kona-workspace-capture','5')
        image=self.runtime/'kona-overview/workspace-5.png'
        self.assertEqual(image.read_bytes(),b'partial-complete')
        before=(image.stat().st_ino,image.stat().st_mtime_ns,image.read_bytes())
        (self.root/'grim-fail').touch()
        self.assertNotEqual(self.run_worker('kona-workspace-capture','5',ok=False).returncode,0)
        self.assertEqual(before,(image.stat().st_ino,image.stat().st_mtime_ns,image.read_bytes()))
        (self.root/'grim-fail').unlink();(self.root/'disappear').touch()
        self.run_worker('kona-workspace-capture','5')
        self.assertEqual(image.read_bytes(),before[2])
        self.assertEqual(image.stat().st_ino,before[0])
        for arg in ['0','11','../5','5;touch bad','--bad']:
            self.assertEqual(self.run_worker('kona-workspace-capture',arg,ok=False).returncode,2)
        self.assertEqual(list(image.parent.glob('.workspace*')),[])

    def test_capture_serialization_and_overview_gate(self):
        self.run_worker('kona-workspace-capture','5')
        image=self.runtime/'kona-overview/workspace-5.png'
        (self.root/'slow-grim').touch()
        workers=[subprocess.Popen([str(self.bin/'kona-workspace-capture'),'5'],env=self.env,
                                 stdout=subprocess.PIPE,stderr=subprocess.PIPE) for _ in range(3)]
        while any(w.poll() is None for w in workers):
            self.assertEqual(image.read_bytes(),b'partial-complete')
            time.sleep(.01)
        for w in workers:self.assertEqual(w.returncode,0,w.communicate()[1])
        before=(self.root/'grim.log').read_text()
        with (image.parent/'overview.lock').open('w') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            self.run_worker('kona-workspace-capture','5')
            self.assertEqual(before,(self.root/'grim.log').read_text())
            self.run_worker('kona-workspace-capture','--visible')
        (self.runtime/'kona-game-mode').touch()
        before=(self.root/'grim.log').read_text()
        self.run_worker('kona-workspace-capture','5')
        self.assertEqual(before,(self.root/'grim.log').read_text())

    def test_missing_runtime_state_and_legacy_interfaces(self):
        shutil.rmtree(self.runtime)
        view=json.loads(self.run_worker('kona-state').stdout)
        self.assertEqual(view,dict(schema=1,profile='daily',return_to='daily',scene='constellation-motion',gaming={'active':False},recording={'active':False},
                                   wallpaper={'mode':'animated'},night_light={'mode':'scheduled'}))
        self.run_worker('kona-session-daemon')
        self.assertTrue((self.state/'kona/session-restore-enabled').exists())
        self.run_worker('kona-workspace-history-daemon')
        self.assertTrue((self.runtime/'kona-overview/workspace-5.png').exists())
        report=self.run_worker('kona-overview','--check').stdout
        self.assertIn('workspace_cards=10',report)
        self.assertEqual(len((self.runtime/'kona-overview/menu').read_bytes().splitlines()),10)

    def test_gaming_transitions_and_reconcile(self):
        self.write('monitors.json', [dict(name=n,x=i*1920) for i,n in enumerate(['LEFT','CENTER','RIGHT'])])
        self.run_worker('kona-game-mode','on')
        self.assertEqual(self.run_worker('kona-game-mode','status').stdout,'on\n')
        self.assertTrue(json.loads(self.run_worker('kona-state').stdout)['gaming']['active'])
        self.run_worker('kona-game-mode','reconcile')
        self.run_worker('kona-game-mode','toggle')
        self.assertEqual(self.run_worker('kona-game-mode','status').stdout,'off\n')
        self.assertEqual(sum(json.loads(line)[0]=='-RTMIN+9' for line in (self.root/'signals.log').read_text().splitlines()),2)

    def test_failed_gaming_toggle_retains_intent_and_reports_failure(self):
        self.write('monitors.json', [dict(name=n,x=i*1920) for i,n in enumerate(['LEFT','CENTER','RIGHT'])])
        self.run_worker('kona-game-mode','on')
        (self.root/'ipc-fail').touch()
        before=(self.root/'signals.log').read_text()
        self.assertNotEqual(self.run_worker('kona-game-mode','toggle',ok=False).returncode,0)
        self.assertEqual(self.run_worker('kona-game-mode','status').stdout,'on\n')
        self.assertEqual((self.root/'signals.log').read_text(),before)
        calls=[json.loads(line) for line in (self.root/'ipc.log').read_text().splitlines()]
        self.assertEqual(json.loads((self.state/'kona/profile.json').read_text())['profile'],'gaming')
        self.assertTrue((self.runtime/'kona/profile-transition.json').exists(),'Failed IPC leaves an explicit recoverable transaction')

    def test_recording_lifecycle_and_unexpected_exit(self):
        recorder=self.home/'.local/opt/kona-pkgs/wf-recorder/usr/bin/wf-recorder'
        recorder.parent.mkdir(parents=True)
        recorder.write_text('''#!/usr/bin/env python3
import signal,time,sys
signal.signal(signal.SIGINT,lambda *_:sys.exit(0))
signal.signal(signal.SIGTERM,lambda *_:sys.exit(1))
while True:signal.pause()
''');recorder.chmod(0o755)
        self.run_worker('kona-record','output')
        self.assertEqual(json.loads(self.run_worker('kona-record-status').stdout)['class'],'recording')
        self.run_worker('kona-record','output')
        self.assertEqual(json.loads(self.run_worker('kona-record-status').stdout)['class'],'idle')
        self.run_worker('kona-record','output')
        pid=int((self.runtime/'kona-record/pid').read_text())
        os.kill(pid,signal.SIGTERM)
        deadline=time.monotonic()+3
        while (self.runtime/'kona-record/pid').exists() and time.monotonic()<deadline:time.sleep(.02)
        self.assertFalse((self.runtime/'kona-record/pid').exists())
        self.assertEqual(json.loads(self.run_worker('kona-record-status').stdout)['class'],'idle')
        recorder.write_text('#!/bin/sh\nexit 7\n');recorder.chmod(0o755)
        self.assertNotEqual(self.run_worker('kona-record','output',ok=False).returncode,0)
        self.assertEqual(json.loads(self.run_worker('kona-record-status').stdout)['class'],'idle')
        self.assertFalse((self.runtime/'kona-record/pid').exists())

if __name__=='__main__':unittest.main(verbosity=2)
