from pathlib import Path
import argparse,re,json,hashlib
from playwright.sync_api import sync_playwright
ap=argparse.ArgumentParser();ap.add_argument('--directory',type=Path,default=Path(__file__).resolve().parent);ap.add_argument('--chromium');ap.add_argument('--captures',type=Path);a=ap.parse_args();D=a.directory
s=(D/'Astral_Archive_Shelf_Study_B8s11.html').read_text();base=(D/'Astral_Archive_Shelf_Study_B8s10r1.html').read_text()
for k in ('ASSETS','FACES','CATALOGUE','INITIAL'):
 if k=='INITIAL':continue
 assert re.search(r'^const '+k+r'=(.*);$',s,re.M)[1]==re.search(r'^const '+k+r'=(.*);$',base,re.M)[1],k
if a.captures:a.captures.mkdir(exist_ok=True,parents=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path=a.chromium,args=['--no-sandbox']);p=b.new_page(viewport={'width':1366,'height':900},offline=True);p.set_default_timeout(6000);errors=[];requests=[];p.on('pageerror',lambda e:errors.append(e.message));p.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);p.set_content(s)
 def chk(js):assert p.evaluate(js),js
 def btn(id):p.locator('#'+id).click()
 def cap(name):
  if a.captures:p.screenshot(path=str(a.captures/('B8s11-'+name+'.png')))
 def menu(label):p.get_by_role('menuitem',name=label,exact=True).click()
 def main(label):btn('mainMenu');menu(label)
 def right(sel,label):p.locator(sel).click(button='right');menu(label)
 def tab(name):p.get_by_role('tab',name=name,exact=True).click()
 def drag(kind,dx,dy):
  aa,bb=p.evaluate('''([k,dx,dy])=>{let r=scene.querySelector('[data-resize="'+k+'"] rect:last-child'),x=+r.getAttribute('x')+3.5,y=+r.getAttribute('y')+3.5,m=scene.getScreenCTM(),f=(x,y)=>{let p=new DOMPoint(x,y).matrixTransform(m);return[p.x,p.y]};return[f(x,y),f(x+dx,y+dy)]}''',[kind,dx,dy]);p.mouse.move(*aa);p.mouse.down();p.mouse.move(*bb,steps=7);p.mouse.up()
 chk('!validateLayout(layout,840,480)&&!validateOwnership(layout,caseRecords)');assert not p.locator('#pane').is_visible() and not p.locator('#transactionBar').is_visible();cap('browse')
 # Metadata and presentation retained, including actual visible hover, not hidden vault.
 p.locator('#scene [data-file=art]').hover();assert p.locator('#info').is_visible();p.keyboard.press('Escape');assert not p.locator('#info').is_visible();p.locator('#scene [data-slot=r1]').click();assert p.locator('#scene [data-presented=r1]').count()==1;p.locator('#scene [data-return]').click()
 right('#scene [data-file=art]','File information');assert 'Moonlit.png' in p.locator('#pane').inner_text();p.keyboard.press('Escape')
 # Context menu keyboard navigation and outside dismiss.
 p.locator('#scene [data-cubby=manuscripts]').focus();p.keyboard.press('Shift+F10');assert p.locator('#contextMenu').is_visible();p.keyboard.press('ArrowDown');p.keyboard.press('Escape');assert not p.locator('#contextMenu').is_visible()
 btn('mainMenu');cap('menu');p.keyboard.press('Escape')
 main('Appearance…');cap('appearance');p.select_option('#pickerFamily','fire');p.locator('#pane [data-choice=brazier]').click();chk('appearanceDirty()');tab('Material');p.locator('#shelfNameInput').fill('Test & Archive');p.locator('#shelfNameInput').press('Tab');chk("shelfName==='Test & Archive'");p.select_option('#theme','Midnight');tab('Glazing');p.select_option('#glassEmblem','voyage');tab('Ornament');p.get_by_role('button',name='Artisan workshop').click();p.select_option('#liveBorder','rails');p.select_option('#liveCenter','axis');chk('appearanceDirty()');cap('workshop');p.keyboard.press('Escape');assert not p.locator('#pane').is_visible();chk('appearanceDirty()');btn('discardPending');chk("!appearanceDirty()&&$('motif').value==='astral'&&shelfName==='The Western Collection'&&$('theme').value==='Twilight'&&liveBorder==='ornate'&&liveCenter==='seal'")
 # Outside click does not activate underlying cubby or commit.
 main('Appearance…');p.select_option('#pickerFamily','fire');orig=p.evaluate('JSON.stringify(open)');p.mouse.click(1050,450);assert not p.locator('#pane').is_visible();chk('appearanceDirty()');assert p.evaluate('JSON.stringify(open)')==orig;btn('resumePending');btn('appApply');chk("$('motif').value==='fire'&&!appearanceDirty()")
 # All retained primary choices select through the actual scroll picker.
 main('Appearance…');tab('Ornament');catalogue=json.loads(re.search(r'^const CATALOGUE=(.*);$',s,re.M)[1]);count=0
 for f,entries in catalogue.items():
  p.select_option('#pickerFamily',f)
  for e in entries:
   p.locator('#pane [data-choice="'+e['id']+'"]').evaluate('el=>el.click()');assert p.locator('#scene [data-backing] [data-emblem]').get_attribute('data-emblem')==e['id'];count+=1
 assert count==76;btn('appCancel');chk("$('motif').value==='fire'")
 # Envelope transaction with dismissed pane and undo.
 main('Shelf dimensions…');p.locator('#width').focus();p.keyboard.press('End');chk('draft.w===1100&&committed.w===840');p.keyboard.press('Escape');btn('resumePending');btn('apply');chk('committed.w===1100&&draft===null');main('Shelf dimensions…');btn('undo');chk('committed.w===840');p.keyboard.press('Escape')
 # Arrange mode contextual controls, actual selected handles and support-preserving resize.
 btn('arrangeMode');right('#scene [data-module=rack]','Dimensions and cells…');assert p.locator('#cellRadius').is_visible();cap('rack');p.locator('#arrH').fill('115');btn('arrUpdate');p.keyboard.press('Escape');chk('layoutDraft!==null&&findNode(layout,"rack").h===105');btn('arrCancel');chk('layoutDraft===null')
 p.locator('#scene [data-module=rack]').click();cap('arrange');drag('height',0,-10);chk('findNode(layoutDraft,"rack").h===115&&findNode(layoutDraft,"records").z===115&&findNode(layoutDraft,"records").h===125');btn('arrCancel');drag('cell',-8*.866,0);chk('findNode(layoutDraft,"rack").cellR===18&&JSON.stringify(findNode(layoutDraft,"rack").records)===JSON.stringify(findNode(layout,"rack").records)');btn('arrCancel')
 main('Grid and snapping…');p.select_option('#gridStep','20');p.locator('#gridVisible').uncheck();chk('JSON.stringify(layout)===JSON.stringify(INITIAL)');p.select_option('#gridStep','10');p.locator('#gridVisible').check();p.keyboard.press('Escape')
 # Contextual creation and explicit evacuation. Reopen after dismissal.
 main('Add furniture…');p.select_option('#addKind','cubby');p.select_option('#addSupport','floor');p.locator('#addX').fill('600');btn('addConfirm');chk('activeLayout().length===13');btn('arrCancel');chk('activeLayout().length===12')
 right('#scene [data-module=rack]','Remove…');assert 'dependent' in p.locator('#removeSummary').inner_text();p.keyboard.press('Escape');chk('layoutDraft===null');right('#scene [data-module=rack]','Remove…');btn('removeConfirm');chk('layoutDraft!==null&&activeCase().length>0&&caseRecords.length===0');btn('arrApply');chk('caseRecords.length>0&&!validateOwnership(layout,caseRecords)');btn('caseButton');assert p.locator('#caseItems').is_visible();cap('case');p.keyboard.press('Escape');btn('arrUndo');chk('caseRecords.length===0&&JSON.stringify(layout)===JSON.stringify(INITIAL)');btn('arrangeMode')
 p.set_viewport_size({'width':500,'height':800});main('Appearance…');assert p.evaluate('document.documentElement.scrollWidth<=innerWidth');cap('narrow');p.keyboard.press('Escape');assert not p.locator('#pane').is_visible();assert not errors,errors;assert not requests,requests;print('PASS S11: 76 emblems, contextual menus, transactions, metadata, resize, creation, evacuation, narrow viewport, offline');b.close()
