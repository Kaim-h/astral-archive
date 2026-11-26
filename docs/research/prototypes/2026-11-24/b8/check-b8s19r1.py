"""Focused Map Room r1 direct manipulation checks (offline Chromium)."""
import argparse, hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
base=args.baseline or (root/'Astral_Archive_Map_Room_Study_B8s19.html' if (root/'Astral_Archive_Map_Room_Study_B8s19.html').exists() else root.parent/'s19-release'/'Astral_Archive_Map_Room_Study_B8s19.html')
a=base.read_bytes();assert hashlib.sha1(b'blob '+str(len(a)).encode()+b'\0'+a).hexdigest()=='718ea4d43c2bd7611dc32c8f75e2ac7e6aeadc66';a=a.decode();b=(root/'Astral_Archive_Map_Room_Study_B8s19r1.html').read_text()
for start,end in [('const themes=','let saved='),('const terrain=','function doorArt('),('function footprint(','function status(')]:
    aa=a[a.index(start):a.index(end)];bb=b[b.index(start):b.index(end)];assert bb.startswith(aa.rstrip().removesuffix('let saved=')) or (start=='const themes=' and bb.startswith(aa)),start
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True,reduced_motion='reduce');q.set_default_timeout(3000);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b);q.wait_for_timeout(150)
    def state():return q.evaluate('__mapStudy.state()')
    def model():return q.evaluate('__mapStudy.model()')
    def room(id):return next(r for r in model()['rooms'] if r['id']==id)
    def door(id):return next(d for d in model()['doors'] if d['id']==id)
    def xy(x,y):return q.evaluate('([x,y])=>{let p=new DOMPoint(x,y).matrixTransform(document.getElementById("map").getScreenCTM());return [p.x,p.y]}',[x,y])
    def hit(x,y,button='left'):q.mouse.click(*xy(x,y),button=button)
    def drag(x,y,dx,dy):
        a=xy(x,y);b=xy(x+dx,y+dy);q.mouse.move(*a);q.mouse.down();q.mouse.move(*b,steps=6);q.mouse.up()
    def cap(n):
        if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
    def valid():assert q.evaluate('__mapStudy.valid(__mapStudy.model())')=='',q.evaluate('__mapStudy.valid(__mapStudy.model())')
    def menu(n):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=n,exact=True).click()
    def focus(id):
        r=room(id);hit(r['x']+r['w']/2,r['y']+r['h']/2);assert state()['selected']['id']==id
    def restore():q.locator('#focusBack').click()
    original=state()['saved'];overview=state()['view'];valid();cap('overview')
    for t in ['Evening','Midnight','Twilight']:
        q.locator('#theme').select_option(t);assert state()['saved']==original
    q.locator('#mode').click();focus('hall');assert state()['view']['w']<overview['w'] and q.locator('[data-resize="hall"]').count()==8;cap('room-focus');restore();assert state()['view']==overview
    # Focus selected doorway and both ends remain individually manipulable.
    hit(1200,650);assert state()['selected']['id']=='door-2';assert q.locator('[data-door="door-2"][data-handle]').count()==3;cap('door-focus')
    camera=state()['view'];drag(1200,650,0,20);assert door('door-2')['at']==670 and state()['view']==camera;valid()
    drag(1200,720,0,20);assert door('door-2')['w']==120 and door('door-2')['at']==680;valid()
    assert q.evaluate('__mapStudy.openings("hall").find(d=>d.id==="door-2")')==q.evaluate('__mapStudy.openings("records").find(d=>d.id==="door-2")');restore();assert state()['view']==overview
    # Obstructed target automatically lands at nearest legal opening.
    hit(1200,390);drag(1200,390,0,-100);valid();assert door('door-1')['at']!=290;restore()
    # Move a connected room away: preview, explicit restore and accept; no content mutation.
    drag(600,410,-120,0);assert state()['pending'] and len(model()['doors'])==0;cap('separation');q.locator('#mode').click();assert state()['draft'] is not None;q.locator('#restoreMove').click();assert room('hall')['x']==0 and len(model()['doors'])==2
    drag(600,410,-120,0);q.locator('#keepMove').click();assert room('hall')['x']==-120 and len(model()['doors'])==0;valid();q.locator('#mode').click();menu('Undo');assert state()['saved']==original
    # Slide on a shared wall and automatically retain a clear connection.
    q.locator('#mode').click();drag(1600,220,0,-120);valid();assert room('manuscripts')['y']==-120 and door('door-1')['at']<=280;assert not state()['pending'];assert room('manuscripts')['shelves']==original['rooms'][1]['shelves']
    menu('Undo');assert model()==original
    # Magnetic alignment with off-grid separation, no automatic new connection.
    # Collections slides upward until it touches Main Hall's lower wall.
    drag(660,1270,0,-220);r=room('collections');assert r['y']==820,r;assert len(model()['doors'])==2;valid();focus('collections');assert q.locator('[data-suggest="hall"]').count()==1;cap('suggestion');q.locator('[data-suggest="hall"]').click();assert len(model()['doors'])==3;valid();assert q.locator('[data-suggest="hall"]').count()==1;q.locator('[data-suggest="hall"]').click();assert len(model()['doors'])==4;valid();restore()
    # Click empty map restores focus, no zoom mutation to geometry.
    focus('records');hit(1400,920);assert state()['selected'] is None and state()['view']==overview
    q.locator('#mode').click();assert state()['draft'] is None;menu('Undo');assert state()['saved']==original
    # Numeric precision remains exact; invalid overlap does not apply.
    q.locator('#mode').click();hit(660,1270,'right');q.get_by_role('menuitem',name='Dimensions…',exact=True).click();q.locator('#r-y').fill('300');q.locator('#close').click();assert q.locator('#pane').is_visible();q.keyboard.press('Escape');assert model()==original
    # Room edge resize from focused selection and immutable local contents.
    focus('collections');r=room('collections');drag(r['x']+r['w'],r['y']+r['h']/2,40,0);assert room('collections')['w']==860 and room('collections')['shelves']==r['shelves'];valid();restore();q.locator('#mode').click();menu('Undo');assert state()['saved']==original
    # Direct creation places a clear, selected Room without coordinate entry.
    menu('Add Room…');assert len(model()['rooms'])==5 and state()['selected']['id']=='room-5';valid();assert q.locator('#pane').is_hidden();restore();q.locator('#mode').click();menu('Undo');assert state()['saved']==original
    # Animated camera path and focus restoration in ordinary motion context.
    z=browser.new_page(viewport={'width':1000,'height':700},offline=True);z.set_content(b);z.wait_for_timeout(150);z.locator('#mode').click();old=z.evaluate('__mapStudy.state().view');z.locator('[data-room="hall"]').click();z.wait_for_function('!__mapStudy.state().flight');assert z.evaluate('__mapStudy.state().view.w')<old['w'];z.locator('#focusBack').click();z.wait_for_function('!__mapStudy.state().flight');assert z.evaluate('__mapStudy.state().view')==old
    q.set_viewport_size({'width':500,'height':750});q.locator('#fit').click();q.locator('#mode').click();focus('hall');cap('narrow');valid();assert not errors,errors;assert not requests,requests
    print('PASS: exact inherited artwork and validator; three themes; selection focus/restore, 8 room handles, 3 door handles, frozen drag camera, both openings, nearest clear doorway, separation preview/restore/accept/Undo, slide reconciliation, magnetic wall, multiple suggestions, precise numeric validation, edge resize, direct creation, animated and reduced-motion focus, narrow offline')
    browser.close()
