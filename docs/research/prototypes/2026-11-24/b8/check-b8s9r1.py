from pathlib import Path
from playwright.sync_api import sync_playwright
import hashlib,json,re,argparse
parser=argparse.ArgumentParser(description='Offline B8s9r1 integrated Shelf and arrangement regression');parser.add_argument('--directory',type=Path,default=Path(__file__).resolve().parent);parser.add_argument('--chromium',default=None);parser.add_argument('--captures',type=Path,default=None);args=parser.parse_args();D=args.directory
s=(D/'Astral_Archive_Shelf_Study_B8s9r1.html').read_text(encoding='utf-8');base=(D/'Astral_Archive_Shelf_Replacement_Themes_B8s8r4.html').read_text(encoding='utf-8');new=json.loads(re.search(r'^const CATALOGUE=(.*);$',s,re.M)[1]);old=json.loads(re.search(r'^const CATALOGUE=(.*);$',base,re.M)[1]);assert len(new)==9 and sum(map(len,new.values()))==76;assert all(new[k]==v for k,v in old.items());assert 'cartographic' not in new
for k in ('ASSETS','FACES'):
 a=re.search(r'^const '+k+r'=(.*);$',s,re.M)[1];assert a==re.search(r'^const '+k+r'=(.*);$',base,re.M)[1]
 for v in json.loads(a).values():
  raw=v['svg'].encode();assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()==v['sha']
if args.captures:args.captures.mkdir(parents=True,exist_ok=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);p=b.new_page(viewport={'width':1366,'height':900},offline=True);errors=[];requests=[];p.on('pageerror',lambda e:errors.append(str(e)));p.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http://','https://')) else None);p.set_content(s)
 def check(q):assert p.evaluate(q),q
 def setv(id,v):p.locator('#'+id).fill(str(v))
 def btn(id):p.locator('#'+id).click()
 def capture(name):
  if args.captures:p.locator('#scene').screenshot(path=str(args.captures/name))
 def choice(id):p.locator('[data-choice="'+id+'"]').evaluate('(el)=>el.click()')
 def drag(x,y,dx,dy):
  p.locator('#scene').scroll_into_view_if_needed();a,b=p.evaluate('''([x,y,dx,dy])=>{let t=scene.getScreenCTM(),f=(x,y)=>{let p=new DOMPoint(x,y).matrixTransform(t);return [p.x,p.y]};return [f(x,y),f(x+dx,y+dy)]}''',[x,y,dx,dy]);p.mouse.move(*a);p.mouse.down();p.mouse.move(*b,steps=8);p.mouse.up()
 check('!validateLayout(layout,840,480)');assert p.locator('[data-plate-id]').count()==76
 # Preserve the legacy preview controls and canonical identities before arrange.
 p.locator('[data-slot=r1]').click();assert p.locator('[data-presented=r1]').count()==1;p.locator('[data-return]').click();assert p.locator('[data-presented]').count()==0
 p.locator('[data-file=art]').hover();assert p.locator('#info').is_visible();p.keyboard.press('Escape');assert not p.locator('#info').is_visible()
 p.locator('[data-cubby=manuscripts]').click();assert p.locator('[data-cubby=manuscripts]').get_attribute('data-mode')=='inventory';btn('showVeiled');capture('B8s9r1-browse.png')
 btn('arrangeMode');assert p.locator('[data-module]').count()==12;assert p.locator('#scene [data-cubby]').count()==0
 check('layoutDraft===null');check('!validateLayout(activeLayout(),840,480)');capture('B8s9r1-arrange.png')
 # Real drag moves a support and every descendant by a shared delta.
 drag(425,430,280,0);check('layoutDraft!==null');check('findNode(layout,"rack").x===300&&findNode(layoutDraft,"rack").x===580');check('findNode(layoutDraft,"records").x===580&&findNode(layoutDraft,"parcel").x===756&&findNode(layoutDraft,"owl").x===625');check('!validateLayout(layoutDraft,840,480)');capture('B8s9r1-provisional.png')
 btn('arrangeMode');assert p.locator('#arrangement').is_visible();assert 'Apply or Cancel' in p.locator('#arrFeedback').inner_text();btn('arrApply');check('findNode(layout,"rack").x===580&&layoutDraft===null')
 # Invalid drag overlaps Manuscripts; no draft or committed change.
 drag(700,430,-500,0);check('layoutDraft===null&&findNode(layout,"rack").x===580');assert 'overlap' in p.locator('#arrFeedback').inner_text().lower()
 # Envelope shrink rejected while a module occupies the expanded right-hand area.
 btn('arrangeMode');btn('edit');p.locator('#width').focus();p.keyboard.press('Home');assert p.locator('#wo').inner_text()=='700';assert p.locator('#apply').is_disabled();assert 'exceeds the envelope' in p.locator('#status').inner_text();btn('cancel');assert p.locator('#wo').inner_text()=='840';btn('edit');btn('arrangeMode');btn('arrUndo');check('JSON.stringify(layout)===JSON.stringify(INITIAL)')
 # Inspector: non-grid dimensions retained on a move; support choice explicit.
 p.select_option('#arrSelection','jar');p.select_option('#arrSupport','floor');setv('arrX',600);btn('arrUpdate');check('findNode(layoutDraft,"jar").support==="floor"&&findNode(layoutDraft,"jar").z===0');btn('arrCancel');check('JSON.stringify(layout)===JSON.stringify(INITIAL)')
 p.select_option('#arrSelection','rack');setv('arrH',115);btn('arrUpdate');check('findNode(layoutDraft,"rack").h===115&&findNode(layoutDraft,"rack").w===252');check('findNode(layoutDraft,"records").z===115&&findNode(layoutDraft,"owl").z===240&&findNode(layoutDraft,"parcel").z===115');btn('arrApply');btn('arrUndo');check('JSON.stringify(layout)===JSON.stringify(INITIAL)')
 # Width shrink cannot discard dependent objects; cycle cannot appear in picker.
 p.select_option('#arrSelection','rack');assert p.locator('#arrSupport option[value=records]').count()==0;setv('arrW',230);btn('arrUpdate');check('layoutDraft===null');assert 'must fit' in p.locator('#arrFeedback').inner_text()
 # A wall-mounted board carries its holder, cradle and parcel, without changing file identities.
 p.select_option('#arrSelection','board');setv('arrX',582);btn('arrUpdate');check('findNode(layoutDraft,"board").x===582&&findNode(layoutDraft,"holder").x===587&&findNode(layoutDraft,"cradle").x===683&&findNode(layoutDraft,"letters").x===756');btn('arrApply');btn('arrUndo');check('JSON.stringify(layout)===JSON.stringify(INITIAL)')
 # Off-grid support geometry: one step must be exactly one step, with no absolute-grid jump.
 p.select_option('#arrSelection','rack');setv('arrH',115);btn('arrUpdate');check('findNode(layoutDraft,"rack").h===115&&findNode(layoutDraft,"records").z===115');setv('arrH',125);btn('arrUpdate');check('findNode(layoutDraft,"rack").h===125&&findNode(layoutDraft,"owl").z===250');btn('arrCancel')
 # A wall mount starts off-grid. Real drag by a cell must preserve its phase.
 drag(480,135,10,0);check('findNode(layoutDraft,"art").x===420&&findNode(layoutDraft,"art").z===297');btn('arrCancel')
 p.locator('#scene [data-module=board]').focus();p.keyboard.press('ArrowRight');check('findNode(layoutDraft,"board").x===32&&findNode(layoutDraft,"holder").x===37');btn('arrCancel')
 # Attempt to lift an unsupported floor rack by one full cell; no silent recapture of the floor.
 drag(425,430,0,-10);check('layoutDraft===null');assert 'No compatible support' in p.locator('#arrFeedback').inner_text()
 # Grid visibility and snap independent; changing interval never repositions anything.
 p.select_option('#gridStep','20');check('JSON.stringify(layout)===JSON.stringify(INITIAL)');assert p.locator('#scene [data-layout-grid]').get_attribute('data-layout-grid')=='20';p.locator('#gridVisible').uncheck();assert p.locator('#scene [data-layout-grid]').count()==0;assert p.locator('#snapEnabled').is_checked();p.locator('#snapEnabled').uncheck();p.locator('#gridVisible').check();assert p.locator('#scene [data-layout-grid]').count()==1
 p.select_option('#arrSelection','art');setv('arrX',610.5);setv('arrZ',301.5);btn('arrUpdate');check('findNode(layoutDraft,"art").x===610.5&&findNode(layoutDraft,"art").z===301.5');btn('arrCancel')
 # Keyboard movement and mode isolation.
 p.locator('#scene [data-module=art]').focus();p.keyboard.press('ArrowRight');check('findNode(layoutDraft,"art").x===411');btn('arrCancel');btn('arrangeMode');assert p.locator('#scene [data-module]').count()==0;assert p.locator('#scene [data-cubby]').count()==3
 # Test envelope preview cancellation, growth, and floor-relative positions unchanged.
 btn('edit');p.locator('#width').focus();p.keyboard.press('End');btn('apply');check('committed.w===1100&&JSON.stringify(layout)===JSON.stringify(INITIAL)');btn('undo');check('committed.w===840');btn('edit')
 # Integrated 76 selections, family-specific secondary ornaments and glass-only Voyage.
 p.evaluate("$('liveCenter').value='axis';$('liveCenter').dispatchEvent(new Event('change'));$('liveBorder').value='rails';$('liveBorder').dispatchEvent(new Event('change'))")
 signatures=[]
 for family,items in new.items():
  p.select_option('#pickerFamily',family);assert p.locator('.emblem-tile').count()==len(items);sig=p.locator('#scene [data-secondary]').evaluate_all('(els)=>els.map(e=>e.innerHTML)');assert len(sig)==2;signatures.append(sig[0]);assert p.locator('#scene [data-field-border=rails] > g').count()==6
  for e in items:
   choice(e['id']);assert p.locator('#scene [data-backing] [data-emblem]').count()==1;assert p.locator('#selectedBacking [data-emblem]').get_attribute('data-emblem')==e['id'];assert p.locator('#scene [data-secondary]').evaluate_all('(els)=>els.map(e=>e.innerHTML)')==sig;assert p.locator('#selectedGlass [data-emblem]').count()>0
  print(family,len(items),flush=True)
 assert len(set(signatures))==9
 p.select_option('#pickerFamily','fire');choice('brazier');capture('B8s9r1-fire.png');p.evaluate("$('glassEmblem').value='voyage';$('glassEmblem').dispatchEvent(new Event('change'))");assert p.locator('#scene [data-backing] [data-emblem]').get_attribute('data-emblem')=='brazier';assert p.locator('#selectedGlass [data-emblem=voyage-glass]').count()>0;p.evaluate("$('glassEmblem').value='main';$('glassEmblem').dispatchEvent(new Event('change'))")
 for palette,etch in [('Evening','#b7a2c8'),('Midnight','#568f80'),('Twilight','#91ada1')]:p.select_option('#theme',palette);assert p.evaluate("getComputedStyle(document.body).getPropertyValue('--etch').trim()") == etch
 # Advanced gallery keeps comparison layout static and no duplicate IDs.
 p.locator('#artisan summary').click();p.locator('#border-grid .sample').first.wait_for(state='visible');assert p.locator('#border-grid .sample').count()==4;p.select_option('#panelView','full');assert p.locator('#border-grid [data-module]').count()==0;check('(()=>{const ids=Array.from(document.querySelectorAll("[id]"),e=>e.id);return ids.length===new Set(ids).size})()');p.locator('#artisan summary').click()
 p.set_viewport_size({'width':500,'height':800});assert p.evaluate('document.documentElement.scrollWidth<=innerWidth');btn('arrangeMode');assert p.evaluate('document.documentElement.scrollWidth<=innerWidth');check('!validateLayout(layout,840,480)');assert not errors,errors;assert not requests,requests;b.close()
print('PASS S9r1',flush=True)
