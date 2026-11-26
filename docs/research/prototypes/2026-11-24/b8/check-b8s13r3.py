from pathlib import Path
from playwright.sync_api import sync_playwright
import argparse
ap=argparse.ArgumentParser();ap.add_argument('--chromium',default='/usr/bin/chromium');ap.add_argument('--captures',type=Path);args=ap.parse_args()
source=Path(__file__).with_name('Astral_Archive_Room_Study_B8s13r3.html').read_text()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);page=b.new_page(viewport={'width':1366,'height':900},offline=True)
 errors=[];requests=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);page.set_content(source)
 def state(k='snapshot'):return page.evaluate(f'window.__roomStudy.{k}()')
 def item(m,i):return next(s for s in m['shelves'] if s['id']==i)
 def cap(name):
  if args.captures:args.captures.mkdir(parents=True,exist_ok=True);page.screenshot(path=str(args.captures/(name+'.png')))
 def drag(sel,dx,dy,inspect=None):
  el=page.locator(sel).bounding_box();x=el['x']+el['width']/2;y=el['y']+el['height']/2;scale=page.evaluate("document.getElementById('scene').getScreenCTM().a");page.mouse.move(x,y);page.mouse.down();page.mouse.move(x+dx*scale,y+dy*scale,steps=8)
  if inspect:inspect()
  page.mouse.up()
 def geo(i):page.select_option('#target',str(i))
 original=state();assert page.locator('[data-elevated]').count()==7;assert page.locator('[data-shelf-face="front"]').count()==3;cap('B8s13r3-elevated');page.select_option('#projection','plan');assert page.locator('[data-elevated]').count()==0 and state()==original;cap('B8s13r3-plan');page.select_option('#projection','elevated');assert state()==original;assert page.evaluate('window.__roomStudy.validate(window.__roomStudy.snapshot())')=='',page.locator('#status').inner_text()
 assert len({s['kind'] for s in original['shelves']})==6;assert page.locator('[data-turn]').count()==0
 assert page.locator('.shelfLabel').count()==0;assert page.locator('[data-kind]').count()==8;page.check('#labels');assert page.locator('.shelfLabel').count()==8;cap('B8s13r3-labels');page.uncheck('#labels');assert state()==original and page.locator('.shelfLabel').count()==0; page.locator('[data-move="6"]').click();assert state()==original and state('draft') is None
 page.click('#mode');assert state('draft')==original;page.select_option('#projection','plan');assert state('draft')==original;page.select_option('#projection','elevated');assert state('draft')==original;cap('B8s13r3-arrange');drag('[data-move="6"]',20,20);assert item(state('draft'),6)['x']==440 and item(state('draft'),6)['y']==330
 drag('[data-resize="6"]',20,20);assert (item(state('draft'),6)['w'],item(state('draft'),6)['d'])==(200,200)
 before=state('draft');page.locator('[data-turn="6"]').click();assert item(state('draft'),6)['a']==90;assert [s for s in state('draft')['shelves'] if s['id']!=6]==[s for s in before['shelves'] if s['id']!=6]
 page.click('#cancel');page.click('#mode')
 # Strict plan still supports actual move and resize, then switching preserves the draft.
 page.select_option('#projection','plan');drag('[data-move="6"]',20,20);assert item(state('draft'),6)['x']==440;drag('[data-resize="6"]',20,20);assert item(state('draft'),6)['w']==200;draft_before=state('draft');page.select_option('#projection','elevated');assert state('draft')==draft_before;page.click('#cancel');page.click('#mode')
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
 page.mouse.move(x,y);page.mouse.down();page.mouse.move(cx+dy,cy-dx,steps=12);page.mouse.up();assert item(state('draft'),6)['a']==270
 page.click('#cancel');page.click('#mode')
 # Exact geometry, independent grid, room growth and rejection.
 page.click('#geometry');geo(6);page.fill('#w','240');page.click('#set');assert item(state('draft'),6)['w']==240
 before=state('draft');page.fill('#interval','13');page.locator('#interval').press('Tab');assert state('draft')==before
 page.uncheck('#grid');assert page.locator('rect[fill="url(#planGrid)"]').count()==0 and page.locator('#snap').is_checked();page.check('#grid');page.uncheck('#snap');assert page.locator('rect[fill="url(#planGrid)"]').count()==1;page.check('#snap')
 page.fill('#roomW','1500');page.fill('#roomD','1000');page.click('#roomSet');assert state('draft')['w']==1500 and state('draft')['shelves']==before['shelves']
 before=state('draft');page.fill('#roomW','600');page.click('#roomSet');assert state('draft')==before
 # Create fully rendered invalid furniture; numeric changes and real drag may recover it.
 page.select_option('#kind','reading');page.click('#add');q=state('pending');assert q and q['kind']=='reading' and state('draft')==before and page.locator('#apply').is_disabled()
 page.select_option('#projection','plan');assert state('pending')==q;page.select_option('#projection','elevated');assert state('pending')==q;page.fill('#w','');page.click('#set');assert state('pending')==q and 'finite dimensions' in page.locator('#status').inner_text()
 page.fill('#x','420');page.fill('#y','310');page.click('#set');assert page.locator('#place').is_disabled() and 'overlaps' in page.locator('#status').inner_text();page.click('#close');cap('B8s13r3-invalid-creation')
 # Move candidate to empty area, explicit placement stages it; no hidden mutation.
 drag(f'[data-move="{q["id"]}"]',780,520);assert not page.locator('#place').is_disabled(),page.locator('#status').inner_text();cap('B8s13r3-valid-creation');page.click('#place');assert state('pending') is None and len(state('draft')['shelves'])==9 and state()==original
 # Every type can be created, explicitly placed, removed, then cancel exact state.
 page.click('#geometry');geo(q['id']);page.click('#remove');assert len(state('draft')['shelves'])==8
 for k in state('catalogue'):
  page.select_option('#kind',k);page.click('#add');new=state('pending');assert new['kind']==k
  page.fill('#x','1200');page.fill('#y','800');page.click('#set');assert not page.locator('#place').is_disabled(),(k,page.locator('#status').inner_text());page.click('#place');assert item(state('draft'),new['id'])['kind']==k
  page.click('#remove');assert len(state('draft')['shelves'])==8
 # Floor layer overlaps solid footprints but not other rugs; column is solid.
 page.select_option('#kind','rug');page.click('#add');page.fill('#x','400');page.fill('#y','300');page.click('#set');assert page.locator('#place').is_disabled();page.fill('#x','0');page.fill('#y','0');page.click('#set');assert not page.locator('#place').is_disabled();page.click('#place');assert len(state('draft')['shelves'])==9;page.click('#remove')
 page.select_option('#kind','column');page.click('#add');page.fill('#x','430');page.fill('#y','320');page.click('#set');assert page.locator('#place').is_disabled();page.keyboard.press('Escape');assert state('pending') is None
 expected=state('draft');cap('B8s13r3-geometry');page.click('#close');page.click('#apply');assert state()==expected;page.click('#undo');assert state()==original
 page.click('#mode');page.click('#geometry');page.select_option('#kind','couch');page.click('#add');page.click('#cancel');assert state()==original and state('pending') is None
 page.add_style_tag(content='body{--bg:#101010!important;--panel:#292929!important;--etch:#bbbbbb!important;--metal:#888888!important;--text:#eeeeee!important}');cap('B8s13r3-monochrome');page.evaluate("document.querySelectorAll('style')[1].remove()");
 for t in ['Evening','Midnight','Twilight']:page.select_option('#theme',t);cap('B8s13r3-'+t.lower())
 page.set_viewport_size({'width':500,'height':780});page.click('#mode');page.click('#geometry');assert page.evaluate('document.documentElement.scrollWidth<=innerWidth');cap('B8s13r3-narrow')
 assert not errors,errors;assert not requests,requests;print('PASS S13r3: both projections, mixed plan, real move/resize/turn, all types, invalid and valid creation, floor-layer collision, exact geometry, room growth/shrink, grid independence, transaction rollback, all palettes, narrow viewport');b.close()
