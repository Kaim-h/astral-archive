"""Focused S18r2 rack affordance, application sample and restored access checks."""
import argparse,hashlib,re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Shelf_Study_B8s18r1.html';new=root/'Astral_Archive_Shelf_Study_B8s18r2.html'
a=old.read_bytes();assert hashlib.sha1(b'blob '+str(len(a)).encode()+b'\0'+a).hexdigest()=='228887ea25c4ffc63dbca67da7cf450abe628ddc';a=a.decode();b=new.read_text()
for name in ['ASSETS','FACES']:
    pat=r'^const '+name+r'=.*$';assert re.search(pat,a,re.M).group()==re.search(pat,b,re.M).group(),name
for start,end in [('const CATALOGUE=','const selectedEmblems='),('function validateLayout(','function ownedRack('),('function cellCandidate(','scene.addEventListener(\'pointerdown\'')]:
    assert a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)],start
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1440,'height':900},offline=True);q=ctx.new_page();q.set_default_timeout(3500);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b)
    def capture(n):
        if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
    def state():return q.evaluate('__s18.state()')
    def menu(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=n,exact=True).click()
    original=q.evaluate('__s18.geometry()');assert q.evaluate('!validateLayout(layout,committed.w,committed.h)&&!validateOwnership(layout,caseRecords)')
    assert q.evaluate('!RESIZABLE.has("app-shelf") && findNode(layout,"application-shelf").records.length===0');assert q.locator('#scene [data-app-id]').count()==4
    assert q.evaluate('APP_BOOKS.every(b=>!initialRecords.has(b.id))')
    capture('shelf')
    for t in ['Evening','Midnight','Twilight']:
        q.locator('#studyEnvironment').click();q.locator('#desktopTheme').select_option(t);q.locator('#paneClose').click();assert q.locator('#scene [data-app-id]').count()==4
    # Existing tooltip and simple presentation/return, real pointer events.
    el=q.locator('#scene [data-layout-item="jar"] [data-file="jar"]');el.hover();assert q.locator('#info').is_visible() and 'Vessel.stl' in q.locator('#info').text_content();q.keyboard.press('Escape')
    el=q.locator('#scene [data-layout-item="holder"] [data-slot="r1"]');el.hover();assert 'Field-record.ogg' in q.locator('#info').text_content();el.click();assert q.evaluate('presented')=='r1';q.locator('#scene [data-return]').click();assert q.evaluate('presented') is None
    # No implicit cycling in Browse; explicit preview remains available.
    c=q.locator('#scene [data-cubby="notes"]');before=c.get_attribute('data-mode');c.click();assert c.get_attribute('data-mode')==before
    c.click(button='right');q.get_by_role('button',name='Preview state',exact=True).click();q.get_by_label('Preview state',exact=True).select_option('open');q.locator('#paneClose').click();assert c.get_attribute('data-mode')=='open'
    menu('Backing appearance…');q.get_by_role('button',name='Edit independent backing fields…',exact=True).click();assert q.locator('#panelEditor').is_visible();capture('backing');q.keyboard.press('Escape');assert q.evaluate('__s18.geometry()')==original
    # Rack affordance uses same original cell candidate; no artificial size change.
    q.locator('#arrangeMode').click();q.locator('#scene [data-module="rack"]').click();q.wait_for_selector('#scene [data-resize="cell"]');handle=q.locator('#scene [data-resize="cell"]');assert handle.locator('[data-cell-diamond]').count()==1;assert 'not scrolls' in handle.locator('title').text_content();assert q.locator('#scene [data-resize="width"] rect').count()==2;capture('rack-handle')
    candidate=q.evaluate('''()=>{let n=findNode(activeLayout(),'rack');return [-1,1].find(d=>!cellCandidate(n,n.cellR+d).error)||0}''');assert candidate
    radius=q.evaluate('findNode(activeLayout(),"rack").cellR');records=q.evaluate('JSON.stringify(findNode(activeLayout(),"rack").records)');handle.focus();q.keyboard.press('ArrowRight' if candidate==1 else 'ArrowLeft');assert q.evaluate('findNode(activeLayout(),"rack").cellR')==radius+candidate;assert q.evaluate('JSON.stringify(findNode(activeLayout(),"rack").records)')==records
    # Drag horizontally through a valid four-unit radius change, beyond gesture threshold.
    radius=q.evaluate('findNode(activeLayout(),"rack").cellR');delta=q.evaluate('''()=>{let n=findNode(activeLayout(),'rack');return [4,-4].find(d=>!cellCandidate(n,n.cellR+d).error)||0}''');assert delta
    bounds=handle.bounding_box();x=bounds['x']+bounds['width']/2;y=bounds['y']+bounds['height']/2;scale=q.evaluate('scene.getScreenCTM().a');q.mouse.move(x,y);q.mouse.down();q.mouse.move(x+delta*.866*scale,y,steps=4);q.mouse.up();assert q.evaluate('findNode(activeLayout(),"rack").cellR')==radius+delta;assert q.evaluate('JSON.stringify(findNode(activeLayout(),"rack").records)')==records
    q.locator('#arrangeMode').click();assert not q.evaluate('arranging');menu('Undo arrangement');assert q.evaluate('__s18.geometry()')==original
    q.set_viewport_size({'width':500,'height':750});assert q.locator('#scene [data-app-id]').count()==4;assert not errors,errors;assert not requests,requests
    print('PASS exact assets/catalogue/validator; three palettes; four separate nonresizable application books; hover and holder return; explicit Cubby preview; direct backing fields; rack radius keyboard and pointer drag, Browse commit and Undo; narrow offline.')
    browser.close()
