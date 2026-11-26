"""Offline browser regression for the B8 projection comparison lab."""
import argparse
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parent
html=(root/'Astral_Archive_B8_Projection_Lab.html').read_text()
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path=a.chromium,args=['--no-sandbox'])
    page=b.new_page(viewport={'width':1440,'height':1100})
    errors=[];requests=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None)
    page.set_content(html);page.wait_for_function("document.querySelectorAll('canvas[data-rendered]').length===4")
    original=page.evaluate('JSON.stringify(lab.model)')
    assert page.evaluate('''()=>{const s=lab.settings(),cam=lab.camera('oblique',s),a=cam([0,0,0]),b=cam([100,0,0]),c=cam([0,100,0]),d=cam([0,0,100]);return b[0]-a[0]===100&&b[1]===a[1]&&c[1]-a[1]===100&&c[0]===a[0]&&Math.abs(d[0]-a[0]-100*s.alpha)<1e-8&&Math.abs(d[1]-a[1]+100*s.beta)<1e-8}''')
    assert page.evaluate('''()=>{const s=lab.settings(),c=lab.camera('ortho',s),a=c([0,0,0]),b=c([100,0,0]),d=c([0,100,0]),e=c([0,0,100]);return b[0]-a[0]===100&&b[1]===a[1]&&d[0]===a[0]&&e[0]===a[0]&&Math.abs((d[1]-a[1])**2+(e[1]-a[1])**2-10000)<1e-6}''')
    assert page.evaluate('''()=>{const c=lab.camera('perspective',lab.settings());return c([600,800,0])[3]>c([600,0,0])[3]&&c([600,0,0])[0]===0}''')
    if a.captures:page.screenshot(path=str(root/'compare.png'),full_page=True)
    for mode in ['oblique','ortho','perspective','plan','unfold']:
        page.locator(f'button[data-mode={mode}]').click();page.wait_for_selector(f'canvas[data-rendered={mode}]')
        assert page.locator('canvas').count()==1
        assert page.evaluate('JSON.stringify(lab.model)')==original
        if a.captures:page.screenshot(path=str(root/f'{mode}.png'),full_page=True)
    page.locator('button[data-mode=oblique]').click();page.wait_for_selector('canvas[data-rendered=oblique]')
    before=page.locator('canvas').evaluate('(c)=>c.toDataURL()')
    page.locator('#horizontal').fill('25');page.locator('#vertical').fill('50');page.wait_for_function("document.querySelector('#hOut').textContent==='25%' && document.querySelector('#vOut').textContent==='50%'")
    assert page.locator('canvas').evaluate('(c)=>c.toDataURL()')!=before
    if a.captures:page.screenshot(path=str(root/'oblique-25-50.png'),full_page=True)
    page.locator('#horizontal').fill('0');page.locator('#vertical').fill('10');page.wait_for_function("document.querySelector('#hOut').textContent==='0%' && document.querySelector('#vOut').textContent==='10%'")
    page.locator('#horizontal').fill('45');page.locator('#vertical').fill('65');page.wait_for_function("document.querySelector('#hOut').textContent==='45%' && document.querySelector('#vOut').textContent==='65%'")
    page.locator('button[data-mode=ortho]').click();page.wait_for_selector('canvas[data-rendered=ortho]')
    for t in ['20','30']:
        page.locator('#tilt').fill(t);page.wait_for_function(f"document.querySelector('#tOut').textContent==='{t}°'")
    page.locator('button[data-mode=perspective]').click();page.wait_for_selector('canvas[data-rendered=perspective]')
    for d in ['18','55']:
        page.locator('#distance').fill(d);page.wait_for_function(f"document.querySelector('#dOut').textContent==='{int(d)/10:.1f}×'")
    for palette in ['Evening','Midnight','Twilight']:
        page.locator('#palette').select_option(palette);page.wait_for_timeout(100)
    page.locator('#reset').click();page.wait_for_function("document.querySelector('#hOut').textContent==='12%' && document.querySelector('#tOut').textContent==='22°'")
    page.set_viewport_size({'width':500,'height':800});page.locator('button[data-mode=compare]').click();page.wait_for_function("document.querySelectorAll('canvas[data-rendered]').length===4")
    assert page.evaluate('document.documentElement.scrollWidth <= innerWidth+1')
    assert page.evaluate('JSON.stringify(lab.model)')==original
    assert not errors,errors
    assert not requests,requests
    print('PASS: 5 projections, projection invariants, immutable sample, slider extremes, palette/reset, narrow viewport, no HTTP or page errors')
    b.close()
