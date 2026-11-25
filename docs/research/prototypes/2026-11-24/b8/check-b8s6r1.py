"""Offline B8s6r1 visual regression. Requires Python Playwright and Chromium."""
from pathlib import Path
import argparse, hashlib, json, re, xml.etree.ElementTree as ET
from playwright.sync_api import sync_playwright

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--directory',type=Path,default=Path(__file__).resolve().parent)
parser.add_argument('--chromium',default=None)
parser.add_argument('--captures',type=Path,default=None)
a=parser.parse_args()
p=a.directory/'Astral_Archive_Shelf_Case_Study_B8s6r1.html'
html=p.read_text(encoding='utf-8')
base=(a.directory/'Astral_Archive_Shelf_Case_Study_B8s5.html').read_text(encoding='utf-8')
assert 'B8s6r1 comparative study' in html
for cat in ('ASSETS','FACES'):
    pattern=r'^const '+cat+r'=(.*);$'
    value=re.search(pattern,html,re.M)[1]
    assert value==re.search(pattern,base,re.M)[1]
    for entry in json.loads(value).values():
        b=entry['svg'].encode();assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==entry['sha']
        for element in ET.fromstring(entry['svg']).iter():
            assert element.tag.split('}')[-1] not in ('script','foreignObject')
            for key,val in element.attrib.items():
                assert not key.split('}')[-1].lower().startswith('on')
                if key.split('}')[-1] in ('href','src'):assert val.startswith('#')
# Scope: preserve physical arrangement and interactive fixtures, not the crest/backing.
layout=lambda s:s[s.index('// All furniture coordinates'):s.index('if(guides){for')]
assert layout(html)==layout(base)
assert not re.search(r'astral-archive-private|private-artifacts/|/mnt/data/|github_pat_|BEGIN PRIVATE KEY',html)
veils=['open','frost1','subtle','moderate','clearer','graded','linework','combined']
borders=['ornate','register','inset'];centers=['seal','axis','span'];families=['astral','cartographic','botanical','plain']
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=a.chromium)
    page=browser.new_page(viewport={'width':1366,'height':900},offline=True)
    errors=[];requests=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None)
    page.set_content(html)
    assert page.locator('#veil-grid .sample').count()==8 and page.locator('#border-grid .sample').count()==3 and page.locator('#center-grid .sample').count()==3
    assert page.locator('#scene [data-cubby]').count()==3
    assert page.locator('.sample svg [tabindex],.sample svg [data-file],.sample svg [data-slot]').count()==0
    def integrity():
        problems=page.evaluate('''()=>{const all=[...document.querySelectorAll('[id]')].map(e=>e.id), bad=[];if(new Set(all).size!==all.length)bad.push('duplicate ids');for(const e of document.querySelectorAll('svg *')){for(const a of e.attributes){if(a.name==='href'&&a.value.startsWith('data:'))continue;if(/NaN|undefined|Infinity/.test(a.value))bad.push(a.name+':'+a.value);for(const m of a.value.matchAll(/url\\(#([^)]*)\\)/g))if(!document.getElementById(m[1]))bad.push('unresolved '+m[1]);}}return bad;}''')
        assert not problems,problems[:5]
    def pixel_hash(selector):return hashlib.sha256(page.locator(selector).screenshot(animations='disabled')).hexdigest()
    integrity()
    # B8s5 reference must be pixel-identical for all three cubbies; this checks more
    # than the markup and catches paint-server collisions and coordinate regressions.
    ref=browser.new_page(viewport={'width':1366,'height':900},offline=True);ref.set_content(base);ref.select_option('#liveVeil','frost1');page.select_option('#liveVeil','frost1')
    # Normalize the SVG's screen origin to avoid subpixel differences from different gallery heights.
    for host in (page,ref):host.locator('#scene').evaluate("e=>e.style.cssText='position:fixed;left:24px;top:24px;width:1318px;z-index:50'")
    for id in ['manuscripts','notes','records']:
        sel=f'#scene [data-cubby={id}]'
        assert page.locator(sel).screenshot(animations='disabled')==ref.locator(sel).screenshot(animations='disabled'),id
    page.locator('#scene').evaluate("e=>e.removeAttribute('style')");ref.close()
    for family in families:
        page.select_option('#motif',family)
        assert page.locator('#panelMotif').input_value()==family
        for sample in ['manuscripts','notes','records']:
            page.select_option('#sample',sample)
            for v in veils[2:]:
                card=page.locator(f'#veil-grid [data-variant={v}]');assert card.locator('[data-frost-reveal]').count()==1
                assert card.locator('mask').count()>=2
                assert card.locator('[data-frost-reveal] image').count()>0
                assert card.locator('feGaussianBlur[stdDeviation="4.5"]').count()==1
                assert float(card.locator('feGaussianBlur').nth(1).get_attribute('stdDeviation'))<4.5
            integrity()
        page.select_option('#sample','manuscripts')
        for grid,choices in [('veil-grid',veils),('border-grid',borders),('center-grid',centers)]:
            assert len({pixel_hash(f'#{grid} [data-variant={v}] > svg') for v in choices})==len(choices),(family,grid)
        for theme in ['Twilight','Evening','Midnight']:
            page.select_option('#theme',theme)
            for center in centers:
                page.select_option('#liveCenter',center)
                for border in borders:
                    page.select_option('#liveBorder',border)
                    assert page.locator('#scene [data-center]').get_attribute('data-center')==center
                    assert page.locator('#scene [data-field-border]').get_attribute('data-family')==family
            integrity()
        page.select_option('#theme','Twilight');page.select_option('#liveBorder','ornate');page.select_option('#liveCenter','seal');page.select_option('#liveVeil','moderate')
        if a.captures:
            a.captures.mkdir(parents=True,exist_ok=True)
            for sel,name in [('#center-grid',f'B8s6r1-centers-{family}.png'),('#border-grid',f'B8s6r1-borders-{family}.png'),('#scene',f'B8s6r1-shelf-{family}.png')]:page.locator(sel).screenshot(path=str(a.captures/name),animations='disabled')
        page.select_option('#panelView','full');assert page.locator('#center-grid .panel-image.full').count()==3;integrity();page.select_option('#panelView','detail')
    page.select_option('#motif','astral')
    for v in veils[1:]:
        page.locator(f'#veil-grid [data-value={v}]').click();assert page.locator(f'#scene [data-veil-style={v}]').count()==3
    for grid,values,select in [('border-grid',borders,'liveBorder'),('center-grid',centers,'liveCenter')]:
        for v in values:
            page.locator(f'#{grid} [data-value={v}]').click();assert page.locator('#'+select).input_value()==v
    page.locator('#resetStudy').click();assert page.locator('#scene [data-veil-style=moderate]').count()==3
    page.locator('#allOpen').click();assert page.locator('#scene [data-mode=open]').count()==3
    page.locator('#allClosed').click();assert page.locator('#scene [data-mode=closed]').count()==3
    page.locator('#showVeiled').click();assert page.locator('#scene [data-mode=veiled]').count()==3
    for id in ['r1','t1','r2','l1']:
        slot=page.locator(f'#scene [data-slot={id}]');slot.click();assert page.locator(f'#scene [data-presented={id}] image[data-view=face]').count()==1;assert slot.locator('image').count()==0
        page.locator('#scene [data-return]').click();assert page.locator('#scene [data-slot] image').count()==4
    page.locator('#scene [data-slot=l1]').focus();page.keyboard.press('Enter');assert page.locator('#scene [data-presented=l1]').count()==1
    page.locator('#scene [data-file=art]').hover();assert page.locator('#info').is_visible();page.keyboard.press('Escape');assert not page.locator('#info').is_visible()
    page.locator('#edit').click()
    for key in ['Home','End']:
        for dim in ['width','height']:page.locator('#'+dim).focus();page.keyboard.press(key)
        for v in centers:
            page.select_option('#liveCenter',v)
            assert page.evaluate('''()=>{const e=document.querySelector('#scene [data-center]'),b=e.getBBox(),a=document.querySelector('#scene').viewBox.baseVal,w=a.width-112,h=a.height-132;return b.x>=574-1&&b.x+b.width<=w-20+1&&b.y>=0&&b.y+b.height<=h}'''),key
        integrity()
    page.locator('#apply').click();page.locator('#undo').click();assert page.locator('#wo').inner_text()=='840' and page.locator('#ho').inner_text()=='480'
    page.locator('#width').focus();page.keyboard.press('Home');page.locator('#edit').click();page.locator('#edit').click();assert page.locator('#wo').inner_text()=='700';page.locator('#cancel').click();assert page.locator('#wo').inner_text()=='840';page.locator('#edit').click()
    page.locator('#resetStudy').click();integrity()
    if a.captures:
        for target,name in [('#veils','B8s6r1-glass.png'),('#panels','B8s6r1-ornaments.png'),('#scene','B8s6r1-shelf.png')]:page.locator(target).screenshot(path=str(a.captures/name),animations='disabled')
    for width in [500,360]:
        page.set_viewport_size({'width':width,'height':800});assert page.evaluate('document.documentElement.scrollWidth<=innerWidth'),width
    assert not errors,errors;assert not requests,requests
    browser.close()
b=p.read_bytes();print('PASS: B8s5 satin pixel parity, canonical assets, distinct visual choices for all four families, palettes, sample contents, 108 family/palette/border/center combinations, unique SVG IDs, valid references, bounded center ornaments, existing interactions, viewport sizes, no network or page errors.')
print('blob',hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(),'bytes',len(b))
