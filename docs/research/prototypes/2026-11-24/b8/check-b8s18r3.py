"""S18r3 focused board recovery, independent books and Arrange-mode controls."""
import argparse, hashlib, re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Shelf_Study_B8s18r2.html';new=root/'Astral_Archive_Shelf_Study_B8s18r3.html'
a=old.read_bytes();assert hashlib.sha1(b'blob '+str(len(a)).encode()+b'\0'+a).hexdigest()=='08649cc9796dff6481120d312a0b61b9be47c584';a=a.decode();b=new.read_text()
for name in ['ASSETS','FACES']:
    pat=r'^const '+name+r'=.*$';assert re.search(pat,a,re.M).group()==re.search(pat,b,re.M).group(),name
assert a[a.index('const CATALOGUE='):a.index('const selectedEmblems=')]==b[b.index('const CATALOGUE='):b.index('const selectedEmblems=')]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True);q.set_default_timeout(3500);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b)
    def cap(n):
        if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
    def menu(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=n,exact=True).click()
    def geometry():return q.evaluate('__s18.geometry()')
    def node(id):return q.evaluate('id=>findNode(activeLayout(),id)',id)
    def edit(id):
        q.locator(f'#scene [data-module="{id}"]').click(button='right');q.get_by_role('menuitem',name=re.compile('Geometry and support|Dimensions and cells')).click()
    def valid():assert q.evaluate('!validateLayout(activeLayout(),committed.w,committed.h)&&!validateOwnership(activeLayout(),activeCase())')
    valid();original=geometry();assert q.locator('[data-lighting-board]').count()==2;assert q.locator('[data-app-id]').count()==4
    assert q.evaluate('layout.filter(n=>n.kind==="board").every(n=>n.h===15)&&layout.filter(n=>n.kind==="book").every(n=>n.records.length===0&&!RESIZABLE.has(n.kind)&&findNode(layout,n.support).kind==="board"&&!initialRecords.has(n.appId))')
    cap('shelf')
    for theme in ['Evening','Midnight','Twilight']:
        q.locator('#studyEnvironment').click();q.locator('#desktopTheme').select_option(theme);q.locator('#paneClose').click();assert q.locator('[data-lighting-board]').count()==2 and q.locator('[data-app-id]').count()==4
    q.locator('[data-app-id="sample-browser"]').click();assert 'Application activation' in q.locator('#status').inner_text()
    q.locator('#arrangeMode').click();q.locator('[data-module="book-browser"]').hover();assert q.locator('#info').is_visible() and 'Support: Shelf board' in q.locator('#info').inner_text();cap('book-tooltip')
    q.locator('[data-module="jar"] [data-file="jar"]').hover();assert q.locator('#info').is_visible() and 'Vessel.stl' in q.locator('#info').inner_text();cap('file-tooltip')
    q.locator('[data-module="holder"] [data-slot="r1"]').hover();assert 'Field-record.ogg' in q.locator('#info').inner_text();presented=q.evaluate('presented');q.locator('[data-module="holder"] [data-slot="r1"]').click();assert q.evaluate('presented')==presented
    # Independent books can move, but cannot resize or rest on floor/cubby/rack.
    n=node('book-browser');assert q.evaluate('n=>!!buildCandidate(n.id,n.x,0,n.w,n.h,"floor").error',n)
    edit('book-browser');assert q.locator('#arrW').is_disabled() and q.locator('#arrH').is_disabled();assert q.locator('#arrSupport option').evaluate_all('(a)=>a.map(o=>o.value)')==['board','book-board'];q.locator('#arrX').fill(str(n['x']-5));q.locator('#arrangeMode').click();assert node(n['id'])['x']==n['x']-5 and node('book-editor')['x']==657;valid();menu('Undo arrangement');assert geometry()==original
    # Moving board carries books without scaling or changing identities.
    q.locator('#arrangeMode').click();edit('book-board');q.locator('#arrX').fill('600');q.locator('#arrZ').fill('12');q.locator('#arrangeMode').click();assert node('book-browser')['x']==615 and node('book-browser')['z']==27 and node('book-browser')['w']==n['w'];valid();menu('Undo arrangement');assert geometry()==original
    q.locator('#arrangeMode').click();menu('Appearance ›');q.get_by_role('menuitem',name='Primary emblem…').click();q.locator('#familyPolicy').select_option('botanical');q.locator('#paneClose').click();assert q.evaluate('arranging') and q.evaluate('__s18.state().appearance.family')=='botanical';menu('Appearance ›');q.get_by_role('menuitem',name='Undo appearance').click();assert q.evaluate('__s18.state().appearance.family')=='astral';cap('arrange')
    menu('Shelf dimensions…');q.locator('#width').fill('860');q.locator('#paneClose').click();assert q.evaluate('arranging&&committed.w===860');menu('Shelf dimensions…');q.locator('#width').fill('840');q.locator('#paneClose').click();assert geometry()==original
    # Explicit removal unplaces app books, never makes them file records.
    q.locator('[data-module="book-board"]').click(button='right');q.get_by_role('menuitem',name='Remove…').click();assert '4 application book placement(s)' in q.locator('#removeSummary').inner_text();q.locator('#removeConfirm').click();q.locator('#arrangeMode').click();assert q.locator('[data-app-id]').count()==0 and q.evaluate('caseRecords.length===0&&APP_BOOKS.length===4');valid();menu('Undo arrangement');assert geometry()==original
    q.set_viewport_size({'width':500,'height':750});q.locator('#arrangeMode').click();menu('Appearance ›');q.get_by_role('menuitem',name='Frame appearance…').click();assert q.locator('#palettePolicy').is_visible();q.keyboard.press('Escape');q.locator('#arrangeMode').click();valid();assert not errors,errors;assert not requests,requests
    print('PASS: exact assets/catalogue, restored 15-unit flat board, independent fixed-size supported app books, three palettes, actual Arrange hover, no activation in Arrange, board/dependent moves, implicit commit/Undo, shared menus, removal/Undo, narrow offline')
    browser.close()
