#!/usr/bin/env python3
"""Native FileView contract using private files, never the live profile/record owners."""
from pathlib import Path
import json,os,shutil,subprocess,tempfile,time
R=Path(__file__).resolve().parents[1];P=Path.home()/'.local/opt/kona-pkgs/quickshell-0.3.1/usr'
with tempfile.TemporaryDirectory(prefix='kona-sidebar-policy-') as directory:
 d=Path(directory);shutil.copy2(R/'.config/quickshell/kona/sidebar/qml/SidebarPolicy.qml',d/'SidebarPolicy.qml')
 for n in ['config/kona','state/kona','runtime']:(d/n).mkdir(parents=True)
 (d/'config/kona/preferences.json').write_text('{}')
 (d/'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
 SidebarPolicy { id: policy; configRoot: Quickshell.env("QA_ROOT") + "/config"; stateRoot: Quickshell.env("QA_ROOT") + "/state"; runtimeRoot: Quickshell.env("QA_ROOT") + "/runtime" }
 IpcHandler { target: "test"; function status(): string { return JSON.stringify({ready: policy.ready, reduced: policy.reducedMotion, quiet: policy.quiet, profile: policy.profileName}); } }
}
''')
 system_library_path=os.environ.get('LD_LIBRARY_PATH','/usr/lib')
 env={**os.environ,'QA_ROOT':str(d),'LD_LIBRARY_PATH':f"{P/'lib'}:{system_library_path}",'QML_IMPORT_PATH':str(P/'lib/qt6/qml'),'QT_PLUGIN_PATH':str(P/'lib/qt6/plugins')}
 def state():return json.loads(subprocess.check_output([str(P/'bin/quickshell'),'ipc','-p',str(d),'call','test','status'],env=env,text=True,stderr=subprocess.DEVNULL,timeout=2))
 def wait(key,value):
  end=time.monotonic()+3
  while time.monotonic()<end:
   try:
    if state()[key]==value:return
   except subprocess.SubprocessError:pass
   time.sleep(.025)
  raise AssertionError((key,value,state()))
 def write(name,data):
  p=d/name;t=p.with_suffix('.new');t.write_text(data);t.replace(p)
 child=subprocess.Popen([str(P/'bin/quickshell'),'-n','-p',str(d),'--no-color'],env=env,stdout=subprocess.DEVNULL)
 try:
  wait('ready',True);wait('quiet',False);wait('reduced',False)
  wait('profile','')
  for profile in ['daily','focus','gaming','showcase']:
   write('state/kona/profile.json',json.dumps({'schema':1,'profile':profile,'return_to':'daily'}));wait('profile',profile)
  write('state/kona/profile.json','{"schema":1,"profile":"invalid"}');wait('profile','')
  write('state/kona/profile.json','broken');wait('profile','')
  write('state/kona/profile.json','{"schema":1,"profile":"daily"}');wait('profile','daily')
  (d/'state/kona/profile.json').unlink();wait('profile','');wait('quiet',False)
  write('config/kona/preferences.json','{"motion":"reduced"}');wait('reduced',True)
  write('config/kona/preferences.json','{"motion":"off"}');wait('reduced',True)
  write('config/kona/preferences.json','{}');wait('reduced',False)
  write('state/kona/profile.json','{"profile":"focus"}');wait('quiet',True)
  write('state/kona/profile.json','{"profile":"daily"}');wait('quiet',False)
  (d/'runtime/kona-game-mode').touch();wait('quiet',True)
  (d/'runtime/kona-game-mode').unlink();wait('quiet',False)
  # Parent can appear after startup, as the real recording directory does.
  (d/'runtime/kona-record').mkdir();(d/'runtime/kona-record/pid').write_text('123')
  wait('quiet',True);(d/'runtime/kona-record/pid').unlink();wait('quiet',False)
  write('config/kona/preferences.json','invalid');wait('reduced',True)
  write('config/kona/preferences.json','{"motion":"full"}');wait('reduced',False)
  print('PASS: native preference defaults, reduced/off, atomic updates, profile/game/record transitions, malformed recovery')
 finally:child.terminate();child.wait(timeout=5)
