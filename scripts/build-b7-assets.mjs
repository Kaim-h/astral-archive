// B7-C: pinned-source offline extraction; never imported by runtime.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const refs={
  "artwork": {
    "path": "docs/research/prototypes/2026-11-24/Astral_Archive_Artwork_Study_B7r3.html",
    "sha": "084085e24e767997d89a985cc45a9fb2f4a82a92"
  },
  "sculpture": {
    "path": "docs/research/prototypes/2026-11-24/Astral_Archive_Sculpture_Study_B7s11.html",
    "sha": "0d7f25220df7a3a42c8a07b5a29594c20a5dd20e"
  },
  "upright": {
    "path": "docs/research/prototypes/2026-11-24/Astral_Archive_Upright_Study_B7u3.html",
    "sha": "bccc632e871daabe19464c47a9fd405d2c2998d2"
  },
  "parcel": {
    "path": "docs/research/prototypes/2026-11-24/Astral_Archive_Parcel_Study_B7p10.html",
    "sha": "aefc4cae35dab41a462a207aab5055868f752650"
  }
};
// Frozen Chromium getPointAtLength cross-sections from B7s11. No runtime DOM dependency.
const ringSections={"jar":[{"y":72,"cx":79.62519969454048,"rx":46.201394728289515,"ry":11.550348682072379},{"y":86,"cx":80.22817957897341,"rx":53.720187305799286,"ry":13.430046826449821},{"y":101,"cx":80.47515294933797,"rx":55.28525807461881,"ry":13.821314518654702},{"y":116,"cx":80.23453153570082,"rx":51.785956510737996,"ry":12.946489127684497},{"y":130,"cx":79.87693782232606,"rx":44.31378790650588,"ry":11.07844697662647}],"bottle":[{"y":43,"cx":80,"rx":13,"ry":3.7142857142857144},{"y":65,"cx":80.29813357309686,"rx":20.089205433236458,"ry":5.739772980924703},{"y":84,"cx":80.43827274342767,"rx":40.986631680038755,"ry":11.710466194296787},{"y":99,"cx":80.5832909012657,"rx":47.248360688028384,"ry":13.499531625150967},{"y":114,"cx":80.74118008820102,"rx":47.46475803765116,"ry":13.561359439328907},{"y":130,"cx":80.6798878473546,"rx":42.01528278684802,"ry":12.004366510528005}],"bowl":[{"y":103,"cx":79.99999999076105,"rx":58.46085622662257,"ry":12.458870999116284},{"y":115,"cx":79.99999749666554,"rx":54.78705734995837,"ry":11.67593025490916},{"y":127,"cx":80.00000527792143,"rx":48.774339512428256,"ry":10.394531371501104},{"y":138,"cx":79.99998251768221,"rx":39.44361576806473,"ry":8.406016475161335}],"vase":[{"y":50,"cx":79.99996468487655,"rx":21.2314483867196,"ry":4.6155322579825215},{"y":72,"cx":79.39809589690981,"rx":35.06720117451597,"ry":7.6233046031556455},{"y":88,"cx":79.17970842428119,"rx":43.676089095118144,"ry":9.494801977199597},{"y":103,"cx":79.90439073706058,"rx":46.90155331194104,"ry":10.195989850421965},{"y":118,"cx":81.05948801971108,"rx":44.867422153478344,"ry":9.753787424669206},{"y":132,"cx":81.88983776383947,"rx":37.788830241056885,"ry":8.21496309588193}],"jug":[{"y":50,"cx":80.00000687739876,"rx":25.103447220155456,"ry":5.578543826701212},{"y":73,"cx":80.00000409838147,"rx":36.32366132737006,"ry":8.07192473941557},{"y":88,"cx":80.00000374962815,"rx":45.50952654487412,"ry":10.113228121083138},{"y":103,"cx":80.00003426806914,"rx":50.00553651832349,"ry":11.11234144851633},{"y":118,"cx":79.99990479825925,"rx":49.40198064835971,"ry":10.978217921857713},{"y":132,"cx":79.99994065844507,"rx":43.34562948436022,"ry":9.632362107635604}],"cup":[{"y":82,"cx":79.99999938403951,"rx":40.13333323327128,"ry":7.6444444253850055},{"y":96,"cx":79.9999990790518,"rx":38.50000078495091,"ry":7.333333482847793},{"y":110,"cx":79.99999885382582,"rx":36.866667039146186,"ry":7.022222293170702},{"y":124,"cx":79.99999928441437,"rx":35.23333366123274,"ry":6.711111173568141},{"y":136,"cx":80.21376372953969,"rx":31.967837764735254,"ry":6.089111955187668}],"crock":[{"y":65,"cx":79.9999972137123,"rx":45.64245864705807,"ry":8.29862884491965},{"y":79,"cx":80.00000034795161,"rx":46.61268675463971,"ry":8.475033955389039},{"y":93,"cx":79.99999765405806,"rx":47.08796618293893,"ry":8.561448396897987},{"y":107,"cx":79.99999553407562,"rx":46.99807601542862,"ry":8.54510473007793},{"y":121,"cx":79.9999951409895,"rx":46.25457252928939,"ry":8.409922278052617},{"y":134,"cx":79.99992782671016,"rx":44.24577443377713,"ry":8.04468626068675}]};
const parcelBounds={"satchel":[22,30,138.0625,140],"parcel":[19.2,60.5,139.4,140],"pouch":[26.6364,20,137.6539,140],"folio":[23,69,139,140],"case":[21,56.7143,139,140],"bundle":[18.9333,47,141.2857,140]};
function build(source, ringSections, parcelBounds, refs){
 const slice=(s,a,b)=>{const i=s.indexOf(a),j=s.indexOf(b,i+a.length);if(i<0||j<0)throw Error("Missing extraction marker "+a+" / "+b);return s.slice(i,j)};
 const js=Object.fromEntries(Object.entries(source).map(([k,v])=>[k,slice(v,"<script>","</script>").slice(8)]));
 // Trusted, pinned repository sources only; no browser UI or filesystem code is evaluated.
 const a=new Function(slice(js.artwork,"const motifs=","const sample=")+slice(js.artwork,"function drawing(","function icon(")+"return {motifs,drawing};")();
 const s=new Function("ringSections",slice(js.sculpture,"const bodies=","const svgNS=")+slice(js.sculpture,"function throwingRings(","function cube(")+"return {files,shapes,art,bodyNames,glazeNames};")(ringSections);
 const u=new Function(slice(js.upright,"const specs=","const esc=")+slice(js.upright,"const path=","function icon(")+slice(js.upright,"function edge(","function visible(")+"return {files,edge,face};")();
 const p=new Function(slice(js.parcel,"const files=","let selected=")+slice(js.parcel,"function packet(","function icon(")+"return {files,art};")();
 const ud=slice(js.upright,"<defs>","</defs>")+"</defs>";
 const output={},catalog={};
 const wrap=(box,art)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box.join(" ")}" width="${box[2]}" height="${box[3]}">${art}</svg>\n`;
 const add=(family,id,label,material,geometry,face,edge)=>{const key=family+"/"+id;if(catalog[key])throw Error("Duplicate "+key);const facePath=key+".svg";output[facePath]=wrap(geometry.viewport,face);const item={id:key,family,label,material,face:facePath,geometry};if(edge){const edgePath=key+"-edge.svg";output[edgePath]=wrap(geometry.edgeViewport,edge);item.edge=edgePath;}catalog[key]=item;};
 const artIds=["moonlit-mountains","estuary","celestial-chart","botanical-study","arcade","dusk-dunes"];
 a.motifs.forEach((name,i)=>add("artwork",artIds[i],name,"Symbolic illustration",{viewport:[0,0,100,100],bounds:[0,0,100,100],contact:null,fit:"slice"},a.drawing(i)));
 const stoneBounds={seal:[4,68,153,160],penguin:[28,27,132,160],fox:[14,69,150,160],tortoise:[14,64,157,160],cat:[14,28,150,160]};
 for(const f of s.files){const b=f.clay?s.shapes[f.shape].bounds:(stoneBounds[f.shape]||[28,20,132,160]);add("sculpture",f.shape,f.title,s.bodyNames[f.body]+(f.glaze?" / "+s.glazeNames[f.glaze]:f.clay?" / Unglazed":""),{viewport:[-8,-8,176,176],bounds:b,contact:[80,160],nominal:[160,160],boundsKind:"reference selection envelope"},s.art(f,"asset"));}
 for(const f of u.files.filter(f=>Number(f.id.split("-")[1])<6)){const {w,h,t}=f;add(f.family,"v"+(f.variant+1),f.family+" "+(f.variant+1),f.family==="record"?"Grooved record":f.family==="ledger"?"Bound ledger":"Engraved stone",{viewport:[-2,-2,w+4,h+4],bounds:[0,0,w,h],contact:[w/2,h],nominal:[w,h],thickness:t,edgeViewport:[-2,-2,t+4,h+4],edgeBounds:[0,0,t,h],edgeContact:[t/2,h],accent:f.accent,body:f.color},ud+u.face(f,0,0,1),ud+u.edge(f,0,0,t,h));}
 for(const f of p.files)add("parcel",f.id,f.form,f.material,{viewport:[-3,-3,166,146],bounds:parcelBounds[f.id],contact:[80,140],nominal:[160,140],boundsKind:"sampled SVG geometric envelope, stroke excluded"},p.art(f,"asset"));
 const manifest={schema:1,source:refs,assets:catalog};
 output["manifest.json"]=JSON.stringify(manifest,null,2)+"\n";
 return output;
}
const source={};
for(const [k,ref] of Object.entries(refs)){const bytes=fs.readFileSync(path.join(root,ref.path));const sha=crypto.createHash('sha1').update('blob '+bytes.length+String.fromCharCode(0)).update(bytes).digest('hex');if(sha!==ref.sha)throw Error('Reference changed: '+ref.path+' '+sha);source[k]=bytes.toString('utf8');}
const out=build(source,ringSections,parcelBounds,refs),dir=path.join(root,'quickshell/archive/representation-assets');
const write=process.argv.includes('--write');
for(const [name,content] of Object.entries(out)){const dest=path.join(dir,name);if(write){fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,content);}else if(fs.readFileSync(dest,'utf8')!==content)throw Error('Asset drift: '+name);}
console.log((write?'Generated ':'Verified ')+Object.keys(out).length+' files from four pinned references');
