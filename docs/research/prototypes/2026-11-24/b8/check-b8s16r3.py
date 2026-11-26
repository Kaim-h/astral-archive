"""S16r3 transition comparison; offline Chromium, RAF callback diagnostics."""
import argparse, hashlib, json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Room_Study_B8s16r2.html';new=root/'Astral_Archive_Room_Study_B8s16r3.html'
def blob(f):
 b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(old)=='ed1b8c59908dd9315a76e4af67e9821eadc2bc29'
a,b=old.read_text(),new.read_text()
for start,end in [('function meshScene','// Owner-selected H:'),('const FRONTAL_PLATES=','let nav=null'),('function prepareArt(','async function plateFor(')]:assert a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)],start
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
 errors=[];requests=[]
 def load(s,context=ctx):
  y=context.new_page();y.on('pageerror',lambda e:errors.append(str(e)));y.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);y.set_content(s);return y
 x,y=load(a),load(b);initial=y.evaluate('JSON.stringify(saved)')
 def wait(phase):y.wait_for_function('p=>p===null?__navigationStudy.state()===null:__navigationStudy.state()?.phase===p',arg=phase)
 def enter(id):y.locator(f'[data-enter="{id}"]').click();wait('shelf');assert y.locator('#navPlate').evaluate('(e)=>e.complete&&e.naturalWidth>0');assert y.evaluate('JSON.stringify(saved)')==initial
 def back():y.locator('#navBack').click();wait(None);assert y.evaluate('JSON.stringify(saved)')==initial
 def capture(name):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/(name+'.png'))
 y.locator('#motion').select_option('0')
 for theme in ['Twilight','Evening','Midnight']:
  for page in [x,y]:page.locator('#theme').select_option(theme)
  assert x.evaluate('JSON.stringify(meshScene(saved))')==y.evaluate('JSON.stringify(meshScene(saved))')
  for mode,id in [('plan',1),('elevated',3)]:
   y.locator('#view2d' if mode=='plan' else '#view3d').click();reference=None
   for method in ['control','A','B','C']:
    y.locator('#transitionMethod').select_option(method);enter(id);assert y.evaluate('__navigationStudy.state().options.Method')==method
    actual=y.evaluate('async()=>await(await fetch($("navPlate").src)).text()');reference=actual if reference is None else reference;assert actual==reference
    assert y.evaluate('''()=>{let p=$('navPlate'),r=p.getBoundingClientRect();return getComputedStyle(p).opacity==='1'&&getComputedStyle(p).transform==='none'&&getComputedStyle($('navMesh')).opacity==='0'&&r.width>0}''')
    if method=='B':assert y.locator('#navStructure').evaluate('(e)=>e.complete&&e.naturalWidth>0')
    back();assert y.evaluate('projection')==mode
 print('PASS: 24 instant entries and returns, all methods/views/palettes; same art, layout, Room mesh and final frame',flush=True)
 y.locator('#theme').select_option('Twilight');y.locator('#motion').select_option('600')
 for method in ['control','A','B','C']:
  y.locator('#transitionMethod').select_option(method)
  for mode,id in [('plan',1),('elevated',3)]:
   y.locator('#view2d' if mode=='plan' else '#view3d').click();enter(id)
   for t in [.45,.58,.72,.90,1]:
    y.evaluate('p=>renderTransition(p)',t)
    assert y.evaluate('''()=>{let p=$('navPlate'),r=p.getBoundingClientRect();return [r.x,r.y,r.width,r.height].every(Number.isFinite)}''')
    if t in [.58,.72,1] and mode=='plan':capture(method+'-'+str(t))
    if method=='C':assert y.evaluate('''()=>+getComputedStyle($('navPlate')).opacity*+getComputedStyle($('navMesh')).opacity===0''')
   back();assert y.evaluate('projection')==mode
 report=y.evaluate('__navigationStudy.pacing()');assert len(report)==16 and all(r['frames']>1 for r in report);print(json.dumps(report,indent=2),flush=True)
 if args.captures:(args.captures/'pacing.json').write_text(json.dumps(report,indent=2))
 y.locator('#continuity').click();y.locator('#profileTarget').select_option('3');y.locator('#shelfProfile').select_option('pilaster');y.locator('#optDetail').check();y.locator('#continuityClose').click();y.locator('#transitionMethod').select_option('A');y.locator('#view3d').click();y.locator('[data-enter="3"]').click();wait('enter');y.keyboard.press('Escape');wait(None)
 y.locator('[data-enter="3"]').click();wait('enter');y.locator('#navSkip').click();wait('shelf');assert y.evaluate('__navigationStudy.state().appearance.profile')=='pilaster';y.locator('#navBack').click();wait('return');y.locator('#navSkip').click();wait(None)
 y.locator('#mode').click();assert not y.locator('[data-enter]').count();y.locator('#cancel').click()
 y.set_viewport_size({'width':500,'height':750});y.locator('#motion').select_option('0');y.locator('#view2d').click();enter(1);back()
 reduced=browser.new_context(viewport={'width':1000,'height':750},offline=True,reduced_motion='reduce');z=load(b,reduced);assert z.evaluate('duration()')==0;z.locator('[data-enter="1"]').click();z.wait_for_function('__navigationStudy.state()?.phase==="shelf"');z.locator('#navBack').click();z.wait_for_function('__navigationStudy.state()===null')
 assert not errors,errors;assert not requests,requests
 print('PASS: 16 timed transitions, finite transforms, C no overlap, profile/rotation, detail, Escape/Skip, Arrange, narrow, reduced motion, offline',flush=True)
 browser.close()
