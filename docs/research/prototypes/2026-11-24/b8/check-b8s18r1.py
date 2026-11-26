"""S18r1 focused implicit-commit regression (offline Chromium)."""
import argparse,hashlib,re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--baseline',type=Path);p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
base=args.baseline or root/'Astral_Archive_Shelf_Study_B8s18.html'
a=base.read_bytes();assert hashlib.sha1(b'blob '+str(len(a)).encode()+b'\0'+a).hexdigest()=='53e64a3f117bd7b0cfe1fa565eb6eb7a1e0976b6';a=a.decode()
b=(root/'Astral_Archive_Shelf_Study_B8s18r1.html').read_text()
for name in ['ASSETS','FACES']:
 pat=r'^const '+name+r'=.*$';assert re.search(pat,a,re.M).group()==re.search(pat,b,re.M).group(),name
assert a[a.index('const CATALOGUE='):a.index('const selectedEmblems=')]==b[b.index('const CATALOGUE='):b.index('const selectedEmblems=')]
assert a[a.index('function validateLayout('):a.index('function ownedRack(')]==b[b.index('function validateLayout('):b.index('function ownedRack(')]
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True);q.set_default_timeout(3000);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b)
 def state():return q.evaluate('__s18.state()')
 def capture(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
 def menu(name):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=name,exact=True).click()
 def tab(name):q.get_by_role('tab',name=name,exact=True).click()
 def cubby(id='manuscripts'):q.locator(f'#scene [data-cubby="{id}"]').click(button='right');assert state()['tab']=='glazing' and state()['glazingTarget']==id
 def geometry():return q.evaluate('__s18.geometry()')
 def mode():return q.evaluate('arranging')
 def edit(id):
  q.locator(f'#scene [data-module="{id}"]').click(button='right');q.get_by_role('menuitem',name=re.compile('Geometry and support|Dimensions and cells')).click()
 original=geometry();assert not errors,errors
 # Real SVG coordinate hits on the cornice and clear backing, no intermediate menu.
 def hit(x,y):
  pt=q.evaluate('([x,y])=>{const p=new DOMPoint(x,y).matrixTransform(scene.getScreenCTM());return [p.x,p.y]}',[x,y]);q.mouse.click(*pt,button='right')
 hit(420,-14);assert state()['tab']=='material' and state()['panel']=='appearance';q.keyboard.press('Escape')
 hit(750,190);assert state()['tab']=='backing' and state()['panel']=='appearance';q.keyboard.press('Escape')
 menu('Primary emblem…');q.locator('#familyPolicy').select_option('botanical');q.locator('#familyPolicy').select_option('water');assert state()['history']==0;assert not q.locator('#appApply').is_visible();capture('appearance')
 q.locator('#scene').click(position={'x':5,'y':5});assert not q.locator('#pane').is_visible() and state()['history']==1 and state()['appearance']['family']=='water'
 menu('Undo appearance');assert state()['appearance']['family']=='astral' and state()['history']==0
 menu('Primary emblem…');q.locator('#familyPolicy').select_option('bestiary');q.keyboard.press('Escape');assert state()['appearance']['family']=='astral' and state()['history']==0
 cubby();q.locator('#localGlazing').select_option('subtle');capture('glazing');cubby('notes');assert state()['appearance']['localVeils']=={'manuscripts':'subtle'} and state()['history']==1
 q.locator('#localGlazing').select_option('moderate');q.locator('#arrangeMode').click();assert mode() and state()['history']==2 and state()['appearance']['localVeils']['notes']=='moderate';q.locator('#arrangeMode').click();assert not mode() and geometry()==original
 menu('Backing appearance…');tab('Frame');q.locator('#palettePolicy').select_option('Evening');q.locator('#studyEnvironment').click();assert state()['panel']=='environment' and state()['history']==3;q.locator('#desktopTheme').select_option('Midnight');q.locator('#paneClose').click();assert state()['appearance']['theme']=='Evening';menu('Undo appearance');assert state()['appearance']['theme']=='Midnight'
 print('PASS appearance sessions',flush=True)
 candidate=q.evaluate('''()=>{for(const n of layout)for(const dx of [1,-1,5,-5,10,-10,20,-20]){let x=n.x+dx,q=buildCandidate(n.id,x,n.z,n.w,n.h,n.support);if(!q.error)return {id:n.id,x};}return null}''');assert candidate
 q.locator('#arrangeMode').click();edit(candidate['id']);q.locator('#arrX').fill(str(candidate['x']));q.locator('#arrangeMode').click();assert not mode() and geometry()!=original;assert q.evaluate('layoutHistory.length')==1;menu('Undo arrangement');assert geometry()==original
 q.locator('#arrangeMode').click();edit(candidate['id']);q.locator('#arrX').fill('-999');q.locator('#arrangeMode').click();assert mode() and geometry()==original and q.locator('#pane').is_visible();capture('invalid');q.locator('#arrX').fill(str(candidate['x']));q.locator('#arrangeMode').click();assert not mode();menu('Undo arrangement');assert geometry()==original
 menu('Shelf dimensions…');q.locator('#width').fill('860');q.locator('#paneClose').click();assert q.evaluate('committed.w')==860 and not q.evaluate('!!draft');menu('Shelf dimensions…');q.locator('#width').fill('840');q.locator('#paneClose').click();assert geometry()==original
 print('PASS numeric arrangement and envelope',flush=True)
 q.locator('#arrangeMode').click();menu('Add furniture…');q.locator('#addX').fill('-999');q.locator('#arrangeMode').click();assert mode() and q.evaluate('!!creation') and geometry()==original;q.locator('#addDismiss').click();q.locator('#arrangeMode').click();assert not mode()
 q.locator('#arrangeMode').click();menu('Add furniture…');q.locator('#addKind').select_option('mount');place=q.evaluate('''()=>{for(let z=0;z<=390;z+=10)for(let x=0;x<=720;x+=10){let n={...creation,x,z,w:120,h:90,support:'wall'};if(!creationError(n))return {x,z}}return null}''');assert place
 q.locator('#addX').fill(str(place['x']));q.locator('#addZ').fill(str(place['z']));assert q.evaluate('!creationError(creation)');q.locator('#arrangeMode').click();assert not mode() and q.evaluate('layout.some(n=>n.id.startsWith("new-"))');menu('Undo arrangement');assert geometry()==original
 q.locator('#arrangeMode').click();q.locator('#scene [data-module="manuscripts"]').click(button='right');q.get_by_role('menuitem',name='Remove…').click();q.locator('#arrangeMode').click();assert mode() and geometry()==original;q.locator('#removeConfirm').click();q.locator('#arrangeMode').click();assert not mode() and q.evaluate('caseRecords.length>0 && !validateOwnership(layout,caseRecords)');menu('Undo arrangement');assert geometry()==original
 q.set_viewport_size({'width':500,'height':750});menu('Primary emblem…');q.locator('#familyPolicy').select_option('none');q.locator('#paneClose').click();assert state()['appearance']['family']=='none';menu('Undo appearance');assert state()['appearance']['family']=='astral';assert not errors,errors;assert not requests,requests
 print('PASS exact asset/catalogue/validator source; grouped commit, Escape, direct context, valid creation/evacuation, invalid blocking, Undo, narrow viewport, offline',flush=True)
 browser.close()
