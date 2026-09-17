#!/usr/bin/env python3
"""V4 owner contracts: preview isolation, rollback, input bounds and shared motion."""
import copy
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import profiles
ROOT=profiles.ROOT

class Preview(unittest.TestCase):
    call=profiles.Profiles.call
    backend=profiles.Profiles.backend
    view=profiles.Profiles.view
    intent=profiles.Profiles.intent
    def setUp(self):
        profiles.Profiles.setUp(self)
        self.env.pop("HYPRLAND_INSTANCE_SIGNATURE",None)
        self.env.pop("DBUS_SESSION_BUS_ADDRESS",None)
        self.config=self.home/'.config/kona'
        shutil.copytree(ROOT/'.config/kona/theme',self.config/'theme',symlinks=True)
        shutil.copytree(ROOT/'.config/kona/appearance',self.config/'appearance')
        self.env['XDG_CONFIG_HOME']=str(self.home/'.config')
        (self.bin/'kona-theme').unlink();(self.bin/'kona-theme').symlink_to(ROOT/'.local/bin/kona-theme')
        matugen=self.fake/'matugen'
        matugen.write_text('#!/usr/bin/env python3\nimport json,os,sys\nif os.environ.get("FAIL_MATUGEN"):sys.exit(1)\nprint(json.dumps({"colors":{"primary":{"dark":{"color":"#e090cc"}},"secondary":{"dark":{"color":"#e8a6cb"}}}}))\n')
        matugen.chmod(0o755)
        self.image=self.home/'.local/share/wallpapers/konata-command-center/center.png'
        self.before=(self.config/'theme/current/tokens.json').read_text()
    def test_preview_keeps_durable_scene_and_profile_then_reverts_exact_palette(self):
        self.call('preview',str(self.image))
        self.assertEqual(self.view()['scene'],'midnight')
        self.assertFalse((self.config/'scene-images.json').exists())
        self.assertTrue((self.runtime/'kona/wallpaper-preview.json').exists())
        self.assertNotEqual((self.config/'theme/current/tokens.json').read_text(),self.before)
        self.call('preview-revert')
        self.assertEqual(json.loads((self.config/'theme/current/tokens.json').read_text()),json.loads(self.before))
        self.assertFalse((self.runtime/'kona/wallpaper-preview.json').exists())
    def test_apply_commits_only_current_scene_image(self):
        self.call('preview',str(self.image));self.call('preview-apply')
        self.assertEqual(json.loads((self.config/'scene-images.json').read_text()),{'simple':str(self.image)})
        self.assertEqual(self.view()['profile'],'daily')
        self.call('wallpaper','restore')
        self.assertIn(str(self.image),str(self.backend()['awww_images'][-1]))
    def test_other_profile_writer_reverts_preview_before_changing_policy(self):
        self.call('preview',str(self.image));self.call('set','focus')
        self.assertFalse((self.runtime/'kona/wallpaper-preview.json').exists())
        self.assertEqual(self.view()['profile'],'focus');self.assertTrue(self.backend()['hyprpaper'])
        self.assertEqual(json.loads((self.config/'theme/current/tokens.json').read_text()),json.loads(self.before))
    def test_generation_failure_rolls_back_runtime_and_retains_palette(self):
        self.env['FAIL_MATUGEN']='1'
        self.assertNotEqual(self.call('preview',str(self.image),ok=False).returncode,0)
        self.assertFalse((self.runtime/'kona/wallpaper-preview.json').exists())
        self.assertEqual(json.loads((self.config/'theme/current/tokens.json').read_text()),json.loads(self.before))
        self.assertIn('selected.png',str(self.backend()['awww_images'][-1]))
    def test_invalid_image_does_not_create_transaction(self):
        self.assertNotEqual(self.call('preview','/missing image.png',ok=False).returncode,0)
        self.assertFalse((self.runtime/'kona/wallpaper-preview.json').exists())
    def test_mosaic_retains_return_palette_across_generation_cleanup(self):
        self.call('--image',str(self.image),command='kona-theme')
        expected=json.loads((self.config/'theme/current/tokens.json').read_text())
        self.call('mosaic-start')
        for args in [('--default',),('--image',str(self.image)),('--default',)]:
            self.call(*args,command='kona-theme')
        self.call('mosaic-end')
        self.assertEqual(json.loads((self.config/'theme/current/tokens.json').read_text()),expected)

    def test_mosaic_restores_gaming_return_intent(self):
        self.call('set','focus');self.call('gaming','on');old=self.intent()
        self.call('mosaic-start');self.assertEqual(self.view()['profile'],'showcase')
        self.call('mosaic-end');self.assertEqual(self.intent(),old)
        self.call('gaming','off');self.assertEqual(self.view()['profile'],'focus')

    def test_restore_intent_preserves_gaming_return_and_rejects_invalid_input(self):
        self.call('set','focus');self.call('gaming','on');old=self.intent()
        self.call('set','daily');self.call('restore-intent',json.dumps(old))
        self.assertEqual(self.intent(),old)
        self.assertEqual(self.view()['return_to'],'focus')
        self.assertNotEqual(self.call('restore-intent','{}',ok=False).returncode,0)
        self.assertEqual(self.intent(),old)
        self.call('gaming','off');self.assertEqual(self.view()['profile'],'focus')

class Contracts(unittest.TestCase):
    def test_event_subscription_exits_when_consumer_pipe_closes_without_state_event(self):
        with tempfile.TemporaryDirectory() as directory:
            worker=subprocess.Popen([str(ROOT/'.local/bin/kona-surface-data'),'events'],
                stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                env={'HOME':directory,'XDG_RUNTIME_DIR':directory,'PATH':'/usr/bin:/bin'})
            try:
                worker.stdout.close()
                self.assertEqual(worker.wait(timeout=3),0,worker.stderr.read().decode())
            finally:
                if worker.poll() is None:worker.kill();worker.wait()
                worker.stderr.close()
    def test_preference_updates_preserve_disjoint_changes_and_reject_stale_write(self):
        m=runpy.run_path(str(ROOT/'.local/bin/kona-preferences'))
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(m['update'].__globals__,CONFIG=Path(directory)):
                m['update']({'motion':'reduced'})
                result=m['update']({'accent':'cyan'})
                self.assertEqual(result['motion'],'reduced')
                with self.assertRaises(RuntimeError):
                    m['update']({'motion':'off'},expected={'motion':'full'})
                self.assertEqual(m['preferences']()['motion'],'reduced')

    def test_failed_preset_restores_preferences_and_exact_profile_return_intent(self):
        m=runpy.run_path(str(ROOT/'.local/bin/kona-surface-data'))
        old=m['preferences']({});old['favorites']=['kept.png']
        saved={'profile':'gaming','return_to':'focus','scene':'midnight'}
        writes=[];commands=[];failed=False
        def run(args,timeout=60):
            nonlocal failed
            args=[str(x) for x in args];commands.append(args)
            if args[-1]=='status':return json.dumps(saved)
            if Path(args[0]).name=='kona-motion' and not failed:
                failed=True;raise RuntimeError('injected motion failure')
            return ''
        def preferences(value=None):return copy.deepcopy(old if value is None else value)
        def update(value,expected=None):writes.append(copy.deepcopy(value))
        data={'schema':1,'preferences':old|{'motion':'reduced'},'profile':'daily','scene':'constellation'}
        with patch.dict(m['action'].__globals__,run=run,preferences=preferences,pref_update=update):
            with self.assertRaisesRegex(RuntimeError,'injected motion failure'):
                m['action']('apply-preset',json.dumps(data))
        self.assertEqual(writes[-1],old)
        restored=next(c for c in commands if len(c)>1 and c[1]=='restore-intent')
        self.assertEqual(json.loads(restored[2]),{'schema':1,'profile':'gaming','return_to':'focus'})
    def test_motion_reduces_distance_and_disables_restricted_profiles(self):
        m=runpy.run_path(str(ROOT/'.local/bin/kona-motion'));t=json.loads((ROOT/'.config/kona/motion.json').read_text())
        self.assertIn('slidefade 22%',m['expression'](t))
        self.assertIn('slidefade 3%',m['expression'](t,'reduced'))
        for mode,profile in [('off','daily'),('full','focus'),('full','gaming')]:self.assertNotIn('enabled=true',m['expression'](t,mode,profile))
    def test_preferences_reject_unknown_fields_and_unsafe_ranges(self):
        m=runpy.run_path(str(ROOT/'.local/bin/kona-surface-data'))
        for value in [{'intensity':0},{'motion':'wild'},{'token':'secret'},{'appearance':{'rounding':100}}]:
            with self.assertRaises(ValueError):m['preferences'](value)
    def test_appearance_bounds_are_enforced_before_ipc(self):
        m=runpy.run_path(str(ROOT/'.local/bin/kona-appearance'))
        for key,value in [('rounding',30),('opacity',.1),('inactive',1.2),('blur','yes')]:
            with self.assertRaises(ValueError):m['validate'](m['DEFAULTS']|{key:value})
    def test_native_default_translation_tracks_shared_tokens(self):
        m=runpy.run_path(str(ROOT/'.local/bin/kona-motion'));t=json.loads((ROOT/'.config/kona/motion.json').read_text())
        self.assertIn(m['expression'](t).replace(';','\n'),(ROOT/'.config/hypr/hyprland.lua').read_text())

if __name__=='__main__':unittest.main(verbosity=2)
