from pathlib import Path
from playwright.sync_api import sync_playwright

# Historical v5.4 diagnostic; source-relative input and local output.
source = Path(__file__).resolve().parent.parent / 'prototypes' / 'Astral_Archive_Storage_Workshop_v5_4.html'
with sync_playwright() as pw:
 browser=pw.chromium.launch(headless=True, executable_path='/usr/bin/chromium',args=['--no-sandbox','--disable-dev-shm-usage'])
 page=browser.new_page(viewport={'width':1440,'height':900},device_scale_factor=1)
 errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.set_content(source.read_text(encoding='utf-8'),wait_until='load')
 page.wait_for_timeout(350)
 print('TITLE',page.title())
 print('ERRORS',errors)
 stats=page.evaluate('''() => ({cells: rack.cells.length, count:rack.cells[0].scrolls.length, allPen:Math.max(...rack.cells.map(maxPenetration)), firstVel:rack.cells[0].scrolls.map(s=>[s.vx,s.vy]), pathLength: gapAtlas.regions[0]?.path.length || 0, hasRectangles: gapAtlas.regions[0]?.path.includes('h') })''')
 print('INIT',stats)
 page.screenshot(path='Storage_Workshop_v5_4_preview.png',full_page=True)
 page.locator('#showGaps').check()
 # using programmatic selection on a true void point (tests events separate)
 result=page.evaluate('''() => { const cell=getSelectedCell();let pt=null;for(let y=0;y<512&&!pt;y+=4)for(let x=0;x<512&&!pt;x+=4){let wp={x:(x-$('cellCanvas')._view.offsetX)/$('cellCanvas')._view.scale,y:(y-$('cellCanvas')._view.offsetY)/$('cellCanvas')._view.scale};if(regionAt(gapAtlas,wp)&&!scrollAt(wp))pt={x,y,wp};}return pt;}''')
 print('void point',result)
 if result:
  canvas=page.locator('#cellCanvas').bounding_box();print('canvas box',canvas)
  x=canvas['x']+result['x']/512*canvas['width'];y=canvas['y']+result['y']/512*canvas['height']
  page.mouse.move(x,y);page.mouse.down();page.mouse.up();page.wait_for_timeout(80)
  print('selected anchor',page.evaluate('selectedVoidAnchor'))
  print('insert disabled',page.locator('#insertBtn').is_disabled())
  page.locator('#insertBtn').click()
  print('pending',page.evaluate('pendingInsertion ? {duration:pendingInsertion.duration,started:pendingInsertion.started,ids:pendingInsertion.targets.size} : null'))
  page.wait_for_timeout(850)
  print('after insert',page.evaluate('''() => ({pending:!!pendingInsertion,count:getSelectedCell().scrolls.length,maxPen:maxPenetration(getSelectedCell()),notice:$('notice').textContent})'''))
 # selection click at screen center of one scroll after programmatic
 page.locator('#cellCanvas').scroll_into_view_if_needed()
 first=page.evaluate('''() => {let s=getSelectedCell().scrolls[0],view=$('cellCanvas')._view;return {x:s.x*view.scale+view.offsetX,y:s.y*view.scale+view.offsetY,scrollId:s.id}}''')
 box=page.locator('#cellCanvas').bounding_box();page.mouse.click(box['x']+first['x']/512*box['width'],box['y']+first['y']/512*box['height']);print('selected scroll',page.evaluate('selectedScrollId'), 'expected',first['scrollId'])
 print('remove disabled',page.locator('#removeBtn').is_disabled())
 page.locator('#removeBtn').click();page.wait_for_timeout(250)
 print('after remove',page.evaluate('''() => ({held:!!heldScroll,pen:maxPenetration(getSelectedCell())})'''))
 print('ERRORS LATE',errors)
 page.screenshot(path='Storage_Workshop_v5_4_cell.png',full_page=False)
 browser.close()
