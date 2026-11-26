"""S16 navigation/animation regression, offline Chromium via Playwright."""
import argparse, hashlib, re, gzip, base64
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Room_Study_B8s15r4.html';new=root/'Astral_Archive_Room_Study_B8s16.html'
def blob(f):
 b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(old)=='a1f7f2e1bd5e603134eb070aa7054a843137a868'
a,b=old.read_text(),new.read_text()
assert a[a.index('function meshScene'):a.index('// R4 comparison only:')]==b[b.index('function meshScene'):b.index('// Owner-selected H:')]
for theme in ['Twilight','Evening','Midnight']:
 section=re.search(r' '+theme+r': \[(.*?)\]\.join',b,re.S).group(1)
 art=gzip.decompress(base64.b64decode(''.join(re.findall(r'"([A-Za-z0-9+/=]+)"',section)))).decode()
 assert '<svg' in art and 'THE WESTERN COLLECTION' in art and not re.search(r'<script|\son\w+=',art,re.I)
 assert set(re.findall(r'https?://[^\s"<>]+',art))=={'http://www.w3.org/2000/svg'}
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
 errors=[];requests=[]
 def load(html,context=ctx):
  page=context.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(html);return page
 x,y=load(a),load(b);initial=y.evaluate('JSON.stringify(saved)');assert x.evaluate('JSON.stringify(saved)')==initial
 assert y.locator('[data-plan-symbol="H"]').count()==3 and not y.locator('#compareSymbols').count()
 def wait(phase):
  y.wait_for_function('phase=>phase===null?__navigationStudy.state()===null:__navigationStudy.state()?.phase===phase',arg=phase)
 def capture(name):
  if args.captures:
   args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/(name+'.png'))
 for theme in ['Twilight','Evening','Midnight']:
  for page in [x,y]:page.locator('#theme').select_option(theme)
  assert x.evaluate('JSON.stringify(meshScene(saved))')==y.evaluate('JSON.stringify(meshScene(saved))')
  x.locator('#planSymbol').select_option('H');y.locator('#view2d').click()
  assert x.locator('[data-plan-symbol="H"]').first.inner_html()==y.locator('[data-plan-symbol="H"]').first.inner_html()
  y.locator('#motion').select_option('0')
  for mode,id in [('plan',1),('elevated',3)]:
   y.locator('#view2d' if mode=='plan' else '#view3d').click()
   if mode=='elevated':y.locator('#tilt').fill('30')
   y.locator(f'[data-enter="{id}"]').click();wait('shelf');state=y.evaluate('__navigationStudy.state()');assert state['origin']==mode and state['id']==id
   assert y.locator('#navPlate').evaluate('(e)=>e.complete&&e.naturalWidth>0')
   assert y.evaluate('JSON.stringify(saved)')==initial
   y.locator('#navBack').click();wait(None);assert y.evaluate('projection')==mode and y.evaluate('JSON.stringify(saved)')==initial
   if mode=='elevated':assert y.locator('#tilt').input_value()=='30'
 print('PASS: fixed H, exact perspective mesh source/data, both entries and returns in three palettes, original projection and geometry')
 y.locator('#theme').select_option('Twilight');y.locator('#view2d').click();y.locator('#motion').select_option('900');capture('plan')
 y.locator('[data-enter="1"]').focus();y.keyboard.press('Enter');y.wait_for_function('(__navigationStudy.state()?.progress||0)>.35');assert y.evaluate('__navigationStudy.state().phase')=='enter';capture('plan-transition');wait('shelf');capture('shelf')
 y.locator('#navBack').click();wait('return');y.locator('#navSkip').click();wait(None);assert y.locator('[data-enter="1"]').evaluate('(e)=>document.activeElement===e')
 y.locator('#view3d').click();y.locator('#tilt').fill('22');capture('perspective');y.locator('[data-enter="3"]').click();y.wait_for_function('(__navigationStudy.state()?.progress||0)>.35');capture('perspective-transition');y.keyboard.press('Escape');wait(None)
 y.locator('[data-enter="3"]').click();wait('enter');y.locator('#navSkip').click();wait('shelf');capture('shelf3');assert y.locator('#navName').text_content()=='Collections';y.locator('#navBack').click();wait(None)
 print('PASS: animated keyboard entry, mid-animation capture, skip, reverse, Escape and focus restoration')
 y.locator('#view2d').click();y.locator('#mode').click();assert not y.locator('[data-enter]').count();y.locator('[data-move="1"]').dblclick();assert y.evaluate('__navigationStudy.state()') is None;y.locator('#cancel').click()
 y.locator('#appearance').click();assert not y.locator('[data-enter]').count();y.locator('#appearanceClose').click();y.locator('[data-move="1"]').click();assert y.evaluate('__navigationStudy.state()') is None and y.evaluate('styleDraft!==null');y.locator('#appearanceCancel').click()
 y.locator('#motion').select_option('0');y.locator('#mode').click();y.locator('#geometry').click();y.locator('#target').select_option('1');y.locator('#angle').select_option('180');y.locator('#set').click();y.locator('#apply').click();y.locator('[data-enter="1"]').click();wait('shelf');assert y.evaluate('__navigationStudy.state().orientation')==180;y.locator('#navBack').click();wait(None);y.locator('#undo').click();assert y.evaluate('JSON.stringify(saved)')==initial
 y.set_viewport_size({'width':500,'height':750});y.locator('[data-enter="1"]').click();wait('shelf');capture('narrow-shelf');y.locator('#navBack').click();wait(None)
 reduced=browser.new_context(viewport={'width':1000,'height':750},offline=True,reduced_motion='reduce');z=load(b,reduced);z.locator('#motion').select_option('900');assert z.evaluate('duration()')==0;z.locator('[data-enter="1"]').click();z.wait_for_function('__navigationStudy.state()?.phase==="shelf"');z.locator('#navBack').click();z.wait_for_function('__navigationStudy.state()===null')
 assert not errors,errors;assert not requests,requests;print('PASS: Arrange double-click cannot enter, appearance transaction guard, 180-degree identity, undo, narrow viewport, reduced motion, offline/no errors');browser.close()
