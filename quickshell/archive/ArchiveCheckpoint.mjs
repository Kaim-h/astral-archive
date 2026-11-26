// Native synthetic checkpoint codec. V2 adds mixed ownership without rewriting v1.
import * as Core from "./ArchiveCore.mjs";
import * as Capacity from "./ArchiveCapacity.mjs";
import * as Spatial from "./ArchiveSpatial.mjs";
// Legacy writers retained; adopted physical profiles use distinct v4.
export const version=2;
export const spatialVersion=3;
export const physicalProfileVersion=4;
export const independentProfileVersion=5;
function fail(msg){throw Error(msg);}
function plain(v){return !!v&&typeof v==='object'&&!Array.isArray(v);}
function finite(v,min,max){return Number.isFinite(v)&&v>=min&&v<=max;}
function preflight(s,v){
 Capacity.preflight(s,v);
 const err=Core.validate(s);if(err)fail(err);
}
function viewState(s,v,formatVersion=version){
 if(!plain(v)||!Capacity.pathValid(s,v.path)||!Number.isInteger(v.theme)||v.theme<0||v.theme>2||!plain(v.cameras))fail('Invalid view metadata');
 // Optional v1 view-only field. Older checkpoints retain the default
 // veiled mode when restored; never rewrite their snapshot.
 if(v.cubbyPreviewMode!==undefined&&!['veiled','inventory','closed'].includes(v.cubbyPreviewMode))fail('Invalid cubby preview mode');
 if(v.roomPerspective!==undefined&&typeof v.roomPerspective!=='boolean')fail('Invalid Room projection preference');
 if(v.snapEnabled!==undefined&&typeof v.snapEnabled!=='boolean')fail('Invalid snapping preference');
 if(v.showGrid!==undefined&&typeof v.showGrid!=='boolean')fail('Invalid grid visibility');
 if(v.snapDistance!==undefined&&(!Number.isInteger(v.snapDistance)||v.snapDistance<5||v.snapDistance>100))fail('Invalid grid interval');
 if(Object.keys(v.cameras).length>128)fail('Camera budget');
 for(const [k,c] of Object.entries(v.cameras))if(!Object.prototype.hasOwnProperty.call(s.cubbies,k)||!plain(c)||!finite(c.zoom,.5,2.5)||!finite(c.x,-100000,100000)||!finite(c.y,-100000,100000))fail('Invalid camera');
 if(formatVersion>=2&&JSON.stringify(v).length>Capacity.limits.viewChars)fail('View size budget exceeded');
 return Core.clone(v);
}
export function encode(session,view){
 if(session.draft)fail('Finish pending rack proposal');
 const formatVersion=Spatial.checkpointVersion(session.snapshot);
 preflight(session.snapshot,formatVersion);const v=viewState(session.snapshot,view,formatVersion);
 const value=JSON.stringify({format:'astral-archive-native-study',version:formatVersion,snapshot:session.snapshot,view:v});
 if(value.length>Capacity.limits.envelopeChars)fail('Checkpoint too large');return value;
}
export function decode(text){
 if(typeof text!=='string'||!text.length||text.length>Capacity.limits.envelopeChars)fail('Invalid checkpoint length');
 const envelope=JSON.parse(text);
 if(!plain(envelope)||envelope.format!=='astral-archive-native-study'||![1,version,spatialVersion,physicalProfileVersion,independentProfileVersion].includes(envelope.version))fail('Unsupported native checkpoint');
 if(envelope.version===1&&text.length>Capacity.limits.legacyChars)fail('Invalid legacy checkpoint length');
 preflight(envelope.snapshot,envelope.version);const view=viewState(envelope.snapshot,envelope.view,envelope.version);
 return {snapshot:Core.clone(envelope.snapshot),view};
}
