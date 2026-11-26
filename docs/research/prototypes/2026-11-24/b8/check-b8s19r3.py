"""S19r3 Map Room appearance regression; offline Chromium."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=args.baseline or root/'Astral_Archive_Map_Room_Study_B8s19r2.html'
if not old.exists():old=root.parent/'s19r2-release'/old.name
raw=old.read_bytes();assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()=='60c2c5419f22a74e653ca4d3eab566b88a7e23e6';a=raw.decode();b=(root/'Astral_Archive_Map_Room_Study_B8s19r3.html').read_text()
for start,end in [('function footprint(','function status('),('const terrain=','// Interaction-only camera'),('function stopFlight(','function render()')]:
 aa=a[a.index(start):a.index(end)];bb=b[b.index(start):b.index(end)]
 if start=='function stopFlight(':bb=bb.split('// Map-only presentation')[0]
 assert aa==bb,start
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1440,'height':900},offline=True,reduced_motion='reduce');q=ctx.new_page();q.set_default_timeout(3000);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b);q.wait_for_timeout(150)
 def cap(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
 def state():return q.evaluate('__mapStudy.state()')
 def model():return q.evaluate('__mapStudy.model()')
 def geom():return q.evaluate('()=>{let m=__mapStudy.model();return {rooms:m.rooms.map(r=>[r.id,r.x,r.y,r.w,r.h,r.shelves]),doors:m.doors}}')
 def menu(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=n,exact=True).click()
 def room(id):q.locator(f'[data-room="{id}"] > rect').click(button='right');q.get_by_role('menuitem',name='Appearance…',exact=True).click()
 def sel(id,v):q.locator('#'+id).select_option(v)
 def close():q.locator('#close').click();assert not q.locator('#pane').is_visible()
 g=geom();initial=state()['saved'];cap('default')
 for t in ['Twilight','Evening','Midnight']:sel('theme',t);assert geom()==g;cap(t)
 sel('theme','Twilight');menu('Appearance…');assert q.locator('#fields fieldset').count()==3
 q.locator('#map-title').fill('The Western Atlas');q.locator('#map-subtitle').fill('Research collections');sel('map-ornament','compass');sel('map-frame','engraved');sel('map-labels','title');sel('map-marks','all');sel('map-family','botanical');assert q.locator('#title').inner_text()=='The Western Atlas';assert q.locator('#chartSubtitle').inner_text()=='Research collections';assert q.locator('[data-chart-ornament="compass"]').count()==1;assert q.locator('[data-room] .subtitle').count()==0;assert q.locator('[data-map-frame="engraved"]').count()==4;assert q.locator('[data-room] [data-family-mark="botanical"]').count()==4;assert state()['saved']==initial and geom()==g;cap('controls');close();cap('engraved')
 room('hall');sel('r-frame','plain');sel('r-labels','both');sel('r-family','water');sel('r-marks','none');sel('r-pal','Evening');close();assert q.locator('[data-room="hall"] [data-map-frame]').count()==0;assert q.locator('[data-room="hall"] .subtitle').count()==1;assert q.locator('[data-room="hall"] [data-family-mark]').count()==0;assert '#343c43' in q.locator('[data-room="hall"]').get_attribute('style');cap('override')
 menu('Appearance…');sel('map-frame','inset');sel('map-family','fire');sel('map-ornament','none');sel('map-labels','both');close();assert model()['rooms'][0]['family']=='water';assert model()['rooms'][0]['mapFrame']=='plain';assert q.locator('[data-room="records"] [data-map-frame="inset"]').count()==1;assert q.locator('[data-room="records"] [data-family-mark="fire"]').count()==1
 before=state()['saved'];menu('Appearance…');sel('contours','none');q.locator('#density').fill('100');q.keyboard.press('Escape');assert state()['saved']==before
 menu('Appearance…');sel('contours','engraved');q.locator('#density').fill('65');close();assert model()['appearance']['density']==65;menu('Undo');assert state()['saved']==before
 sel('detail','plan');assert q.locator('[data-plan-symbol="H"]').count()==8;cap('plan');q.locator('[data-room="hall"] > rect').click();assert state()['inside']=='hall' and q.locator('[data-plan-symbol="H"]').count()==3;assert q.locator('[data-map-frame]').count()==0;assert q.locator('[data-family-mark="water"]').count()==1;q.locator('#roomBack').click();assert geom()==g
 q.locator('#mode').click();menu('Appearance…');sel('map-frame','engraved');close();q.locator('#mode').click();assert state()['saved']['appearance']['frame']=='engraved';assert geom()==g
 q.set_viewport_size({'width':500,'height':750});menu('Appearance…');cap('narrow');assert q.locator('#pane').is_visible();q.keyboard.press('Escape');assert not q.locator('#pane').is_visible();assert geom()==g;assert q.evaluate('__mapStudy.valid(__mapStudy.model())')=='';assert not errors,errors;assert not requests,requests
 print('PASS: exact geometry/contour/plan/interaction source; 3 themes, live appearance, inheritance and local overrides, all frame choices, subtitles, compass, rollback, Undo, Room inspection, Arrange commit, narrow offline; geometry unchanged')
 browser.close()
