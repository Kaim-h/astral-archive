"""S15 furniture-only regression against the exact S14r5 HTML. Python Playwright + Chromium."""
import argparse, hashlib, json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
base=args.baseline or root/'Astral_Archive_Room_Study_B8s14r5.html'
new=root/'Astral_Archive_Room_Study_B8s15.html'
def blob(path):
 b=path.read_bytes();return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert blob(base)=='69f5794b628a022c8fe039f39e3e8287547a0c31'
a,b=base.read_text(),new.read_text()
def parts(s):
 i=s.index(" if(q.kind==='shelf')",s.index('function meshScene')) if 'Room plan B8s14r5' in s else s.index(' // Furniture uses the same local footprint transform')
 j=s.index(' }tf=id;return',i);return s[:i].replace('Room plan B8s14r5','Room plan B8s15'),s[j:]
assert parts(a)==parts(b), 'non-furniture source changed'
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1440,'height':960},offline=True)
 errors=[];requests=[]
 def load(s):
  page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(s);return page
 old=load(a);newp=load(b)
 for page in [old,newp]:page.locator('#view2d').click()
 assert old.locator('#scene').inner_html()==newp.locator('#scene').inner_html()
 assert old.evaluate('JSON.stringify(saved)')==newp.evaluate('JSON.stringify(saved)')
 assert old.evaluate('JSON.stringify(meshScene({...saved,shelves:[]}))')==newp.evaluate('JSON.stringify(meshScene({...saved,shelves:[]}))')
 assert old.evaluate('JSON.stringify(meshScene({...saved,shelves:saved.shelves.filter(q=>q.kind==="rug")}))')==newp.evaluate('JSON.stringify(meshScene({...saved,shelves:saved.shelves.filter(q=>q.kind==="rug")}))')
 print('Exact non-furniture source, 2D SVG, empty Room and rug meshes match')
 bounds=newp.evaluate('''()=>{let empty={...saved,shelves:[]},ref=meshScene(empty),n=0;for(const [k,t] of Object.entries(TYPES))for(const [w,d] of [[t[3],t[4]],[t[1],t[2]],[900,k==='rug'?600:400]])for(const a of [0,90,180,270]){let q=item(99,k,k,100,100,w,d,a),bb=box(q),mesh=meshScene({...empty,shelves:[q]});let points=[...mesh.tri.slice(ref.tri.length).flatMap(v=>v.slice(0,3)),...mesh.edges.slice(ref.edges.length).flatMap(v=>v.slice(0,2))];if(!points.length||points.some(p=>!p.every(Number.isFinite)||p[0]<bb.x-1e-6||p[0]>bb.x+bb.w+1e-6||p[1]<bb.y-1e-6||p[1]>bb.y+bb.h+1e-6||p[2]<0))return {k,w,d,a,bad:points.filter(p=>!p.every(Number.isFinite)||p[0]<bb.x-1e-6||p[0]>bb.x+bb.w+1e-6||p[1]<bb.y-1e-6||p[1]>bb.y+bb.h+1e-6||p[2]<0).slice(0,2)};n++;}return n}''');assert bounds==72,bounds;print('72 size/orientation meshes remain inside footprints')
 old.close();original=newp.evaluate('JSON.stringify(saved)');newp.locator('#view3d').click()
 for theme in ['Evening','Midnight','Twilight']:
  newp.locator('#theme').select_option(theme);newp.locator('#tilt').fill('30');newp.locator('#tilt').fill('20');assert newp.evaluate('JSON.stringify(saved)')==original
 newp.locator('#tilt').fill('22');newp.locator('#mode').click();newp.locator('#geometry').click();newp.locator('#target').select_option('1');newp.locator('#x').fill('68');newp.locator('#set').click();assert newp.evaluate('draft.shelves[0].x')==68;newp.locator('#view2d').click();newp.locator('#apply').click();assert newp.evaluate('saved.shelves[0].x')==68;newp.locator('#undo').click();assert newp.evaluate('JSON.stringify(saved)')==original
 newp.locator('#view3d').click();newp.locator('#appearance').click();newp.locator('#floorMaterial').select_option('hex');newp.locator('#appearanceCancel').click();assert newp.evaluate('JSON.stringify(saved)')==original
 if args.captures:
  args.captures.mkdir(parents=True,exist_ok=True);newp.screenshot(path=args.captures/'room-s15.png')
 newp.set_viewport_size({'width':500,'height':750});newp.wait_for_timeout(250);assert newp.evaluate('valid(saved)')=='';assert not errors,errors;assert not requests,requests
 print('Projection, palette, tilt, exact geometry, Apply/Undo, appearance Cancel, narrow viewport, offline and page errors: PASS');print(newp.evaluate('window.__roomStudy.renderStats()'));browser.close()
