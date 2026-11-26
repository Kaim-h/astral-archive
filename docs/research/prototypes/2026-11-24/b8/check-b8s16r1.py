"""S16r1 optional flat continuity study, offline Chromium."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
base=args.baseline or root/'Astral_Archive_Room_Study_B8s16.html';new=root/'Astral_Archive_Room_Study_B8s16r1.html'
def blob(f):
 b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(base)=='7bf468341d0b6dc5ae3675c6ee61c5ebf3628c3b'
a,b=base.read_text(),new.read_text()
for start,end in [('function meshScene','// Owner-selected H:'),('const FRONTAL_PLATES=','let nav=null')]:assert a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)]
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
 errors=[];requests=[];y=ctx.new_page();y.on('pageerror',lambda e:errors.append(str(e)));y.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);y.set_content(b)
 initial=y.evaluate('JSON.stringify(saved)')
 def wait(phase):y.wait_for_function('p=>p===null?__navigationStudy.state()===null:__navigationStudy.state()?.phase===p',arg=phase)
 def capture(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/(n+'.png'))
 def choose(keys):
  y.locator('#continuity').click();y.locator('#controlPreset').click()
  for key in keys:y.locator('#opt'+key).check()
  y.locator('#continuityClose').click()
 def enter(id=1):
  y.locator(f'[data-enter="{id}"]').click();wait('shelf');assert y.locator('#navPlate').evaluate('(e)=>e.complete&&e.naturalWidth>0');assert y.evaluate('JSON.stringify(saved)')==initial
 def back():
  y.locator('#navBack').click();wait(None);assert y.evaluate('JSON.stringify(saved)')==initial;assert y.locator('#navStructure').get_attribute('src') is None
 keys=['Cornice','Frame','Proportion','Material','Detail','Flat'];y.locator('#motion').select_option('0');y.locator('#view2d').click()
 for variant in [[],*[[k] for k in keys],keys]:
  choose(variant);enter();assert y.evaluate('__navigationStudy.state().options')=={k:k in variant for k in keys}
  if 'Detail' in variant:assert y.locator('#navStructure').evaluate('(e)=>e.complete&&e.naturalWidth>0')
  if not variant or len(variant)==6:capture('control' if not variant else 'combined')
  back();assert y.evaluate('projection')=='plan'
 for theme in ['Evening','Midnight','Twilight']:
  y.locator('#theme').select_option(theme);y.locator('#view3d').click();enter(3);back();assert y.evaluate('projection')=='elevated'
 print('11 individual/combined entries and returns passed; exact embedded art and Room renderer unchanged')
 y.locator('#view2d').click();y.locator('#continuity').click();capture('controls');y.locator('#continuityClose').click();y.locator('#motion').select_option('900');y.locator('[data-enter="1"]').click();y.wait_for_function('__navigationStudy.state()?.progress>.60');capture('transition');wait('shelf');y.locator('#navBack').click();wait('return');y.locator('#navSkip').click();wait(None)
 y.locator('#view3d').click();y.locator('[data-enter="3"]').click();wait('enter');y.keyboard.press('Escape');wait(None);assert y.evaluate('JSON.stringify(saved)')==initial
 y.locator('#mode').click();assert not y.locator('[data-enter]').count();y.locator('#cancel').click();assert not errors,errors;assert not requests,requests
 print('Animated detail stage, Skip, Escape, Arrange guard, offline/no errors passed');browser.close()
