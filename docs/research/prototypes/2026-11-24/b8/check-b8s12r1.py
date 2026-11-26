from pathlib import Path
from playwright.sync_api import sync_playwright
import argparse

ap=argparse.ArgumentParser()
ap.add_argument('--chromium',default='/usr/bin/chromium')
ap.add_argument('--captures',type=Path)
args=ap.parse_args()
source=Path(__file__).with_name('Astral_Archive_Room_Study_B8s12r1.html').read_text()
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=args.chromium,args=['--no-sandbox'])
    page=b.new_page(viewport={'width':1366,'height':900},offline=True)
    errors=[]; requests=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None)
    page.set_content(source)
    def snap():return page.evaluate('window.__roomStudy.snapshot()')
    def draft():return page.evaluate('window.__roomStudy.draft()')
    def shelf(m,i):return next(s for s in m['shelves'] if s['id']==i)
    def cap(name):
        if args.captures:
            args.captures.mkdir(parents=True,exist_ok=True)
            page.screenshot(path=str(args.captures/(name+'.png')))
    def move(sel,dx,dy,inspect=None):
        box=page.locator(sel).bounding_box();x=box['x']+box['width']/2;y=box['y']+box['height']/2
        scale=page.evaluate("document.getElementById('scene').getScreenCTM().a")
        page.mouse.move(x,y);page.mouse.down();page.mouse.move(x+dx*scale,y+dy*scale,steps=6)
        if inspect:inspect()
        page.mouse.up()
    original=snap();assert page.evaluate('window.__roomStudy.validate(window.__roomStudy.snapshot())')==''
    assert page.locator('[data-resize]').count()==0
    page.locator('[data-move="1"]').click();assert snap()==original and draft() is None
    cap('B8s12r1-plan')
    page.click('#mode');assert draft()==original
    cap('B8s12r1-arrange')
    move('[data-move="1"]',20,20);assert shelf(draft(),1)['x']==80 and shelf(draft(),1)['y']==74
    assert snap()==original
    move('[data-resize="1"]',20,20);assert shelf(draft(),1)['w']==280 and shelf(draft(),1)['d']==112
    # Rotation about center, preserving local dimensions.
    prev=shelf(draft(),6);page.locator('[data-turn="6"]').click();s=shelf(draft(),6)
    assert s['a']==270 and (s['w'],s['d'])==(prev['w'],prev['d'])
    assert s['x']==prev['x']+(prev['w']-prev['d'])/2
    # Reproduce original defect at every initial wall-adjacent footprint.
    # Each test starts from identical saved geometry, and leaves other objects unchanged.
    page.click('#cancel')
    for i in range(1,7):
        page.click('#mode');before=draft();q=shelf(before,i)
        page.locator(f'[data-turn="{i}"]').click();v=shelf(draft(),i)
        assert v['a']==(q['a']+90)%360,(i,page.locator('#status').inner_text())
        assert (v['w'],v['d'])==(q['w'],q['d'])
        assert [x for x in draft()['shelves'] if x['id']!=i]==[x for x in before['shelves'] if x['id']!=i]
        assert page.evaluate('window.__roomStudy.validate(window.__roomStudy.draft())')==''
        if i==1:
            assert v['y']==0 and 'shifted inward' in page.locator('#status').inner_text()
            cap('B8s12r1-wall-turn')
        page.click('#cancel');assert snap()==original
    # Actual angular drag (counter-clockwise quarter-turn), stable centre.
    page.click('#mode');q=shelf(draft(),6);handle=page.locator('[data-turn="6"]').bounding_box()
    x=handle['x']+handle['width']/2;y=handle['y']+handle['height']/2
    centre=page.locator('[data-move="6"]').bounding_box();cx=centre['x']+centre['width']/2;cy=centre['y']+centre['height']/2
    dx=x-cx;dy=y-cy
    page.mouse.move(x,y);page.mouse.down();page.mouse.move(cx+dy,cy-dx,steps=12);page.mouse.up()
    assert shelf(draft(),6)['a']==90 and shelf(draft(),6)['x']==q['x']+(q['w']-q['d'])/2
    page.click('#cancel')
    # Inspector and keyboard use the same wall-aware rotation rule.
    page.click('#mode');page.click('#geometry');page.select_option('#target','1');page.select_option('#angle','90');page.click('#set')
    assert shelf(draft(),1)['a']==90 and shelf(draft(),1)['y']==0
    page.click('#close');page.click('#cancel');page.click('#mode');page.locator('[data-turn="1"]').focus();page.keyboard.press('Enter');assert shelf(draft(),1)['a']==90
    page.click('#cancel')
    # An overlapping turn cannot commit (place first shelf close to its neighbour).
    page.click('#mode');page.click('#geometry');page.select_option('#target','1');page.fill('#x','20');page.fill('#y','160');page.click('#set');page.click('#close')
    # Start from a valid horizontal footprint; its centred turn intersects observations.
    before=draft();assert shelf(before,1)['x']==20 and shelf(before,1)['y']==160
    page.locator('[data-turn="1"]').click();assert draft()==before and 'overlaps' in page.locator('#status').inner_text()
    # The explicitly selected centre rotation must not rearrange any other objects.
    assert [x for x in draft()['shelves'] if x['id']!=1]==[x for x in before['shelves'] if x['id']!=1]
    page.click('#cancel');page.click('#mode')
    move('[data-move="1"]',20,20);move('[data-resize="1"]',20,20);page.locator('[data-turn="6"]').click()
    # Invalid overlapping drag must retain draft and show error before release.
    before=draft()
    def invalid():
        assert 'overlaps' in page.locator('#status').inner_text()
        assert page.locator('#apply').is_disabled()
        cap('B8s12r1-invalid')
    move('[data-move="1"]',300,0,invalid);assert draft()==before
    # Rotated footprints resize in local coordinates.
    move('[data-resize="4"]',20,20);s=shelf(draft(),4);assert s['w']==250 and s['d']==114
    # Room drag growth preserves every footprint and changes only envelope.
    before=draft();move('[data-room]',40,20);assert draft()['w']==1040 and draft()['d']==700 and draft()['shelves']==before['shelves']
    page.click('#geometry');page.select_option('#target','1');page.fill('#w','242');page.click('#set');assert shelf(draft(),1)['w']==242
    page.fill('#w','240');page.click('#set');assert shelf(draft(),1)['w']==240
    before=draft();page.fill('#roomW','700');page.click('#roomSet');assert draft()==before and 'wall' in page.locator('#status').inner_text()
    page.fill('#roomW','1103');page.fill('#roomD','723');page.click('#roomSet');assert draft()['w']==1103 and draft()['d']==723 and draft()['shelves']==before['shelves']
    before=draft();page.fill('#interval','13');page.locator('#interval').press('Tab');assert draft()==before
    page.uncheck('#grid');assert page.locator('rect[fill="url(#planGrid)"]').count()==0 and page.locator('#snap').is_checked()
    page.check('#grid');page.uncheck('#snap');assert page.locator('rect[fill="url(#planGrid)"]').count()==1
    page.check('#snap');page.click('#align');assert shelf(draft(),1)['x']%13==0 and shelf(draft(),1)['y']%13==0
    page.click('#add');assert len(draft()['shelves'])==7;page.click('#remove');assert len(draft()['shelves'])==6
    cap('B8s12r1-geometry');page.click('#close');assert draft() is not None and snap()==original
    page.click('#mode');assert draft() is not None
    expected=draft();page.click('#apply');assert snap()==expected and draft() is None
    cap('B8s12r1-applied');page.click('#undo');assert snap()==original
    page.click('#mode');move('[data-move="1"]',26,0);assert draft()!=original;page.click('#cancel');assert snap()==original
    for theme in ['Evening','Midnight','Twilight']:page.select_option('#theme',theme)
    page.set_viewport_size({'width':500,'height':780});page.click('#mode');page.click('#geometry');cap('B8s12r1-narrow');assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
    assert not errors,errors
    assert not requests,requests
    print('PASS S12r1: actual pointer move/resize/rotate, rejection, room growth, exact numeric geometry, independent grid/snap, add/remove, Apply/Cancel/Undo, palettes and narrow viewport')
    b.close()
