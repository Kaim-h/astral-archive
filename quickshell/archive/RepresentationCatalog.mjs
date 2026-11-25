// Pure representation policy candidate; no filesystem, DOM, Qt or placement mutation.
// Asset identity is independent of file name and user placement. The manifest is loaded by future adapters.
export const pools={
  "artwork": [
    "artwork/moonlit-mountains",
    "artwork/estuary",
    "artwork/celestial-chart",
    "artwork/botanical-study",
    "artwork/arcade",
    "artwork/dusk-dunes"
  ],
  "sculpture": [
    "sculpture/jar",
    "sculpture/seal",
    "sculpture/bottle",
    "sculpture/bowl",
    "sculpture/vase",
    "sculpture/arch",
    "sculpture/jug",
    "sculpture/cup",
    "sculpture/moon",
    "sculpture/owl",
    "sculpture/crock",
    "sculpture/obelisk",
    "sculpture/fox",
    "sculpture/tortoise",
    "sculpture/cat",
    "sculpture/penguin"
  ],
  "record": [
    "record/v1",
    "record/v2",
    "record/v3",
    "record/v4",
    "record/v5",
    "record/v6"
  ],
  "ledger": [
    "ledger/v1",
    "ledger/v2",
    "ledger/v3",
    "ledger/v4",
    "ledger/v5",
    "ledger/v6"
  ],
  "tablet": [
    "tablet/v1",
    "tablet/v2",
    "tablet/v3",
    "tablet/v4",
    "tablet/v5",
    "tablet/v6"
  ],
  "parcel": [
    "parcel/satchel",
    "parcel/parcel",
    "parcel/pouch",
    "parcel/folio",
    "parcel/case",
    "parcel/bundle"
  ]
};
const suffixes={artwork:['png','jpg','jpeg','webp','svg','gif','bmp','tif','tiff','avif','heic','mp4','webm','mov','mkv','avi','ppt','pptx','odp'],sculpture:['obj','stl','glb','gltf','blend','3mf','ply','fbx'],record:['flac','mp3','ogg','wav','m4a','opus','aac','aiff','alac'],ledger:['csv','tsv','xlsx','xls','ods'],tablet:['otf','ttf','woff','woff2','ttc'],parcel:['zip','7z','rar','tar','gz','bz2','xz','zst','tgz','tbz2','txz']};
export function representation(filename){const name=String(filename||'').split(/[\\/]/).pop().toLowerCase();const i=name.lastIndexOf('.');if(i<=0)return 'scroll';const ext=name.slice(i+1);for(const family of Object.keys(suffixes))if(suffixes[family].indexOf(ext)>=0)return family;return 'scroll';}
export function stableHash(id){if(typeof id!=='string'||!id.length)throw Error('Stable file identity required');let h=2166136261;for(let i=0;i<id.length;i++)h=Math.imul(h^id.charCodeAt(i),16777619)>>>0;return h;}
export function chooseVariant(family,id,override){if(family==='scroll')return null;const hash=stableHash(id);const pool=pools[family];if(!pool)throw Error('Unknown family '+family);if(override!=null){if(pool.indexOf(override)<0)throw Error('Invalid variant override');return override;}return pool[hash%pool.length];}
export function resolveAppearance(record){const family=record.compact===true?'scroll':representation(record.name);return {family,variant:chooseVariant(family,record.id,record.variant)};}
// B7r3 frame proportions in study units. Plaque is a separate metadata component.
export function frameGeometry(w,h,profile){if(!Number.isFinite(w)||!Number.isFinite(h)||w<=10||h<=10||['bronze','stone','slim'].indexOf(profile)<0)throw Error('Invalid frame dimensions/profile');const t=profile==='slim'?Math.max(3,w*.045):Math.max(5,w*.075),m=profile==='stone'?t*.65:t*.35,a=t+m;if(w<=2*a||h<=2*a)throw Error('Frame aperture would collapse');const pw=Math.min(68,Math.max(48,w*.36),w-10),ph=Math.min(26,h-10);return {bounds:[0,0,w,h],contact:[w/2,h],mountAnchor:[w/2,0],inset:a,aperture:[a,a,w-2*a,h-2*a],frameThickness:t,revealThickness:m,materialRole:profile==='stone'?'background':'metal',reveal:profile==='stone'?'#776758':profile==='slim'?'#313936':'#b8ae92',shadow:{width:Math.min(10,Math.max(3,w*.055)),slope:Math.min(15,h*.15)},plaque:[w-pw-5,h-ph-5,pw,ph]};}

// Map the SVG coordinate system (including transparent stroke padding) onto a fixture contact.
// Physical bounds and viewBox are intentionally distinct.
export function supportedImage(geometry,x,y,scale,edge=false) {
    const box=edge?geometry.edgeViewport:geometry.viewport, anchor=edge?geometry.edgeContact:geometry.contact;
    if(!box||!anchor||![x,y,scale].every(Number.isFinite)||scale<=0)throw Error('Invalid support transform');
    return {x:x+(box[0]-anchor[0])*scale,y:y+(box[1]-anchor[1])*scale,width:box[2]*scale,height:box[3]*scale};
}
// U3-derived slot geometry. This is a layout helper, not a transaction or collision solver.
// Null entries represent vacancies; fixed-width tester gets its maximum thickness from the caller.
export function uprightLayout(slots,scale,availableWidth,floor,options={}) {
    if(!Array.isArray(slots)||!slots.length||![scale,availableWidth,floor].every(Number.isFinite)||scale<=0||availableWidth<=0)throw Error('Invalid holder dimensions');
    for(const g of slots)if(g!==null&&(!g||!Number.isFinite(g.thickness)||g.thickness<=0||!g.nominal||!Number.isFinite(g.nominal[1])||g.nominal[1]<=0))throw Error('Invalid upright geometry');
    const maxT=Math.max(0,...slots.filter(g=>g!==null).map(g=>g.thickness),Number(options.maxThickness)||0);
    if(maxT<=0)throw Error('Vacant holder requires thickness');
    const widths=slots.map(g=>((options.fixed||!g)?maxT:g.thickness)*scale+12);
    const total=widths.reduce((a,b)=>a+b,0),fit=Math.min(1,availableWidth/total);
    let left=0;
    return {span:total*fit,fit,slots:slots.map((g,i)=>{const width=widths[i]*fit,cx=left+width/2,w=g?g.thickness*scale*fit:0,h=g?g.nominal[1]*scale:0;
        const item={left,width,cx,x:cx-w/2,y:floor-h,w,h};left+=width;return item;})};
}
