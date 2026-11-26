"""S16r2: profile continuity, palette roles and stationary endpoint, offline Chromium."""
import argparse, hashlib, re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Room_Study_B8s16r1.html';new=root/'Astral_Archive_Room_Study_B8s16r2.html'
def blob(f):
 b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(old)=='7ae1b24f87ffd10c9ad3be12159ed53fbd24b7e2'
a,b=old.read_text(),new.read_text()
assert a[a.index('const FRONTAL_PLATES='):a.index('let nav=null')]==b[b.index('const FRONTAL_PLATES='):b.index('let nav=null')]
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
 errors=[];requests=[];y=ctx.new_page();y.on('pageerror',lambda e:errors.append(str(e)));y.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);y.set_content(b)
 initial=y.evaluate('JSON.stringify(saved)')
 def wait(phase):y.wait_for_function('p=>p===null?__navigationStudy.state()===null:__navigationStudy.state()?.phase===p',arg=phase)
 def capture(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/(n+'.png'))
 def choose(id,profile,detail=False):
  y.locator('#continuity').click();y.locator('#profileTarget').select_option(str(id));y.locator('#shelfProfile').select_option(profile);y.locator('#optDetail').set_checked(detail);y.locator('#continuityClose').click()
 def enter(id):
  y.locator(f'[data-enter="{id}"]').click();wait('shelf');assert y.locator('#navPlate').evaluate('(e)=>e.complete&&e.naturalWidth>0');assert y.evaluate('JSON.stringify(saved)')==initial
 def back():
  y.locator('#navBack').click();wait(None);assert y.evaluate('JSON.stringify(saved)')==initial
 y.locator('#motion').select_option('0')
 for theme in ['Twilight','Evening','Midnight']:
  y.locator('#theme').select_option(theme)
  assert y.evaluate('''()=>{let m={...saved,shelves:[],appearance:{...saved.appearance,floor:'plain'}};return JSON.stringify(meshScene(m).tri[0][3])===JSON.stringify(rgb(themes[$('theme').value][0]))}''')
  for id,profile in [(1,'crest'),(2,'cornice'),(3,'pilaster')]:
   choose(id,profile);y.locator('#view3d').click();enter(id)
   assert y.evaluate('__navigationStudy.state().appearance.profile')==profile
   art=y.evaluate('''async()=>{const raw=await (await fetch($('navPlate').src)).text(),r=new DOMParser().parseFromString(raw,'image/svg+xml').documentElement;return {crest:!!r.querySelector('path[d="M310 -25Q358 -28 385 -48Q420 -76 455 -48Q482 -28 530 -25Z"]'),post:r.children[3].getAttribute('width'),flat:!r.querySelector('[fill="url(#stone)"],[fill="url(#recess)"]'),palette:r.getAttribute('style')}}''')
   assert art['crest']==(profile=='crest') and art['post']==('27' if profile=='pilaster' else '16') and art['flat'],art
   assert y.evaluate('themes[$("theme").value].every(c=>'+repr(art['palette'])+'.includes(c))')
   if theme=='Twilight':capture(profile+'-frontal')
   back()
  capture(theme+'-room')
 # All 3 profiles have distinct actual meshes. Same ID geometry remains unchanged.
 assert y.evaluate('''()=>{let q=saved.shelves[0],m={...saved,shelves:[q]},seen=new Set();for(let p of Object.keys(SHELF_PROFILES)){studyProfiles.set(q.id,p);seen.add(JSON.stringify(meshScene(m)));}studyProfiles.set(q.id,'crest');return seen.size===3}''')
 print('PASS: 9 profile/palette entries, exact plate palette and flat fills, crest/pilaster anatomy, distinct actual meshes')
 # Inspect endpoint across animation settle: exact visual rectangle/opacity at p=.90 and p=1.
 y.locator('#theme').select_option('Twilight');y.locator('#motion').select_option('900')
 for mode,id,detail in [('plan',1,False),('elevated',3,True)]:
  choose(id,'crest' if id==1 else 'pilaster',detail);y.locator('#view2d' if mode=='plan' else '#view3d').click()
  y.locator(f'[data-enter="{id}"]').click();y.wait_for_function('__navigationStudy.state()?.progress>.25');capture(mode+'-transition');wait('shelf')
  # Replay transition terminal frames while settled. Artwork must be identical, stationary, no separate scale.
  assert y.evaluate('''()=>{let sig=()=>{let r=$('navPlate').getBoundingClientRect();return JSON.stringify([r.x,r.y,r.width,r.height,getComputedStyle($('navPlate')).opacity,getComputedStyle($('navPlate')).transform,getComputedStyle($('navMesh')).opacity,getComputedStyle($('navTop')).opacity])};renderTransition(.90);let a=sig();renderTransition(1);return a===sig()&&getComputedStyle($('navPlate')).transform==='none';}''')
  back();assert y.evaluate('projection')==mode
 y.locator('#motion').select_option('0');y.locator('#view2d').click();y.locator('#mode').click();assert not y.locator('[data-enter]').count();y.locator('#cancel').click()
 y.set_viewport_size({'width':500,'height':750});enter(1);capture('narrow');back()
 assert not errors,errors;assert not requests,requests
 print('PASS: both animated paths, invariant terminal frame rectangle/opacity, return, Arrange guard, narrow viewport, offline')
 browser.close()
