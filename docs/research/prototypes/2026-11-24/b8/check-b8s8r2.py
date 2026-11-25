from pathlib import Path
from playwright.sync_api import sync_playwright
import hashlib, json, re, argparse
parser=argparse.ArgumentParser(description="Offline B8s8r2 catalogue regression")
parser.add_argument("--directory",type=Path,default=Path(__file__).resolve().parent)
parser.add_argument("--chromium",default=None)
parser.add_argument("--captures",type=Path,default=None)
args=parser.parse_args()
if args.captures: args.captures.mkdir(parents=True,exist_ok=True)
p=args.directory/'Astral_Archive_Shelf_Replacement_Themes_B8s8r2.html';s=p.read_text(encoding='utf-8')
base=(args.directory/'Astral_Archive_Shelf_Case_Study_B8s7r1.html').read_text(encoding='utf-8')
for k in ('ASSETS','FACES'):
 a=re.search(r'^const '+k+r'=(.*);$',s,re.M)[1];assert a==re.search(r'^const '+k+r'=(.*);$',base,re.M)[1]
 for v in json.loads(a).values():
  raw=v['svg'].encode();assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()==v['sha']
def capture(el,name):
 if args.captures: el.screenshot(path=str(args.captures/name),timeout=15000)

with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path=args.chromium,args=['--no-sandbox']);page=b.new_page(viewport={'width':1366,'height':900},offline=True);err=[];page.on('pageerror',lambda e:err.append(str(e)));requests=[];page.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http://','https://')) else None);page.set_content(s);assert not err,err
 assert page.locator('[data-plate-id]').count()==56
 for family,n in [('bestiary',16),('water',8),('air',8),('earth',8),('fire',8),('horological',8)]:
  page.select_option('#pickerFamily',family);assert page.locator('.emblem-tile').count()==n
  plate=page.locator(f'[data-plate={family}]');capture(plate,f'B8s8r2-{family}.png')
  # select each candidate without browser auto-scroll overhead
  for i in range(n):
   page.locator('.emblem-tile').nth(i).evaluate('(el)=>el.click()');assert page.locator('#selectedBacking [data-emblem]').get_attribute('data-emblem')==page.locator('.emblem-tile').nth(i).get_attribute('data-choice');assert page.locator('#selectedGlass [data-emblem]').count()>0
  print(family,n,flush=True)
 page.select_option('#pickerFamily','bestiary');page.locator('#pickerPrev').click();page.locator('#pickerPrev').click();page.locator('#pickerPrev').click();assert '1–4 of 16'==page.locator('#pickerRange').inner_text()
 for x in ['5–8 of 16','9–12 of 16','13–16 of 16']:
  page.locator('#pickerNext').click();page.wait_for_timeout(100);assert page.locator('#pickerRange').inner_text()==x, (x,page.locator('#pickerRange').inner_text())
 page.locator('[data-plate-id=shell]').evaluate('(el)=>el.click()');assert page.locator('#selectedTitle').inner_text()=='Turtle shell';capture(page.locator('#scene'),'B8s8r2-shelf.png')
 capture(page.locator('#selectedBacking'),'B8s8r2-shell-detail.png')
 page.select_option('#theme','Midnight');assert page.evaluate("getComputedStyle(document.body).getPropertyValue('--etch').trim()")=='#568f80';page.select_option('#theme','Evening');page.select_option('#theme','Twilight')
 page.locator('[data-slot=r1]').click();assert page.locator('[data-presented=r1]').count()==1;page.locator('[data-return]').click();assert page.locator('[data-presented]').count()==0
 page.locator('[data-file=art]').hover();assert page.locator('#info').is_visible();page.keyboard.press('Escape');assert not page.locator('#info').is_visible()
 page.locator('#edit').click();page.locator('#width').focus();page.keyboard.press('End');page.locator('#apply').click();page.locator('#undo').click();assert page.locator('#wo').inner_text()=='840'
 page.locator('#edit').click();page.locator('#artisan summary').click();page.locator('#veil-grid .sample').first.wait_for(state='visible');assert page.locator('#veil-grid .sample').count()>0;page.locator('#artisan summary').click()
 page.set_viewport_size({'width':500,'height':800});assert page.evaluate('document.documentElement.scrollWidth<=innerWidth');assert not err,err
 assert not requests,requests
 print('PASS',flush=True);b.close()
