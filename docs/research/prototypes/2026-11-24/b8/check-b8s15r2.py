"""S15r2 focused perspective Shelf contrast regression (offline Chromium)."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
old=root/'Astral_Archive_Room_Study_B8s15r1.html'; new=root/'Astral_Archive_Room_Study_B8s15r2.html'
def blob(f):
    b=f.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(old)=='271224e2fbebbf8ac7dd1fa020e16c10ab9f2d12'
a,b=old.read_text(),new.read_text()
def parts(s):
    i=s.index(" if(q.kind==='shelf'){",s.index('function meshScene'));j=s.index(" if(q.kind==='reading'){",i)
    return s[:i].replace('Room plan B8s15r1','Room plan B8s15r2'),s[j:]
assert parts(a)==parts(b),'Non-Shelf source changed'
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1400,'height':900},offline=True)
    errors=[];requests=[]
    def load(s):
        page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(s);return page
    x,y=load(a),load(b)
    initial=y.evaluate('JSON.stringify(saved)')
    for theme in ['Twilight','Evening','Midnight']:
        for page in [x,y]:
            page.locator('#theme').select_option(theme);page.locator('#view2d').click()
        assert x.locator('#scene').inner_html()==y.locator('#scene').inner_html(),theme
        assert x.evaluate('JSON.stringify(meshScene({...saved,shelves:saved.shelves.filter(q=>q.kind!=="shelf")}))')==y.evaluate('JSON.stringify(meshScene({...saved,shelves:saved.shelves.filter(q=>q.kind!=="shelf")}))'),theme
        for page in [x,y]:page.locator('#view3d').click()
        for tilt in ['20','30']:
            y.locator('#tilt').fill(tilt);assert y.evaluate('JSON.stringify(saved)')==initial
            if args.captures:
                args.captures.mkdir(parents=True,exist_ok=True);y.screenshot(path=args.captures/f'{theme}-{tilt}.png')
    print('Exact 2D SVG and all non-Shelf meshes match, three palettes; perspective tilt 20–30 unchanged')
    bounds=y.evaluate('''()=>{let empty={...saved,shelves:[]},ref=meshScene(empty),n=0;for(const [w,d] of [[70,40],[180,75],[900,400]])for(const a of [0,90,180,270]){let q=item(99,'shelf','sample',100,100,w,d,a),bb=box(q),mesh=meshScene({...empty,shelves:[q]});let points=[...mesh.tri.slice(ref.tri.length).flatMap(v=>v.slice(0,3)),...mesh.edges.slice(ref.edges.length).flatMap(v=>v.slice(0,2))];if(!points.length||points.some(p=>!p.every(Number.isFinite)||p[0]<bb.x-1e-6||p[0]>bb.x+bb.w+1e-6||p[1]<bb.y-1e-6||p[1]>bb.y+bb.h+1e-6||p[2]<0))return {w,d,a};n++;}return n}''');assert bounds==12,bounds
    print('12 Shelf footprint/orientation samples passed')
    y.locator('#mode').click();y.locator('#geometry').click();y.locator('#target').select_option('1');y.locator('#x').fill('68');y.locator('#set').click();assert y.evaluate('draft.shelves[0].x')==68;y.locator('#view2d').click();y.locator('#apply').click();assert y.evaluate('saved.shelves[0].x')==68;y.locator('#undo').click();assert y.evaluate('JSON.stringify(saved)')==initial
    y.locator('#view3d').click();y.set_viewport_size({'width':500,'height':750});y.wait_for_timeout(250);assert not errors,errors;assert not requests,requests
    print('Exact edit, Apply/Undo, narrow viewport, offline/no uncaught errors passed');browser.close()
