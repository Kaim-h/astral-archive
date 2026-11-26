"""Focused S17 appearance workshop regression (offline Chromium)."""
import argparse
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);args=p.parse_args()
html=Path(__file__).with_name('Astral_Archive_Appearance_Workshop_B8s17.html').read_text()
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1440,'height':900},offline=True);q=ctx.new_page();errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(html)
    def capture(n):
        if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
    def state():return q.evaluate('__appearanceStudy.state()')
    def resolved(k):return q.evaluate('k=>__appearanceStudy.resolved(k)',k)
    def op(k):q.locator(f'[data-open="{k}"]').click();assert q.locator('#context').is_visible()
    def setv(k,v):q.locator('#f-'+k).select_option(v)
    def finish(apply=True):q.locator('#apply' if apply else '#cancel').click();assert not q.locator('#context').is_visible()
    original=state()['saved'];geometry=q.evaluate('__appearanceStudy.geometry()');capture('default')
    for t in ['Twilight','Evening','Midnight']:
        q.locator('#desktop').select_option(t);assert all(resolved(k)['theme']==t for k in ['room','shelf','cubby']);capture(t)
    q.locator('#desktop').select_option('Twilight');q.locator('[data-space="room"]').click(button='right',position={'x':10,'y':10});assert q.locator('#context').is_visible();setv('family','botanical');assert all(resolved(k)['resolvedFamily']=='botanical' for k in ['room','shelf','cubby']);assert state()['saved']==original;capture('context');finish();capture('botanical')
    op('shelf');setv('family','plain');setv('palette','Evening');setv('profile','pilaster');finish();assert resolved('cubby')['resolvedFamily']=='plain';assert resolved('cubby')['theme']=='Twilight';assert resolved('shelf')['theme']=='Evening';capture('override')
    op('cubby');setv('family','none');finish();assert resolved('cubby')['resolvedFamily']=='none';assert q.locator('#cubby [data-family-mark]').count()==0
    op('room');setv('family','fire');finish();assert resolved('shelf')['resolvedFamily']=='plain' and resolved('cubby')['resolvedFamily']=='none'
    op('shelf');setv('family','inherit');finish();assert resolved('shelf')['resolvedFamily']=='fire' and resolved('cubby')['resolvedFamily']=='none'
    op('cubby');setv('family','inherit');finish();assert resolved('cubby')['resolvedFamily']=='fire'
    before=state()['saved'];op('room');setv('palette','Midnight');assert resolved('shelf')['theme']=='Evening' and resolved('cubby')['theme']=='Twilight';q.keyboard.press('Escape');assert not q.locator('#context').is_visible() and state()['draft'];q.locator('[data-open="shelf"]').click();assert not q.locator('#context').is_visible() and state()['draft']['key']=='room';q.locator('#reopen').click();assert q.locator('#f-palette').input_value()=='Midnight';finish(False);assert state()['saved']==before and not state()['draft']
    q.locator('[data-space="shelf"]').focus();q.keyboard.press('Shift+F10');assert q.locator('#context').is_visible();q.locator('#advanced summary').click();q.locator('#f-detail').fill('25');assert resolved('shelf')['detail']==25;finish();q.locator('#undo').click();assert state()['saved']==before
    op('room');floors=q.locator('#f-floor option').evaluate_all('(a)=>a.map(o=>o.value)');walls=q.locator('#f-wall option').evaluate_all('(a)=>a.map(o=>o.value)');assert len(floors)==9 and len(walls)==8
    for f in floors:setv('floor',f);assert resolved('room')['floor']==f
    for w in walls:setv('wall',w);assert q.locator(f'#room [data-wall-material="{w}"]').count()==1
    finish(False)
    op('shelf');seen=set()
    for pr in ['crest','cornice','pilaster']:
        setv('profile',pr);seen.add(q.locator('#shelf').inner_html())
    assert len(seen)==3;finish(False)
    op('room');setv('family','water');q.locator('#veil').click(position={'x':2,'y':2});assert not q.locator('#context').is_visible() and state()['draft'];q.locator('#discard').click();assert state()['saved']==before
    q.locator('#reset').click();assert state()['saved']==original
    q.set_viewport_size({'width':480,'height':750});q.locator('[data-open="cubby"]').click(button='right');assert q.locator('#context').is_visible();r=q.locator('#context').bounding_box();assert r['x']>=0 and r['x']+r['width']<=481 and r['y']>=0 and r['y']+r['height']<=751;finish(False);assert q.evaluate('__appearanceStudy.geometry()')==geometry
    assert not errors,errors;assert not requests,requests
    print('PASS: 3 themes, recursive live inheritance and overrides, explicit None, independent palette, contextual controls, draft blocking/resume/cancel, Undo/reset, 9 floors, 8 walls, 3 profiles, narrow viewport, fixed geometry, offline/no errors')
    browser.close()
