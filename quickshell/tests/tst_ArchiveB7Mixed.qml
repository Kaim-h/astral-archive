import QtQuick
import QtTest
import "../archive/ArchiveCore.mjs" as Core
import "ArchiveB7MixedFixture.mjs" as Mixed

Item {
    id:root
    width:1366;height:900
    ArchiveNativeN2Study {id:study;anchors.fill:parent;initialSnapshot:Mixed.fixture()}
    TestCase {
        name:"ArchiveB7Mixed"
        when:windowShown
        function init(){
            study.scene.abortGesture()
            study.closeContext();study.closeMaterials();study.rackInspector=false
            study.controller.reset(Mixed.fixture())
            study.scene.caseDock.pinned=false;study.scene.caseDock.hoverOpen=false;study.scene.caseDock.dismissed=false
            study.scene.motion.notice="";study.scene.message=""
            study.scene.viewPath=["root"];study.scene.mode="browse"
            study.scene.zoom=1;study.scene.pan=Qt.point(0,0);study.scene.clearSelection()
        }
        function click(item){
            verify(!!item)
            var last=""
            tryVerify(function(){
                if(!item.visible||!item.enabled||item.width<=0||item.height<=0)return false
                var p=item.mapToItem(study,item.width/2,item.height/2),next=[p.x,p.y,item.width,item.height].join(",")
                var ok=last===next&&p.x>=0&&p.y>=0&&p.x<study.width&&p.y<study.height;last=next;return ok
            })
            mouseClick(item,item.width/2,item.height/2)
        }
        function test_camera_lifecycle(){
            var scene=study.scene,ctl=study.controller
            var command={kind:"create",type:"cubby",cubbyId:"root",patch:{x:10,y:500,w:160,h:120}}
            function create(){
                verify(ctl.proposeStructure(command));verify(ctl.applyStructure())
                return ctl.snapshot.cubbies.root.mods.find(m=>m.type==="cubby"&&m.x===10&&m.y===500)
            }
            var before=JSON.stringify(ctl.snapshot),child=create(),id=child.childId
            verify(scene.openChild(id));scene.zoom=1.45;scene.pan=Qt.point(31,-17)
            verify(scene.back())
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            child=create();compare(child.childId,id)
            verify(scene.openChild(id));compare(scene.zoom,1);compare(scene.pan,Qt.point(0,0))
            scene.zoom=1.35;scene.pan=Qt.point(-23,19)
            var created=JSON.stringify(ctl.snapshot)
            verify(ctl.proposeStructure({kind:"delete",cubbyId:"root",moduleId:child.id}))
            verify(ctl.applyStructure());tryCompare(scene,"cubbyId","root")
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),created)
            verify(scene.openChild(id));compare(scene.zoom,1.35);compare(scene.pan,Qt.point(-23,19))
            var view=study.checkpointView(),payload=ctl.exportCheckpoint(view)
            verify(payload.length>0)
            var restored=ctl.importCheckpoint(payload);verify(!!restored)
            scene.viewPath=restored.path.slice();scene.cameras=restored.cameras;scene.restoreCamera()
            compare(scene.cubbyId,id);compare(scene.zoom,1.35);compare(scene.pan,Qt.point(-23,19))
            compare(JSON.stringify(ctl.snapshot),created);compare(ctl.archiveState.history.length,0)
        }
        function test_imported_camera_identity(){
            var scene=study.scene,ctl=study.controller,sample=Core.fixture()
            sample.cubbies.root.mods.push({id:"import-child",type:"cubby",x:520,y:0,w:160,h:120,childId:"toString"})
            sample.cubbies.toString={id:"toString",w:470,h:340,mods:[]}
            compare(Core.validate(sample),null)
            ctl.reset(sample)
            var payload=ctl.exportCheckpoint({path:["root","toString"],theme:0,cameras:{}})
            verify(payload.length>0)
            var restored=ctl.importCheckpoint(payload);verify(!!restored)
            scene.viewPath=restored.path.slice();scene.cameras=restored.cameras;scene.restoreCamera()
            compare(scene.cubbyId,"toString");compare(scene.zoom,1);compare(scene.pan,Qt.point(0,0))
            scene.zoom=1.4;scene.pan=Qt.point(31,-17)
            verify(scene.back());verify(scene.openChild("toString"))
            compare(scene.zoom,1.4);compare(scene.pan,Qt.point(31,-17))
            var saved=ctl.exportCheckpoint(study.checkpointView());verify(saved.length>0)
            var view=ctl.importCheckpoint(saved);verify(!!view)
            scene.viewPath=view.path.slice();scene.cameras=view.cameras;scene.restoreCamera()
            compare(scene.zoom,1.4);compare(scene.pan,Qt.point(31,-17))
        }
        function test_maximum_cradle_reservation(){
            var scene=study.scene,ctl=study.controller,sample=Core.fixture()
            sample.cubbies.root.w=1400;sample.cubbies.root.h=800
            sample.cubbies.root.mods.push({id:"max-scale-board",type:"shelf",x:540,y:400,w:397,h:15,items:[
                {kind:"holder",id:"max-holder",x:0,w:130,scale:1.3,slots:[{id:"max-audio",name:"Max.flac",r:13,representation:"record",variant:"record/v1"}]}
            ]})
            compare(Core.validate(sample),null);ctl.reset(sample)
            var shelf=scene.moduleItem("max-scale-board")
            tryVerify(function(){shelf=scene.moduleItem("max-scale-board");return !!shelf})
            var holder=findChild(shelf,"holder-max-holder"),cradle=findChild(shelf,"cradle-max-holder")
            verify(!!holder&&!!cradle);compare(cradle.width,251)
            click(findChild(holder,"b7-slot-0"));tryCompare(cradle,"imageStatus",Image.Ready)
            verify(cradle.facePlacement.box.x>=2)
            verify(cradle.facePlacement.box.x+cradle.facePlacement.box.width<=cradle.width-2)
        }
        function test_case_return_to_mixed_origin(){
            var scene=study.scene,ctl=study.controller,before=Core.clone(ctl.snapshot)
            var jar=findChild(scene.moduleItem("mixed-board"),"mixed-jar")
            click(jar);tryCompare(scene,"selectedScrollId","mixed-jar")
            scene.forceActiveFocus();keyClick(Qt.Key_X,Qt.ControlModifier)
            tryVerify(function(){return ctl.snapshot.caseItems.some(r=>r.id==="mixed-jar")&&!scene.busy})
            var carried=ctl.snapshot.caseItems.find(r=>r.id==="mixed-jar")
            compare(carried.originModuleId,"mixed-board");compare(carried.originPlacement.support,"plinth")
            compare(carried.variant,"sculpture/jar")
            scene.caseDock.pinned=true
            tryVerify(function(){return !!findChild(scene.caseDock,"scroll-mixed-jar")})
            click(findChild(scene.caseDock,"scroll-mixed-jar"))
            tryCompare(scene,"selectedScrollId","mixed-jar")
            click(findChild(study,"case-return-origin"))
            tryVerify(function(){return !scene.busy&&Core.owners(ctl.snapshot).find(e=>e.id==="mixed-jar").where==="shelf"})
            var entry=ctl.snapshot.cubbies.root.mods.find(m=>m.id==="mixed-board").items.find(e=>e.kind==="object"&&e.record.id==="mixed-jar")
            compare(entry.x,90);compare(entry.scale,.86);compare(entry.support,"plinth")
            compare(entry.record.variant,"sculpture/jar")
            verify(ctl.undo());verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),JSON.stringify(before))
            scene.caseDock.pinned=false;scene.caseDock.hoverOpen=false
        }
        function test_mixed_render_and_holder(){
            var scene=study.scene,before=JSON.stringify(study.controller.snapshot)
            var shelf=scene.moduleItem("mixed-board"),mount=scene.moduleItem("mixed-art")
            tryVerify(function(){return !!shelf&&!!mount&&!!findChild(shelf,"mixed-jar")})
            var jar=findChild(shelf,"mixed-jar")
            tryCompare(jar,"imageStatus",Image.Ready)
            click(jar);tryCompare(scene,"selectedScrollId","mixed-jar")
            click(mount);tryCompare(scene,"selectedScrollId","mixed-picture")
            var holder=findChild(shelf,"holder-mixed-upright")
            var slot=findChild(holder,"b7-slot-0")
            click(slot)
            tryCompare(holder,"selectedId","mixed-audio")
            var cradle=findChild(shelf,"cradle-mixed-upright")
            tryCompare(cradle,"imageStatus",Image.Ready)
            compare(JSON.stringify(study.controller.snapshot),before)
            mouseMove(study,2,2);wait(150)
            grabImage(study).save("archive-b7-native-mixed-presented.png")
            keyClick(Qt.Key_Escape);tryCompare(holder,"selectedId","")
            slot.forceActiveFocus();keyClick(Qt.Key_Space);keyClick(Qt.Key_Right);keyClick(Qt.Key_Return)
            tryVerify(function(){return Core.owners(study.controller.snapshot).find(e=>e.id==="mixed-audio").slot===1})
            compare(study.controller.archiveState.history.length,1)
            verify(study.controller.undo());compare(JSON.stringify(study.controller.snapshot),before)
            scene.clearSelection();mouseMove(study,2,2);wait(150)
            grabImage(study).save("archive-b7-native-mixed.png")
        }
        // Verify the actual composited scene, not a separately grabbed
        // transformed delegate or one pixel which may fall on an ink line.
        // Save the exact image being tested even if its color check fails.
        function captureMotionCue(cue,filename){
            verify(!!cue&&cue.visible)
            verify(study.scene.motion.busy)
            var pixels=grabImage(study)
            verify(pixels.width>0&&pixels.height>0)
            pixels.save(filename)
            var a=cue.mapToItem(study,cue.width*.25,cue.height*.25)
            var b=cue.mapToItem(study,cue.width*.75,cue.height*.75)
            var left=Math.max(0,Math.ceil(a.x*pixels.width/study.width))
            var right=Math.min(pixels.width-1,Math.floor(b.x*pixels.width/study.width))
            var top=Math.max(0,Math.ceil(a.y*pixels.height/study.height))
            var bottom=Math.min(pixels.height-1,Math.floor(b.y*pixels.height/study.height))
            verify(right>left&&bottom>top,"Cue must occupy an on-screen region")
            var color=cue.parchmentColor,matched=0,total=0
            for(var y=top;y<=bottom;y++)for(var x=left;x<=right;x++){
                var r=pixels.red(x,y),g=pixels.green(x,y),bl=pixels.blue(x,y)
                // Allow the existing 0.85 provisional opacity over the dark
                // backing, antialiasing and fine engraved marks. An empty
                // outline or the dark shelf/rack background cannot qualify.
                if(Math.abs(r-color.r*255)<=42&&Math.abs(g-color.g*255)<=42&&
                   Math.abs(bl-color.b*255)<=42)matched++
                total++
            }
            verify(matched>total*.5,"Parchment pixels "+matched+"/"+total+" in "+filename+
                " at "+left+","+top+"–"+right+","+bottom)
            verify(study.scene.motion.busy)
        }
        function test_provisional_mixed_rendering(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot)
            var rack=scene.moduleItem("rack-1"),m=Core.rackAt(ctl.snapshot,"root","rack-1")
            var c=Core.geometry(m).cells.find(q=>q.area>14000&&!(m.scrollCells[q.key]||[]).length)
            verify(!!c)
            var target=rack.mapToItem(scene,c.cx,c.cy)
            var jar=findChild(scene.moduleItem("mixed-board"),"mixed-jar")
            var start=jar.mapToItem(scene,jar.width/2,jar.height/2)
            mousePress(scene,start.x,start.y,Qt.LeftButton)
            mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
            tryCompare(scene,"pointerActive",true)
            tryCompare(jar,"suppressed",true);compare(jar.opacity,0);verify(jar.visible)
            verify(findChild(scene,"carry-ghost").visible)
            compare(JSON.stringify(ctl.snapshot),before)
            captureMotionCue(findChild(findChild(scene,"carry-ghost"),"scroll-mixed-jar"),"archive-b7-native-aud17-carry.png")
            keyClick(Qt.Key_Escape);mouseRelease(scene,target.x,target.y,Qt.LeftButton)
            tryCompare(scene,"busy",false);tryCompare(jar,"suppressed",false)
            compare(JSON.stringify(ctl.snapshot),before)
            mousePress(scene,start.x,start.y,Qt.LeftButton)
            mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
            tryCompare(jar,"suppressed",true)
            mouseRelease(scene,target.x,target.y,Qt.LeftButton)
            verify(scene.motion.busy);verify(scene.motion.released)
            compare(jar.opacity,0);verify(!findChild(scene,"carry-ghost").visible)
            verify(!!scene.moduleItem("rack-1").scrollItem("mixed-jar"))
            compare(JSON.stringify(ctl.snapshot),before)
            captureMotionCue(scene.moduleItem("rack-1").scrollItem("mixed-jar"),"archive-b7-native-aud17-settling-rack.png")
            tryCompare(scene.motion,"busy",false,15000)
            compare(Core.owners(ctl.snapshot).find(e=>e.id==="mixed-jar").where,"rack")
            var packed=JSON.stringify(ctl.snapshot),glyph=scene.moduleItem("rack-1").scrollItem("mixed-jar")
            var board=scene.moduleItem("mixed-lower")
            start=glyph.mapToItem(scene,glyph.width/2,glyph.height/2)
            target=board.mapToItem(scene,200,board.supportY-4)
            mousePress(scene,start.x,start.y,Qt.LeftButton)
            mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
            tryCompare(scene,"pointerActive",true)
            mouseRelease(scene,target.x,target.y,Qt.LeftButton)
            verify(scene.motion.busy);verify(scene.motion.released)
            var pending=findChild(scene,"pending-mixed-mixed-jar")
            verify(!!pending&&pending.visible)
            verify(!scene.moduleItem("rack-1").scrollItem("mixed-jar"))
            verify(!findChild(board,"mixed-jar"))
            compare(JSON.stringify(ctl.snapshot),packed)
            captureMotionCue(pending,"archive-b7-native-aud17-settling-shelf.png")
            tryCompare(scene.motion,"busy",false,15000)
            tryVerify(function(){return !!findChild(scene.moduleItem("mixed-lower"),"mixed-jar")})
            verify(!findChild(scene,"pending-mixed-mixed-jar"))
            compare(Core.owners(ctl.snapshot).find(e=>e.id==="mixed-jar").where,"shelf")
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),packed)
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            var mount=scene.moduleItem("mixed-art"),face=findChild(mount,"mixed-mount-frame-mixed-picture")
            verify(!!face);start=face.mapToItem(scene,face.width/2,face.height/2)
            rack=scene.moduleItem("rack-1");target=rack.mapToItem(scene,c.cx,c.cy)
            mousePress(scene,start.x,start.y,Qt.LeftButton)
            mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
            tryCompare(face,"suppressed",true);compare(face.opacity,0);verify(face.visible)
            compare(JSON.stringify(ctl.snapshot),before)
            mouseRelease(scene,target.x,target.y,Qt.LeftButton)
            verify(scene.motion.busy);compare(face.opacity,0)
            scene.abortGesture();tryCompare(face,"suppressed",false)
            compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,0)
        }
        function test_direct_mixed_drag(){
            var scene=study.scene,before=JSON.stringify(study.controller.snapshot)
            var jar=findChild(scene.moduleItem("mixed-board"),"mixed-jar"),board=scene.moduleItem("mixed-lower")
            verify(!!jar&&!!board)
            var start=jar.mapToItem(scene,jar.width/2,jar.height/2)
            var target=board.mapToItem(scene,200,board.supportY-4)
            mousePress(scene,start.x,start.y,Qt.LeftButton)
            mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
            tryCompare(scene,"pointerActive",true)
            compare(JSON.stringify(study.controller.snapshot),before)
            mouseRelease(scene,target.x,target.y,Qt.LeftButton)
            tryVerify(function(){return Core.owners(study.controller.snapshot).find(e=>e.id==="mixed-jar").moduleId==="mixed-lower"})
            compare(study.controller.archiveState.history.length,1)
            verify(study.controller.undo())
            compare(JSON.stringify(study.controller.snapshot),before)
            // Attempt overlap with the parcel, then drop outside every fixture.
            jar=findChild(scene.moduleItem("mixed-board"),"mixed-jar")
            start=jar.mapToItem(scene,jar.width/2,jar.height/2)
            board=scene.moduleItem("mixed-board")
            target=board.mapToItem(scene,285,board.supportY-4)
            mousePress(scene,start.x,start.y,Qt.LeftButton)
            mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
            mouseRelease(scene,target.x,target.y,Qt.LeftButton)
            tryCompare(scene,"busy",false)
            compare(JSON.stringify(study.controller.snapshot),before)
            compare(study.controller.archiveState.history.length,0)
            verify(!scene.pointer)
        }
        function test_rack_compaction_roundtrip(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot)
            function owner(){return Core.owners(ctl.snapshot).find(e=>e.id==="mixed-jar")}
            function drag(start,target){
                mousePress(scene,start.x,start.y,Qt.LeftButton)
                mouseMove(scene,target.x,target.y,40,Qt.LeftButton)
                tryCompare(scene,"pointerActive",true)
                mouseRelease(scene,target.x,target.y,Qt.LeftButton)
                tryCompare(scene.motion,"busy",false,15000)
            }
            var jar=findChild(scene.moduleItem("mixed-board"),"mixed-jar")
            verify(!!jar)
            var rack=scene.moduleItem("rack-1"),m=Core.rackAt(ctl.snapshot,"root","rack-1")
            var c=Core.geometry(m).cells.find(q=>q.area>14000&&!(m.scrollCells[q.key]||[]).length)
            verify(!!c)
            drag(jar.mapToItem(scene,jar.width/2,jar.height/2),rack.mapToItem(scene,c.cx,c.cy))
            compare(owner().where,"rack");compare(owner().key,c.key)
            compare(owner().scroll.variant,"sculpture/jar");verify(owner().scroll.compact!==true)
            compare(ctl.archiveState.history.length,1)
            tryVerify(function(){return !!scene.moduleItem("rack-1").scrollItem("mixed-jar")})
            var packed=JSON.stringify(ctl.snapshot)
            scene.clearSelection();mouseMove(study,2,2);wait(150)
            grabImage(study).save("archive-b7-native-mixed-compacted.png")
            var glyph=scene.moduleItem("rack-1").scrollItem("mixed-jar"),board=scene.moduleItem("mixed-lower")
            drag(glyph.mapToItem(scene,glyph.width/2,glyph.height/2),board.mapToItem(scene,200,board.supportY-4))
            compare(owner().where,"shelf");compare(owner().moduleId,"mixed-lower")
            compare(owner().scroll.variant,"sculpture/jar")
            tryVerify(function(){return !!findChild(scene.moduleItem("mixed-lower"),"mixed-jar")})
            tryCompare(findChild(scene.moduleItem("mixed-lower"),"mixed-jar"),"imageStatus",Image.Ready)
            compare(ctl.archiveState.history.length,2)
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),packed)
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
        }
        function test_contextual_fixtures(){
            var scene=study.scene,before=JSON.stringify(study.controller.snapshot)
            scene.mode="arrange"
            var lower=scene.moduleItem("mixed-lower")
            mouseClick(lower,180,lower.supportY+5,Qt.RightButton)
            tryCompare(scene,"selectedModuleId","mixed-lower")
            click(findChild(study,"add-holder"))
            tryVerify(function(){return study.controller.structuralProposal&&study.controller.structuralProposal.ok})
            compare(JSON.stringify(study.controller.snapshot),before)
            click(findChild(study,"structure-apply"))
            tryVerify(function(){return !study.controller.structuralProposal})
            var board=study.controller.snapshot.cubbies.root.mods.find(m=>m.id==="mixed-lower")
            verify(board.items.some(e=>e.kind==="holder"))
            verify(study.controller.undo());compare(JSON.stringify(study.controller.snapshot),before)
            var mount=scene.moduleItem("mixed-art")
            mouseClick(mount,mount.width/2,mount.height/2,Qt.RightButton)
            tryCompare(scene,"selectedModuleId","mixed-art")
            click(findChild(study,"edit-artwork"))
            click(findChild(study,"mount-profile-slim"))
            tryVerify(function(){return study.controller.structuralProposal&&study.controller.structuralProposal.ok})
            compare(JSON.stringify(study.controller.snapshot),before)
            click(findChild(study,"structure-apply"))
            tryVerify(function(){return study.controller.snapshot.cubbies.root.mods.find(m=>m.id==="mixed-art").profile==="slim"})
            verify(study.controller.undo());compare(JSON.stringify(study.controller.snapshot),before)
            var holder=findChild(scene.moduleItem("mixed-board"),"holder-mixed-upright")
            mouseClick(holder,holder.width/2,holder.height/2,Qt.RightButton)
            tryCompare(scene,"selectedHolderId","mixed-upright")
            click(findChild(study,"delete-holder"))
            tryVerify(function(){return study.controller.structuralProposal&&study.controller.structuralProposal.caseTransferCount===2})
            compare(JSON.stringify(study.controller.snapshot),before)
            click(findChild(study,"structure-cancel"))
            compare(JSON.stringify(study.controller.snapshot),before)
            // Reopen and actually confirm the occupied holder-only evacuation.
            holder=findChild(scene.moduleItem("mixed-board"),"holder-mixed-upright")
            mouseClick(holder,holder.width/2,holder.height/2,Qt.RightButton)
            tryCompare(scene,"selectedHolderId","mixed-upright")
            click(findChild(study,"delete-holder"))
            tryVerify(function(){return study.controller.structuralProposal&&study.controller.structuralProposal.caseTransferCount===2})
            click(findChild(study,"structure-apply"))
            tryVerify(function(){return !study.controller.structuralProposal})
            var owners=Core.owners(study.controller.snapshot)
            for(var id of ["mixed-audio","mixed-font"]){
                var entry=owners.find(e=>e.id===id)
                compare(entry.where,"case");verify(entry.scroll.originStale)
                compare(entry.scroll.originHolderId,"mixed-upright")
            }
            compare(owners.find(e=>e.id==="mixed-jar").where,"shelf")
            compare(owners.find(e=>e.id==="mixed-parcel").where,"shelf")
            compare(owners.length,Core.owners(JSON.parse(before)).length)
            verify(study.controller.undo())
            compare(JSON.stringify(study.controller.snapshot),before)
        }
        function test_shelf_rearrangement(){
            var before=JSON.stringify(study.controller.snapshot)
            study.scene.mode="arrange"
            var shelf=study.scene.moduleItem("mixed-lower")
            var owl=findChild(shelf,"mixed-owl")
            verify(!!owl)
            mouseClick(owl,owl.width/2,owl.height/2,Qt.RightButton)
            tryCompare(study.scene,"selectedModuleId","mixed-lower")
            click(findChild(study,"edit-shelf"))
            var command=Core.clone(study.controller.structuralProposal.command)
            command.patch.w=600
            verify(!study.controller.proposeStructure(command))
            click(findChild(study,"shelf-suggest"))
            tryVerify(function(){return study.controller.structuralProposal&&study.controller.structuralProposal.ok})
            compare(JSON.stringify(study.controller.snapshot),before)
            click(findChild(study,"structure-cancel"))
            compare(JSON.stringify(study.controller.snapshot),before)
            verify(!study.controller.proposeStructure(command))
            click(findChild(study,"shelf-suggest"))
            click(findChild(study,"structure-apply"))
            tryVerify(function(){return !study.controller.structuralProposal})
            var board=study.controller.snapshot.cubbies.root.mods.find(m=>m.id==="mixed-lower")
            compare(board.w,600);verify(board.items[0].x<680)
            verify(study.controller.undo());compare(JSON.stringify(study.controller.snapshot),before)
        }
    }
}
