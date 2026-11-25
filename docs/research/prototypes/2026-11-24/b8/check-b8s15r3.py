"""Shelf-only B8 scope and simplified plan regression; offline Chromium."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Room_Study_B8s15r2.html';new=root/'Astral_Archive_Room_Study_B8s15r3.html'
def blob(f):
    b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(old)=='b9b623bf7b3cc566ff46c911330ce9d0acd8c8a5'
a,b=old.read_text(),new.read_text()
assert a[a.index('function meshScene'):a.index('function render(){')]==b[b.index('function meshScene'):b.index('function render(){')]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
    errors=[];requests=[]
    def load(s):
        page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(s);return page
    x,y=load(a),load(b)
    initial=y.evaluate('JSON.stringify(saved)')
    assert y.evaluate('JSON.stringify(saved.shelves)')==x.evaluate('JSON.stringify(saved.shelves.filter(q=>q.kind==="shelf"))')
    assert y.evaluate('Object.keys(TYPES).length')==6
    assert y.locator('#kind option').count()==1 and y.locator('#kind').input_value()=='shelf'
    assert y.evaluate('Object.keys(TYPES).filter(k=>k!=="shelf").every(k=>valid({...saved,shelves:[item(99,k,k,50,50,TYPES[k][1],TYPES[k][2])]}).includes("deferred"))')
    for theme in ['Twilight','Evening','Midnight']:
        for page in [x,y]:page.locator('#theme').select_option(theme)
        assert x.evaluate('JSON.stringify(meshScene({...saved,shelves:saved.shelves.filter(q=>q.kind==="shelf")}))')==y.evaluate('JSON.stringify(meshScene(saved))'),theme
        y.locator('#view2d').click();assert y.locator('[data-plan-shelf="frame"]').count()==3;assert y.locator('[data-kind]:not([data-kind="shelf"])').count()==0
        assert y.locator('[data-kind="shelf"] [data-plan-shelf]').count()==9
        if args.captures:
            args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/f's15r3-{theme}-2d.png')
        y.locator('#view3d').click();assert y.locator('[data-kind]:not([data-kind="shelf"])').count()==0
        if args.captures:y.screenshot(path=args.captures/f's15r3-{theme}-3d.png')
    print('Shelf-only initial state, active catalogue and validation; exact r2 Shelf-only meshes across 3 palettes; simplified plan passed')
    y.locator('#theme').select_option('Twilight');y.locator('#view2d').click();y.locator('#mode').click();y.locator('#geometry').click();y.locator('#add').click();assert y.evaluate('pending.kind')=='shelf';assert y.evaluate('pending.id')==12
    y.locator('#place').click();assert y.evaluate('draft.shelves.length')==4
    y.locator('#target').select_option('12');y.locator('#angle').select_option('90');y.locator('#set').click();assert y.evaluate('draft.shelves.find(s=>s.id===12).a')==90
    y.locator('#w').fill('200');y.locator('#set').click();assert y.evaluate('draft.shelves.find(s=>s.id===12).w')==200
    y.locator('#x').fill('40');y.locator('#y').fill('450');y.locator('#set').click();assert y.evaluate('draft.shelves.find(s=>s.id===12).x')==40
    y.locator('#x').fill('70');y.locator('#y').fill('72');y.locator('#set').click();assert y.evaluate('draft.shelves.find(s=>s.id===12).x')==40
    y.locator('#view3d').click();y.locator('#apply').click();assert y.evaluate('saved.shelves.length')==4
    y.locator('#undo').click();assert y.evaluate('JSON.stringify(saved)')==initial
    y.locator('#mode').click();y.locator('#geometry').click();y.locator('#add').click();y.locator('#discard').click();assert y.evaluate('pending===null && draft.shelves.length===3');y.locator('#target').select_option('1');y.locator('#remove').click();assert y.evaluate('draft.shelves.length')==2;y.locator('#cancel').click();assert y.evaluate('JSON.stringify(saved)')==initial
    y.set_viewport_size({'width':500,'height':750});y.wait_for_timeout(200);assert not errors,errors;assert not requests,requests
    print('Add/place, rotate, resize, exact movement, collision rejection, projection switch, Apply/Undo, discard, remove/Cancel, narrow viewport and offline passed');browser.close()
