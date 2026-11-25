from pathlib import Path
from playwright.sync_api import sync_playwright

# Historical v5.4 diagnostic; source-relative input and local output.
source = Path(__file__).resolve().parent.parent / 'prototypes' / 'Astral_Archive_Storage_Workshop_v5_4.html'
h=source.read_text(encoding='utf-8')
with sync_playwright() as pw:
 browser=pw.chromium.launch(headless=True,executable_path='/usr/bin/chromium',args=['--no-sandbox','--disable-dev-shm-usage'])
 page=browser.new_page(viewport={'width':1440,'height':1100})
 errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
 page.set_content(h)
 print('INITIAL',page.evaluate('''() => ({maxPen:Math.max(...rack.cells.map(maxPenetration)),maxVel:Math.max(...rack.cells.flatMap(c=>c.scrolls.map(s=>Math.hypot(s.vx,s.vy))))})'''))
 for pattern in ['square','diamond','triangle','hex']:
  for density in [2,3,4,5]:
   page.select_option('#patternSelect',pattern)
   page.locator('#densityRange').fill(str(density))
   a=page.evaluate('''() => ({cells:rack.cells.length, scrolls:rack.cells.reduce((n,c)=>n+c.scrolls.length,0), pen:Math.max(...rack.cells.map(maxPenetration)), maximumInitialSpeed:Math.max(...rack.cells.flatMap(c=>c.scrolls.map(s=>Math.hypot(s.vx,s.vy)))), pathIsVector:!gapAtlas.regions[0]?.path.includes('h')})''')
   if a['pen']>0.05 or a['maximumInitialSpeed']>0.01 or not a['pathIsVector']:print('FAIL',pattern,density,a)
   else:print('OK',pattern,density,a['cells'],'scrolls',a['scrolls'],'pen',round(a['pen'],4))
 print('ERRORS',errors)
 page.select_option('#patternSelect','diamond');page.locator('#densityRange').fill('3')
 page.locator('#cellCanvas').scroll_into_view_if_needed()
 # choose largest void region & hover its peak
 point=page.evaluate('''() => { let r=gapAtlas.regions.slice().sort((a,b)=>b.area-a.area)[0]; return {x:r.x,y:r.y,area:r.area,regionId:r.id} }''')
 print('void for screenshot',point)
 page.evaluate('''p=>{selectedVoidAnchor={x:p.x,y:p.y};hoveredVoidAnchor=selectedVoidAnchor;pointerOverCell=false;renderCellInspector();updateStatus();}''',point)
 page.screenshot(path='Storage_Workshop_v5_4_smooth_void.png')
 browser.close()
