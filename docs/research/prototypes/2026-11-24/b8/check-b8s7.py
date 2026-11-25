"""B8s7 offline browser and visual-continuity checks; Python Playwright + Chromium."""
from pathlib import Path
import argparse, hashlib, json, re, xml.etree.ElementTree as ET
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--directory',type=Path,default=Path(__file__).resolve().parent)
parser.add_argument('--chromium',default=None)
parser.add_argument('--captures',type=Path,default=None)
parser.add_argument('--part',choices=['all','astral','cartographic','botanical','plain','interactions'],default='all')
a=parser.parse_args()
p=a.directory/'Astral_Archive_Shelf_Case_Study_B8s7.html'
html=p.read_text(encoding='utf-8');base=(a.directory/'Astral_Archive_Shelf_Case_Study_B8s6r1.html').read_text(encoding='utf-8')
assert 'B8s7 emblem catalogue' in html
for cat in ('ASSETS','FACES'):
    pattern=r'^const '+cat+r'=(.*);$'
    value=re.search(pattern,html,re.M)[1];assert value==re.search(pattern,base,re.M)[1]
    for entry in json.loads(value).values():
        b=entry['svg'].encode();assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==entry['sha']
        for element in ET.fromstring(entry['svg']).iter():
            assert element.tag.split('}')[-1] not in ('script','foreignObject')
            for key,val in element.attrib.items():
                assert not key.split('}')[-1].lower().startswith('on')
                if key.split('}')[-1] in ('href','src'):assert val.startswith('#')
layout=lambda s:s[s.index('// All furniture coordinates'):s.index('if(guides){for')]
assert layout(html)==layout(base)
assert not re.search(r'astral-archive-private|private-artifacts/|/mnt/data/|github_pat_|BEGIN PRIVATE KEY',html)
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=a.chromium)
    page=browser.new_page(viewport={'width':1366,'height':900},offline=True)
    errors=[];requests=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None)
    page.set_content(html)
    def integrity():
        problems=page.evaluate('''()=>{const all=[...document.querySelectorAll('[id]')].map(e=>e.id),bad=[];if(new Set(all).size!==all.length)bad.push('duplicate ids');for(const e of document.querySelectorAll('svg *'))for(const a of e.attributes){if(a.name==='href'&&a.value.startsWith('data:'))continue;if(/NaN|undefined|Infinity/.test(a.value))bad.push(a.name+':'+a.value);for(const m of a.value.matchAll(/url\\(#([^)]*)\\)/g))if(!document.getElementById(m[1]))bad.push('unresolved '+m[1]);}return bad;}''')
        assert not problems,problems[:5]
    def visible():
        return page.locator('#emblemScroll').evaluate('''el=>{const b=el.getBoundingClientRect();return [...el.querySelectorAll('button')].filter(c=>{const r=c.getBoundingClientRect();return Math.min(r.bottom,b.bottom)-Math.max(r.top,b.top)>r.height*.9}).map(c=>c.dataset.choice)}''')
    def turn(second):
        selector='#pickerNext' if second else '#pickerPrev'
        if not page.locator(selector).is_disabled():page.locator(selector).click()
        page.wait_for_function('expected=>document.getElementById("pickerRange").textContent===expected',arg='5–8 of 8' if second else '1–4 of 8')
    def select(id):
        page.locator(f'#emblemGrid [data-choice={id}]').click()
        assert page.locator(f'#emblemGrid [data-choice={id}]').get_attribute('aria-pressed')=='true'
        assert page.locator(f'#selectedBacking [data-emblem={id}]').count()==1
        assert page.locator(f'#selectedGlass mask [data-emblem={id}]').count()==1
        assert page.locator(f'#selectedCrest [data-emblem={id}]').count()==1
        assert page.locator(f'#scene [data-backing] [data-emblem={id}]').count()==1
        assert page.locator(f'#scene mask [data-emblem={id}]').count()==3
        integrity()
    assert not page.locator('#artisan').evaluate('e=>e.open')
    assert page.locator('#liveVeil').input_value()=='linework' and page.locator('#liveBorder').input_value()=='ornate'
    assert page.locator('#scene [data-veil-style=linework]').count()==3
    # Compare exact original satin cubby pixels, with normalized screen origin.
    ref=browser.new_page(viewport={'width':1366,'height':900},offline=True);ref.set_content(base);ref.select_option('#liveVeil','frost1');page.locator('#artisan summary').click();page.select_option('#liveVeil','frost1')
    for host in (page,ref):host.locator('#scene').evaluate("e=>e.style.cssText='position:fixed;left:24px;top:24px;width:1318px;z-index:50'")
    for id in ['manuscripts','notes','records']:
        sel=f'#scene [data-cubby={id}]';assert page.locator(sel).screenshot(animations='disabled')==ref.locator(sel).screenshot(animations='disabled'),id
    page.locator('#scene').evaluate("e=>e.removeAttribute('style')");ref.close();page.select_option('#liveVeil','linework');page.locator('#artisan summary').click()
    ids=[];remembered={};families=['astral','cartographic','botanical','plain']
    for f in (families if a.part=='all' else [] if a.part=='interactions' else [a.part]):
        page.select_option('#pickerFamily',f)
        assert page.locator('#motif').input_value()==f and page.locator('#panelMotif').input_value()==f
        choices=page.locator('#emblemGrid button').evaluate_all('es=>es.map(e=>e.dataset.choice)');assert len(choices)==8 and len(set(choices))==8
        ids+=choices;assert visible()==choices[:4],(f,visible())
        # Screenshot every actual backing and glass render; all eight options must be distinct.
        backing=set();glass=set()
        for i,id in enumerate(choices):
            if i==4:turn(True);assert visible()==choices[4:],(f,visible())
            select(id)
            backing.add(hashlib.sha256(page.locator('#selectedBacking svg').screenshot(animations='disabled')).hexdigest())
            glass.add(hashlib.sha256(page.locator('#selectedGlass > svg').screenshot(animations='disabled')).hexdigest())
        assert len(backing)==len(glass)==8,(f,len(backing),len(glass))
        remembered[f]=choices[-1]
        print("checked",f,flush=True)
        # Capture all eight at enlarged catalogue scale for review, then restore the normal picker.
        if a.captures:
            a.captures.mkdir(parents=True,exist_ok=True)
            page.locator('#emblemScroll').evaluate("e=>e.style.height='378px'")
            page.locator('#emblemScroll').screenshot(path=str(a.captures/f'B8s7-{f}.png'),animations='disabled')
            page.locator('#emblemScroll').evaluate("e=>e.removeAttribute('style')")
        turn(False);assert visible()==choices[:4]
        # All palette variants use the same selected emblem and preserve family-specific corners.
        for t in ['Evening','Midnight','Twilight']:
            page.select_option('#theme',t);assert page.locator(f'#scene [data-backing] [data-emblem={choices[-1]}]').count()==1;integrity()
    assert len(ids)==len(set(ids))==(32 if a.part=='all' else 0 if a.part=='interactions' else 8)
    if a.part=='interactions':
        for f in families:
            page.select_option('#pickerFamily',f);turn(True)
            id=visible()[-1];select(id);remembered[f]=id
    for f,id in remembered.items():
        page.select_option('#pickerFamily',f);assert page.locator(f'#emblemGrid [data-choice={id}]').get_attribute('aria-pressed')=='true'
        if a.part in ('all','interactions') and f!=list(remembered)[-1]:assert id in visible()
    if a.part not in ('all','interactions'):
        assert not errors,errors;assert not requests,requests
        print('PASS family:',a.part,flush=True);browser.close();raise SystemExit(0)
    page.select_option('#pickerFamily','astral');page.locator('#resetStudy').click();assert page.locator('#selectedTitle').inner_text()=='Stellar seal';assert page.locator('#pickerRange').inner_text()=='1–4 of 8'
    # Keyboard activation of a catalogue option, not just forced script input.
    page.locator('[data-choice=armillary]').focus();page.keyboard.press('Enter');assert page.locator('#selectedTitle').inner_text()=='Armillary'
    for content in ['notes','records','manuscripts']:
        page.select_option('#sample',content);assert page.locator('#selectedGlass mask [data-emblem=armillary]').count()==1;integrity()
    page.locator('#artisan summary').click();assert page.locator('#artisan').evaluate('e=>e.open')
    for v in ['frost1','subtle','moderate','clearer','graded','linework','combined']:
        page.select_option('#liveVeil',v);assert page.locator(f'#scene [data-veil-style={v}]').count()==3;integrity()
    for v in ['register','inset','ornate']:
        page.select_option('#liveBorder',v);assert page.locator(f'#scene [data-field-border={v}]').count()==1
    for v in ['axis','span','seal']:
        page.select_option('#liveCenter',v);assert page.locator(f'#scene [data-center={v}]').count()==1
    page.select_option('#liveVeil','linework');page.locator('#artisan summary').click()
    page.locator('#allOpen').click();assert page.locator('#scene [data-mode=open]').count()==3
    page.locator('#allClosed').click();assert page.locator('#scene [data-mode=closed]').count()==3
    page.locator('#showVeiled').click();assert page.locator('#scene [data-mode=veiled]').count()==3
    for id in ['r1','t1','r2','l1']:
        slot=page.locator(f'#scene [data-slot={id}]');slot.click();assert page.locator(f'#scene [data-presented={id}] image[data-view=face]').count()==1;assert slot.locator('image').count()==0
        page.locator('#scene [data-return]').click();assert page.locator('#scene [data-slot] image').count()==4
    page.locator('#scene [data-file=art]').hover();assert page.locator('#info').is_visible();page.keyboard.press('Escape');assert not page.locator('#info').is_visible()
    page.locator('#edit').click()
    for key in ['Home','End']:
        for dim in ['width','height']:page.locator('#'+dim).focus();page.keyboard.press(key)
        integrity();assert page.locator('#scene [data-backing]').count()==1
    page.locator('#apply').click();page.locator('#undo').click();assert page.locator('#wo').inner_text()=='840' and page.locator('#ho').inner_text()=='480'
    page.locator('#width').focus();page.keyboard.press('Home');page.locator('#cancel').click();assert page.locator('#wo').inner_text()=='840';page.locator('#edit').click()
    for width in [500,360]:
        page.set_viewport_size({'width':width,'height':850});page.locator('#emblemScroll').evaluate('e=>e.scrollTop=0');page.wait_for_timeout(100);assert len(visible())==4,(width,visible());turn(True);assert len(visible())==4,(width,visible());turn(False);assert page.evaluate('document.documentElement.scrollWidth<=innerWidth'),width;integrity()
    page.set_viewport_size({'width':1366,'height':900});page.locator('#resetStudy').click();page.locator('#scene [data-slot=l1]').click();page.mouse.move(0,0);page.locator('#allOpen').focus();page.keyboard.press('Escape')
    if a.captures:
        page.locator('#catalogue').screenshot(path=str(a.captures/'B8s7-catalogue.png'),animations='disabled');page.locator('#scene').screenshot(path=str(a.captures/'B8s7-shelf.png'),animations='disabled')
    assert not errors,errors;assert not requests,requests
    browser.close()
    print('PASS '+a.part+': family memory; four-visible scroll on desktop and narrow views; keyboard; original satin pixels; ten exact assets; advanced options; holder/return, metadata and resize; no invalid IDs or external requests/errors.' + (' All 32 choices and per-family distinct engraving/glass renders checked.' if a.part=='all' else ''))
b=p.read_bytes();print('blob',hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(),'bytes',len(b))
