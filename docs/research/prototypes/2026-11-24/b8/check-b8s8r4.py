from pathlib import Path
from playwright.sync_api import sync_playwright
import hashlib, json, re, argparse
parser=argparse.ArgumentParser(description='Offline B8s8r4 catalogue and shared ornament regression')
parser.add_argument('--directory',type=Path,default=Path(__file__).resolve().parent)
parser.add_argument('--chromium',default=None);parser.add_argument('--captures',type=Path,default=None)
args=parser.parse_args();D=args.directory
s=(D/'Astral_Archive_Shelf_Replacement_Themes_B8s8r4.html').read_text(encoding='utf-8');base=(D/'Astral_Archive_Shelf_Replacement_Themes_B8s8r3.html').read_text(encoding='utf-8')
old=json.loads(re.search(r'^const CATALOGUE=(.*);$',base,re.M)[1]);new=json.loads(re.search(r'^const CATALOGUE=(.*);$',s,re.M)[1]);removed={'hoof','hare','tail','snake'}
assert list(new)==list(old)
assert [(k,[(e['id'],e['name']) for e in v]) for k,v in new.items()]==[(k,[(e['id'],e['name']) for e in v if e['id'] not in removed]) for k,v in old.items()]
assert sum(len(v) for v in new.values())==52
for k,items in new.items():
 for e in items:
  if e['id']!='geode':assert e==next(x for x in old[k] if x['id']==e['id'])
assert next(e for e in new['earth'] if e['id']=='geode')!=next(e for e in old['earth'] if e['id']=='geode')
for k in ('ASSETS','FACES'):
 a=re.search(r'^const '+k+r'=(.*);$',s,re.M)[1];assert a==re.search(r'^const '+k+r'=(.*);$',base,re.M)[1]
 for v in json.loads(a).values():
  raw=v['svg'].encode();assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()==v['sha']
if args.captures:args.captures.mkdir(parents=True,exist_ok=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);p=b.new_page(viewport={'width':1366,'height':900},offline=True);errors=[];requests=[];p.on('pageerror',lambda e:errors.append(str(e)));p.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http://','https://')) else None);p.set_content(s)
 assert p.locator('[data-plate-id]').count()==52
 p.evaluate("$('liveCenter').value='axis';$('liveCenter').dispatchEvent(new Event('change'))")
 p.evaluate("$('liveBorder').value='rails';$('liveBorder').dispatchEvent(new Event('change'))")
 for fam,items in new.items():
  p.select_option('#pickerFamily',fam);assert p.locator('.emblem-tile').count()==len(items)
  secondary=p.locator('#scene [data-secondary]').evaluate_all('(els)=>els.map(e=>e.innerHTML)');assert len(secondary)==2
  assert p.locator('#scene [data-field-border=rails] > g').count()==6
  for i,e in enumerate(items):
   p.locator('.emblem-tile').nth(i).evaluate('(el)=>el.click()');assert p.locator('#scene [data-backing] [data-emblem]').count()==1;assert p.locator('#selectedBacking [data-emblem]').get_attribute('data-emblem')==e['id'];assert p.locator('#scene [data-secondary]').evaluate_all('(els)=>els.map(e=>e.innerHTML)')==secondary;assert p.locator('#selectedGlass [data-emblem]').count()>0
  print(fam,len(items),flush=True)
 if args.captures:
  p.select_option('#pickerFamily','earth');p.locator('[data-choice=geode]').evaluate('(el)=>el.click()');p.locator('#scene').screenshot(path=str(args.captures/'B8s8r4-verified-geode.png'))
  p.select_option('#pickerFamily','fire');p.locator('[data-choice=brazier]').evaluate('(el)=>el.click()');p.locator('#scene').screenshot(path=str(args.captures/'B8s8r4-verified-fire.png'))
 p.select_option('#pickerFamily','bestiary');p.locator('#pickerPrev').click();p.locator('#pickerPrev').click();assert p.locator('#pickerRange').inner_text()=='1–4 of 12'
 for x in ['5–8 of 12','9–12 of 12']:
  p.locator('#pickerNext').click();p.wait_for_timeout(100);assert p.locator('#pickerRange').inner_text()==x
 p.locator('[data-slot=r1]').click();assert p.locator('[data-presented=r1]').count()==1;p.locator('[data-return]').click();assert p.locator('[data-presented]').count()==0
 p.locator('[data-file=art]').hover();assert p.locator('#info').is_visible();p.keyboard.press('Escape');assert not p.locator('#info').is_visible()
 p.locator('#edit').click();p.locator('#width').focus();p.keyboard.press('End');p.locator('#apply').click();p.locator('#undo').click();assert p.locator('#wo').inner_text()=='840';p.locator('#edit').click()
 p.locator('#artisan summary').click();p.locator('#border-grid .sample').first.wait_for(state='visible');assert p.locator('#border-grid .sample').count()==4;p.locator('#artisan summary').click()
 p.set_viewport_size({'width':500,'height':800});assert p.evaluate('document.documentElement.scrollWidth<=innerWidth');assert not errors,errors;assert not requests,requests;b.close()
print('PASS r4',flush=True)
