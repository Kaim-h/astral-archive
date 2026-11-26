"""S18 focused contextual appearance regression; not full inherited physics testing."""
import argparse,hashlib,re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parent
base=args.baseline or root/'Astral_Archive_Shelf_Study_B8s11r1.html'
a=base.read_bytes();assert hashlib.sha1(b'blob '+str(len(a)).encode()+b'\0'+a).hexdigest()=='59e8278ad6247eda2c08bd013271e55c7abfd411';a=a.decode()
b=(root/'Astral_Archive_Shelf_Study_B8s18.html').read_text()
for name in ['ASSETS','FACES']:
    pat=r'^const '+name+r'=.*$';assert re.search(pat,a,re.M).group()==re.search(pat,b,re.M).group(),name
assert a[a.index('const CATALOGUE='):a.index('const selectedEmblems=')]==b[b.index('const CATALOGUE='):b.index('CATALOGUE.none=')]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);q=browser.new_page(viewport={'width':1440,'height':900},offline=True);errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(b)
    def state():return q.evaluate('__s18.state()')
    def capture(n):
        if args.captures:args.captures.mkdir(parents=True,exist_ok=True);q.screenshot(path=args.captures/(n+'.png'))
    def menu(name):q.locator('#mainMenu').click();q.get_by_role('menuitem',name=name,exact=True).click()
    def tab(name):q.get_by_role('tab',name=name,exact=True).click()
    def apply():q.locator('#appApply').click()
    def cancel():q.locator('#appCancel').click()
    def context(theme=None,family=None):
        q.locator('#studyEnvironment').click()
        if theme:q.locator('#desktopTheme').select_option(theme)
        if family:q.locator('#parentFamily').select_option(family)
        q.locator('#paneClose').click()
    original=q.evaluate('__s18.geometry()');assert q.evaluate('Object.values(CATALOGUE).slice(0,-1).flat().length')==76
    capture('shelf');assert q.locator('#scene [fill="url(#stone)"],#scene [fill="url(#recess)"]').count()==0
    for t in ['Evening','Midnight','Twilight']:
        context(theme=t);assert state()['appearance']['theme']==t
    context(family='botanical');assert state()['appearance']['family']=='botanical'
    menu('Primary emblem…');assert q.locator('#familyPolicy').input_value()=='inherit';capture('emblem');q.locator('#familyPolicy').select_option('bestiary');assert q.locator('#emblemGrid button').count()==12;apply()
    context(family='water');assert state()['appearance']['family']=='bestiary'
    menu('Primary emblem…');q.locator('#familyPolicy').select_option('none');assert q.locator('#scene [data-backing]').count()==0;cancel();assert state()['appearance']['family']=='bestiary'
    menu('Primary emblem…');q.locator('#familyPolicy').select_option('inherit');apply();assert state()['appearance']['family']=='water'
    menu('Backing appearance…');assert state()['tab']=='backing';q.locator('#liveCenter').select_option('axis');q.keyboard.press('Escape');assert state()['appearanceDirty'];q.locator('#scene [data-cubby="manuscripts"]').click();assert state()['appearanceDirty'];q.locator('#resumePending').click();assert q.locator('#liveCenter').input_value()=='axis';cancel();assert state()['appearance']['center']=='seal'
    menu('Backing appearance…');tab('Frame');q.locator('#palettePolicy').select_option('Evening');q.locator('#profile').select_option('pilaster');capture('frame');apply();context(theme='Midnight');assert state()['appearance']['theme']=='Evening';assert q.evaluate("document.body.style.getPropertyValue('--bg')")=='#080f10';assert q.evaluate("scene.style.getPropertyValue('--bg')")=='#343c43';menu('Undo appearance');assert state()['appearance']['theme']=='Midnight' and state()['appearance']['profile']=='crest'
    q.locator('#scene [data-cubby="manuscripts"]').click(button='right');q.get_by_role('menuitem',name='Glazing appearance…').click();q.locator('#localGlazing').select_option('subtle');capture('glazing');apply();assert state()['appearance']['localVeils']=={'manuscripts':'subtle'}
    menu('Shelf glazing defaults…');q.locator('#liveVeil').select_option('moderate');apply();assert state()['appearance']['localVeils']=={'manuscripts':'subtle'};assert q.locator('#scene [data-cubby="manuscripts"] [data-veil-style="subtle"]').count()>0;assert q.locator('#scene [data-cubby="notes"] [data-veil-style="moderate"]').count()>0
    q.locator('#scene [data-cubby="manuscripts"]').click(button='right');q.get_by_role('menuitem',name='Glazing appearance…').click();q.locator('#localGlazing').select_option('inherit');apply();assert state()['appearance']['localVeils']=={}
    menu('Backing appearance…');tab('Advanced');assert q.get_by_text('Edit independent fields…').count()==1;assert q.get_by_text('View undiscovered options').is_visible()==False;cancel()
    q.locator('#scene').focus();q.keyboard.press('Shift+F10');assert q.locator('#contextMenu').is_visible();q.keyboard.press('Escape')
    q.set_viewport_size({'width':500,'height':750});menu('Primary emblem…');assert q.locator('#pane').is_visible();capture('narrow');cancel()
    assert q.evaluate('__s18.geometry()')==original;assert not errors,errors;assert not requests,requests
    print('PASS: exact asset and emblem sources, 3 themes, family inheritance/override/None, local palette, frame/backing context, dismissal/resume, Apply/Cancel/Undo, per-Cubby glazing, keyboard, narrow and unchanged model; offline')
    browser.close()
