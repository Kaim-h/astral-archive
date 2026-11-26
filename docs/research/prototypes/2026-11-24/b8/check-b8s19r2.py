"""S19r2 focused doorway interactions; offline Chromium."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=args.baseline or root/'Astral_Archive_Map_Room_Study_B8s19r1.html'
if not old.exists():old=root.parent/'s19r1-tested'/old.name
raw=old.read_bytes();assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()=='c850d8acbdbce3d1a5f9f715056f41e5d85cd101';a=raw.decode();b=(root/'Astral_Archive_Map_Room_Study_B8s19r2.html').read_text()
for start,end in [('const themes=','let focusView='),('const terrain=','function plan('),('function stopFlight(','function pendingChange(')]:assert a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)],start
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True,reduced_motion='reduce');q.set_default_timeout(3000);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b);q.wait_for_timeout(120)
 def state():return q.evaluate('__mapStudy.state()')
 def model():return q.evaluate('__mapStudy.model()')
 def door(id):return next(d for d in model()['doors'] if d['id']==id)
 def xy(x,y):return q.evaluate('([x,y])=>{let p=new DOMPoint(x,y).matrixTransform(document.getElementById("map").getScreenCTM());return [p.x,p.y]}',[x,y])
 def hit(x,y,button='left'):q.mouse.click(*xy(x,y),button=button)
 def drag(x,y,dx,dy,preview=False):
  a=xy(x,y);b=xy(x+dx,y+dy);q.mouse.move(*a);q.mouse.down();q.mouse.move(*b,steps=6)
  if preview:assert 'Merge preview' in q.locator('#status').inner_text();capture('merge-preview')
  q.mouse.up()
 def capture(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
 def valid():assert q.evaluate('__mapStudy.valid(__mapStudy.model())')=='',q.evaluate('__mapStudy.valid(__mapStudy.model())')
 def menu(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=n,exact=True).click()
 def overview():
  if q.locator('#focusBack').is_visible():q.locator('#focusBack').click()
 def focusdoor(id):
  overview();d=door(id);c=q.evaluate('id=>{let m=__mapStudy.model(),d=door(m,id);return common(find(m,d.a),find(m,d.b))}',id);hit(c['line'] if d['axis']=='v' else d['at'],d['at'] if d['axis']=='v' else c['line']);assert state()['selected']['id']==id
 def adddoor():
  overview();hit(1600,650,'right');q.get_by_role('menuitem',name='Connect doorway…',exact=True).click();q.locator('#d-neighbor').select_option('hall');q.locator('#d-at').fill('520');q.locator('#d-w').fill('60');q.locator('#close').click();assert q.locator('#pane').is_hidden();valid()
 original=state()['saved'];view=state()['view'];valid();capture('overview')
 for t in ['Evening','Midnight','Twilight']:q.locator('#theme').select_option(t);assert state()['saved']==original
 # Browse never deletes via keyboard.
 hit(1200,650);q.keyboard.press('Delete');assert state()['saved']==original
 q.locator('#mode').click();adddoor();before=model();focusdoor('door-2');capture('separate');camera=state()['view']
 # Resize across another doorway; active ID stays; both Room views share the result.
 drag(1200,600,0,-60,True);assert len(model()['doors'])==2 and door('door-2')['w']==210 and door('door-2')['at']==595;assert state()['view']==camera;valid();capture('merged')
 assert q.evaluate('__mapStudy.openings("hall").find(d=>d.id==="door-2")')==q.evaluate('__mapStudy.openings("records").find(d=>d.id==="door-2")')
 menu('Undo');assert model()==before
 # Move merge as well, including a pointer overshoot. Restore just this edit.
 focusdoor('door-3');drag(1200,520,0,100);assert len(model()['doors'])==2 and door('door-3')['w']==110;valid();menu('Undo');assert model()==before
 # Remove by both keyboard keys; undo retains preceding added door.
 for key in ['Delete','Backspace']:
  focusdoor('door-3');q.keyboard.press(key);assert len(model()['doors'])==2 and not q.locator('#pane').is_visible();valid();menu('Undo');assert model()==before
 # Numeric fields consume Backspace/Delete, not the selected doorway.
 focusdoor('door-3');hit(1200,520,'right');q.get_by_role('menuitem',name='Position and width…',exact=True).click();q.locator('#d-at').focus();q.keyboard.press('Backspace');assert len(model()['doors'])==3;q.keyboard.press('Escape');assert model()==before
 # Commit an actual merge, then global session Undo restores initial map.
 focusdoor('door-2');drag(1200,600,0,-60);q.locator('#mode').click();assert len(state()['saved']['doors'])==2;menu('Undo');assert state()['saved']==original
 # Clamp along corners and retain the stationary endpoint; widen beyond former maximum.
 q.locator('#mode').click();focusdoor('door-2');drag(1200,650,0,-240);assert door('door-2')['at']==522;valid();capture('corner');drag(1200,572,0,400);assert door('door-2')['at']-door('door-2')['w']/2==472 and door('door-2')['w']==336;valid();capture('wide-opening');menu('Undo');assert model()==original
 # Source model tests exercise horizontal pair, different room pairs, a blocked span, and exact corners.
 assert q.evaluate('''()=>{let m=__mapStudy.model(),d=door(m,'door-1'),z=manipulateDoor(m,d.id,'move',-1000);return z.model.doors.find(e=>e.id===d.id).at===385&&z.clamped&&!valid(z.model)}''')
 assert q.evaluate('''()=>{let m={rooms:[room('a','A','',0,0,800,400,[]),room('b','B','',0,400,800,400,[])],doors:[{id:'x',a:'a',b:'b',axis:'h',at:180,w:100},{id:'y',a:'b',b:'a',axis:'h',at:380,w:100}]};let z=manipulateDoor(m,'x','end',160);return !valid(z.model)&&z.merged[0]==='y'&&z.model.doors[0].w===300}''')
 assert q.evaluate('''()=>{let m={rooms:[room('a','A','',0,0,800,400,[]),room('b','B','',0,400,400,400,[]),room('c','C','',400,400,400,400,[])],doors:[{id:'x',a:'a',b:'b',axis:'h',at:300,w:100},{id:'y',a:'a',b:'c',axis:'h',at:470,w:100}]};let z=manipulateDoor(m,'x','end',500);return !valid(z.model)&&z.merged.length===0&&z.model.doors.length===2&&door(z.model,'x').at+door(z.model,'x').w/2===388}''')
 assert q.evaluate('''()=>{let m={rooms:[room('a','A','',0,0,800,400,[shelf(1,360,330,80,60)]),room('b','B','',0,400,800,400,[])],doors:[{id:'x',a:'a',b:'b',axis:'h',at:180,w:100}]};let z=manipulateDoor(m,'x','move',500);return !valid(z.model)&&z.clamped&&door(z.model,'x').at===310}''')
 # Narrow viewport and original content positions; no external requests.
 q.set_viewport_size({'width':500,'height':750});q.locator('#fit').click();focusdoor('door-2');capture('narrow');valid();assert model()['rooms']==original['rooms'];assert not errors,errors;assert not requests,requests
 print('PASS: exact r1 source checkpoint, unchanged artwork, 3 themes, actual move/resize merge preview, shared openings, Delete/Backspace, typing guard, local and session Undo, corner clamping, >240 width, horizontal/different-pair and obstruction cases, unchanged rooms, narrow offline')
 browser.close()
