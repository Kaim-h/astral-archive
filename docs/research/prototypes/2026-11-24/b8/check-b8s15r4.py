"""Shelf plan comparison: verify all 8 options, unchanged model and perspective."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Room_Study_B8s15r3.html';new=root/'Astral_Archive_Room_Study_B8s15r4.html'
def blob(f):
    b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(old)=='3dadd39f17c109ee14866f8ff81220c9bbacda42'
a,b=old.read_text(),new.read_text()
assert a[a.index('function meshScene'):a.index('function render(){')]==b[b.index('function meshScene'):b.index('// R4 comparison only:')]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
    errors=[];requests=[]
    def load(s):
        page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(s);return page
    x,y=load(a),load(b);initial=y.evaluate('JSON.stringify(saved)');assert x.evaluate('JSON.stringify(saved)')==initial
    assert y.locator('#view2d').get_attribute('aria-pressed')=='true'
    for theme in ['Twilight','Evening','Midnight']:
        for page in [x,y]:page.locator('#theme').select_option(theme)
        assert x.evaluate('JSON.stringify(meshScene(saved))')==y.evaluate('JSON.stringify(meshScene(saved))'),theme
        y.locator('#compareSymbols').click();assert y.locator('#symbolCards button').count()==8
        if args.captures:
            args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/f'{theme}-gallery.png')
        y.locator('[data-symbol="A"]').click();assert not y.locator('#symbolGallery').is_visible()
        seen=set()
        for key in 'ABCDEFGH':
            y.locator('#planSymbol').select_option(key);assert y.locator(f'[data-plan-symbol="{key}"]').count()==3
            seen.add(y.locator('[data-plan-symbol]').first.inner_html());assert y.evaluate('JSON.stringify(saved)')==initial
            if args.captures and theme=='Twilight':y.screenshot(path=args.captures/f'{key}-plan.png')
        assert len(seen)==8
        y.locator('#view3d').click();assert y.locator('[data-plan-symbol]').count()==0
        y.locator('#view2d').click();assert y.locator('[data-plan-symbol="H"]').count()==3
    # Check all marks at min and large dimensions and quarter turns; no negative SVG rectangles.
    assert y.evaluate('''()=>{for(let key of Object.keys(PLAN_SYMBOLS))for(let [w,d] of [[70,40],[180,75],[900,400]]){let host=document.createElementNS('http://www.w3.org/2000/svg','svg');host.innerHTML=shelfPlanSymbol(w,d,'#fff',key);if([...host.querySelectorAll('rect')].some(r=>+r.getAttribute('width')<0||+r.getAttribute('height')<0)||/NaN|Infinity/.test(host.innerHTML))return false;}return true;}''')
    y.locator('#mode').click();y.locator('#geometry').click();y.locator('#target').select_option('1');y.locator('#angle').select_option('180');y.locator('#set').click();before=y.evaluate('JSON.stringify(draft)');y.locator('#planSymbol').select_option('D');assert y.evaluate('JSON.stringify(draft)')==before;y.locator('#apply').click();assert y.evaluate('saved.shelves[0].a')==180;y.locator('#undo').click();assert y.evaluate('JSON.stringify(saved)')==initial
    y.set_viewport_size({'width':500,'height':750});y.locator('#compareSymbols').click();y.locator('[data-symbol="F"]').click();assert y.locator('[data-plan-symbol="F"]').count()==3;assert not errors,errors;assert not requests,requests
    print('PASS: 8 distinct options × 3 palettes, gallery, projection, exact mesh identity, minimum and large dimensions, rotation/Apply/Undo, narrow viewport, offline')
    browser.close()
