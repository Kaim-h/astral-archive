"""Focused S19 Map Room visual/connection contract checks in offline Chromium."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
html=(root/'Astral_Archive_Map_Room_Study_B8s19.html').read_text()
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True);q.set_default_timeout(3000)
    errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(html);q.wait_for_timeout(150)
    def state():return q.evaluate('__mapStudy.state()')
    def model():return q.evaluate('__mapStudy.model()')
    def cap(name):
        if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(name+'.png'))
    def xy(x,y):return q.evaluate('([x,y])=>{let p=new DOMPoint(x,y).matrixTransform(document.getElementById("map").getScreenCTM());return [p.x,p.y]}',[x,y])
    def hit(x,y,button='left'):q.mouse.click(*xy(x,y),button=button)
    def drag(x,y,dx,dy):
        a=xy(x,y);b=xy(x+dx,y+dy);q.mouse.move(*a);q.mouse.down();q.mouse.move(*b,steps=5);q.mouse.up()
    def choose(name):q.get_by_role('menuitem',name=name,exact=True).click()
    def rootmenu(name):q.locator('#mainMenu').click();assert q.locator('#menu button').count()==5;choose(name)
    def rightroom(id,name):
        r=next(r for r in model()['rooms'] if r['id']==id);hit(r['x']+r['w']/2,r['y']+r['h']/2,'right');choose(name)
    def rightdoor(id,name):
        m=model();d=next(d for d in m['doors'] if d['id']==id);c=q.evaluate('d=>__mapStudy.common(__mapStudy.model().rooms.find(r=>r.id===d.a),__mapStudy.model().rooms.find(r=>r.id===d.b))',d);hit(c['line'] if c['axis']=='v' else d['at'],d['at'] if c['axis']=='v' else c['line'],'right');choose(name)
    def valid():assert q.evaluate('__mapStudy.valid(__mapStudy.model())')==''
    valid();original=state()['saved'];assert q.locator('[data-room]').count()==4 and q.locator('[data-room-plan]').count()==0;cap('overview')
    for t in ['Evening','Midnight','Twilight']:
        q.locator('#theme').select_option(t);assert state()['saved']==original;cap(t.lower())
    q.locator('#plus').click();assert q.locator('[data-room-plan]').count()==4 and q.locator('[data-plan-symbol="H"]').count()==8;cap('zoom');q.locator('#fit').click();assert not q.locator('[data-room-plan]').count()
    q.locator('#detail').select_option('plan');assert q.locator('[data-plan-symbol="H"]').count()==8;cap('plan');q.locator('#detail').select_option('auto');assert state()['saved']==original
    # Room reference shares the same doorway records, returns to exact view.
    before=state()['view'];hit(600,410);assert state()['inside']=='hall';assert q.locator('[data-room]').count()==1 and q.locator('[data-door]').count()==2;cap('room');q.locator('#roomBack').click();assert state()['view']==before
    # Appearance live preview then commit; explicit Escape reverts.
    rootmenu('Appearance…');q.locator('#contours').select_option('engraved');q.locator('#density').fill('80');assert model()['appearance']['density']==80 and state()['saved']==original;q.locator('#close').click();assert state()['saved']['appearance']['contours']=='engraved';cap('engraved');rootmenu('Undo');assert state()['saved']==original
    rightroom('hall','Appearance…');q.locator('#r-sub').fill('Test subtitle');q.locator('#r-pal').select_option('Evening');assert model()['rooms'][0]['subtitle']=='Test subtitle';q.keyboard.press('Escape');assert state()['saved']==original and model()==original
    # Pan background and fit do not change the geometry.
    a=state()['view'];drag(150,950,100,80);assert state()['view']!=a and state()['saved']==original;q.locator('#fit').click()
    q.locator('#mode').click();assert state()['draft'] is not None;cap('arrange')
    # Shared doorway pointer movement and numeric width. Both opening records identical.
    drag(1200,650,0,20);assert next(d for d in model()['doors'] if d['id']=='door-2')['at']==670;valid()
    rightdoor('door-2','Position and width…');q.locator('#d-at').fill('690');q.locator('#d-w').fill('120');q.locator('#close').click();assert q.locator('#pane').is_hidden();valid()
    a=q.evaluate('__mapStudy.openings("hall").find(d=>d.id==="door-2")');b=q.evaluate('__mapStudy.openings("records").find(d=>d.id==="door-2")');assert a==b and a['at']==690 and a['w']==120
    # Both outline paths have an opening at the same coordinates.
    for id in ['hall','records']:
        path=q.evaluate('id=>{let m=__mapStudy.model();return __mapStudy.wallPath(m,m.rooms.find(r=>r.id===id))}',id);assert 'V630' in path and 'M1200 750' in path,path
    rightdoor('door-1','Position and width…');q.locator('#d-at').fill('300');q.locator('#mode').click();assert state()['draft'] is not None and q.locator('#pane').is_visible() and 'clearance' in q.locator('#status').inner_text();q.keyboard.press('Escape')
    # Multiple doors along the same horizontal wall, no overlapping doors.
    for at in [1480,1760]:
        rightroom('manuscripts','Connect doorway…');q.locator('#d-neighbor').select_option('records');q.locator('#d-at').fill(str(at));q.locator('#close').click();assert q.locator('#pane').is_hidden();valid()
    assert len(model()['doors'])==4;cap('doors')
    rightdoor('door-4','Position and width…');q.locator('#d-at').fill('1480');q.locator('#close').click();assert q.locator('#pane').is_visible() and 'overlap' in q.locator('#status').inner_text();q.keyboard.press('Escape')
    # Reject movement severing a connection and room overlap, preserve last valid state.
    rightroom('hall','Dimensions…');q.locator('#r-x').fill('-100');q.locator('#close').click();assert q.locator('#pane').is_visible() and 'shared wall' in q.locator('#status').inner_text();q.keyboard.press('Escape')
    rightroom('collections','Dimensions…');q.locator('#r-y').fill('300');q.locator('#close').click();assert q.locator('#pane').is_visible() and 'overlap' in q.locator('#status').inner_text();q.keyboard.press('Escape')
    # Actual room drag and resize with no change to local Shelf coordinates.
    shelves=next(r for r in model()['rooms'] if r['id']=='collections')['shelves'];drag(660,1270,40,0);r=next(r for r in model()['rooms'] if r['id']=='collections');assert r['x']==290 and r['shelves']==shelves
    drag(r['x']+r['w'],r['y']+r['h'],40,20);r=next(r for r in model()['rooms'] if r['id']=='collections');assert r['w']==860 and r['h']==440 and r['shelves']==shelves;valid()
    # Explicit disconnect from both rooms; commit and undo whole session.
    rightdoor('door-4','Disconnect…');q.get_by_role('button',name='Disconnect',exact=True).click();assert len(model()['doors'])==3;valid();q.locator('#mode').click();assert state()['draft'] is None and len(state()['saved']['doors'])==3
    rootmenu('Undo');assert state()['saved']==original
    # Create and remove an empty independent Room, and grid/snap independence.
    rootmenu('Grid and snapping…');q.locator('#g-visible').uncheck();q.locator('#g-step').fill('25');q.locator('#close').click();assert not state()['grid'] and state()['snap'] and state()['interval']==25
    rootmenu('Add Room…');q.locator('#new-x').fill('2300');q.locator('#new-y').fill('1000');q.locator('#new-name').fill('New study');q.locator('#close').click();valid();q.locator('#mode').click();q.locator('#fit').click();assert len(state()['saved']['rooms'])==5
    rightroom('room-5','Remove empty Room…');q.get_by_role('button',name='Remove Room',exact=True).click();q.locator('#mode').click();assert len(state()['saved']['rooms'])==4;valid()
    q.set_viewport_size({'width':500,'height':750});q.locator('#fit').click();q.locator('#mainMenu').click();rect=q.locator('#menu').bounding_box();assert rect['x']>=0 and rect['x']+rect['width']<=501 and rect['y']>=0 and rect['y']+rect['height']<=751;cap('narrow');q.keyboard.press('Escape');assert not errors,errors;assert not requests,requests
    print('PASS: 3 palettes, automatic/forced detail, H footprints, fixed Room reference and restored view, live appearance/Undo/Escape, pan/fit, actual room and door drags, resize, two aligned openings, multiple doors, clearance/overlap/disconnection rejection, explicit disconnect, create/remove, grid/snap, implicit commit and narrow offline.');browser.close()
