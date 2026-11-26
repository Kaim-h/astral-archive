"""S18r4 focused review in offline Chromium."""
import argparse,hashlib,re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
a=(root/'Astral_Archive_Shelf_Study_B8s18r3.html').read_bytes();assert hashlib.sha1(b'blob '+str(len(a)).encode()+b'\0'+a).hexdigest()=='fe0c8a381e38193d976771c3e7b4c308331aa6e5';a=a.decode();b=(root/'Astral_Archive_Shelf_Study_B8s18r4.html').read_text()
for name in ['ASSETS','FACES']:
 pat=r'^const '+name+r'=.*$';assert re.search(pat,a,re.M).group()==re.search(pat,b,re.M).group(),name
for start,end in [('const CATALOGUE=','const selectedEmblems='),('function flatBoardArt','function bookArt'),('function validateLayout(','function ownedRack(')]:assert a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)],start
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True);q.set_default_timeout(3500);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b)
 def cap(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
 def menu(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=n,exact=True).click()
 def tab(n):q.get_by_role('tab',name=n,exact=True).click()
 def state():return q.evaluate('__s18.state()')
 def node(id):return q.evaluate('id=>findNode(activeLayout(),id)',id)
 def geometry():return q.evaluate('__s18.geometry()')
 def close():q.locator('#paneClose').click()
 def undo(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name='Undo',exact=True).hover();q.get_by_role('menuitem',name=n,exact=True).click()
 def edit(id):q.locator(f'#scene [data-module="{id}"]').click(button='right');q.get_by_role('menuitem',name=re.compile('Geometry and support|Dimensions and cells')).click()
 assert not errors,errors
 original=geometry();assert q.locator('[data-lighting-board]').count()==2 and q.locator('[data-app-id]').count()==4
 assert q.locator('[data-bookmark="focused"]').count()==1 and q.locator('[data-bookmark="running"]').count()==1
 assert len(set(q.locator('[data-app-id] > rect:first-child').evaluate_all('(a)=>a.map(e=>e.getAttribute("fill"))')))==4
 cap('shelf')
 q.locator('#mainMenu').click();assert q.locator('#contextMenu > button').count()==5;cap('browse-menu');q.keyboard.press('Escape')
 menu('Appearance…');assert q.get_by_role('tab').count()==5
 for name,selector in [('Frame','#palettePolicy'),('Frame','#profile'),('Emblem','#familyPolicy'),('Backing','#liveBorder'),('Backing','#liveCenter'),('Glazing','#liveVeil'),('Glazing','#glassEmblem')]:
  tab(name);sel=q.locator(selector);opts=sel.evaluate_all('(a)=>[...a[0].options].map(o=>o.value)');seen=set()
  for v in opts:sel.select_option(v);seen.add(q.locator('#scene').inner_html());assert geometry()==original
  assert len(seen)==len(opts),(selector,len(seen),len(opts));print(selector,len(opts),flush=True)
 tab('Emblem');assert q.locator('#familyPolicy optgroup').count()==1;cap('appearance');close()
 q.locator('#mainMenu').click();q.get_by_role('menuitem',name='Undo',exact=True).hover();assert q.locator('.flyout').get_attribute('data-side')=='left';cap('flyout-left');q.get_by_role('menuitem',name='Undo appearance',exact=True).click()
 menu('Appearance…');q.locator('#palettePolicy').select_option('Evening');close()
 q.evaluate('contextActions(scene,null,12,100,$("mainMenu"))');q.get_by_role('menuitem',name='Undo',exact=True).hover();assert q.locator('.flyout').get_attribute('data-side')=='right';cap('flyout-right');q.get_by_role('menuitem',name='Undo',exact=True).focus();q.keyboard.press('ArrowRight');assert q.locator('.flyout').evaluate('(e)=>e.contains(document.activeElement)');q.keyboard.press('Escape');assert q.locator('.flyout').count()==0;q.keyboard.press('Escape');assert not q.locator('#contextMenu').is_visible()
 undo('Undo appearance')
 q.locator('#scene [data-cubby="notes"]').click(button='right');assert q.get_by_role('tab').count()==1;assert q.locator('#localGlazing').is_visible();local=q.locator('#localGlazing');opts=local.evaluate_all('(a)=>[...a[0].options].map(o=>o.value)');assert len(opts)==8
 for v in opts:local.select_option(v);assert geometry()==original
 local.select_option('subtle');q.get_by_role('button',name='Shelf appearance…',exact=True).click();assert state()['glazingTarget'] is None and q.get_by_role('tab').count()==5;assert q.get_by_role('button',name='Preview state',exact=True).count()==0;close();undo('Undo appearance')
 menu('Appearance…');tab('Backing');q.get_by_role('button',name='Edit independent backing fields…').click();q.get_by_role('button',name='Add panel',exact=True).click();q.get_by_role('button',name='Add panel',exact=True).click();assert q.evaluate('backingPanels.length===3&&!panelError(backingPanels,committed.w,committed.h)');cap('backing-fields');q.locator('#panelSelect').select_option(q.evaluate('backingPanels[2].id'));before=q.evaluate('JSON.stringify(backingPanels)');q.locator('#panel-x').fill(str(q.evaluate('backingPanels[1].x')));q.locator('#panel-x').press('Tab');assert q.evaluate('JSON.stringify(backingPanels)')==before;assert q.evaluate('!panelError(backingPanels,committed.w,committed.h)');assert q.evaluate('panelError([backingPanels[0],{...backingPanels[0]}],committed.w,committed.h).includes("overlap")');q.keyboard.press('Escape');assert geometry()==original
 q.locator('#arrangeMode').click();q.locator('#mainMenu').click();assert q.locator('#contextMenu > button').count()==5;cap('arrange-menu');q.keyboard.press('Escape');edit('book-browser');q.locator('#findFurniture').fill('Editor');assert q.locator('#arrSelection option').count()==2;q.locator('#arrX').fill('615');q.locator('#arrSelection').select_option('book-editor');assert node('book-browser')['x']==615;assert q.locator('#arrSelection').input_value()=='book-editor';assert q.locator('#findFurniture').count()==1
 q.locator('#arrX').fill('-999');q.locator('#arrSelection').select_option('book-browser');assert q.locator('#arrSelection').input_value()=='book-editor' and q.locator('#arrX').input_value()=='-999';q.locator('#arrX').fill(str(node('book-editor')['x']));q.locator('#arrangeMode').click();assert not q.evaluate('arranging') and node('book-browser')['x']==615;undo('Undo arrangement');assert geometry()==original
 q.locator('#arrangeMode').click();edit('rack');radius=node('rack')['cellR'];delta=q.evaluate('[-1,1].find(d=>!cellCandidate(findNode(activeLayout(),"rack"),findNode(activeLayout(),"rack").cellR+d).error)');assert delta;q.locator('#cellRadius').fill(str(radius+delta));q.locator('#arrSelection').select_option('book-browser');assert node('rack')['cellR']==radius+delta;q.locator('#arrangeMode').click();undo('Undo arrangement');assert geometry()==original
 q.locator('#arrangeMode').click();q.locator('#scene [data-module="book-browser"]').hover();assert 'Support: Shelf board' in q.locator('#info').inner_text();q.locator('#scene [data-module="jar"] [data-file="jar"]').hover();assert 'Vessel.stl' in q.locator('#info').inner_text();q.locator('#arrangeMode').click()
 q.locator('#scene [data-layout-item="holder"] [data-slot="r1"]').click();assert q.evaluate('presented')=='r1';q.locator('#scene [data-return]').click();assert q.evaluate('presented') is None
 # Retained board/dependent behavior and explicit app unplacement/Undo.
 q.locator('#arrangeMode').click();edit('book-board');q.locator('#arrX').fill('600');q.locator('#arrZ').fill('12');q.locator('#arrangeMode').click();assert node('book-browser')['x']==615 and node('book-browser')['z']==27;undo('Undo arrangement');assert geometry()==original
 q.locator('#arrangeMode').click();q.locator('[data-module="book-board"]').click(button='right');q.get_by_role('menuitem',name='Remove…',exact=True).click();assert '4 application book placement(s)' in q.locator('#removeSummary').inner_text();q.locator('#removeConfirm').click();q.locator('#arrangeMode').click();assert q.locator('[data-app-id]').count()==0 and q.evaluate('caseRecords.length===0&&APP_BOOKS.length===4');undo('Undo arrangement');assert geometry()==original
 q.set_viewport_size({'width':500,'height':400});menu('Appearance…');q.locator('#palettePolicy').select_option('Midnight');close();q.locator('#mainMenu').click();q.get_by_role('menuitem',name='Undo',exact=True).hover();r=q.locator('.flyout').bounding_box();assert r['x']>=0 and r['x']+r['width']<=501 and r['y']>=0 and r['y']+r['height']<=401;cap('narrow');q.get_by_role('menuitem',name='Undo appearance',exact=True).click();assert geometry()==original
 assert not errors,errors;assert not requests,requests
 print('PASS: exact assets/catalogue/board/geometry source; flat book states; five actions; both flyout directions and keyboard; all sampled global selector options; local scope; nonoverlap; valid/invalid target changes; Undo; metadata/holder; narrow offline.',flush=True)
 browser.close()
