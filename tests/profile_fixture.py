"""Stateful command boundaries for profile and legacy event integration tests."""
from pathlib import Path

SHIM = r'''#!/usr/bin/env python3
import json,os,re,sys
from pathlib import Path
root=Path(os.environ['FIXTURE']);name=Path(sys.argv[0]).name;args=sys.argv[1:]
path=root/'backend.json'
def initial():return {'awww':True,'hyprpaper':False,'bar':True,'effects':{'animations.enabled':True,'decoration.blur.enabled':True,'decoration.shadow.enabled':True,'general.allow_tearing':False,'misc.vrr':0}}
state=json.loads(path.read_text()) if path.exists() else initial()
def save():path.write_text(json.dumps(state))
with (root/'boundary.log').open('a') as f:f.write(json.dumps([name,*args])+'\n')
if name=='hyprctl':
 with (root/'ipc.log').open('a') as f:f.write(json.dumps(args)+'\n')
 if (root/'ipc-fail').exists():sys.exit(1)
 if args[0] in ['clients','monitors']:print((root/(args[0]+'.json')).read_text())
 elif args[0]=='getoption':
  key=args[1].replace(':','.');v=state['effects'][key];print(json.dumps({'int' if key=='misc.vrr' else 'bool':v}))
 elif args[:2]==['-j','layers']:print(json.dumps({'TEST':{'levels':{('2' if state['bar'] else '1'):[{'namespace':'waybar','alpha':1}]}}}))
 elif args[0]=='eval':
  for key,v in re.findall(r'\["([^"]+)"\]=(true|false|\d+)',args[1]):state['effects'][key]=json.loads(v)
  save();print('ok')
 elif args[0]=='hyprpaper':
  if not state['hyprpaper'] or state.get('paper_error'):
   print('error: fake Hyprpaper IPC failure');sys.exit(0)
  if args[1]=='wallpaper':state.setdefault('paper_images',[]).append(args[2]);save()
  print('ok')
 else:print('ok')
elif name=='awww':
 if args[0]=='kill':state['awww']=False;save()
 elif args[0]=='query':sys.exit(0 if state['awww'] else 1)
 elif args[0]=='img':
  if state.get('image_failure') or os.environ.get('KONA_TEST_FAIL')=='wallpaper':sys.exit(1)
  state.setdefault('awww_images',[]).append(args);save()
elif name=='uwsm':
 state['hyprpaper' if 'hyprpaper' in args else 'awww']=True;save()
elif name=='pgrep':
 target=args[-1]
 active=state.get('awww' if target=='awww-daemon' else target,False)
 sys.exit(0 if active else 1)
elif name=='pkill':
 with (root/'signals.log').open('a') as f:f.write(json.dumps(args)+'\n')
 if args[-1]=='hyprpaper':state['hyprpaper']=False;save()
 elif args[0]=='-USR1':state['bar']=not state['bar'];save()
 elif (root/'waybar-absent').exists():sys.exit(1)
'''


def install(fake, root):
    for name in ('hyprctl', 'awww', 'uwsm', 'pgrep', 'pkill'):
        p = Path(fake) / name
        p.write_text(SHIM)
        p.chmod(0o755)


def assets(home):
    root = Path(home) / '.local/share/wallpapers/konata-command-center'
    for rel in ('v2/selected.png', 'left.png', 'center.png', 'right.png',
                'animated/left.webp', 'animated/center.webp', 'animated/right.webp'):
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(b'isolated backend boundary fixture')
