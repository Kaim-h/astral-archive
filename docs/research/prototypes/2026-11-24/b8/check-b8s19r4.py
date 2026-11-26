"""S19r4 contour study; no layout/door changes, offline Chromium."""
import argparse,hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--chromium',default='/usr/bin/chromium');p.add_argument('--captures',type=Path);p.add_argument('--baseline',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parent
base=a.baseline or root.parent/'s19r3-release'/'Astral_Archive_Map_Room_Study_B8s19r3.html'
raw=base.read_bytes();assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()=='95a7cbedc813d407a8e27a0b584da36904c1f67f'
old=raw.decode();new=(root/'Astral_Archive_Map_Room_Study_B8s19r4.html').read_text()
assert old[:old.index('// Stable world-coordinate isocontours')].replace('S19r3','S19r4').replace('B8s19r3','B8s19r4').replace('STUDY 19r3','STUDY 19r4').replace('Study 19r3','Study 19r4')==new[:new.index('// Synthetic terrain adapted')]
assert old[old.index('function shelfPlanSymbol'):].replace('S19r3','S19r4').replace('B8s19r3','B8s19r4').replace('STUDY 19r3','STUDY 19r4').replace('Study 19r3','Study 19r4')==new[new.index('function shelfPlanSymbol'):]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path=a.chromium,args=['--no-sandbox']);q=b.new_page(viewport={'width':1440,'height':900},offline=True,reduced_motion='reduce');errors=[];requests=[];q.on('pageerror',lambda e:errors.append(str(e)));q.on('request',lambda r:requests.append(r.url) if r.url.startswith(('http:','https:')) else None);q.set_content(new)
 def cap(n):
  if a.captures:a.captures.mkdir(exist_ok=True,parents=True);q.screenshot(path=a.captures/(n+'.png'))
 def geom():return q.evaluate('()=>{let m=__mapStudy.model();return {rooms:m.rooms,doors:m.doors}}')
 def menu():q.locator('#mainMenu').click();q.get_by_role('menuitem',name='Appearance…',exact=True).click()
 orig=geom(); group=q.locator('[data-contour-source]');assert group.count()==1
 sample=q.evaluate('[terrain(0,0),terrain(100,200),terrain(-900,1800)]');assert all(isinstance(v,float) for v in sample)
 for t in ['Twilight','Evening','Midnight']:
  q.locator('#theme').select_option(t);assert geom()==orig;cap(t)
 q.locator('#theme').select_option('Twilight');cap('overview')
 q.evaluate('__mapStudy.zoom(4)');assert int(group.get_attribute('data-contour-stride'))>=4;assert q.locator('[data-contour-level]').count()>0;cap('wide')
 assert q.evaluate('[terrain(0,0),terrain(100,200),terrain(-900,1800)]')==sample
 q.evaluate('__mapStudy.fit()');q.evaluate('__mapStudy.zoom(.45)');cap('near');assert int(group.get_attribute('data-contour-stride'))==2
 q.evaluate('__mapStudy.fit()');menu();q.locator('#contours').select_option('engraved');q.locator('#density').fill('95');assert int(group.get_attribute('data-contour-stride'))==1;q.locator('#close').click();cap('engraved')
 menu();q.locator('#contours').select_option('none');assert not group.count();q.keyboard.press('Escape');assert group.count()==1
 assert geom()==orig and not q.evaluate('__mapStudy.valid(__mapStudy.model())');assert not errors,errors;assert not requests,requests
 print('PASS exact non-contour source; themes, zoom LOD, deterministic world samples, density, none, Escape, unchanged geometry, offline');b.close()
