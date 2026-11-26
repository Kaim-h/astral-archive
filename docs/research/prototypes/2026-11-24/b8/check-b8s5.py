"""Offline visual-study regression. Requires Python Playwright and Chromium."""
from pathlib import Path
import argparse, hashlib, json, re, xml.etree.ElementTree as ET
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parent)
parser.add_argument('--chromium', default=None)
parser.add_argument('--captures', type=Path, default=None)
args = parser.parse_args()
path = args.directory / 'Astral_Archive_Shelf_Case_Study_B8s5.html'
html = path.read_text(encoding='utf-8')
baseline = (args.directory / 'Astral_Archive_Shelf_Study_B8s3.html').read_text(encoding='utf-8')
assert 'B8s5 comparative study' in html
for catalog in ('ASSETS', 'FACES'):
    pattern = r'^const '+catalog+r'=(.*);$'
    same = re.search(pattern, html, re.M)[1]
    assert same == re.search(pattern, baseline, re.M)[1]
    for entry in json.loads(same).values():
        b = entry['svg'].encode()
        assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest() == entry['sha']
        root = ET.fromstring(entry['svg'])
        for e in root.iter():
            assert e.tag.split('}')[-1] not in ('script','foreignObject')
            for key, value in e.attrib.items():
                assert not key.split('}')[-1].lower().startswith('on')
                if key.split('}')[-1] in ('href','src'):
                    assert value.startswith('#')
assert not re.search(r'astral-archive-private|private-artifacts/|/mnt/data/|github_pat_|BEGIN PRIVATE KEY', html)
veils = ['open','baseline','closed','frosted','glass','frost1','frost2','smoke','ribbed','leaded','stone','wood']
borders = ['none','corners','stepped','diamond','foliate','astralcorner','fan','adaptive']
with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path=args.chromium)
    page = browser.new_page(viewport={'width':1366,'height':900},offline=True)
    errors, network = [], []
    page.on('pageerror', lambda err: errors.append(str(err)))
    page.on('request', lambda req: network.append(req.url) if req.url.startswith(('http:', 'https:')) else None)
    page.set_content(html)
    assert page.locator('#veil-grid .sample').count() == 12
    assert page.locator('#border-grid .sample').count() == 8
    assert page.locator('#scene [data-cubby]').count() == 3
    assert page.locator('.sample svg [tabindex],.sample svg [data-file],.sample svg [data-slot]').count() == 0
    # Same viewBox and populated source scene in every sample across all three interiors.
    for sample in ['manuscripts','notes','records']:
        page.select_option('#sample',sample)
        assert page.locator('#veil-grid svg').evaluate_all("es=>es.filter(e=>e.parentElement.classList.contains('sample')).every(e=>e.getAttribute('viewBox')==='0 0 264 182')")
        for v in veils[3:]:
            assert page.locator(f'#veil-grid [data-variant={v}] [data-veil-style={v}]').count() == 1
            assert (page.locator(f'#veil-grid [data-variant={v}] image').count() > 0) == (v not in ('stone','wood'))
        assert page.locator('#veil-grid [data-variant=closed] image').count()==0
        assert page.locator('#veil-grid [data-variant=frost2] feGaussianBlur').get_attribute('stdDeviation')=='7.2'
        assert page.locator('#veil-grid [data-variant=frost1] feGaussianBlur').get_attribute('stdDeviation')=='4.5'
        for v in ['glass','frost1','frost2','smoke','ribbed','leaded','stone','wood']:
            assert page.locator(f'#veil-grid [data-variant={v}] [data-door-material]').count()==1
    page.select_option('#sample','manuscripts')
    # Actual pixels differ, not merely labels/DOM strings.
    # Adaptive intentionally matches the selected fixed grammar, so it is not a seventh unique corner shape.
    for grid, variants in [('veil-grid',veils),('border-grid',borders[:-1])]:
        images = [page.locator(f'#{grid} [data-variant={v}] > svg').screenshot(animations='disabled') for v in variants]
        assert len(set(hashlib.sha256(b).hexdigest() for b in images))==len(variants)
    for theme in ['Twilight','Evening','Midnight']:
        page.select_option('#theme',theme)
        for motif in ['astral','cartographic','botanical','plain']:
            page.select_option('#panelMotif',motif)
            assert page.locator('#motif').input_value()==motif
            # Both material gallery and corner gallery must refresh on motif selection.
            stone=page.locator('#veil-grid [data-variant=stone] [data-door-material]')
            assert stone.count()==1
            # The opaque surface uses the same emblem logic as the exterior.
            assert ('<g opacity="0.64">' in stone.inner_html()) or ('<g opacity=".64">' in stone.inner_html())
            for border in borders:
                card=page.locator(f'#border-grid [data-variant={border}]')
                assert card.locator('[data-field-border]').count()==(border!='none')
                assert card.locator('[data-backing]').count()==(motif!='plain')
                if border=='adaptive':
                    expected={'astral':'astralcorner','cartographic':'diamond','botanical':'foliate','plain':'stepped'}[motif]
                    assert card.locator('[data-field-border]').get_attribute('data-corner-grammar')==expected
        page.select_option('#profile','pilaster');page.select_option('#panelView','full')
        assert page.locator('#border-grid svg.panel-image.full').count()==8
        page.select_option('#profile','cornice');page.select_option('#panelView','detail')
        assert page.locator('#border-grid svg.panel-image.full').count()==0
    page.select_option('#theme','Twilight');page.select_option('#profile','crest');page.select_option('#panelMotif','astral')
    # Select each candidate by actual buttons and confirm live rendering.
    for v in veils[3:]:
        page.locator(f'#veil-grid [data-value={v}]').click()
        assert page.locator('#liveVeil').input_value()==v
        assert page.locator(f'#scene [data-veil-style={v}]').count()==3
    for v in borders:
        page.locator(f'#border-grid [data-value={v}]').click()
        assert page.locator('#liveBorder').input_value()==v
        assert page.locator('#scene [data-field-border]').count()==(v!='none')
    page.locator('#resetStudy').click()
    assert page.locator('#scene [data-mode=open]').count()==1
    assert page.locator('#scene [data-mode=veiled]').count()==1
    assert page.locator('#scene [data-mode=closed]').count()==1
    assert page.locator('#liveVeil').input_value()=='baseline' and page.locator('#liveBorder').input_value()=='none'
    page.locator('#allOpen').click();assert page.locator('#scene [data-mode=open]').count()==3
    page.locator('#allClosed').click();assert page.locator('#scene [data-mode=closed]').count()==3
    page.locator('#showVeiled').click();assert page.locator('#scene [data-mode=veiled]').count()==3
    for id in ['r1','t1','r2','l1']:
        slot=page.locator(f'#scene [data-slot={id}]');slot.click()
        assert page.locator(f'#scene [data-presented={id}] image[data-view=face]').count()==1
        assert slot.locator('image').count()==0
        page.locator('#scene [data-return]').click()
        assert page.locator('#scene [data-presented]').count()==0
        assert page.locator('#scene [data-slot] image').count()==4
    page.locator('#scene [data-slot=l1]').focus();page.keyboard.press('Enter')
    assert page.locator('#scene [data-presented=l1]').count()==1
    page.locator('#scene [data-file=art]').hover();assert page.locator('#info').is_visible()
    page.keyboard.press('Escape');assert not page.locator('#info').is_visible()
    page.locator('#edit').click();page.locator('#width').focus();page.keyboard.press('Home')
    assert page.locator('#wo').inner_text()=='700'
    page.locator('#edit').click();page.locator('#edit').click();assert page.locator('#wo').inner_text()=='700'
    page.locator('#apply').click();page.locator('#undo').click();assert page.locator('#wo').inner_text()=='840'
    page.locator('#height').focus();page.keyboard.press('Home');page.locator('#cancel').click();assert page.locator('#ho').inner_text()=='480'
    page.locator('#edit').click();page.select_option('#liveVeil','frost2');page.select_option('#liveBorder','astralcorner')
    if args.captures:
        args.captures.mkdir(parents=True,exist_ok=True)
        for target,name in [('#veils','B8s5-veils.png'),('#panels','B8s5-borders.png'),('#scene','B8s5-context.png')]:
            page.locator(target).screenshot(path=str(args.captures/name),animations='disabled')
    for width in [500,360]:
        page.set_viewport_size({'width':width,'height':800})
        assert page.evaluate('document.documentElement.scrollWidth<=innerWidth'),width
    assert not errors,errors
    assert not network,network
    browser.close()
b=path.read_bytes();print('PASS: 12 door/preview states, 8 corner states, distinct rendered pixels, three storage samples, themes/motifs, live selection/reset, canonical assets, reserved upright return, hover, resize/undo/cancel, narrow viewports, no network or uncaught errors.')
print('blob',hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(),'bytes',len(b))
