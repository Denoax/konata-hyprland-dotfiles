#!/usr/bin/env python3
"""Exercise real profile coordinator, shell backend, state files and rollback."""
import json
import fcntl
import time
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from profile_fixture import install, assets

ROOT = Path(__file__).resolve().parents[1]


class Profiles(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kona profile ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'home'
        self.bin = self.home / '.local/bin'
        self.bin.mkdir(parents=True)
        for name in ('kona-profile', 'kona-wallpaper', 'kona-game-mode', 'kona-waybar-refresh'):
            (self.bin / name).symlink_to(ROOT / '.local/bin' / name)
        for name in ('kona-theme', 'notify-send'):
            p = self.bin / name
            p.write_text('#!/bin/sh\nexit 0\n')
            p.chmod(0o755)
        p = self.bin / 'kona-osd'
        p.write_text('#!/usr/bin/env python3\nimport os,sys,json\nfrom pathlib import Path\nwith (Path(os.environ["FIXTURE"])/"osd.log").open("a") as f:f.write(json.dumps(sys.argv[1:])+"\\n")\nsys.exit(int(os.environ.get("KONA_TEST_OSD_FAIL","0")))\n')
        p.chmod(0o755)
        self.fake = self.root / 'fake'
        self.fake.mkdir()
        install(self.fake, self.root)
        assets(self.home)
        self.state = self.root / 'state'
        self.runtime = self.root / 'runtime'
        self.state.mkdir()
        self.runtime.mkdir()
        (self.state / 'kona-wallpaper-mode').write_text('simple\n')
        (self.root / 'monitors.json').write_text(json.dumps([{'name': n, 'x': i*1920} for i,n in enumerate(['LEFT','CENTER','RIGHT'])]))
        self.env = {**os.environ, 'HOME': str(self.home), 'FIXTURE':str(self.root),
                    'XDG_STATE_HOME':str(self.state), 'XDG_RUNTIME_DIR':str(self.runtime),
                    'PATH':str(self.fake)+':'+str(self.bin)+':/usr/bin:/bin'}

    def call(self, *args, ok=True, command='kona-profile'):
        p = subprocess.run([str(self.bin/command),*args],env=self.env,capture_output=True,text=True,timeout=20)
        if ok:self.assertEqual(p.returncode,0,p.stderr+p.stdout)
        return p

    def backend(self):return json.loads((self.root/'backend.json').read_text())
    def view(self):return json.loads(self.call('status').stdout)
    def intent(self):return json.loads((self.state/'kona/profile.json').read_text())

    def test_visualizer_pause_resume_preserves_identity_and_prior_stop(self):
        import runpy
        import signal
        m = runpy.run_path(str(ROOT / '.local/bin/kona-profile'))
        worker = subprocess.Popen(['sleep', '30'])
        try:
            saved = m['identity'](worker.pid)
            m['set_visualizers']([saved], True)
            os.waitpid(worker.pid, os.WUNTRACED)
            self.assertEqual(m['identity'](worker.pid)['state'], 'T')
            m['set_visualizers']([{**saved, 'start_ticks': saved['start_ticks'] + 1}], False)
            self.assertEqual(m['identity'](worker.pid)['state'], 'T')
            m['set_visualizers']([saved], False)
            os.waitpid(worker.pid, os.WCONTINUED)
            self.assertNotEqual(m['identity'](worker.pid)['state'], 'T')
        finally:
            os.kill(worker.pid, signal.SIGCONT)
            worker.terminate()
            worker.wait(timeout=5)

    def test_gaming_feedback_preserves_osd_once_per_real_state_change(self):
        self.call('on', command='kona-game-mode')
        self.call('on', command='kona-game-mode')
        self.call('reconcile')
        self.call('off', command='kona-game-mode')
        self.call('off', command='kona-game-mode')
        rows = [json.loads(x) for x in (self.root / 'osd.log').read_text().splitlines()]
        self.assertEqual(rows, [
            ['message', 'Gaming mode enabled', 'applications-games-symbolic'],
            ['message', 'Gaming mode disabled', 'applications-games-symbolic']])

    def test_optional_osd_failure_does_not_undo_applied_gaming_policy(self):
        self.env['KONA_TEST_OSD_FAIL'] = '1'
        result = self.call('on', command='kona-game-mode')
        self.assertEqual(self.view()['profile'], 'gaming')
        self.assertTrue((self.runtime / 'kona-game-mode').exists())
        self.assertIn('OSD feedback failed', result.stderr)

    def test_daily_focus_daily_restores_backend_effects_and_bar(self):
        self.call('set','focus');b=self.backend()
        self.assertTrue(b['hyprpaper']);self.assertFalse(b['awww']);self.assertFalse(b['bar'])
        self.assertFalse(b['effects']['animations.enabled'])
        self.call('set','daily');b=self.backend()
        self.assertTrue(b['awww']);self.assertFalse(b['hyprpaper']);self.assertTrue(b['bar'])
        self.assertTrue(b['effects']['animations.enabled']);self.assertFalse((self.runtime/'kona-game-mode').exists())

    def test_gaming_returns_to_focus_even_after_reconcile(self):
        self.call('set','focus');self.call('on',command='kona-game-mode')
        self.assertTrue((self.runtime/'kona-game-mode').exists());self.assertEqual(self.intent()['return_to'],'focus')
        self.call('reconcile',command='kona-game-mode');self.call('off',command='kona-game-mode')
        self.assertEqual(self.view()['profile'],'focus');self.assertFalse(self.backend()['awww'])
        self.assertFalse((self.runtime/'kona-game-mode').exists())

    def test_daily_gaming_off_restores_original_options(self):
        self.call('on',command='kona-game-mode');b=self.backend()
        self.assertTrue(b['effects']['general.allow_tearing']);self.assertEqual(b['effects']['misc.vrr'],1)
        self.call('off',command='kona-game-mode');b=self.backend()
        self.assertFalse(b['effects']['general.allow_tearing']);self.assertEqual(b['effects']['misc.vrr'],0)
        self.assertTrue(b['bar']);self.assertTrue(b['awww'])

    def test_repeated_on_off_does_not_repeat_effects_writes_or_signals(self):
        self.call('on',command='kona-game-mode');paths=[self.state/'kona/profile.json',self.runtime/'kona/profile-session.json',self.runtime/'kona-game-mode',self.root/'boundary.log']
        before=[(p.stat().st_mtime_ns,p.read_bytes()) for p in paths]
        self.call('on',command='kona-game-mode');self.assertEqual(before,[(p.stat().st_mtime_ns,p.read_bytes()) for p in paths])
        self.call('off',command='kona-game-mode');log=(self.root/'boundary.log').read_bytes();self.call('off',command='kona-game-mode');self.assertEqual(log,(self.root/'boundary.log').read_bytes())

    def test_scene_changes_do_not_change_focus_profile(self):
        self.call('set','focus');self.call('scene','constellation-motion');v=self.view()
        self.assertEqual(v['profile'],'focus');self.assertEqual(v['scene'],'constellation-motion')
        self.assertEqual(v['wallpaper']['mode'],'animated');self.assertEqual(v['wallpaper']['backend'],'hyprpaper')
        self.assertTrue(all('.png,cover' in x for x in self.backend()['paper_images']))
        self.call('set','showcase');self.assertEqual(self.view()['scene'],'constellation-motion')
        self.assertTrue(any('.webp' in str(x) for x in self.backend()['awww_images']))

    def test_showcase_restores_custom_daily_effects_and_hidden_bar(self):
        state={'awww':True,'hyprpaper':False,'bar':False,'effects':{'animations.enabled':False,'decoration.blur.enabled':False,'decoration.shadow.enabled':True,'general.allow_tearing':False,'misc.vrr':2}}
        (self.root/'backend.json').write_text(json.dumps(state));self.call('set','showcase')
        self.assertTrue(self.backend()['effects']['animations.enabled']);self.call('set','daily')
        self.assertEqual(self.backend()['effects'],state['effects']);self.assertFalse(self.backend()['bar'])

    def test_paper_error_with_success_exit_does_not_stop_previous_backend(self):
        self.call('set','daily');state=self.backend();state['paper_error']=True;(self.root/'backend.json').write_text(json.dumps(state))
        self.assertNotEqual(self.call('set','focus',ok=False).returncode,0)
        self.assertEqual(self.view()['profile'],'daily');self.assertTrue(self.backend()['awww'])
        self.assertFalse((self.runtime/'kona-game-mode').exists())

    def test_failed_transition_keeps_intent_and_recovers_after_ipc_returns(self):
        self.call('set','gaming');(self.root/'ipc-fail').touch()
        self.assertNotEqual(self.call('off',command='kona-game-mode',ok=False).returncode,0)
        self.assertEqual(self.intent()['profile'],'gaming');self.assertTrue((self.runtime/'kona/profile-transition.json').exists())
        (self.root/'ipc-fail').unlink();self.call('off',command='kona-game-mode')
        self.assertEqual(self.view()['profile'],'daily');self.assertFalse((self.runtime/'kona/profile-transition.json').exists())

    def test_missing_wallpaper_preserves_selection_and_profile(self):
        self.call('set','daily');(self.home/'.local/share/wallpapers/konata-command-center/center.png').unlink()
        self.assertNotEqual(self.call('scene','constellation',ok=False).returncode,0)
        self.assertEqual(self.view()['scene'],'midnight');self.assertEqual(self.view()['profile'],'daily')
        self.assertTrue(self.backend()['awww'])

    def test_malformed_intent_fails_without_runtime_changes(self):
        p=self.state/'kona/profile.json';p.parent.mkdir();p.write_text('{bad')
        self.assertNotEqual(self.call('set','focus',ok=False).returncode,0)
        self.assertFalse((self.root/'boundary.log').exists());self.assertEqual(p.read_text(),'{bad')

    def test_invalid_inputs_do_not_spawn_or_write(self):
        for args in [('set','other'),('scene','../bad'),('gaming','maybe')]:self.assertNotEqual(self.call(*args,ok=False).returncode,0)
        self.assertFalse((self.root/'boundary.log').exists());self.assertFalse((self.state/'kona/profile.json').exists())

    def test_status_is_read_only_and_exposes_independent_fields(self):
        self.assertEqual(self.view(),{'profile':'daily','return_to':'daily','scene':'midnight','wallpaper':{'mode':'simple','backend':'awww'}})
        self.assertFalse((self.root/'boundary.log').exists());self.assertFalse((self.state/'kona/profile.json').exists())

    def test_startup_recreates_gaming_projection_and_return_target(self):
        path=self.state/'kona/profile.json';path.parent.mkdir()
        path.write_text(json.dumps({'schema':1,'profile':'gaming','return_to':'focus'}))
        self.call('startup')
        self.assertTrue((self.runtime/'kona-game-mode').exists())
        self.assertEqual(self.intent()['return_to'],'focus')
        signals=(self.root/'signals.log').read_text()
        self.assertIn('-RTMIN+9',signals)
        self.call('off',command='kona-game-mode')
        self.assertEqual(self.view()['profile'],'focus')

    def test_interrupted_commit_recovers_old_intent_before_reconcile(self):
        self.call('set','focus')
        baseline=json.loads((self.runtime/'kona/profile-session.json').read_text())['baseline']
        pending={'old':{'schema':1,'profile':'daily','return_to':'daily'},'session':{},'mode':'simple','baseline':baseline}
        (self.runtime/'kona/profile-transition.json').write_text(json.dumps(pending))
        self.call('reconcile')
        self.assertEqual(self.view()['profile'],'daily')
        self.assertTrue(self.backend()['bar']);self.assertTrue(self.backend()['awww'])
        self.assertFalse((self.runtime/'kona/profile-transition.json').exists())

    def test_concurrent_profile_writers_leave_one_consistent_policy(self):
        with (self.runtime/'kona-wallpaper.lock').open('w') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            workers=[subprocess.Popen([str(self.bin/'kona-profile'),'set',p],env=self.env,stdout=subprocess.PIPE,stderr=subprocess.PIPE) for p in ['focus','gaming','daily','showcase']]
            time.sleep(.1)
            self.assertFalse((self.root/'boundary.log').exists())
            fcntl.flock(lock,fcntl.LOCK_UN)
            for worker in workers:
                out,err=worker.communicate(timeout=20)
                self.assertEqual(worker.returncode,0,err)
        active=self.view()['profile'];restricted=active in ['focus','gaming'];b=self.backend()
        self.assertEqual(b['hyprpaper'],restricted);self.assertEqual(b['awww'],not restricted)
        self.assertEqual((self.runtime/'kona-game-mode').exists(),active=='gaming')
        self.assertFalse((self.runtime/'kona/profile-transition.json').exists())

if __name__=='__main__':unittest.main(verbosity=2)
