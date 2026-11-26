from playwright.sync_api import sync_playwright
from pathlib import Path
import hashlib, json, re, argparse
# Run from any directory with Python Playwright and a Chromium installation.
parser=argparse.ArgumentParser(description='Offline B8s3 browser regression')
parser.add_argument('--directory',type=Path,default=Path(__file__).resolve().parent)
parser.add_argument('--chromium',default=None,help='Optional system Chromium executable')
parser.add_argument('--captures',type=Path,default=None,help='Optional screenshot output directory')
args=parser.parse_args()
p=args.directory/'Astral_Archive_Shelf_Study_B8s3.html'; html=p.read_text(encoding='utf-8'); old=(args.directory/'Astral_Archive_Shelf_Study_B8s2.html').read_text(encoding='utf-8')

assert re.search(r'^const ASSETS=(.*);$',html,re.M)[1]==re.search(r'^const ASSETS=(.*);$',old,re.M)[1]
expected_faces={'record/v1':'6337dd85df8ab4c8cace2eda9486c3e315bf088f','ledger/v1':'a3710fa41d11e79ac1130756d3efa01911aee139','tablet/v1':'b9f2305e72b54b20dbe3eee3bc33c0c041683696'}
assert {k:v['sha'] for k,v in json.loads(re.search(r'^const FACES=(.*);$',html,re.M)[1]).items()}==expected_faces
for name in ('ASSETS','FACES'):
 for id,a in json.loads(re.search(r'^const '+name+r'=(.*);$',html,re.M)[1]).items():
  b=a['svg'].encode(); assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==a['sha'],id
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path=args.chromium); page=browser.new_page(viewport={'width':1366,'height':900},offline=True); errs=[]; page.on('pageerror',lambda e:errs.append(str(e))); page.set_content(html); assert not errs,errs
 page.locator('#allOpen').click(); assert page.locator('[data-mode=open]').count()==3; assert page.locator('[data-cubby] [data-slot],[data-cubby] [data-file]').count()==0
 assert page.locator('[data-presented=l1] image[data-view=face]').count()==1; assert page.locator('[data-slot=l1] image').count()==0
 for id in ['r1','t1','r2','l1']:
  slot=page.locator(f'[data-slot={id}]'); slot.click(); assert page.locator(f'[data-presented={id}] image[data-view=face]').count()==1; assert slot.locator('image').count()==0; assert page.locator('[data-slot] image').count()==3
  assert page.evaluate('''async()=>{const im=new Image();im.src=document.querySelector('[data-presented] image').getAttribute('href');await im.decode();return im.naturalWidth>100}''')
 page.locator('[data-return]').click(); assert page.locator('[data-presented]').count()==0; assert page.locator('[data-slot] image').count()==4
 page.locator('[data-slot=l1]').focus();page.keyboard.press('Enter'); assert page.locator('[data-presented=l1]').count()==1
 for id in ['jar','owl','parcel','letters','art','l1']:
  el=page.locator(f'[data-file={id}]');el.hover(); assert page.locator('#info').is_visible(),id;assert 'Synthetic study entry' in page.locator('#info').inner_text(); page.keyboard.press('Escape');assert not page.locator('#info').is_visible()
 for id in ['jar','art']:
  page.locator(f'[data-file={id}]').focus();assert page.locator('#info').is_visible();page.keyboard.press('Escape');assert not page.locator('#info').is_visible()
 for theme in ['Twilight','Evening','Midnight']:
  page.select_option('#theme',theme)
  for profile in ['crest','cornice','pilaster']:
   page.select_option('#profile',profile)
   for motif in ['astral','cartographic','botanical','plain']:
    page.select_option('#motif',motif);assert page.locator('[data-backing]').count()==(motif!='plain');assert page.locator('[data-cubby]').count()==3
 page.select_option('#theme','Twilight');page.select_option('#profile','crest');page.select_option('#motif','astral')
 page.locator('#edit').click();page.locator('#width').focus();page.keyboard.press('Home');page.locator('#height').focus();page.keyboard.press('Home'); assert page.locator('#wo').inner_text()=='700' and page.locator('#ho').inner_text()=='440';page.locator('#edit').click();page.locator('#edit').click();assert page.locator('#wo').inner_text()=='700';page.locator('#apply').click();page.locator('#undo').click();assert page.locator('#wo').inner_text()=='840' and page.locator('#ho').inner_text()=='480'
 page.locator('#width').focus();page.keyboard.press('End');page.locator('#cancel').click();assert page.locator('#wo').inner_text()=='840';page.locator('#edit').click();page.locator('#guides').click();assert page.locator('#guides').get_attribute('aria-pressed')=='true';page.locator('#guides').click()
 cubby=page.locator('[data-cubby=manuscripts]');
 for mode in ['veiled','inventory','closed','open']:
  cubby.click();assert cubby.get_attribute('data-mode')==mode
 page.locator('#allClosed').click();assert page.locator('[data-mode=closed]').count()==3;page.locator('#allOpen').click()
 page.mouse.move(0,0);page.locator('#allOpen').focus();
 if args.captures:
  args.captures.mkdir(parents=True,exist_ok=True);page.screenshot(path=str(args.captures/'B8s3-preview.png'),full_page=True)
 page.locator('[data-file=art]').hover();assert page.locator('#info').is_visible()
 if args.captures:page.screenshot(path=str(args.captures/'B8s3-metadata.png'),full_page=False)
 page.set_viewport_size({'width':500,'height':750});assert page.evaluate('document.documentElement.scrollWidth<=innerWidth');page.locator('[data-file=art]').hover();box=page.locator('#info').bounding_box();assert box['x']>=0 and box['x']+box['width']<=500 and box['y']>=0 and box['y']+box['height']<=750
 assert not errs,errs
 print('PASS: 10 asset hashes; actual offline render; all four upright identities, single presentation and return; 6 plaque hover targets, keyboard and Escape; 36 theme/profile/motif combinations; four cubby modes; resize apply/cancel/undo, narrow viewport; zero page errors.')
 browser.close()
b=p.read_bytes();print('blob',hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(), 'bytes',len(b))
