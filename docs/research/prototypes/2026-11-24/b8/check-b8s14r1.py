from pathlib import Path
from playwright.sync_api import sync_playwright
import argparse
ap=argparse.ArgumentParser();ap.add_argument('--chromium',default='/usr/bin/chromium');ap.add_argument('--captures',type=Path);args=ap.parse_args()
source=Path(__file__).with_name('Astral_Archive_Room_Study_B8s14r1.html').read_text()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);page=b.new_page(viewport={'width':1366,'height':900},offline=True)
 errors=[];requests=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(source)
 def state(k='snapshot'):return page.evaluate(f'window.__roomStudy.{k}()')
 def item(m,i):return next(s for s in m['shelves'] if s['id']==i)
 def cap(name):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);page.screenshot(path=str(args.captures/(name+'.png')))
 def drag(sel,dx,dy,inspect=None):
  el=page.locator(sel).bounding_box();x=el['x']+el['width']/2;y=el['y']+el['height']/2;a,b,c,d=page.evaluate("(()=>{let m=document.getElementById('floorProjection').getScreenCTM();return [m.a,m.b,m.c,m.d]})()");page.mouse.move(x,y);page.mouse.down();page.mouse.move(x+dx*a+dy*c,y+dx*b+dy*d,steps=8)
  if inspect:inspect()
  page.mouse.up()
 def geo(i):page.select_option('#target',str(i))
 original=state();assert page.locator('[data-elevated]').count()==7;assert page.locator('[data-wall]').count()==3;assert page.locator('[data-shelf-face="front"]').count()==3;cap('B8s14r1-elevated');page.click('#view2d');assert page.locator('[data-elevated]').count()==0 and page.locator('[data-wall]').count()==0 and state()==original;cap('B8s14r1-plan');page.click('#view3d');assert state()==original;
 for tilt in [20,30,22]:
  page.locator('#tilt').fill(str(tilt));assert state()==original;cap('B8s14r1-tilt-'+str(tilt))
 # Verify physical wall junctions in floor coordinates, independent of camera tilt.
 def joints():
  return page.evaluate("""()=>{let n=q=>Array.from(document.querySelector('[data-wall-face="'+q+'"]').points,p=>[p.x,p.y]);let eq=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1])<.001;let N=n('north-inner'),E=n('east-inner'),F=n('far-cap'),W=n('west-outer'),S=n('south-left-outer'),C=n('southwest-cap'),R=n('southright-cap'),T=n('north-trim'),U=n('east-trim');return N.length===4&&E.length===4&&F.length===6&&C.length===6&&eq(N[1],E[0])&&eq(N[2],E[3])&&eq(F[4],N[2])&&eq(W[1],S[0])&&eq(W[2],S[3])&&eq(C[5],W[2])&&eq(T[1],U[0])&&eq(T[2],U[3])&&eq(R[1],[E[1][0]+(E[3][0]-E[0][0])*12/125,E[1][1]-14+(E[3][1]-E[0][1])*12/125])}""")
 for t in [20,22,24,26,28,30]:
  page.locator('#tilt').fill(str(t));assert joints(),t
 page.locator('#tilt').fill('22')
 assert page.evaluate('window.__roomStudy.validate(window.__roomStudy.snapshot())')=='',page.locator('#status').inner_text()
 assert len({s['kind'] for s in original['shelves']})==6;assert page.locator('[data-turn]').count()==0
 assert page.locator('.shelfLabel').count()==0;assert page.locator('[data-kind]').count()==8;page.check('#labels');assert page.locator('.shelfLabel').count()==8;cap('B8s14r1-labels');page.uncheck('#labels');assert state()==original and page.locator('.shelfLabel').count()==0; page.locator('[data-move="6"]').click();assert state()==original and state('draft') is None
 # Camera-specific invariants and actual floor-relative pointer increments at extreme tilts.
 for t in [20,30]:
  page.locator('#tilt').fill(str(t));page.click('#mode');before=state('draft');drag('[data-move="6"]',20,20);assert item(state('draft'),6)['x']==440 and item(state('draft'),6)['y']==330
  drag('[data-resize="6"]',20,20);assert (item(state('draft'),6)['w'],item(state('draft'),6)['d'])==(200,200)
  old=state('draft');page.locator('#tilt').fill('26');assert state('draft')==old;page.click('#cancel');assert state()==original
 page.locator('#tilt').fill('22');
 page.click('#mode');assert state('draft')==original;page.click('#view2d');assert state('draft')==original;page.click('#view3d');assert state('draft')==original;cap('B8s14r1-arrange');drag('[data-move="6"]',20,20);assert item(state('draft'),6)['x']==440 and item(state('draft'),6)['y']==330
 drag('[data-resize="6"]',20,20);assert (item(state('draft'),6)['w'],item(state('draft'),6)['d'])==(200,200)
 before=state('draft');page.locator('[data-turn="6"]').click();assert item(state('draft'),6)['a']==90;assert [s for s in state('draft')['shelves'] if s['id']!=6]==[s for s in before['shelves'] if s['id']!=6]
 page.click('#cancel');page.click('#mode')
 # Strict plan still supports actual move and resize, then switching preserves the draft.
 page.click('#view2d');drag('[data-move="6"]',20,20);assert item(state('draft'),6)['x']==440;drag('[data-resize="6"]',20,20);assert item(state('draft'),6)['w']==200;draft_before=state('draft');page.click('#view3d');assert state('draft')==draft_before;page.click('#cancel');page.click('#mode')
 # Every sample type rotates; some may be blocked by an actual collision, never move its neighbours.
 for s in original['shelves']:
  before=state('draft');page.locator(f'[data-turn="{s["id"]}"]').click();after=state('draft')
  assert [v for v in before['shelves'] if v['id']!=s['id']]==[v for v in after['shelves'] if v['id']!=s['id']]
  q=item(after,s['id']);assert (q['w'],q['d'])==(s['w'],s['d']);assert q['a']==(s['a']+90)%360 or ('overlaps' in page.locator('#status').inner_text() and after==before)
  assert page.evaluate('window.__roomStudy.validate(window.__roomStudy.draft())')==''
  page.click('#cancel');page.click('#mode')
 # Rotation changes the exposed side, not the underlying dimensions.
 page.locator('[data-turn="1"]').click();page.locator('[data-turn="1"]').click();assert item(state('draft'),1)['a']==180;assert page.locator('[data-elevated="1"] [data-shelf-face="back"]').count()==1;page.click('#cancel');page.click('#mode')
 # Actual angular drag rotates a table counter-clockwise.
 handle=page.locator('[data-turn="6"]').bounding_box();body=page.locator('[data-move="6"]').bounding_box();x=handle['x']+handle['width']/2;y=handle['y']+handle['height']/2;cx=body['x']+body['width']/2;cy=body['y']+body['height']/2;dx=x-cx;dy=y-cy
 page.mouse.move(x,y);page.mouse.down();q=page.evaluate("([x,y,cx,cy])=>{let m=document.getElementById('floorProjection').getScreenCTM(),iv=m.inverse(),p=new DOMPoint(x,y).matrixTransform(iv),c=new DOMPoint(cx,cy).matrixTransform(iv);let r=new DOMPoint(c.x+p.y-c.y,c.y-p.x+c.x).matrixTransform(m);return [r.x,r.y]}",[x,y,cx,cy]);page.mouse.move(*q,steps=12);page.mouse.up();assert item(state('draft'),6)['a']==270
 page.click('#cancel');page.click('#mode')
 # Exact geometry, independent grid, room growth and rejection.
 page.click('#geometry');geo(6);page.fill('#w','240');page.click('#set');assert item(state('draft'),6)['w']==240
 before=state('draft');page.fill('#interval','13');page.locator('#interval').press('Tab');assert state('draft')==before
 page.uncheck('#grid');assert page.locator('rect[fill="url(#planGrid)"]').count()==0 and page.locator('#snap').is_checked();page.check('#grid');page.uncheck('#snap');assert page.locator('rect[fill="url(#planGrid)"]').count()==1;page.check('#snap')
 page.fill('#roomW','1500');page.fill('#roomD','1000');page.click('#roomSet');assert state('draft')['w']==1500 and state('draft')['shelves']==before['shelves']
 before=state('draft');page.fill('#roomW','600');page.click('#roomSet');assert state('draft')==before
 # Create fully rendered invalid furniture; numeric changes and real drag may recover it.
 page.select_option('#kind','reading');page.click('#add');q=state('pending');assert q and q['kind']=='reading' and state('draft')==before and page.locator('#apply').is_disabled()
 page.click('#view2d');assert state('pending')==q;page.click('#view3d');assert state('pending')==q;page.fill('#w','');page.click('#set');assert state('pending')==q and 'finite dimensions' in page.locator('#status').inner_text()
 page.fill('#x','420');page.fill('#y','310');page.click('#set');assert page.locator('#place').is_disabled() and 'overlaps' in page.locator('#status').inner_text();page.click('#close');cap('B8s14r1-invalid-creation')
 # Move candidate to empty area, explicit placement stages it; no hidden mutation.
 drag(f'[data-move="{q["id"]}"]',780,520);assert not page.locator('#place').is_disabled(),page.locator('#status').inner_text();cap('B8s14r1-valid-creation');page.click('#place');assert state('pending') is None and len(state('draft')['shelves'])==9 and state()==original
 # Every type can be created, explicitly placed, removed, then cancel exact state.
 page.click('#geometry');geo(q['id']);page.click('#remove');assert len(state('draft')['shelves'])==8
 for k in state('catalogue'):
  page.select_option('#kind',k);page.click('#add');new=state('pending');assert new['kind']==k
  page.fill('#x','1200');page.fill('#y','800');page.click('#set');assert not page.locator('#place').is_disabled(),(k,page.locator('#status').inner_text());page.click('#place');assert item(state('draft'),new['id'])['kind']==k
  page.click('#remove');assert len(state('draft')['shelves'])==8
 # Floor layer overlaps solid footprints but not other rugs; column is solid.
 page.select_option('#kind','rug');page.click('#add');page.fill('#x','400');page.fill('#y','300');page.click('#set');assert page.locator('#place').is_disabled();page.fill('#x','0');page.fill('#y','0');page.click('#set');assert not page.locator('#place').is_disabled();page.click('#place');assert len(state('draft')['shelves'])==9;page.click('#remove')
 page.select_option('#kind','column');page.click('#add');page.fill('#x','430');page.fill('#y','320');page.click('#set');assert page.locator('#place').is_disabled();page.keyboard.press('Escape');assert state('pending') is None
 expected=state('draft');cap('B8s14r1-geometry');page.click('#close');page.click('#apply');assert state()==expected;page.click('#undo');assert state()==original
 page.click('#mode');page.click('#geometry');page.select_option('#kind','couch');page.click('#add');page.click('#cancel');assert state()==original and state('pending') is None
 page.add_style_tag(content='body{--bg:#101010!important;--panel:#292929!important;--etch:#bbbbbb!important;--metal:#888888!important;--text:#eeeeee!important}');cap('B8s14r1-monochrome');page.evaluate("document.querySelectorAll('style')[1].remove()");
 for t in ['Evening','Midnight','Twilight']:page.select_option('#theme',t);cap('B8s14r1-'+t.lower())
 # Explicit orthonormal camera and projected wall directions.
 for t in range(20,31):
  page.locator('#tilt').fill(str(t));assert joints()
  assert page.evaluate("""()=>{let c=__roomStudy.camera(),e=1e-9;let r=[c.a,c.c,c.zx],s=[c.b,c.d,c.zy];let dot=(a,b)=>a.reduce((v,x,i)=>v+x*b[i],0);if(Math.abs(dot(r,r)-1)>e||Math.abs(dot(s,s)-1)>e||Math.abs(dot(r,s))>e||Math.abs(c.zx)>e)return false;let m=document.getElementById('floorProjection').getCTM();let n=q=>Array.from(document.querySelector('[data-wall-face="'+q+'" ]').points,p=>new DOMPoint(p.x,p.y).matrixTransform(m));let N=n('north-inner'),E=n('east-inner'),W=n('west-outer'),S=n('south-left-outer');let diff=(a,b)=>[a.x-b.x,a.y-b.y];let cross=(a,b)=>(a[0]*b[1]-a[1]*b[0])/(Math.hypot(...a)*Math.hypot(...b));return Math.abs(cross(diff(N[2],N[1]),diff(W[2],W[1])))<1e-5&&Math.abs(cross(diff(E[2],E[1]),diff(S[2],S[1])))<1e-5&&Math.abs(cross(diff(N[1],N[0]),diff(S[1],S[0])))<1e-5&&Math.abs(cross(diff(E[1],E[0]),diff(W[1],W[0])))<1e-5;}"""),t
 page.locator('#tilt').fill('22')
 page.click('#appearance');assert state('appearanceDraft')==original
 for k in ['slabs','bond','diagonal','octagon','hex','herringbone','basket','ashlar']:
  page.select_option('#floorMaterial',k);assert page.locator('[data-floor-material="'+k+'"]').count()==1
  coverage=page.evaluate("""()=>{let {w,h,tiles}=__roomStudy.stonePattern();let inside=(x,y,p)=>{let n=0;for(let i=0,j=p.length-1;i<p.length;j=i++){let [a,b]=p[i],[c,d]=p[j];if((b>y)!==(d>y)&&x<(c-a)*(y-b)/(d-b)+a)n++;}return n%2;};for(let j=0;j<37;j++)for(let i=0;i<41;i++){let x=(i+.317)*w/41,y=(j+.619)*h/37;let n=tiles.reduce((c,t)=>c+inside(x,y,t.p),0);if(n!==1)return [x,y,n];}return true;}""")
  assert coverage is True,(k,coverage);page.click('#appearanceClose');cap('B8s14r1-floor-'+k);page.click('#appearance')
 page.select_option('#floorMaterial','plain');assert page.locator('#roomSurface').count()==0
 page.select_option('#floorMaterial','herringbone');page.select_option('#roomFamily','water');page.select_option('#roomPalette','Evening');page.locator('#detail').fill('75');page.fill('#roomName','The Reading Hall');page.locator('#roomName').press('Tab')
 assert page.locator('#roomTitle').text_content()=='The Reading Hall';assert page.locator('[data-kind="shelf"][data-furniture-palette="Twilight"]').count()==3
 assert page.locator('[data-kind] [data-family-mark]').count()==0;assert page.locator('#styleTarget').count()==0
 for k in ['plain','panel','masonry','rubble','pilaster','arcade','wainscot','ribbed']:
  page.select_option('#wallMaterial',k);assert page.locator('[data-wall-material="'+k+'"]').count()==2;page.click('#appearanceClose');cap('B8s14r1-wall-'+k);page.click('#appearance')
 page.locator('summary').click();page.fill('#floorScale','70');page.locator('#floorScale').press('Tab');page.select_option('#floorAngle','45');page.locator('#grout').fill('2.5');page.locator('#variation').fill('65');page.select_option('#borderStyle','diamond');page.fill('#wallScale','110');page.locator('#wallScale').press('Tab');page.select_option('#wallMaterial','arcade')
 a=state('appearanceDraft')['appearance'];assert a['scale']==70 and a['angle']==45 and a['grout']==2.5 and a['variation']==65 and a['wallScale']==110
 style=state('appearanceDraft');assert style['shelves']==original['shelves'];page.click('#appearanceClose');assert state('appearanceDraft')==style and state()==original
 page.click('#mode');assert state('draft') is None;page.click('#view2d');assert state('appearanceDraft')==style and page.locator('[data-wall-decoration]').count()==0;cap('B8s14r1-custom-plan');page.click('#view3d');assert state('appearanceDraft')==style;cap('B8s14r1-custom-elevated');page.click('#appearance');cap('B8s14r1-appearance');page.click('#appearanceCancel');assert state()==original and state('appearanceDraft') is None
 page.click('#appearance');page.select_option('#roomFamily','earth');page.select_option('#floorMaterial','octagon');page.click('#appearanceApply');applied=state();assert applied['appearance']['family']=='earth' and applied['shelves']==original['shelves'];page.click('#undo');assert state()==original
 page.set_viewport_size({'width':500,'height':780});page.click('#mode');page.click('#geometry');assert page.evaluate('document.documentElement.scrollWidth<=innerWidth');cap('B8s14r1-narrow')
 assert not errors,errors;assert not requests,requests;print('PASS S14r1: room-local appearance, stone coverage, camera axes and transactions, both projections, mixed plan, real move/resize/turn, all types, invalid and valid creation, floor-layer collision, exact geometry, room growth/shrink, grid independence, transaction rollback, all palettes, narrow viewport');b.close()
