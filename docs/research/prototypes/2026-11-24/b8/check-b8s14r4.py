from pathlib import Path
from playwright.sync_api import sync_playwright
import argparse
ap=argparse.ArgumentParser();ap.add_argument('--chromium',default='/usr/bin/chromium');ap.add_argument('--captures',type=Path);args=ap.parse_args()
source=Path(__file__).with_name('Astral_Archive_Room_Study_B8s14r4.html').read_text()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);page=b.new_page(viewport={'width':1366,'height':900},offline=True);errors=[];requests=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(source)
 def state(k='snapshot'):return page.evaluate(f'__roomStudy.{k}()')
 def item(m,i):return next(s for s in m['shelves'] if s['id']==i)
 def cap(n):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);page.screenshot(path=str(args.captures/(n+'.png')))
 def screen(x,y):return page.evaluate('([x,y])=>{let a=__roomStudy.screenProject(x,y),p=new DOMPoint(a[0],a[1]).matrixTransform(document.getElementById("floorProjection").getScreenCTM());return [p.x,p.y]}',[x,y])
 def drag(sel,dx,dy):
  a=page.locator(sel).bounding_box();x=a['x']+a['width']/2;y=a['y']+a['height']/2
  q=page.evaluate('([x,y,dx,dy])=>{let m=document.getElementById("floorProjection").getScreenCTM(),v=new DOMPoint(x,y).matrixTransform(m.inverse()),p=__roomStudy.floorInverse(v.x,v.y),r=__roomStudy.screenProject(p.x+dx,p.y+dy),s=new DOMPoint(r[0],r[1]).matrixTransform(m);return [s.x,s.y]}',[x,y,dx,dy]);page.mouse.move(x,y);page.mouse.down();page.mouse.move(*q,steps=5);page.mouse.up()
 original=state();assert original['appearance']['grout']==.5;assert page.locator('#perspectiveCanvas').count()==1;assert not errors,errors;cap('B8s14r4-perspective');count=state('renderStats')['count'];page.wait_for_timeout(400);assert state('renderStats')['count']==count
 # Native-density output and supersampling. Resolution changes cannot change the camera or model.
 initial_quality=state('renderStats')['quality'];assert initial_quality['mode']=='refined'
 assert initial_quality['sampleWidth']>initial_quality['width'] and initial_quality['sampleWidth']*initial_quality['sampleHeight']<=5000000
 assert page.locator('#perspectiveCanvas').evaluate('(c)=>c.width')==initial_quality['width']
 assert abs(initial_quality['width']-1050*initial_quality['cssScale']*initial_quality['dpr'])<3
 before=state('renderStats');page.locator('#tilt').fill('23');assert state('renderStats')['meshBuilds']==before['meshBuilds'];page.locator('#tilt').fill('22')
 page.click('#mode');a=page.locator('[data-move="6"]').bounding_box();x=a['x']+a['width']/2;y=a['y']+a['height']/2
 q=page.evaluate('([x,y])=>{let m=document.getElementById("floorProjection").getScreenCTM(),v=new DOMPoint(x,y).matrixTransform(m.inverse()),p=__roomStudy.floorInverse(v.x,v.y),r=__roomStudy.screenProject(p.x+20,p.y+20),s=new DOMPoint(r[0],r[1]).matrixTransform(m);return [s.x,s.y]}',[x,y]);page.mouse.move(x,y);page.mouse.down();page.mouse.move(*q,steps=3)
 preview=state('renderStats')['quality'];assert preview['mode']=='preview' and preview['width']<initial_quality['width'] and preview['sampleWidth']==preview['width'];cap('B8s14r4-drag-preview');page.mouse.up();refined=state('renderStats')['quality'];assert refined['mode']=='refined' and refined['width']==initial_quality['width'];assert item(state('draft'),6)['x']==440;cap('B8s14r4-drag-refined');page.click('#cancel');assert state()==original
 page.set_viewport_size({'width':1920,'height':1200});page.wait_for_function('()=>__roomStudy.renderStats().quality.width>1300');large=state('renderStats')['quality'];assert large['width']>initial_quality['width'] and large['sampleWidth']*large['sampleHeight']<=5000000;assert state()==original;cap('B8s14r4-large')
 page.set_viewport_size({'width':1366,'height':900});page.wait_for_function('(w)=>__roomStudy.renderStats().quality.width===w',arg=initial_quality['width']);before=state('renderStats')['count'];page.wait_for_timeout(400);assert state('renderStats')['count']==before
 hi=b.new_page(viewport={'width':1366,'height':900},device_scale_factor=2,offline=True);hi.set_content(source);h=hi.evaluate('()=>__roomStudy.renderStats().quality');assert h['dpr']==2 and h['width']>initial_quality['width'] and h['width']*h['height']<=1800000 and h['sampleWidth']*h['sampleHeight']<=5000000
 if args.captures:hi.screenshot(path=str(args.captures/'B8s14r4-hidpi.png'))
 hi.close();print('Adaptive quality:',initial_quality,'preview:',preview,'large:',large,'HiDPI:',h)
 for t in range(20,31):
  page.locator('#tilt').fill(str(t));assert state()==original
  assert page.evaluate('()=>{let f=__roomStudy.perspectiveFrame();for(let x of [0,300,f.w])for(let y of [0,200,f.d]){let p=__roomStudy.screenProject(x,y),q=__roomStudy.floorInverse(p[0],p[1]);if(Math.hypot(x-q.x,y-q.y)>1e-7)return false;}let n=__roomStudy.screenProject(100,0),m=__roomStudy.screenProject(200,0),a=__roomStudy.screenProject(100,f.d),b=__roomStudy.screenProject(200,f.d);return b[0]-a[0]>m[0]-n[0]}'),t
 for t in [20,22,30]:
  page.locator('#tilt').fill(str(t));page.click('#mode');drag('[data-move="6"]',20,20);assert (item(state('draft'),6)['x'],item(state('draft'),6)['y'])==(440,330),state('draft');drag('[data-resize="6"]',20,20);assert (item(state('draft'),6)['w'],item(state('draft'),6)['d'])==(200,200);page.locator('[data-turn="6"]').click();assert item(state('draft'),6)['a']==90;before=state('draft');page.click('#view2d');assert state('draft')==before and not page.locator('#perspectiveCanvas').count();page.click('#view3d');assert state('draft')==before;page.click('#cancel');assert state()==original
 page.locator('#tilt').fill('22');page.click('#view2d');cap('B8s14r4-plan');page.click('#mode');a=page.locator('[data-move="6"]').bounding_box();x=a['x']+a['width']/2;y=a['y']+a['height']/2;scale=page.evaluate('document.getElementById("floorProjection").getScreenCTM().a');page.mouse.move(x,y);page.mouse.down();page.mouse.move(x+20*scale,y+20*scale,steps=5);page.mouse.up();assert item(state('draft'),6)['x']==440;page.click('#cancel');page.click('#view3d');page.click('#mode');cap('B8s14r4-arrange');page.click('#geometry');page.fill('#roomW','1500');page.fill('#roomD','1000');page.click('#roomSet');assert state('draft')['shelves']==original['shelves'];page.fill('#roomW','600');page.click('#roomSet');assert state('draft')['w']==1500
 for k in state('catalogue'):
  page.select_option('#kind',k);page.click('#add');q=state('pending');assert q['kind']==k;page.fill('#x','1200');page.fill('#y','800');page.click('#set');assert not page.locator('#place').is_disabled(),(k,page.locator('#status').inner_text());page.click('#place');assert item(state('draft'),q['id'])['kind']==k;page.click('#remove');assert len(state('draft')['shelves'])==8
 page.select_option('#kind','shelf');page.click('#add');q=state('pending');page.fill('#x','420');page.fill('#y','310');page.click('#set');assert page.locator('#place').is_disabled();page.click('#close');cap('B8s14r4-invalid');page.keyboard.press('Escape');assert state('pending') is None;page.click('#apply');assert state()['w']==1500;page.click('#undo');assert state()==original
 page.click('#appearance');assert state('appearanceDraft')==original
 for k in ['plain','slabs','bond','diagonal','octagon','hex','herringbone','basket','ashlar']:
  page.select_option('#floorMaterial',k);assert not errors,errors;assert state('appearanceDraft')['appearance']['floor']==k;assert state('appearanceDraft')['shelves']==original['shelves'];assert page.locator('#perspectiveCanvas').get_attribute('data-rendered')=='perspective'
  if k!='plain':
   # Whole-tile representative lattice coverage, no artificial repeat-boundary joints.
   assert page.evaluate('''()=>{let {w,h,tiles}=__roomStudy.stonePattern();let cells=tiles.filter(t=>{let x=t.p.reduce((s,q)=>s+q[0],0)/t.p.length,y=t.p.reduce((s,q)=>s+q[1],0)/t.p.length;return x>=-1e-7&&x<w-1e-7&&y>=-1e-7&&y<h-1e-7});const inside=(x,y,p)=>{let r=false;for(let i=0,j=p.length-1;i<p.length;j=i++){let [a,b]=p[i],[u,v]=p[j];if((b>y)!==(v>y)&&x<(u-a)*(y-b)/(v-b)+a)r=!r;}return r};for(let j=0;j<23;j++)for(let i=0;i<29;i++){let x=(i+.317)*w/29,y=(j+.619)*h/23,n=0;for(let u=-1;u<=1;u++)for(let v=-1;v<=1;v++)for(const t of cells)if(inside(x-u*w,y-v*h,t.p))n++;if(n!==1)return false}return true}'''),k
 for k in ['plain','panel','masonry','rubble','pilaster','arcade','wainscot','ribbed']:
  page.select_option('#wallMaterial',k);assert state('appearanceDraft')['appearance']['wall']==k;assert not errors,errors
 page.select_option('#floorMaterial','herringbone');page.select_option('#wallMaterial','arcade');page.select_option('#roomFamily','water');page.select_option('#roomPalette','Evening');page.locator('#detail').fill('75');page.click('#appearanceClose');cap('B8s14r4-custom');before=state('appearanceDraft');page.click('#view2d');assert state('appearanceDraft')==before;page.click('#view3d');assert state('appearanceDraft')==before;page.click('#appearanceApply');assert state()['appearance']['wall']=='arcade';assert state()['shelves']==original['shelves'];page.click('#undo');assert state()==original
 for theme in ['Evening','Midnight','Twilight']:page.select_option('#theme',theme);assert state()==original
 page.set_viewport_size({'width':500,'height':780});page.click('#mode');page.click('#geometry');assert page.evaluate('document.documentElement.scrollWidth<=innerWidth');cap('B8s14r4-narrow');assert not errors,errors;assert not requests,requests;print('PASS S14r4: perspective inverse, depth scaling, idle render count, real movement/resizing/rotation, 2D fallback, all six creation types, invalid creation, growth/shrink, transactions, nine floors/eight walls, periodic tile coverage, palettes, narrow viewport; last raster ms',state('renderStats')['ms']);b.close()
