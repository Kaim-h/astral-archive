import QtQuick
import QtTest
import "../themes" as Themes
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveSpatial.mjs" as Spatial
import "ArchiveB8ShelfFixture.mjs" as Sample
import "../archive/ArchiveView.mjs" as View
import "../archive/ArchiveRoomProjection.mjs" as Projection

Item {
    width:1366;height:900
    ArchiveNativeN2Study {id:study;anchors.fill:parent;spatialEnabled:true;physicalProfilesEnabled:true;initialSnapshot:Sample.fixture()}
    // Same isolated SQLite database across distinct QML storage objects;
    // unique per test invocation, never the standalone study's database.
    ArchiveStudyStorage {id:preferenceWriter;databaseName:"AstralArchive.Test.B8.Preference."+Date.now()}
    ArchiveStudyStorage {id:preferenceReader;databaseName:preferenceWriter.databaseName}
    TestCase {
        name:"ArchiveB8Shelf"
        when:windowShown
        function init(){study.abortRoomNavigation();study.reducedRoomMotion=true;study.roomPlanOpen=false;study.roomPerspective=false;study.scene.abortGesture();study.closeContext();study.closeMaterials();study.controller.reset(Sample.fixture());study.scene.mode="browse";study.scene.zoom=1;study.scene.pan=Qt.point(0,0);study.scene.clearSelection()}
        function clickNamed(name){
            var item=null,last=""
            tryVerify(function(){
                item=findChild(study,name)
                if(!item||!item.visible||!item.enabled||item.width<=0||item.height<=0)return false
                var point=item.mapToItem(study,item.width/2,item.height/2)
                var next=[point.x,point.y,item.width,item.height].join(",")
                var ok=last===next&&point.x>=0&&point.x<study.width&&point.y>=0&&point.y<study.height
                last=next;return ok
            },3000,name)
            var trace=study.mapNavigationDiagnostics&&(name==="open-map-room"||name==="toggle-room-plan")
            if(trace)study.traceMapNavigation("before pointer "+name)
            mouseClick(item,item.width/2,item.height/2)
            if(trace)study.traceMapNavigation("after pointer "+name)
        }
        function test_room_navigation_motion(){
            var ctl=study.controller,scene=study.scene
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront})
            var roomId=ctl.snapshot.spatial.shelves.root.roomId
            verify(ctl.proposeStructure({kind:"spatialRoomEdit",roomId:roomId,patch:{w:1800,h:2000}}));verify(ctl.applyStructure())
            verify(ctl.proposeStructure({kind:"spatialShelfEdit",containerId:"root",patch:{w:1450,h:1100,depth:185,orientation:90}}));verify(ctl.applyStructure())
            verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:"root",patch:{profile:"crest"}}));verify(ctl.applyStructure())
            var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
            scene.zoom=1.15;scene.pan=Qt.point(12,-9)
            clickNamed("toggle-room-plan")
            var plan=findChild(study,"archive-room-plan")
            tryVerify(function(){return plan.visible&&!study.roomNavigating})
            study.reducedRoomMotion=false
            for(var perspective=0;perspective<2;perspective++){
                if(perspective)clickNamed("toggle-room-perspective")
                plan.selectedShelf="root"
                // Actual input starts the transition, locks both arrangement
                // surfaces and keeps the same selected root and camera.
                var button=findChild(study,"plan-inspect-shelf")
                mouseClick(button,button.width/2,button.height/2)
                verify(study.roomNavigating)
                verify(!scene.enabled&&!plan.enabled)
                verify(!study.viewSwitchReady&&!study.checkpointReady)
                verify(!study.navigateRoom("root",true))
                tryVerify(function(){return study.roomProgress>=.25&&study.roomProgress<.60})
                grabImage(study).save("archive-b8-native-shelf-navigation-"+perspective+".png")
                if(perspective)keyClick(Qt.Key_Escape)
                else {
                    var skip=findChild(study,"room-navigation-skip")
                    mouseClick(skip,skip.width/2,skip.height/2)
                }
                tryVerify(function(){return !study.roomNavigating&&scene.visible&&!plan.visible})
                compare(scene.cubbyId,"root");compare(scene.zoom,1.15);compare(scene.pan,Qt.point(12,-9))
                compare(scene.frontEnvelope.w,Spatial.shelfGeometry(ctl.snapshot,"root").w)
                verify(!!findChild(scene,"archive-book-org.example.Reader"))
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                // Reverse animation completes normally.
                clickNamed("toggle-room-plan")
                tryVerify(function(){return !study.roomNavigating&&plan.visible&&!scene.visible})
                compare(plan.perspective,!!perspective);compare(plan.selectedShelf,"root")
                compare(JSON.stringify(ctl.snapshot),before)
            }
            clickNamed("plan-inspect-shelf")
            tryVerify(function(){return !study.roomNavigating&&scene.visible&&!plan.visible})
            clickNamed("toggle-room-plan")
            tryVerify(function(){return !study.roomNavigating&&plan.visible&&!scene.visible})
            study.reducedRoomMotion=true
            clickNamed("plan-inspect-shelf")
            verify(!study.roomNavigating);tryVerify(function(){return scene.visible&&!plan.visible})
            compare(scene.zoom,1.15);compare(scene.pan,Qt.point(12,-9))
            compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
        }
        function test_room_toolbar_reservation(){
            var ctl=study.controller,scene=study.scene,tools=findChild(study,"archive-primary-tools")
            verify(!!tools)
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront&&tools.height>=tools.implicitHeight})
            var original=study.parent.width
            try{
                for(var w of [1366,740]){
                    // Resize the test root; keep the study's fill binding.
                    study.parent.width=w
                    var last=""
                    tryVerify(function(){
                        var key=[tools.width,tools.height,tools.implicitHeight,scene.y,scene.height].join(",")
                        var stable=last===key;last=key
                        return stable&&tools.width===w-20&&tools.height>=tools.implicitHeight&&tools.height===study.reservedToolbarHeight(tools)
                    })
                    var h=scene.height,y=scene.y,bar=tools.height
                    console.log("B8 reserved viewport",w,"toolbar",bar,"scene",y,h)
                    clickNamed("toggle-room-plan")
                    var plan=findChild(study,"archive-room-plan")
                    tryVerify(function(){return plan.visible&&!scene.visible})
                    wait(50);compare(tools.height,bar);compare(scene.height,h);compare(scene.y,y)
                    clickNamed("toggle-room-perspective")
                    wait(50);compare(tools.height,bar);compare(scene.height,h);compare(scene.y,y)
                    clickNamed("toggle-room-plan")
                    tryVerify(function(){return scene.visible&&!plan.visible})
                    wait(50);compare(tools.height,bar);compare(scene.height,h);compare(scene.y,y)
                }
            }finally{study.parent.width=original;study.roomPlanOpen=false}
        }
        function test_map_room_navigation(){
            var ctl=study.controller,scene=study.scene,original=study.parent.width
            study.mapEnabled=true
            study.mapNavigationDiagnostics=true
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var s=ctl.snapshot,before=JSON.stringify(s),history=ctl.archiveState.history.length
                var rootRoom=s.spatial.shelves.root.roomId
                var empty=Object.keys(s.spatial.rooms).find(function(id){return !Object.values(s.spatial.shelves).some(function(p){return p.roomId===id})})
                verify(!!empty)
                var map=findChild(study,"archive-map-room"),plan=findChild(study,"archive-room-plan")
                var mapButton=findChild(study,"open-map-room"),perspectiveButton=findChild(study,"toggle-room-perspective")
                var roomButton=findChild(study,"toggle-room-plan"),rootButton=findChild(study,"open-shelf-root")
                verify(!!mapButton&&!!perspectiveButton&&!!roomButton&&!!rootButton)
                function buttonCenter(button){return button.mapToItem(study,button.width/2,button.height/2)}
                clickNamed("open-map-room")
                tryVerify(function(){return map.visible&&!plan.visible&&!scene.visible})
                verify(!mapButton.visible&&!mapButton.enabled&&!roomButton.visible&&!roomButton.enabled&&!perspectiveButton.visible&&!perspectiveButton.enabled&&!rootButton.enabled)
                grabImage(study).save("archive-b8-native-shelf-map-overview.png")
                clickNamed("map-zoom-in")
                verify(map.zoom>1)
                var zoom=map.zoom,center=JSON.stringify(map.center)
                var r=s.spatial.rooms[empty],pt=map.pointFor(r.x+r.w/2,r.y+r.h/2)
                // Use a visible point after zoom; fit if necessary.
                if(pt.x<0||pt.x>=map.width||pt.y<0||pt.y>=map.height){clickNamed("map-fit");zoom=map.zoom;center=JSON.stringify(map.center);pt=map.pointFor(r.x+r.w/2,r.y+r.h/2)}
                compare(map.hit(pt.x,pt.y),empty)
                mouseDoubleClickSequence(map,pt.x,pt.y,Qt.LeftButton)
                tryVerify(function(){return plan.visible&&!map.visible&&!scene.visible})
                compare(plan.roomId,empty);compare(plan.planData.shelves.length,0)
                verify(!findChild(study,"toggle-room-plan").enabled)
                grabImage(study).save("archive-b8-native-shelf-map-empty-room.png")
                clickNamed("toggle-room-perspective")
                tryVerify(function(){return !!plan.visibilityRaster})
                compare(plan.roomId,empty)
                clickNamed("open-map-room")
                tryVerify(function(){return map.visible&&!plan.visible})
                compare(map.selectedRoom,empty);compare(map.zoom,zoom);compare(JSON.stringify(map.center),center)
                clickNamed("map-fit")
                r=s.spatial.rooms[rootRoom];pt=map.pointFor(r.x+r.w/2,r.y+r.h/2)
                mouseClick(map,pt.x,pt.y);compare(map.selectedRoom,rootRoom)
                clickNamed("map-enter-room")
                tryVerify(function(){return plan.visible&&plan.perspective})
                compare(plan.roomId,rootRoom)
                clickNamed("toggle-room-perspective")
                var b=Spatial.footprint(s,"root");pt=plan.pointFor(b.x+b.w/2,b.y+b.h/2)
                mouseDoubleClickSequence(plan,pt.x,pt.y,Qt.LeftButton)
                tryVerify(function(){return scene.visible&&!plan.visible&&!map.visible})
                compare(scene.cubbyId,"root")
                // Real nested-Cubby input, then the direct upper-layer path.
                clickNamed("cubby-cubby-child");tryCompare(scene,"cubbyId","child")
                clickNamed("toggle-room-plan");tryVerify(function(){return plan.visible&&plan.activeFocus})
                compare(plan.roomId,rootRoom);compare(plan.selectedShelf,"root")
                clickNamed("toggle-room-plan");tryVerify(function(){return scene.visible&&scene.activeFocus})
                compare(scene.cubbyId,"root")
                var shelfMapCenter=buttonCenter(mapButton),shelfPlanCenter=buttonCenter(roomButton)
                verify(!perspectiveButton.visible&&!perspectiveButton.enabled)
                clickNamed("toggle-room-plan");tryVerify(function(){return plan.visible})
                compare(plan.roomId,rootRoom);compare(plan.selectedShelf,"root")
                // Check immediately after the real layer change, before any
                // extra event-loop wait: navigation controls must not reflow.
                compare(buttonCenter(mapButton),shelfMapCenter)
                compare(buttonCenter(roomButton),shelfPlanCenter)
                var projectionCenter=buttonCenter(perspectiveButton)
                verify(Math.abs(projectionCenter.x-shelfMapCenter.x)>=(mapButton.width+perspectiveButton.width)/2||
                    Math.abs(projectionCenter.y-shelfMapCenter.y)>=(mapButton.height+perspectiveButton.height)/2)
                verify(!rootButton.enabled)
                try{
                    clickNamed("open-map-room");tryVerify(function(){return map.visible})
                    verify(!study.roomPerspective)
                }finally{
                    study.traceMapNavigation("final populated Room return")
                    if(!map.visible)grabImage(study).save("archive-b8-native-shelf-map-return-failure.png")
                }
                study.parent.width=740;tryVerify(function(){return map.width===740})
                grabImage(study).save("archive-b8-native-shelf-map-narrow.png")
                clickNamed("map-enter-room");tryVerify(function(){return plan.visible&&!map.visible})
                compare(plan.roomId,rootRoom)
                verify(!rootButton.enabled&&!study.roomPerspective)
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&!plan.visible})
                verify(!study.roomPerspective)
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                ctl.reset(Sample.fixture())
                tryVerify(function(){return !map.visible&&!plan.visible&&scene.visible})
            }finally{study.mapNavigationDiagnostics=false;study.mapEnabled=false;study.parent.width=original;study.roomPlanOpen=false;study.roomPerspective=false}
        }
        function test_map_room_arrangement(){
            var ctl=study.controller,scene=study.scene
            study.mapEnabled=true;study.mapNavigationDiagnostics=true
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                var originalRooms=Object.keys(ctl.snapshot.spatial.rooms)
                var map=findChild(study,"archive-map-room")
                clickNamed("open-map-room");tryVerify(function(){return map.visible})
                var nav=findChild(map,"map-navigation-actions"),fit=findChild(map,"map-fit"),add=findChild(map,"map-add-room")
                var oldFit=fit.mapToItem(map,fit.width/2,fit.height/2)
                verify(!add.visible&&!add.enabled)
                study.switchMode("arrange")
                compare(fit.mapToItem(map,fit.width/2,fit.height/2),oldFit)
                verify(add.visible&&add.enabled)
                var addPoint=add.mapToItem(map,add.width/2,add.height/2)
                verify(addPoint.y+add.height/2<nav.y+nav.parent.y)
                try{
                    clickNamed("map-add-room")
                    tryVerify(function(){return !!ctl.structuralProposal},3000,"Add Room click must produce a proposal")
                    verify(ctl.structuralProposal.ok,ctl.structuralProposal.error)
                }finally{
                    console.log("B8 map arrangement first click",JSON.stringify({point:addPoint,mode:scene.mode,ready:study.viewSwitchReady,selected:map.selectedRoom,proposal:ctl.structuralProposal?ctl.structuralProposal.command:null,error:ctl.structuralProposal?ctl.structuralProposal.error:"No proposal"}))
                    if(!ctl.structuralProposal||!ctl.structuralProposal.ok)grabImage(study).save("archive-b8-native-shelf-map-arrangement-failure.png")
                }
                compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("map-add-room");clickNamed("structure-apply")
                var id=Object.keys(ctl.snapshot.spatial.rooms).find(k=>!originalRooms.includes(k))
                verify(!!id);compare(map.selectedRoom,id)
                clickNamed("map-edit-room")
                var input=findChild(study,"map-room-input-w");verify(!!input)
                input.forceActiveFocus();keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace)
                for(var digit of "10")keyClick(digit)
                tryVerify(function(){return !ctl.structuralProposal.ok});verify(!findChild(study,"structure-apply").enabled)
                input.forceActiveFocus();keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace)
                for(var digit of "900")keyClick(digit)
                tryVerify(function(){return ctl.structuralProposal.ok})
                clickNamed("structure-apply");compare(ctl.snapshot.spatial.rooms[id].w,900)
                verify(ctl.undo());verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                var empty=Object.keys(ctl.snapshot.spatial.rooms).find(k=>!Object.values(ctl.snapshot.spatial.shelves).some(p=>p.roomId===k))
                var r=ctl.snapshot.spatial.rooms[empty],pt=map.pointFor(r.x+r.w/2,r.y+r.h/2),end=map.pointFor(r.x+r.w/2+200,r.y+r.h/2)
                mousePress(map,pt.x,pt.y,Qt.LeftButton);tryVerify(function(){return map.dragging})
                mouseMove(map,end.x,end.y,20,Qt.LeftButton);tryVerify(function(){return !!map.dragPatch})
                compare(JSON.stringify(ctl.snapshot),before);verify(!ctl.structuralProposal)
                keyClick(Qt.Key_Escape);tryVerify(function(){return !map.dragging})
                mouseRelease(map,end.x,end.y,Qt.LeftButton);verify(!ctl.structuralProposal)
                mousePress(map,pt.x,pt.y,Qt.LeftButton);mouseMove(map,end.x,end.y,20,Qt.LeftButton);mouseRelease(map,end.x,end.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&!ctl.structuralProposal.ok})
                compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("map-room-resolve-doors");tryVerify(function(){return ctl.structuralProposal.ok})
                verify(ctl.structuralProposal.removedDoorIds.length===1)
                clickNamed("structure-apply");verify(!Object.keys(ctl.snapshot.spatial.doors).length)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                map.selectedRoom=empty
                clickNamed("map-delete-room");tryVerify(function(){return !!ctl.structuralProposal&&!ctl.structuralProposal.ok})
                clickNamed("map-room-resolve-doors");clickNamed("structure-apply")
                verify(!ctl.snapshot.spatial.rooms[empty]);verify(ctl.undo())
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
            }finally{study.mapNavigationDiagnostics=false;study.mapEnabled=false;study.switchMode("browse")}
        }
        function test_map_room_resize_and_grid(){
            var ctl=study.controller,scene=study.scene,originalWidth=study.parent.width
            var oldSnap=scene.snapEnabled,oldGrid=scene.showGrid,oldInterval=scene.snapDistance
            study.mapEnabled=true
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                var map=findChild(study,"archive-map-room")
                clickNamed("open-map-room");tryVerify(function(){return map.visible})
                study.switchMode("arrange");scene.snapEnabled=false;scene.showGrid=false;scene.snapDistance=20
                clickNamed("map-grid");verify(map.showGrid&&!map.snapEnabled)
                clickNamed("map-snap");verify(map.showGrid&&map.snapEnabled)
                clickNamed("map-grid");verify(!map.showGrid&&map.snapEnabled)
                clickNamed("map-snap-interval");compare(map.snapDistance,25)
                clickNamed("map-magnetic");verify(!map.magnetic)
                var empty=Object.keys(ctl.snapshot.spatial.rooms).find(k=>!Object.values(ctl.snapshot.spatial.shelves).some(p=>p.roomId===k))
                var r=ctl.snapshot.spatial.rooms[empty],pt=map.pointFor(r.x+r.w/2,r.y+r.h/2)
                mouseClick(map,pt.x,pt.y);compare(map.selectedRoom,empty)
                var handle=findChild(map,"map-room-resize-handle")
                verify(handle.visible&&handle.width>=22)
                var corner=handle.mapToItem(map,handle.width/2,handle.height/2)
                var end=map.pointFor(r.x+r.w-100,r.y+r.h)
                var frame=JSON.stringify(map.camera)
                mousePress(map,corner.x,corner.y,Qt.LeftButton);tryVerify(function(){return map.dragging})
                mouseMove(map,end.x,end.y,20,Qt.LeftButton);tryVerify(function(){return !!map.dragPatch})
                compare(JSON.stringify(map.camera),frame);compare(map.dragPatch.w,r.w-100)
                compare(JSON.stringify(ctl.snapshot),before);verify(!ctl.structuralProposal)
                scene.forceActiveFocus();tryVerify(function(){return !map.dragging})
                mouseRelease(map,end.x,end.y,Qt.LeftButton);verify(!ctl.structuralProposal)
                mousePress(map,corner.x,corner.y,Qt.LeftButton);mouseMove(map,end.x,end.y,20,Qt.LeftButton)
                mouseRelease(map,end.x,end.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                compare(ctl.structuralProposal.command.patch.w,r.w-100)
                grabImage(study).save("archive-b8-native-shelf-map-resize-preview.png")
                clickNamed("structure-apply")
                compare(ctl.snapshot.spatial.rooms[empty].w,r.w-100)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                // North edge: a perpendicular-only drag must be a true no-op.
                clickNamed("map-focus");verify(!!map.focusState)
                var north=findChild(map,"map-room-resize-n");tryVerify(function(){return north.visible})
                var n=north.mapToItem(map,north.width/2,north.height/2)
                var sideways=map.pointFor(r.x+r.w/2+100,r.y)
                mousePress(map,n.x,n.y,Qt.LeftButton);mouseMove(map,sideways.x,sideways.y,20,Qt.LeftButton)
                mouseRelease(map,sideways.x,sideways.y,Qt.LeftButton)
                verify(!ctl.structuralProposal);compare(JSON.stringify(ctl.snapshot),before)
                var lower=map.pointFor(r.x+r.w/2,r.y+100)
                mousePress(map,n.x,n.y,Qt.LeftButton);mouseMove(map,lower.x,lower.y,20,Qt.LeftButton)
                mouseRelease(map,lower.x,lower.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                compare(ctl.structuralProposal.command.patch.y,r.y+100)
                compare(ctl.structuralProposal.command.patch.h,r.h-100)
                clickNamed("structure-apply")
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("map-overview")
                clickNamed("map-magnetic");verify(map.magnetic)
                clickNamed("map-grid");verify(map.showGrid&&map.snapEnabled)
                study.parent.width=740;tryVerify(function(){return map.width===740})
                grabImage(study).save("archive-b8-native-shelf-map-arrange-narrow.png")
                compare(ctl.archiveState.history.length,history)
                var filled=ctl.snapshot.spatial.shelves.root.roomId
                r=ctl.snapshot.spatial.rooms[filled];pt=map.pointFor(r.x+r.w/2,r.y+r.h/2)
                mouseClick(map,pt.x,pt.y);compare(map.selectedRoom,filled)
                verify(!findChild(map,"map-delete-room").enabled)
            }finally{study.mapEnabled=false;study.switchMode("browse");study.parent.width=originalWidth;scene.snapEnabled=oldSnap;scene.showGrid=oldGrid;scene.snapDistance=oldInterval}
        }
        function test_map_door_arrangement(){
            var ctl=study.controller,scene=study.scene,oldSnap=scene.snapEnabled
            study.mapEnabled=true
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var initial=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                var map=findChild(study,"archive-map-room"),door=Object.values(ctl.snapshot.spatial.doors)[0]
                clickNamed("open-map-room");tryVerify(function(){return map.visible})
                study.switchMode("arrange");scene.snapEnabled=false
                verify(map.suggestions.length>0)
                clickNamed("map-door-add");tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                compare(JSON.stringify(ctl.snapshot),initial)
                grabImage(study).save("archive-b8-native-shelf-map-door-suggestion.png")
                clickNamed("structure-apply")
                var newId=Object.keys(ctl.snapshot.spatial.doors).find(k=>k!==door.id)
                verify(!!newId);compare(map.selectedDoor,newId)
                var beforeMove=JSON.stringify(ctl.snapshot)
                var g=Spatial.doorGeometry(ctl.snapshot,newId),pt=map.pointFor(g.line,(g.start+g.end)/2)
                var end=map.pointFor(g.line,(g.start+g.end)/2+40)
                mousePress(map,pt.x,pt.y,Qt.LeftButton);tryVerify(function(){return map.dragging})
                mouseMove(map,end.x,end.y,20,Qt.LeftButton);tryVerify(function(){return !!map.dragPatch})
                compare(JSON.stringify(ctl.snapshot),beforeMove);verify(!ctl.structuralProposal)
                keyClick(Qt.Key_Escape);tryVerify(function(){return !map.dragging})
                mouseRelease(map,end.x,end.y,Qt.LeftButton);verify(!ctl.structuralProposal)
                mousePress(map,pt.x,pt.y,Qt.LeftButton);mouseMove(map,end.x,end.y,20,Qt.LeftButton);mouseRelease(map,end.x,end.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                clickNamed("structure-apply");verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),beforeMove)
                var handle=findChild(map,"map-door-end-handle");verify(handle.visible)
                var hp=handle.mapToItem(map,handle.width/2,handle.height/2)
                mousePress(map,hp.x,hp.y,Qt.LeftButton);tryVerify(function(){return map.dragging})
                mouseMove(map,hp.x,hp.y+20,20,Qt.LeftButton);mouseRelease(map,hp.x,hp.y+20,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),beforeMove)
                // Actual keyboard deletion is immediate and exactly undoable.
                map.forceActiveFocus();keyClick(Qt.Key_Delete)
                verify(!ctl.snapshot.spatial.doors[newId]);verify(!ctl.structuralProposal)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),beforeMove)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),initial)
                // Same-wall contact and merge through real preview controls.
                var p=Core.previewStructure(ctl.archiveState,{kind:"spatialDoorCreate",patch:{a:door.a,b:door.b,start:door.end,end:door.end+100}})
                verify(p.ok,p.error);verify(ctl.proposeStructure(p.command));verify(ctl.applyStructure())
                var contact=JSON.stringify(ctl.snapshot),geo=Spatial.doorGeometry(ctl.snapshot,door.id)
                pt=map.pointFor(geo.line,(geo.start+geo.end)/2)
                mouseClick(map,pt.x,pt.y);compare(map.selectedDoor,door.id)
                clickNamed("map-door-merge");tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                clickNamed("structure-apply");compare(Object.keys(ctl.snapshot.spatial.doors).length,1)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),contact)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),initial);compare(ctl.archiveState.history.length,history)
            }finally{study.mapEnabled=false;study.switchMode("browse");scene.snapEnabled=oldSnap}
        }
        function test_map_chart_arrange_isolation(){
            var ctl=study.controller,scene=study.scene
            study.mapEnabled=true
            var map=findChild(study,"archive-map-room"),oldTitle=map.chartTitle
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                clickNamed("open-map-room");tryVerify(function(){return map.visible})
                study.switchMode("arrange")
                var door=Object.values(ctl.snapshot.spatial.doors)[0],g=Spatial.doorGeometry(ctl.snapshot,door.id)
                var before=JSON.stringify(ctl.snapshot),revision=ctl.archiveState.revision,history=JSON.stringify(ctl.archiveState.history)
                function unchanged(){
                    compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.revision,revision)
                    compare(JSON.stringify(ctl.archiveState.history),history)
                    verify(!ctl.structuralProposal&&!map.dragging&&!map.dragPatch)
                }
                var pt=map.pointFor(g.line,(g.start+g.end)/2)
                mouseClick(map,pt.x,pt.y);compare(map.selectedDoor,door.id)
                var handle=findChild(map,"map-door-end-handle");verify(handle.visible&&handle.enabled)
                var hp=handle.mapToItem(map,handle.width/2,handle.height/2)
                clickNamed("map-chart")
                var panel=findChild(map,"map-chart-panel")
                tryVerify(function(){return map.appearanceOpen&&panel.activeFocus})
                verify(!handle.visible&&!handle.enabled)
                verify(!findChild(map,"map-door-delete").enabled&&!findChild(study,"archive-undo").enabled)
                keyClick(Qt.Key_Delete);keyClick(Qt.Key_Backspace);unchanged()
                // Former endpoint hit location must be inert.
                mousePress(map,hp.x,hp.y,Qt.LeftButton);mouseMove(map,hp.x,hp.y+40,20,Qt.LeftButton);mouseRelease(map,hp.x,hp.y+40,Qt.LeftButton)
                unchanged()
                // Explicit entry guards independently of pointer routing.
                verify(!map.removeSelectedDoor());verify(!map.startDoorGesture(door.id,"end",hp.x,hp.y))
                study.startMapDoorEdit("spatialDoorDelete",door.id,{})
                study.startMapRoomEdit("spatialRoomEdit",door.a.roomId,{w:1900})
                unchanged()
                var input=findChild(map,"map-chart-title")
                mouseClick(input,input.width/2,input.height/2);verify(input.activeFocus)
                keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace)
                compare(map.chartTitle,"")
                keyClick("A");keyClick("B");keyClick(Qt.Key_Left);keyClick(Qt.Key_Delete)
                compare(map.chartTitle,"A");unchanged()
                keyClick(Qt.Key_Escape);tryVerify(function(){return !map.appearanceOpen&&map.activeFocus})
                verify(handle.visible&&handle.enabled)
                // Also isolate actual Room resize handles.
                var room=ctl.snapshot.spatial.rooms[door.b.roomId]
                pt=map.pointFor(room.x+room.w/2,room.y+room.h/2)
                mouseClick(map,pt.x,pt.y);compare(map.selectedRoom,room.id);compare(map.selectedDoor,"")
                var rh=findChild(map,"map-room-resize-handle");verify(rh.visible&&rh.enabled)
                hp=rh.mapToItem(map,rh.width/2,rh.height/2)
                clickNamed("map-chart");verify(!rh.visible&&!rh.enabled)
                mousePress(map,hp.x,hp.y,Qt.LeftButton);mouseMove(map,hp.x-40,hp.y,20,Qt.LeftButton);mouseRelease(map,hp.x-40,hp.y,Qt.LeftButton)
                verify(!map.startGesture(room.id,"resize",hp.x,hp.y));unchanged()
                clickNamed("map-chart-close");tryVerify(function(){return !map.appearanceOpen&&map.activeFocus})
                verify(rh.visible&&rh.enabled)
                // A selected Room's west-edge handle can cover the opening's
                // midpoint. First dismiss Room selection through real empty
                // map input, then exercise normal doorway selection/deletion.
                pt=map.pointFor(g.line,(g.start+g.end)/2)
                var west=findChild(map,"map-room-resize-w"),wp=west.mapToItem(map,0,0)
                console.log("B8 Chart reselect geometry",JSON.stringify({doorPoint:{x:pt.x,y:pt.y},westHandle:{x:wp.x,y:wp.y,w:west.width,h:west.height,visible:west.visible}}))
                var blank=Qt.point(map.width/2,80)
                compare(map.hit(blank.x,blank.y),"")
                compare(View.mapDoorHit(map.dataModel,map.camera,blank.x,blank.y),"")
                mouseClick(map,blank.x,blank.y);compare(map.selectedRoom,"");compare(map.selectedDoor,"")
                verify(!rh.visible);unchanged()
                mouseClick(map,pt.x,pt.y);compare(map.selectedDoor,door.id)
                keyClick(Qt.Key_Delete);verify(!ctl.snapshot.spatial.doors[door.id]);verify(!ctl.structuralProposal)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before);compare(JSON.stringify(ctl.archiveState.history),history)
            }finally{map.chartTitle=oldTitle;study.mapEnabled=false;study.switchMode("browse")}
        }
        function test_map_cartography(){
            var ctl=study.controller,original=Themes.Theme.index
            study.mapEnabled=true
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length,map=findChild(study,"archive-map-room")
                var initialPaints=map.mapPaints
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&map.mapPaints>initialPaints&&map.contourSegmentCount>0})
                var builds=map.contourBuilds
                for(var i=0;i<3;i++){
                    var paints=map.mapPaints,changed=Themes.Theme.index!==i
                    Themes.Theme.index=i
                    if(changed)tryVerify(function(){return map.mapPaints>paints})
                    grabImage(study).save("archive-b8-native-shelf-map-chart-"+i+".png")
                }
                compare(map.contourBuilds,builds)
                clickNamed("map-chart");var paints=map.mapPaints;clickNamed("map-contour-none")
                tryVerify(function(){return map.mapPaints>paints})
                compare(map.contourBuilds,builds)
                clickNamed("map-contour-engraved");clickNamed("map-contour-more")
                clickNamed("map-mark-family");clickNamed("map-chart-close")
                clickNamed("map-zoom-in");clickNamed("map-zoom-in");clickNamed("map-zoom-in")
                tryVerify(function(){return map.contourBuilds>builds})
                grabImage(study).save("archive-b8-native-shelf-map-chart-detail.png")
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
            }finally{Themes.Theme.index=original;study.mapEnabled=false;var m=findChild(study,"archive-map-room");m.contourMode="subtle";m.contourDensity=55;m.chartOrnament="compass"}
        }
        function test_map_focus_checkpoint_and_transition(){
            var ctl=study.controller,oldStore=study.checkpointStore,oldMotion=study.reducedRoomMotion,oldPref=study.roomPreferenceStore
            var payload=null
            study.checkpointStore={read:function(){return payload},write:function(v){payload=v}}
            study.roomPreferenceStore=null;study.mapEnabled=true
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length,map=findChild(study,"archive-map-room"),plan=findChild(study,"archive-room-plan")
                var empty=Object.keys(ctl.snapshot.spatial.rooms).find(k=>!Object.values(ctl.snapshot.spatial.shelves).some(p=>p.roomId===k))
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&map.activeFocus})
                clickNamed("map-zoom-in")
                var base=JSON.stringify(map.cameraState()),room=ctl.snapshot.spatial.rooms[empty],pt=map.pointFor(room.x+room.w/2,room.y+room.h/2)
                // Fit if the zoomed center is outside the viewport.
                if(pt.x<0||pt.x>=map.width||pt.y<0||pt.y>=map.height){clickNamed("map-fit");base=JSON.stringify(map.cameraState());pt=map.pointFor(room.x+room.w/2,room.y+room.h/2)}
                mouseClick(map,pt.x,pt.y);compare(map.selectedRoom,empty)
                clickNamed("map-focus");verify(!!map.focusState);compare(JSON.stringify(map.focusState.base),base)
                var d=Object.values(ctl.snapshot.spatial.doors)[0],g=Spatial.doorGeometry(ctl.snapshot,d.id)
                map.selectDoor(d.id);clickNamed("map-focus");compare(map.focusState.kind,"door");compare(JSON.stringify(map.focusState.base),base)
                clickNamed("map-overview");compare(JSON.stringify(map.cameraState()),base);verify(!map.focusState)
                map.selectedDoor="";map.selectedRoom=empty;clickNamed("map-focus")
                var retained=JSON.stringify(map.savedView())
                verify(study.saveCheckpoint());var savedMap=payload
                payload="{bad";verify(study.requestCheckpointLoad());verify(!study.loadCheckpoint())
                compare(JSON.stringify(map.savedView()),retained);verify(map.visible&&map.activeFocus)
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                study.reducedRoomMotion=false
                clickNamed("map-enter-room");verify(study.mapNavigating)
                verify(!map.enabled&&!study.viewSwitchReady&&!study.checkpointReady)
                var skip=findChild(study,"map-navigation-skip");verify(skip.visible&&skip.enabled)
                mouseClick(skip,skip.width/2,skip.height/2)
                tryVerify(function(){return plan.visible&&plan.activeFocus&&!study.mapNavigating})
                compare(plan.roomId,empty);compare(JSON.stringify(map.savedView()),retained)
                verify(study.saveCheckpoint());var savedRoom=payload
                payload="{bad";verify(study.requestCheckpointLoad());verify(!study.loadCheckpoint())
                verify(plan.visible&&plan.activeFocus);compare(plan.roomId,empty);compare(JSON.stringify(map.savedView()),retained)
                payload=savedMap;verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                tryVerify(function(){return map.visible&&map.activeFocus});compare(JSON.stringify(map.savedView()),retained)
                payload=savedRoom;verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                tryVerify(function(){return plan.visible&&plan.activeFocus});compare(plan.roomId,empty)
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&map.activeFocus})
                study.reducedRoomMotion=false;clickNamed("map-enter-room");verify(study.mapNavigating);keyClick(Qt.Key_Escape)
                tryVerify(function(){return plan.visible&&!study.mapNavigating})
                study.mapEnabled=false;tryVerify(function(){return study.scene.visible&&!plan.visible&&!map.visible})
                study.mapEnabled=true;clickNamed("open-map-room");tryVerify(function(){return map.visible})
                compare(map.zoom,1);verify(!map.focusState)
                compare(JSON.stringify(ctl.snapshot),before)
                // The same physical-profile checkpoint without optional upper
                // view metadata is still valid and returns to the Shelf.
                var legacy=JSON.parse(savedMap);delete legacy.view.mapView
                payload=JSON.stringify(legacy)
                verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                tryVerify(function(){return study.scene.visible&&study.scene.activeFocus&&!plan.enabled&&!map.visible})
                compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&map.activeFocus})
                map.selectedRoom=empty
                study.reducedRoomMotion=false;clickNamed("map-enter-room");verify(study.mapNavigating)
                ctl.reset(Sample.roomFixture())
                tryVerify(function(){return !study.mapNavigating&&study.scene.visible&&study.scene.activeFocus&&!plan.visible&&!map.visible})
                verify(!map.focusState)
            }finally{study.mapEnabled=false;study.reducedRoomMotion=oldMotion;study.checkpointStore=oldStore;study.roomPreferenceStore=oldPref}
        }
        function test_map_integrated_horizontal_and_resources(){
            var ctl=study.controller,scene=study.scene,oldSnap=scene.snapEnabled,oldTheme=Themes.Theme.index
            study.mapEnabled=true
            try{
                ctl.reset(Sample.mapFixture())
                var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                var hall=ctl.snapshot.spatial.shelves.root.roomId,south=Object.values(ctl.snapshot.spatial.rooms).find(r=>r.name==="South Reading Room").id
                var d=Object.values(ctl.snapshot.spatial.doors).find(d=>d.a.roomId===hall&&d.a.side==="south"&&d.b.roomId===south)
                var map=findChild(study,"archive-map-room"),plan=findChild(study,"archive-room-plan")
                var paints=map.mapPaints
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&map.mapPaints>paints})
                verify(map.contourSegmentCount>0&&map.contourSegmentCount<=50000)
                var g=Spatial.doorGeometry(ctl.snapshot,d.id),pt=map.pointFor((g.start+g.end)/2,g.line)
                mouseClick(map,pt.x,pt.y);compare(map.selectedDoor,d.id)
                clickNamed("map-focus");verify(map.focusState.kind==="door")
                study.switchMode("arrange");scene.snapEnabled=false
                clickNamed("map-door-edit")
                var input=findChild(study,"map-door-input-start");verify(!!input)
                input.forceActiveFocus();keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace)
                verify(!!ctl.snapshot.spatial.doors[d.id]);tryVerify(function(){return !ctl.structuralProposal.ok})
                compare(JSON.stringify(ctl.snapshot),before)
                for(var digit of "120")keyClick(digit)
                tryVerify(function(){return ctl.structuralProposal.ok})
                clickNamed("structure-apply");compare(ctl.snapshot.spatial.doors[d.id].start,120)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                g=Spatial.doorGeometry(ctl.snapshot,d.id);pt=map.pointFor((g.start+g.end)/2,g.line)
                var end=map.pointFor((g.start+g.end)/2+240,g.line)
                mousePress(map,pt.x,pt.y,Qt.LeftButton);tryVerify(function(){return map.dragging})
                mouseMove(map,end.x,end.y,20,Qt.LeftButton);mouseRelease(map,end.x,end.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                compare(ctl.structuralProposal.command.patch.end,300)
                clickNamed("structure-apply")
                var contact=JSON.stringify(ctl.snapshot)
                clickNamed("map-door-merge");clickNamed("structure-apply")
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),contact)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                map.selectDoor(d.id);map.forceActiveFocus();keyClick(Qt.Key_Backspace)
                verify(!ctl.snapshot.spatial.doors[d.id]);verify(!ctl.structuralProposal)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                study.switchMode("browse");clickNamed("map-fit")
                var root=ctl.snapshot.spatial.rooms[hall];pt=map.pointFor(root.x+root.w/2,root.y+root.h/2)
                mouseClick(map,pt.x,pt.y);clickNamed("map-enter-room")
                tryVerify(function(){return plan.visible&&plan.activeFocus})
                compare(plan.roomId,hall);verify(plan.planData.openings.some(o=>o.id===d.id&&o.side==="south"&&o.start===100&&o.end===250))
                grabImage(study).save("archive-b8-native-shelf-map-horizontal-hall-plan.png")
                clickNamed("toggle-room-perspective");tryVerify(function(){return !!plan.visibilityRaster})
                grabImage(study).save("archive-b8-native-shelf-map-horizontal-hall-perspective.png")
                clickNamed("open-map-room");clickNamed("map-fit")
                root=ctl.snapshot.spatial.rooms[south];pt=map.pointFor(root.x+root.w/2,root.y+root.h/2)
                mouseClick(map,pt.x,pt.y);clickNamed("map-enter-room");tryVerify(function(){return plan.visible&&!!plan.visibilityRaster})
                compare(plan.roomId,south);verify(plan.planData.openings.some(o=>o.id===d.id&&o.side==="north"&&o.start===100&&o.end===250))
                grabImage(study).save("archive-b8-native-shelf-map-horizontal-south-perspective.png")
                clickNamed("toggle-room-perspective")
                grabImage(study).save("archive-b8-native-shelf-map-horizontal-south-plan.png")
                // Return to the actual south Shelf, switch to root directly,
                // and ensure the atlas uses that Shelf's Room rather than a
                // stale active Room ID from the previous upper layer.
                var southShelf=Object.keys(ctl.snapshot.spatial.shelves).find(k=>ctl.snapshot.spatial.shelves[k].roomId===south)
                var shelfBox=Spatial.footprint(ctl.snapshot,southShelf)
                var sp=plan.pointFor(shelfBox.x+shelfBox.w/2,shelfBox.y+shelfBox.h/2)
                mouseDoubleClickSequence(plan,sp.x,sp.y,Qt.LeftButton)
                tryCompare(scene,"cubbyId",southShelf);tryVerify(function(){return scene.visible&&scene.activeFocus})
                clickNamed("open-shelf-root");tryCompare(scene,"cubbyId","root")
                clickNamed("open-map-room");tryVerify(function(){return map.visible&&map.activeFocus})
                compare(map.selectedRoom,hall)
                clickNamed("map-fit")
                paints=map.mapPaints;var start=Date.now();clickNamed("map-zoom-in");tryVerify(function(){return map.mapPaints>paints})
                var elapsed=Date.now()-start
                // Deliberate idle measurement, not an interaction retry.
                wait(120);paints=map.mapPaints;var builds=map.contourBuilds;wait(150)
                compare(map.mapPaints,paints);compare(map.contourBuilds,builds)
                console.log("B8 N4 resource sample",JSON.stringify({zoomInputToPaintMs:elapsed,lastBuildMs:map.contourLastBuildMs,maxBuildMs:map.contourMaxBuildMs,lastPaintMs:map.mapLastPaintMs,segments:map.contourSegmentCount,idleMs:150,idlePaints:map.mapPaints-paints,idleBuilds:map.contourBuilds-builds}))
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
            }finally{study.mapEnabled=false;study.switchMode("browse");scene.snapEnabled=oldSnap;Themes.Theme.index=oldTheme}
        }
        function test_checkpoint_preference_write_failure(){
            var ctl=study.controller,scene=study.scene,oldStore=study.checkpointStore,oldPref=study.roomPreferenceStore
            var payload=null,persisted=false,attempts=0,rejectWrite=true
            study.checkpointStore={read:function(){return payload},write:function(v){payload=v}}
            study.roomPreferenceStore={
                readRoomPerspective:function(){return persisted},
                writeRoomPerspective:function(v){
                    attempts++
                    if(rejectWrite)throw Error("injected preference write failure")
                    persisted=v
                }
            }
            try{
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var savedSnapshot=JSON.stringify(ctl.snapshot)
                study.roomPerspective=true
                verify(study.saveCheckpoint())
                var saved=payload
                compare(JSON.parse(saved).version,5)
                ctl.reset(Sample.fixture())
                verify(!study.roomPerspective)
                verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                compare(JSON.stringify(ctl.snapshot),savedSnapshot)
                verify(study.roomPerspective);verify(!persisted)
                compare(attempts,1);compare(payload,saved)
                verify(scene.message.indexOf("Study checkpoint loaded")===0)
                verify(scene.message.indexOf("Room preference not saved")>=0)
                verify(scene.message.indexOf("injected preference write failure")>=0)
                // A failed decode must not try writing the preference.
                payload="{bad"
                verify(study.requestCheckpointLoad());verify(!study.loadCheckpoint())
                compare(attempts,1);verify(!persisted&&study.roomPerspective)
                compare(JSON.stringify(ctl.snapshot),savedSnapshot)
                verify(scene.message.indexOf("Checkpoint not loaded")===0)
                // Retry with healthy preference storage: no stale warning.
                payload=saved;rejectWrite=false
                verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                compare(attempts,2);verify(persisted&&study.roomPerspective)
                compare(JSON.stringify(ctl.snapshot),savedSnapshot);compare(payload,saved)
                compare(scene.message,"Study checkpoint loaded")
            }finally{study.roomPlanOpen=false;study.checkpointStore=oldStore;study.roomPreferenceStore=oldPref}
        }
        function test_independent_sqlite_preference(){
            var ctl=study.controller,oldStore=study.checkpointStore,oldPref=study.roomPreferenceStore
            try{
                compare(preferenceReader.read(),null);compare(preferenceReader.readRoomPerspective(),false)
                study.roomPreferenceStore=preferenceWriter;study.checkpointStore=preferenceWriter
                ctl.reset(Sample.roomFixture())
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                clickNamed("toggle-room-plan");clickNamed("toggle-room-perspective")
                compare(preferenceReader.readRoomPerspective(),true);compare(preferenceReader.read(),null)
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                verify(study.saveCheckpoint());var saved=preferenceReader.read()
                compare(JSON.parse(saved).version,5)
                clickNamed("toggle-room-perspective")
                compare(preferenceReader.readRoomPerspective(),false);compare(preferenceReader.read(),saved)
                // Distinct storage object reopens persisted data. This is a
                // same-process SQLite roundtrip, not a compositor restart.
                study.roomPreferenceStore=preferenceReader;study.checkpointStore=preferenceReader
                ctl.reset(Sample.fixture())
                study.restoreRoomPreference();verify(!study.roomPerspective)
                verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                verify(study.roomPerspective);compare(preferenceWriter.readRoomPerspective(),true)
                compare(JSON.stringify(ctl.snapshot),before);compare(preferenceWriter.read(),saved)
                var refused=false
                try{preferenceReader.write("{bad")}catch(e){refused=true}
                verify(refused);compare(preferenceReader.read(),saved)
                refused=false
                try{preferenceReader.writeRoomPerspective("true")}catch(e){refused=true}
                verify(refused);compare(preferenceWriter.readRoomPerspective(),true)
            }finally{study.roomPlanOpen=false;study.checkpointStore=oldStore;study.roomPreferenceStore=oldPref}
        }
        function test_selected_independent_policy(){
            var ctl=study.controller,scene=study.scene,original=study.parent.width
            var oldStore=study.checkpointStore,oldPref=study.roomPreferenceStore,payload=null,preference=false,writes=0
            study.checkpointStore={read:function(){return payload},write:function(v){payload=v}}
            study.roomPreferenceStore={readRoomPerspective:function(){return preference},writeRoomPerspective:function(v){preference=v;writes++}}
            try{
                ctl.reset(Sample.roomFixture())
                tryVerify(function(){return scene.physicalFront})
                var prior=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                clickNamed("adopt-independent-profiles")
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                compare(ctl.structuralProposal.profileAdoption.shelves.root.frameBasis,24)
                compare(JSON.stringify(ctl.snapshot),prior)
                clickNamed("structure-apply")
                tryVerify(function(){return Spatial.independentProfiles(ctl.snapshot)})
                compare(scene.frontEnvelope.h,1182);compare(ctl.snapshot.cubbies.root.b,12)
                compare(ctl.archiveState.history.length,history+1)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),prior)
                clickNamed("adopt-independent-profiles");clickNamed("structure-apply")
                var before=JSON.stringify(ctl.snapshot),h=ctl.archiveState.history.length,plan=findChild(study,"archive-room-plan")
                grabImage(study).save("archive-b8-native-shelf-v5-front.png")
                clickNamed("toggle-room-plan")
                tryVerify(function(){return plan.visible&&!plan.perspective})
                grabImage(study).save("archive-b8-native-shelf-v5-plan.png")
                clickNamed("toggle-room-perspective")
                tryVerify(function(){return !!plan.visibilityRaster&&preference})
                compare(writes,1);compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,h)
                grabImage(study).save("archive-b8-native-shelf-v5-perspective.png")
                study.parent.width=740;wait(80)
                grabImage(study).save("archive-b8-native-shelf-v5-narrow.png")
                var b=Spatial.footprint(ctl.snapshot,"root"),g=Spatial.shelfGeometry(ctl.snapshot,"root")
                var q=Projection.project([b.x+b.w/2,b.y+b.h,g.h-g.inscription.y-g.inscription.h/2],plan.perspectiveData.frame)
                compare(plan.hit(q[0],q[1]),"root")
                study.reducedRoomMotion=false
                mouseDoubleClickSequence(plan,q[0],q[1],Qt.LeftButton)
                tryVerify(function(){return scene.visible&&!plan.visible&&!study.roomNavigating})
                compare(scene.cubbyId,"root");compare(scene.frontEnvelope.h,1182)
                clickNamed("toggle-room-plan")
                tryVerify(function(){return plan.visible&&!scene.visible&&!study.roomNavigating})
                compare(plan.selectedShelf,"root");verify(plan.perspective)
                verify(study.saveCheckpoint());compare(JSON.parse(payload).version,5)
                var saved=payload
                ctl.reset(Sample.fixture());verify(!study.roomPerspective)
                study.restoreRoomPreference();verify(study.roomPerspective)
                study.roomPerspective=false
                verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                compare(JSON.stringify(ctl.snapshot),before);verify(study.roomPerspective&&preference)
                payload="{bad"
                verify(study.requestCheckpointLoad());verify(!study.loadCheckpoint())
                verify(study.roomPerspective&&preference);compare(JSON.stringify(ctl.snapshot),before)
                // Explicit old checkpoint without preference supersedes global
                // view preference; no silent geometry upgrade.
                var old=JSON.parse(saved);old.version=4;old.snapshot=JSON.parse(prior);delete old.view.roomPerspective
                payload=JSON.stringify(old)
                verify(study.requestCheckpointLoad());verify(study.loadCheckpoint())
                verify(!study.roomPerspective&&!preference&&!Spatial.independentProfiles(ctl.snapshot))
                compare(JSON.stringify(ctl.snapshot),prior)
            }finally{study.abortRoomNavigation();study.reducedRoomMotion=true;study.parent.width=original;study.roomPlanOpen=false;study.checkpointStore=oldStore;study.roomPreferenceStore=oldPref}
        }
        function test_room_navigation_lifecycle(){
            var ctl=study.controller,scene=study.scene,plan=findChild(study,"archive-room-plan")
            var animation=findChild(study,"room-navigation-animation"),overlay=findChild(study,"room-navigation-overlay")
            var original=study.parent.width,oldStore=study.checkpointStore,calls=0
            // In-memory adapter only: blocked operations must never reach it.
            study.checkpointStore={read:function(){calls++;return null},write:function(){calls++}}
            function enterPlan(perspective){
                study.reducedRoomMotion=true
                verify(scene.openShelf("root"))
                scene.zoom=1;scene.pan=Qt.point(0,0)
                clickNamed("toggle-room-plan")
                tryVerify(function(){return plan.visible&&!scene.visible})
                if(plan.perspective!==perspective)clickNamed("toggle-room-perspective")
                tryVerify(function(){return plan.perspective===perspective&&(!perspective||!!plan.visibilityRaster)})
            }
            function startEntry(){
                var b=Spatial.footprint(ctl.snapshot,"root"),g=Spatial.shelfGeometry(ctl.snapshot,"root")
                var pt=plan.pointFor(b.x+b.w/2,b.y+b.h/2)
                if(plan.perspective){
                    var q=Projection.project([b.x+g.w/2,b.y+b.h,g.h-g.inscription.y-g.inscription.h/2],plan.perspectiveData.frame)
                    pt=Qt.point(q[0],q[1])
                }
                study.reducedRoomMotion=false
                mouseDoubleClickSequence(plan,pt.x,pt.y,Qt.LeftButton)
                verify(study.roomNavigating)
            }
            function pauseActive(){
                tryVerify(function(){return study.roomNavigating&&study.roomProgress>.20&&study.roomProgress<.80},1500)
                animation.pause()
                verify(study.roomNavigating&&overlay.visible&&!scene.enabled&&!plan.enabled)
            }
            function guard(before,history){
                var zoom=scene.zoom,pan=scene.pan,path=JSON.stringify(scene.viewPath),mode=scene.mode
                verify(!study.viewSwitchReady&&!study.checkpointReady)
                verify(!study.saveCheckpoint()&&!study.requestCheckpointLoad())
                study.switchMode("arrange");compare(scene.mode,mode)
                verify(!study.navigateRoom("root",!study.roomNavigation.entering))
                mouseClick(overlay,overlay.width/2,overlay.height/2)
                mouseWheel(overlay,overlay.width/2,overlay.height/2,0,120)
                compare(scene.zoom,zoom);compare(scene.pan,pan);compare(JSON.stringify(scene.viewPath),path)
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                compare(calls,0);verify(!ctl.structuralProposal&&!ctl.draft)
                verify(study.roomNavigating)
            }
            try{
                for(var perspective of [false,true]){
                    study.parent.width=original;study.roomPlanOpen=false
                    ctl.reset(Sample.roomFixture())
                    tryVerify(function(){return scene.physicalFront})
                    verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:"root",patch:{palette:0}}));verify(ctl.applyStructure())
                    enterPlan(perspective)
                    var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
                    startEntry();pauseActive();guard(before,history)
                    // Resize during actual entry, settle to the chosen Shelf.
                    study.parent.width=740
                    tryVerify(function(){return !study.roomNavigating&&scene.visible&&!plan.visible&&scene.width===740})
                    compare(scene.cubbyId,"root");compare(scene.zoom,1);compare(scene.pan,Qt.point(0,0))
                    verify(!overlay.visible);compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                    // Real narrow reverse, resize while moving back.
                    clickNamed("toggle-room-plan");pauseActive();guard(before,history)
                    study.parent.width=original
                    tryVerify(function(){return !study.roomNavigating&&plan.visible&&!scene.visible&&plan.width===original})
                    compare(plan.selectedShelf,"root");compare(plan.perspective,perspective)
                    compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                    // Snapshot replacement interrupts both directions. Reset
                    // to the legacy-compatible v3 fixture, never stale geometry.
                    startEntry();pauseActive()
                    ctl.reset(Sample.fixture())
                    tryVerify(function(){return !study.roomNavigating&&!overlay.visible&&scene.visible&&!plan.visible&&!scene.physicalFront})
                    compare(Core.validate(ctl.snapshot),null)
                    ctl.reset(Sample.roomFixture())
                    tryVerify(function(){return scene.physicalFront})
                    enterPlan(perspective)
                    startEntry();study.reducedRoomMotion=true
                    tryVerify(function(){return scene.visible&&!plan.visible&&!study.roomNavigating})
                    study.reducedRoomMotion=false;clickNamed("toggle-room-plan");pauseActive()
                    ctl.reset(Sample.fixture())
                    tryVerify(function(){return !study.roomNavigating&&!overlay.visible&&scene.visible&&!plan.visible&&!scene.physicalFront})
                    compare(Core.validate(ctl.snapshot),null);verify(!ctl.structuralProposal&&!ctl.draft)
                    compare(calls,0)
                }
            }finally{study.abortRoomNavigation();study.reducedRoomMotion=true;study.parent.width=original;study.roomPlanOpen=false;study.checkpointStore=oldStore}
        }
        function test_room_full_fit_crest_handoff(){
            var ctl=study.controller,scene=study.scene,original=study.parent.width
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            var roomId=ctl.snapshot.spatial.shelves.root.roomId
            function edit(cmd){verify(ctl.proposeStructure(cmd));verify(ctl.applyStructure())}
            edit({kind:"spatialRoomEdit",roomId:roomId,patch:{w:1800,h:2000}})
            // Comparative test-only basis; no change to persisted profile-v1.
            edit({kind:"spatialShelfEdit",containerId:"root",patch:{b:24}})
            edit({kind:"spatialAppearance",containerId:"root",patch:{profile:"crest"}})
            var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
            var g=Spatial.shelfGeometry(ctl.snapshot,"root"),p=ctl.snapshot.spatial.shelves.root
            scene.zoom=1;scene.pan=Qt.point(0,0)
            var plan=findChild(study,"archive-room-plan"),animation=findChild(study,"room-navigation-animation")
            function sample(name,values){
                verify(study.roomNavigating)
                animation.pause()
                var dst=study.roomNavigation.geometry.destination
                verify(dst.x>=15.99&&dst.y>=15.99&&dst.x+g.w*dst.scale<=scene.width-15.99&&dst.y+g.h*dst.scale<=scene.height-42-15.99)
                // Explicit staged phase sampling while paused, not a claim
                // of observed 500ms frame pacing. Timed motion test retained.
                for(var v of values){
                    study.roomProgress=v;wait(70)
                    verify(Math.abs(study.roomProgress-v)<.0001)
                    compare(scene.camera,dst)
                    grabImage(study).save("archive-b8-native-shelf-handoff-"+name+"-"+Math.round(v*100)+".png")
                }
                clickNamed("room-navigation-skip")
            }
            try{
                for(var w of [1366,740]){
                    study.parent.width=w;wait(80)
                    study.reducedRoomMotion=true
                    clickNamed("toggle-room-plan")
                    tryVerify(function(){return plan.visible&&!scene.visible})
                    var box=Spatial.footprint(ctl.snapshot,"root")
                    var pt=plan.pointFor(box.x+box.w/2,box.y+box.h/2)
                    mouseClick(plan,pt.x,pt.y);tryCompare(plan,"selectedShelf","root")
                    study.reducedRoomMotion=false
                    clickNamed("plan-inspect-shelf")
                    sample(w+"-plan-in",[.59,.60,.69,.70])
                    tryVerify(function(){return scene.visible&&!plan.visible&&!study.roomNavigating})
                    grabImage(study).save("archive-b8-native-shelf-handoff-"+w+"-settled.png")
                    clickNamed("toggle-room-plan")
                    sample(w+"-plan-out",[.70,.69,.60,.59])
                    tryVerify(function(){return plan.visible&&!scene.visible&&!study.roomNavigating})
                    compare(plan.selectedShelf,"root")
                    if(w===1366){
                        clickNamed("toggle-room-perspective")
                        tryVerify(function(){return !!plan.perspectiveData})
                        var q=Projection.project([p.x+g.w/2,p.y+g.depth,g.h-g.inscription.y-g.inscription.h/2],plan.perspectiveData.frame)
                        mouseClick(plan,q[0],q[1]);tryCompare(plan,"selectedShelf","root")
                        clickNamed("plan-inspect-shelf")
                        sample(w+"-perspective-in",[.59,.60,.69,.70])
                        clickNamed("toggle-room-plan")
                        sample(w+"-perspective-out",[.70,.69,.60,.59])
                        clickNamed("toggle-room-perspective")
                    }
                    study.reducedRoomMotion=true
                    clickNamed("plan-inspect-shelf")
                    tryVerify(function(){return scene.visible&&!plan.visible})
                    compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                }
            }finally{study.abortRoomNavigation();study.reducedRoomMotion=true;study.parent.width=original;study.roomPlanOpen=false}
        }
        function test_room_continuous_carrier(){
            var ctl=study.controller,scene=study.scene
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront})
            var roomId=ctl.snapshot.spatial.shelves.root.roomId,other=Object.keys(ctl.snapshot.spatial.shelves).find(k=>k!=="root")
            function edit(cmd){verify(ctl.proposeStructure(cmd));verify(ctl.applyStructure())}
            edit({kind:"spatialRoomEdit",roomId:roomId,patch:{w:1800,h:2000}})
            edit({kind:"spatialShelfEdit",containerId:other,patch:{roomId:roomId,x:1000,y:250,depth:250,orientation:0}})
            edit({kind:"spatialAppearance",containerId:other,patch:{profile:"pilaster",palette:0}})
            // Independent board beside the rack leaves the required full
            // 160-unit book envelope clear, without changing Shelf geometry.
            edit({kind:"create",type:"shelf",cubbyId:other,patch:{x:560,y:200,w:130,h:15}})
            var board=ctl.snapshot.cubbies[other].mods.find(m=>m.type==="shelf").id
            edit({kind:"spatialAppPlace",appId:"org.example.Atlas",containerId:other,moduleId:board,patch:{x:50}})
            var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
            clickNamed("open-shelf-"+other);scene.zoom=1.15;scene.pan=Qt.point(13,-8)
            clickNamed("open-shelf-root");scene.zoom=.85;scene.pan=Qt.point(-11,7)
            clickNamed("toggle-room-plan")
            var plan=findChild(study,"archive-room-plan"),animation=findChild(study,"room-navigation-animation")
            var carrier=findChild(study,"room-navigation-carrier"),interior=findChild(scene,"cubby-interior")
            verify(!!animation&&!!carrier&&!!interior)
            study.reducedRoomMotion=false
            function captureBand(low,high,name){
                tryVerify(function(){return study.roomNavigating&&study.roomProgress>=low&&study.roomProgress<high},1500,name)
                animation.pause();wait(40)
                verify(study.roomProgress>=low&&study.roomProgress<high)
                grabImage(study).save("archive-b8-native-shelf-carrier-"+name+".png")
                console.log("B8 carrier",name,"progress",study.roomProgress,"paintCount",carrier.projectedPaintCount,"last projected JS paint ms",carrier.projectedPaintMs)
                animation.resume()
            }
            for(var perspective=0;perspective<2;perspective++){
                if(perspective)clickNamed("toggle-room-perspective")
                var box=Spatial.footprint(ctl.snapshot,other),pt=plan.pointFor(box.x+box.w/2,box.y+box.h/2)
                if(perspective){
                    var ref=View.roomPerspective(ctl.snapshot,View.roomPlan(ctl.snapshot,roomId),1000,700).frame,f=plan.perspectiveData.frame
                    pt=Qt.point((708-ref.ox)/ref.scale*f.scale+f.ox,(252-ref.oy)/ref.scale*f.scale+f.oy)
                }
                mouseClick(plan,pt.x,pt.y);tryCompare(plan,"selectedShelf",other)
                var oldWidth=scene.width,oldHeight=scene.height
                clickNamed("plan-inspect-shelf")
                verify(study.roomNavigating);compare(scene.cubbyId,other)
                compare(scene.zoom,1.15);compare(scene.pan,Qt.point(13,-8))
                var destination=study.roomNavigation.geometry.destination
                captureBand(.25,.56,perspective+"-midturn")
                captureBand(.76,.95,perspective+"-reveal")
                tryVerify(function(){return !study.roomNavigating&&scene.visible&&!plan.visible})
                compare(scene.width,oldWidth);compare(scene.height,oldHeight)
                compare(scene.camera,destination);compare(interior.opacity,1)
                verify(!!findChild(scene,"archive-book-org.example.Atlas"))
                grabImage(study).save("archive-b8-native-shelf-carrier-"+perspective+"-settled.png")
                clickNamed("toggle-room-plan")
                captureBand(.24,.56,perspective+"-reverse")
                tryVerify(function(){return !study.roomNavigating&&plan.visible&&!scene.visible})
                compare(plan.selectedShelf,other);compare(plan.perspective,!!perspective)
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
            }
            // Actual root selector verifies the distinct previous camera.
            clickNamed("open-shelf-root")
            tryVerify(function(){return !study.roomNavigating&&scene.cubbyId==="root"&&!plan.visible})
            compare(scene.zoom,.85);compare(scene.pan,Qt.point(-11,7))
            compare(JSON.stringify(ctl.snapshot),before)
            study.reducedRoomMotion=true
        }
        function test_room_wall_height_comparison(){
            var ctl=study.controller,scene=study.scene
            ctl.reset(Sample.roomFixture())
            tryVerify(function(){return scene.physicalFront})
            var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
            var g=Spatial.shelfGeometry(ctl.snapshot,"root"),plan=findChild(study,"archive-room-plan")
            clickNamed("toggle-room-plan");clickNamed("toggle-room-perspective")
            tryVerify(function(){return !!plan.visibilityRaster})
            var art=findChild(plan,"room-depth-art")
            verify(!!art)
            try{
                var samples=[{name:"baseline",options:null},{name:"occupied-fit",options:{occupiedFit:true}},{name:"wall-120",options:{farWall:g.h*1.2,occupiedFit:true,wallBands:true}},{name:"wall-160",options:{farWall:g.h*1.6,occupiedFit:true,wallBands:true}}]
                for(var sample of samples){
                    var old=art.paintCount
                    plan.researchProjection=sample.options
                    if(sample.options)tryVerify(function(){return art.paintCount>old})
                    wait(100)
                    var data=plan.perspectiveData
                    verify(!!data&&!!plan.visibilityRaster)
                    console.log("B8 wall comparison",sample.name,"reference",g.h,"far",sample.options&&sample.options.farWall||125,"camera",JSON.stringify(data.frame),"faces",data.faces.length)
                    grabImage(study).save("archive-b8-native-shelf-wall-"+sample.name+".png")
                    compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                }
            }finally{plan.researchProjection=null;study.roomPlanOpen=false}
        }
        function test_room_furnished_arrangement_rejections(){
            var ctl=study.controller,scene=study.scene
            ctl.reset(Sample.roomFixture())
            tryVerify(function(){return scene.physicalFront})
            var other=Object.keys(ctl.snapshot.spatial.shelves).find(k=>k!=="root"&&k!=="sample-1-root"),roomId=ctl.snapshot.spatial.shelves.root.roomId
            var before=JSON.stringify(ctl.snapshot),history=ctl.archiveState.history.length
            var plan=findChild(study,"archive-room-plan")
            clickNamed("toggle-room-plan")
            tryVerify(function(){return plan.visible&&plan.planData.shelves.length===3})
            compare(plan.planData.openings.length,1)
            for(var perspective=0;perspective<2;perspective++){
                if(perspective)clickNamed("toggle-room-perspective")
                tryVerify(function(){return !perspective||!!plan.visibilityRaster})
                var b=Spatial.footprint(ctl.snapshot,other),g=Spatial.shelfGeometry(ctl.snapshot,other)
                var pt=plan.pointFor(b.x+b.w/2,b.y+b.h/2)
                if(perspective){
                    // Orientation 90: front is west-facing, actual lintel
                    // center (not chosen by the current hit function).
                    var q=Projection.project([b.x,b.y+g.w/2,g.h-g.inscription.y-g.inscription.h/2],plan.perspectiveData.frame)
                    pt=Qt.point(q[0],q[1])
                }
                wait(80)
                grabImage(study).save("archive-b8-native-shelf-furnished-room-"+perspective+".png")
                mouseDoubleClickSequence(plan,pt.x,pt.y,Qt.LeftButton)
                tryVerify(function(){return scene.visible&&!plan.visible})
                compare(scene.cubbyId,other)
                verify(!!findChild(scene,"archive-book-org.example.Atlas"))
                clickNamed("toggle-room-plan")
                tryVerify(function(){return plan.visible&&!scene.visible})
                compare(plan.selectedShelf,other)
                study.switchMode("arrange");scene.snapEnabled=true;scene.snapDistance=50
                for(var delta of [[600,0],[0,-750],[550,-450]]){
                    var start=plan.floorAt(pt.x,pt.y),end=plan.pointFor(start.x+delta[0],start.y+delta[1])
                    mousePress(plan,pt.x,pt.y,Qt.LeftButton);tryVerify(function(){return plan.dragging})
                    mouseMove(plan,end.x,end.y,20,Qt.LeftButton)
                    tryVerify(function(){return !!plan.dragPatch})
                    compare(JSON.stringify(ctl.snapshot),before);verify(!ctl.structuralProposal)
                    mouseRelease(plan,end.x,end.y,Qt.LeftButton)
                    tryVerify(function(){return !!ctl.structuralProposal&&!ctl.structuralProposal.ok})
                    var patch=ctl.structuralProposal.command.patch
                    compare(patch.x===undefined?b.x:patch.x,b.x+delta[0])
                    compare(patch.y===undefined?b.y:patch.y,b.y+delta[1])
                    verify(!findChild(study,"structure-apply").enabled)
                    compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                    clickNamed("structure-cancel");verify(!plan.dragging&&!plan.dragPatch)
                }
                // Explicit focus loss must cancel the captured mapping;
                // release after focus transfer cannot publish a late proposal.
                var start=plan.floorAt(pt.x,pt.y),end=plan.pointFor(start.x+50,start.y)
                mousePress(plan,pt.x,pt.y,Qt.LeftButton);tryVerify(function(){return plan.dragging})
                mouseMove(plan,end.x,end.y,20,Qt.LeftButton);tryVerify(function(){return !!plan.dragPatch})
                scene.forceActiveFocus();tryVerify(function(){return !plan.dragging})
                mouseRelease(plan,end.x,end.y,Qt.LeftButton)
                verify(!ctl.structuralProposal);compare(JSON.stringify(ctl.snapshot),before)
                mousePress(plan,pt.x,pt.y,Qt.LeftButton);tryVerify(function(){return plan.dragging})
                mouseMove(plan,end.x,end.y,20,Qt.LeftButton);mouseRelease(plan,end.x,end.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                clickNamed("structure-cancel")
                compare(JSON.stringify(ctl.snapshot),before);compare(ctl.archiveState.history.length,history)
                study.switchMode("browse")
            }
            study.roomPlanOpen=false
        }
        function test_room_arrangement_gestures(){
            var ctl=study.controller,scene=study.scene
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront})
            var roomId=ctl.snapshot.spatial.shelves.root.roomId
            verify(ctl.proposeStructure({kind:"spatialRoomEdit",roomId:roomId,patch:{w:1800,h:2000}}));verify(ctl.applyStructure())
            var before=JSON.stringify(ctl.snapshot)
            scene.snapEnabled=false
            study.switchMode("arrange");clickNamed("toggle-room-plan")
            var plan=findChild(study,"archive-room-plan")
            for(var perspective=0;perspective<2;perspective++){
                if(perspective)clickNamed("toggle-room-perspective")
                tryVerify(function(){return plan.visible&&(!perspective||!!plan.perspectiveData)})
                var box=Spatial.footprint(ctl.snapshot,"root"),at=plan.pointFor(box.x+box.w/2,box.y+box.h/2)
                if(perspective){
                    var faces=plan.perspectiveData.faces
                    for(var i=faces.length-1;i>=0;i--){
                        var f=faces[i];if(f.shelfId!=="root")continue
                        var x=f.points.reduce((n,q)=>n+q[0],0)/f.points.length,y=f.points.reduce((n,q)=>n+q[1],0)/f.points.length
                        if(plan.hit(x,y)==="root"){at=Qt.point(x,y);break}
                    }
                }
                var floor=plan.floorAt(at.x,at.y),dest=plan.pointFor(floor.x+60,floor.y+40)
                mousePress(plan,at.x,at.y,Qt.LeftButton);tryVerify(function(){return plan.dragging})
                mouseMove(plan,dest.x,dest.y,20,Qt.LeftButton)
                tryVerify(function(){return !!plan.dragPatch})
                compare(JSON.stringify(ctl.snapshot),before);verify(!ctl.structuralProposal)
                mouseRelease(plan,dest.x,dest.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                var patch=ctl.structuralProposal.command.patch
                verify(Math.abs(patch.x-box.x-60)<5&&Math.abs(patch.y-box.y-40)<5)
                clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),before)
                mousePress(plan,at.x,at.y,Qt.LeftButton);tryVerify(function(){return plan.dragging})
                mouseMove(plan,dest.x,dest.y,20,Qt.LeftButton);tryVerify(function(){return !!plan.dragPatch})
                keyClick(Qt.Key_Escape);tryVerify(function(){return !plan.dragging})
                mouseRelease(plan,dest.x,dest.y,Qt.LeftButton)
                verify(!ctl.structuralProposal);compare(JSON.stringify(ctl.snapshot),before)
                var handle=findChild(plan,"room-shelf-resize-handle")
                verify(!!handle&&handle.visible)
                var corner=handle.mapToItem(plan,handle.width/2,handle.height/2),end=plan.pointFor(box.x+box.w+50,box.y+box.h+40)
                mousePress(plan,corner.x,corner.y,Qt.LeftButton);tryVerify(function(){return plan.dragging})
                mouseMove(plan,end.x,end.y,20,Qt.LeftButton);mouseRelease(plan,end.x,end.y,Qt.LeftButton)
                tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
                patch=ctl.structuralProposal.command.patch
                verify(Math.abs(patch.w-ctl.snapshot.cubbies.root.w-50)<5&&Math.abs(patch.depth-ctl.snapshot.spatial.shelves.root.depth-40)<5)
                clickNamed("structure-apply")
                compare(JSON.stringify(ctl.snapshot.cubbies.root.mods),JSON.stringify(JSON.parse(before).cubbies.root.mods))
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("plan-edit-shelf")
                var input=findChild(study,"room-shelf-input-h")
                verify(!!input);input.forceActiveFocus();keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace);for(var digit of "100")keyClick(digit)
                tryVerify(function(){return !ctl.structuralProposal.ok})
                verify(!findChild(study,"structure-apply").enabled)
                compare(input.text,"100")
                input.forceActiveFocus();keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace);for(var digit of "1100")keyClick(digit)
                tryVerify(function(){return ctl.structuralProposal.ok})
                clickNamed("structure-apply")
                compare(ctl.snapshot.cubbies.root.h,1100)
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            }
            study.roomPlanOpen=false;study.switchMode("browse")
        }
        function test_casework_proportion_comparison(){
            var ctl=study.controller,scene=study.scene,theme=Themes.Theme.index
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            var roomId=ctl.snapshot.spatial.shelves.root.roomId
            verify(ctl.proposeStructure({kind:"spatialRoomEdit",roomId:roomId,patch:{w:1800,h:2000}}));verify(ctl.applyStructure())
            var before=JSON.stringify(ctl.snapshot),interior=JSON.stringify(ctl.snapshot.cubbies.root.mods)
            try{
                // Research-only synthetic fixture edits to compare effective
                // frame scales. Not a migration, production preference, or
                // approval to replace stored b. Every edit is undone.
                Themes.Theme.index=1
                for(var b of [12,24,27]){
                    if(ctl.snapshot.cubbies.root.b!==b){verify(ctl.proposeStructure({kind:"spatialShelfEdit",containerId:"root",patch:{b:b}}));verify(ctl.applyStructure())}
                    verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:"root",patch:{profile:"crest"}}));verify(ctl.applyStructure())
                    tryVerify(function(){return scene.physicalFront&&scene.frontEnvelope.profile==="crest"&&scene.cubby.b===b})
                    compare(JSON.stringify(ctl.snapshot.cubbies.root.mods),interior)
                    wait(100)
                    grabImage(study).save("archive-b8-native-shelf-comparison-crest-b"+b+".png")
                    if(b===24){
                        for(var profile of ["cornice","pilaster"]){
                            verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:"root",patch:{profile:profile}}));verify(ctl.applyStructure())
                            tryVerify(function(){return scene.frontEnvelope.profile===profile})
                            wait(100)
                            grabImage(study).save("archive-b8-native-shelf-comparison-"+profile+"-b24.png")
                            verify(ctl.undo())
                        }
                        for(var index of [0,2]){
                            Themes.Theme.index=index;wait(100)
                            grabImage(study).save("archive-b8-native-shelf-comparison-crest-b24-theme"+index+".png")
                        }
                        Themes.Theme.index=1
                    }
                    verify(ctl.undo());if(ctl.snapshot.cubbies.root.b!==JSON.parse(before).cubbies.root.b)verify(ctl.undo())
                    compare(JSON.stringify(ctl.snapshot),before)
                }
            }finally{Themes.Theme.index=theme}
        }
        function test_room_depth_visibility(){
            var ctl=study.controller,scene=study.scene
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront})
            var roomId=ctl.snapshot.spatial.shelves.root.roomId,other=Object.keys(ctl.snapshot.spatial.shelves).find(k=>k!=="root")
            verify(ctl.proposeStructure({kind:"spatialRoomEdit",roomId:roomId,patch:{w:1800,h:2000}}));verify(ctl.applyStructure())
            verify(ctl.proposeStructure({kind:"spatialShelfEdit",containerId:other,patch:{roomId:roomId,x:1000,y:250,depth:250,orientation:0}}));verify(ctl.applyStructure())
            verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:other,patch:{profile:"pilaster"}}));verify(ctl.applyStructure())
            var before=JSON.stringify(ctl.snapshot)
            clickNamed("toggle-room-plan");clickNamed("toggle-room-perspective")
            var plan=findChild(study,"archive-room-plan"),art=findChild(study,"room-depth-art")
            tryVerify(function(){return !!plan.visibilityRaster&&art.paintCount>0})
            var ref=View.roomPerspective(ctl.snapshot,View.roomPlan(ctl.snapshot,roomId),1000,700).frame,actual=plan.perspectiveData.frame
            // Independent pinned Bugfinder coordinates, mapped by the same
            // camera's affine fit, never chosen using the current hit result.
            var x=(708-ref.ox)/ref.scale*actual.scale+actual.ox
            var y=(252-ref.oy)/ref.scale*actual.scale+actual.oy
            mouseClick(plan,x,y);tryCompare(plan,"selectedShelf",other)
            var q=Projection.rasterFaceAt(plan.visibilityRaster,x,y)
            compare(q.shelfId,other);compare(q.role,"right-post")
            var expected=View.roomPerspectiveColor(ctl.snapshot,q,plan.palettes,plan.desktopPalette,plan.colors),point=plan.mapToItem(study,x,y),shot
            try{
                tryVerify(function(){
                    shot=grabImage(study)
                    var px=Math.floor(point.x*shot.width/study.width),py=Math.floor(point.y*shot.height/study.height)
                    return Math.abs(shot.red(px,py)-parseInt(expected.slice(1,3),16))<10&&Math.abs(shot.green(px,py)-parseInt(expected.slice(3,5),16))<10&&Math.abs(shot.blue(px,py)-parseInt(expected.slice(5,7),16))<10
                },3000,"Near Shelf post appears over east wall")
            }finally{
                if(shot){
                    var px=Math.floor(point.x*shot.width/study.width),py=Math.floor(point.y*shot.height/study.height)
                    console.log("B8 depth sample",px,py,"expected",expected,"actual",shot.red(px,py),shot.green(px,py),shot.blue(px,py),"paintCount",art.paintCount)
                    shot.save("archive-b8-native-shelf-depth-multiple.png")
                }
            }
            var paints=art.paintCount;wait(250);compare(art.paintCount,paints)
            clickNamed("plan-inspect-shelf")
            tryVerify(function(){return scene.visible&&!plan.visible});compare(scene.cubbyId,other)
            paints=art.paintCount;wait(250);compare(art.paintCount,paints)
            compare(JSON.stringify(ctl.snapshot),before)
        }
        function test_room_perspective_and_rotation(){
            var ctl=study.controller,scene=study.scene
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront})
            var roomId=ctl.snapshot.spatial.shelves.root.roomId
            verify(ctl.proposeStructure({kind:"spatialRoomEdit",roomId:roomId,patch:{h:2000}}));verify(ctl.applyStructure())
            var before=JSON.stringify(ctl.snapshot)
            clickNamed("toggle-room-plan");clickNamed("toggle-room-perspective")
            var plan=findChild(study,"archive-room-plan")
            tryVerify(function(){return plan.visible&&plan.perspective&&!!plan.perspectiveData})
            var box=Spatial.footprint(ctl.snapshot,"root"),p=plan.pointFor(box.x+box.w/2,box.y+box.h/2),inv=plan.floorAt(p.x,p.y)
            verify(Math.abs(inv.x-box.x-box.w/2)<.001&&Math.abs(inv.y-box.y-box.h/2)<.001)
            function visibleSample(){
                var faces=plan.perspectiveData.faces
                for(var i=faces.length-1;i>=0;i--){
                    var f=faces[i];if(f.shelfId!=="root")continue
                    var x=f.points.reduce((n,q)=>n+q[0],0)/f.points.length,y=f.points.reduce((n,q)=>n+q[1],0)/f.points.length
                    var top=Projection.faceAt(plan.perspectiveData,x,y)
                    if(!top||top.index!==f.index)continue
                    // Require a broad interior sample on this painted face.
                    var area=0
                    for(var j=0;j<f.points.length;j++){var a=f.points[j],b=f.points[(j+1)%f.points.length];area+=a[0]*b[1]-b[0]*a[1]}
                    if(Math.abs(area)<800)continue
                    return {x:x,y:y,face:f}
                }
                return null
            }
            var sample=visibleSample();verify(!!sample)
            mouseClick(plan,sample.x,sample.y);tryCompare(plan,"selectedShelf","root")
            function captureSurface(v,name){
                var shot=null,pt=plan.mapToItem(study,v.x,v.y)
                var expected=View.roomPerspectiveColor(ctl.snapshot,v.face,plan.palettes,plan.desktopPalette,plan.colors)
                try{
                    tryVerify(function(){
                        shot=grabImage(study)
                        var x=Math.floor(pt.x*shot.width/study.width),y=Math.floor(pt.y*shot.height/study.height)
                        return x>=0&&y>=0&&x<shot.width&&y<shot.height&&Math.abs(shot.red(x,y)-parseInt(expected.slice(1,3),16))<10&&Math.abs(shot.green(x,y)-parseInt(expected.slice(3,5),16))<10&&Math.abs(shot.blue(x,y)-parseInt(expected.slice(5,7),16))<10
                    },3000,"Actual composed perspective face role color")
                }finally{
                    if(shot){
                        var x=Math.floor(pt.x*shot.width/study.width),y=Math.floor(pt.y*shot.height/study.height)
                        if(x>=0&&y>=0&&x<shot.width&&y<shot.height)console.log("B8 perspective sample",name,x,y,"expected",expected,"actual",shot.red(x,y),shot.green(x,y),shot.blue(x,y))
                        shot.save(name)
                    }
                }
            }
            captureSurface(sample,"archive-b8-native-shelf-perspective.png")
            compare(JSON.stringify(ctl.snapshot),before)
            study.switchMode("arrange")
            clickNamed("plan-turn-shelf")
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
            compare(ctl.structuralProposal.command.patch.orientation,90)
            verify(!!plan.rotationPreview);compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("plan-turn-shelf");clickNamed("structure-apply")
            tryVerify(function(){return ctl.snapshot.spatial.shelves.root.orientation===90&&!ctl.structuralProposal})
            compare(JSON.stringify(ctl.snapshot.cubbies),JSON.stringify(JSON.parse(before).cubbies))
            sample=visibleSample();verify(!!sample)
            captureSurface(sample,"archive-b8-native-shelf-perspective-rotated.png")
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            study.switchMode("browse")
            sample=visibleSample();verify(!!sample)
            mouseClick(plan,sample.x,sample.y);tryCompare(plan,"selectedShelf","root")
            clickNamed("plan-inspect-shelf")
            tryVerify(function(){return scene.visible&&!plan.visible});compare(scene.cubbyId,"root")
            compare(JSON.stringify(ctl.snapshot),before)
        }
        function test_physical_profiles_and_room_plan(){
            var ctl=study.controller,scene=study.scene,before=JSON.stringify(ctl.snapshot),oldTheme=Themes.Theme.index
            clickNamed("adopt-physical-profiles")
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
            clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("adopt-physical-profiles");clickNamed("structure-apply")
            tryVerify(function(){return scene.physicalFront})
            var adopted=JSON.stringify(ctl.snapshot),base=JSON.stringify(ctl.snapshot.cubbies)
            compare(base,JSON.stringify(JSON.parse(before).cubbies))
            try{
                for(var i=0;i<3;i++){
                    Themes.Theme.index=i
                    var profile=Spatial.shelfProfiles[i]
                    verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:"root",patch:{profile:profile}}))
                    verify(ctl.applyStructure())
                    var g=Spatial.shelfGeometry(ctl.snapshot,"root"),interior=findChild(scene,"cubby-interior")
                    tryVerify(function(){return scene.physicalFront&&scene.frontEnvelope.profile===profile})
                    compare(scene.worldItem.width,g.w);compare(scene.worldItem.height,g.h)
                    compare(interior.x,g.aperture.x);compare(interior.y,g.aperture.y)
                    verify(!!findChild(scene,"archive-book-org.example.Reader"))
                    var frame=findChild(scene,"physical-shelf-frame")
                    verify(frame.visible)
                    var post=g.parts[0].points,inside,outside,center,corner,shot=null
                    function pixel(point,c){
                        var x=Math.floor(point.x*shot.width/study.width),y=Math.floor(point.y*shot.height/study.height),hex=String(c)
                        return x>=0&&y>=0&&x<shot.width&&y<shot.height&&Math.abs(shot.red(x,y)-parseInt(hex.slice(1,3),16))<10&&Math.abs(shot.green(x,y)-parseInt(hex.slice(3,5),16))<10&&Math.abs(shot.blue(x,y)-parseInt(hex.slice(5,7),16))<10
                    }
                    // Wait for the actual layout and evaluate the same
                    // world points in the frame used by each capture.
                    // Keep every original color and tolerance assertion.
                    try{
                        tryVerify(function(){
                            inside=frame.mapToItem(study,(post[0][0]+post[1][0])/2,g.aperture.y+g.aperture.h/2)
                            outside=frame.mapToItem(study,1,g.aperture.y+g.aperture.h/2)
                            center=frame.mapToItem(study,g.w/2,g.inscription.y/2)
                            corner=frame.mapToItem(study,4,g.inscription.y/2)
                            shot=grabImage(study)
                            if(!pixel(inside,frame.frameColor)||!pixel(outside,scene.colors.background))return false
                            if(profile==="crest")return pixel(center,View.mix(String(frame.frameColor),scene.colors.metal,.16))&&pixel(corner,scene.colors.background)
                            return true
                        },3000,"Actual profile post, raised crest and open overhang space")
                    }finally{
                        if(shot){
                            function describe(point,expected){
                                var px=Math.floor(point.x*shot.width/study.width),py=Math.floor(point.y*shot.height/study.height)
                                return {x:px,y:py,expected:String(expected),rgb:px>=0&&py>=0&&px<shot.width&&py<shot.height?[shot.red(px,py),shot.green(px,py),shot.blue(px,py)]:null}
                            }
                            console.log("B8 profile sample",profile,JSON.stringify({post:describe(inside,frame.frameColor),overhang:describe(outside,scene.colors.background),crest:profile==="crest"?describe(center,View.mix(String(frame.frameColor),scene.colors.metal,.16)):null,crestCorner:profile==="crest"?describe(corner,scene.colors.background):null,viewport:[scene.width,scene.height],camera:scene.camera}))
                            shot.save("archive-b8-native-shelf-profile-"+profile+".png")
                        }
                    }
                    clickNamed("toggle-room-plan")
                    var plan=findChild(study,"archive-room-plan")
                    tryVerify(function(){return plan.visible&&!scene.visible&&!!plan.planData})
                    var entry=plan.planData.shelves.find(s=>s.id==="root"),box=entry.box
                    compare(JSON.stringify(box),JSON.stringify(Spatial.footprint(ctl.snapshot,"root")))
                    var pos=plan.pointFor(box.x+box.w/2,box.y+box.h/2)
                    mouseClick(plan,pos.x,pos.y)
                    tryCompare(plan,"selectedShelf","root")
                    var rim=plan.mapToItem(study,plan.pointFor(box.x+3,box.y+3).x,plan.pointFor(box.x+3,box.y+3).y)
                    tryVerify(function(){shot=grabImage(study);return pixel(rim,scene.colors.metal)},3000,"Actual composed H glyph rim")
                    shot.save("archive-b8-native-shelf-room-"+profile+".png")
                    clickNamed("plan-inspect-shelf")
                    tryVerify(function(){return scene.visible&&!plan.visible})
                    compare(scene.cubbyId,"root")
                    verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),adopted)
                }
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                tryVerify(function(){return !scene.physicalFront})
            }finally{Themes.Theme.index=oldTheme;study.roomPlanOpen=false}
        }
        function test_architectural_removal_and_ready_preview(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot)
            study.switchMode("arrange")
            var old=ctl.snapshot.cubbies.root.mods.find(m=>m.id==="rack-1")
            ctl.stage("root","rack-1",{y:old.y+10})
            tryCompare(ctl,"phase","ready",8000)
            var top=findChild(scene,"mixed-top-rack-1")
            tryVerify(function(){top=findChild(scene,"mixed-top-rack-1");return !!top&&top.y+top.supportY===old.y+10})
            compare(JSON.stringify(ctl.snapshot),before)
            ctl.cancel()
            tryVerify(function(){top=findChild(scene,"mixed-top-rack-1");return !!top&&top.y+top.supportY===old.y})
            scene.clearSelection()
            clickNamed("arrange-menu");clickNamed("remove-architectural-shelf")
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
            compare(ctl.structuralProposal.appUnplacementCount,2)
            verify(ctl.structuralProposal.caseTransferCount>0)
            compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("arrange-menu");clickNamed("remove-architectural-shelf");clickNamed("structure-apply")
            var other=Object.keys(ctl.snapshot.spatial.shelves)[0]
            tryCompare(scene,"cubbyId",other)
            verify(!ctl.snapshot.cubbies.root);compare(Spatial.appPlacements(ctl.snapshot).length,0)
            verify(!!ctl.snapshot.spatial.apps["org.example.Reader"])
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
        }
        function test_book_drag_preview_cancel_apply(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot)
            study.switchMode("arrange")
            scene.snapEnabled=true;scene.snapDistance=20
            var book=findChild(scene,"archive-book-org.example.Reader")
            verify(!!book)
            // Use scene coordinates throughout the gesture, not a moving item.
            var p=book.mapToItem(scene,book.width/2,book.height/2)
            var dx=Math.round(60*scene.camera.scale)
            mousePress(scene,p.x,p.y,Qt.LeftButton)
            tryVerify(function(){return !!scene.bookDrag})
            mouseMove(scene,p.x+dx,p.y,20,Qt.LeftButton)
            tryVerify(function(){return !!scene.bookDrag&&scene.bookDrag.active})
            compare(scene.bookDrag.targetX,160)
            verify(findChild(scene,"book-drag-outline").visible)
            verify(!ctl.structuralProposal);compare(JSON.stringify(ctl.snapshot),before)
            mouseRelease(scene,p.x+dx,p.y,Qt.LeftButton)
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
            compare(ctl.structuralProposal.command.appId,"org.example.Reader")
            compare(ctl.structuralProposal.command.patch.x,160)
            compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("structure-cancel")
            compare(JSON.stringify(ctl.snapshot),before)
            // Repeat with actual pointer input, then Apply and Undo.
            book=findChild(scene,"archive-book-org.example.Reader");p=book.mapToItem(scene,book.width/2,book.height/2)
            mousePress(scene,p.x,p.y,Qt.LeftButton);mouseMove(scene,p.x+dx,p.y,20,Qt.LeftButton);mouseRelease(scene,p.x+dx,p.y,Qt.LeftButton)
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
            clickNamed("structure-apply")
            tryVerify(function(){return !ctl.structuralProposal&&Spatial.appPlacements(ctl.snapshot).some(a=>a.appId==="org.example.Reader"&&a.x===160)})
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            // Invalid placement stays uncommitted and refuses Apply.
            book=findChild(scene,"archive-book-org.example.Reader");p=book.mapToItem(scene,book.width/2,book.height/2)
            var left=Math.round(100*scene.camera.scale)
            mousePress(scene,p.x,p.y,Qt.LeftButton);mouseMove(scene,p.x-left,p.y,20,Qt.LeftButton);mouseRelease(scene,p.x-left,p.y,Qt.LeftButton)
            tryVerify(function(){return !!ctl.structuralProposal&&!ctl.structuralProposal.ok})
            verify(!findChild(study,"structure-apply").enabled)
            compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("structure-cancel")
            // Escape during an active press cancels without a release proposal.
            book=findChild(scene,"archive-book-org.example.Reader");p=book.mapToItem(scene,book.width/2,book.height/2)
            mousePress(scene,p.x,p.y,Qt.LeftButton);mouseMove(scene,p.x+dx,p.y,20,Qt.LeftButton)
            tryVerify(function(){return !!scene.bookDrag&&scene.bookDrag.active})
            keyClick(Qt.Key_Escape)
            tryVerify(function(){return !scene.bookDrag})
            mouseRelease(scene,p.x+dx,p.y,Qt.LeftButton)
            verify(!ctl.structuralProposal);compare(JSON.stringify(ctl.snapshot),before)
            scene.snapEnabled=false
        }
        function test_picker_and_support_controls(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot)
            study.switchMode("arrange")
            var top=findChild(scene,"mixed-top-rack-1"),book=findChild(top,"archive-book-org.example.Reader")
            verify(!!book);mouseClick(book,book.width/2,book.height/2)
            tryCompare(scene,"selectedAppId","org.example.Reader")
            clickNamed("arrange-menu");clickNamed("place-book");clickNamed("pick-book-org.example.Atlas")
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok},3000)
            compare(ctl.structuralProposal.command.appId,"org.example.Atlas")
            compare(JSON.stringify(ctl.snapshot),before)
            tryVerify(function(){return !!findChild(scene,"archive-book-org.example.Atlas")})
            clickNamed("structure-cancel")
            tryVerify(function(){return !findChild(scene,"archive-book-org.example.Atlas")})
            compare(JSON.stringify(ctl.snapshot),before)
            // Check another row after reopening, then repeat the original
            // Atlas input. No fallback, retry or direct controller placement.
            clickNamed("arrange-menu");clickNamed("place-book")
            tryVerify(function(){return study.bookPicker&&!study.contextOpen})
            clickNamed("pick-book-org.example.Reader")
            tryVerify(function(){return !!ctl.structuralProposal})
            compare(ctl.structuralProposal.command.appId,"org.example.Reader")
            clickNamed("structure-cancel")
            compare(JSON.stringify(ctl.snapshot),before)
            // Re-select the book and place Atlas through the same visible controls.
            top=findChild(scene,"mixed-top-rack-1");book=findChild(top,"archive-book-org.example.Reader")
            mouseClick(book,book.width/2,book.height/2);clickNamed("arrange-menu");clickNamed("place-book")
            tryVerify(function(){return study.bookPicker&&!study.contextOpen})
            clickNamed("pick-book-org.example.Atlas")
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok},3000)
            compare(ctl.structuralProposal.command.appId,"org.example.Atlas")
            var input=findChild(study,"book-position-input")
            verify(!!input)
            var position=ctl.structuralProposal.command.patch.x
            mouseClick(input,input.width/2,input.height/2)
            keyClick(Qt.Key_A,Qt.ControlModifier);keyClick(Qt.Key_Backspace)
            tryVerify(function(){return !!ctl.structuralProposal&&!ctl.structuralProposal.ok})
            compare(input.text,"")
            // Qt 6.4 QtTest exposes keyClick for individual characters.
            var digits=String(position)
            for(var i=0;i<digits.length;i++)keyClick(digits[i])
            tryVerify(function(){return !!ctl.structuralProposal&&ctl.structuralProposal.ok})
            compare(ctl.structuralProposal.command.patch.x,position)
            var attempts=study.structureApplyAttempts
            clickNamed("structure-apply")
            tryCompare(study,"structureApplyAttempts",attempts+1,3000)
            verify(!ctl.structuralProposal,study.structureApplyError+" / "+ctl.errorText)
            verify(Spatial.appPlacements(ctl.snapshot).some(p=>p.appId==="org.example.Atlas"),"Apply must commit the selected book")
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            top=findChild(scene,"mixed-top-rack-1");book=findChild(top,"archive-book-org.example.Reader")
            mouseClick(book,book.width/2,book.height/2);clickNamed("arrange-menu");clickNamed("toggle-flat-top")
            tryVerify(function(){return !!ctl.structuralProposal&&!ctl.structuralProposal.ok})
            verify(ctl.structuralProposal.error.indexOf("Resolve supported")>=0)
            clickNamed("structure-cancel");compare(JSON.stringify(ctl.snapshot),before)
            top=findChild(scene,"mixed-top-rack-1");book=findChild(top,"archive-book-org.example.Reader")
            mouseClick(book,book.width/2,book.height/2);clickNamed("arrange-menu");clickNamed("unplace-selected-book");clickNamed("structure-apply")
            tryVerify(function(){return !Spatial.appPlacements(ctl.snapshot).some(p=>p.appId==="org.example.Reader")},3000,study.structureApplyError+" / "+ctl.errorText)
            verify(!!ctl.snapshot.spatial.apps["org.example.Reader"]);verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
        }
        function test_shelf_local_appearance(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot)
            study.switchMode("arrange");scene.clearSelection()
            clickNamed("arrange-menu");clickNamed("shelf-appearance")
            tryVerify(function(){return !!ctl.structuralProposal})
            clickNamed("shelf-profile-pilaster")
            tryVerify(function(){return ctl.structuralProposal.ok&&ctl.structuralProposal.command.patch.profile==="pilaster"})
            var trim=findChild(scene,"architectural-frame-detail")
            tryCompare(trim,"profile","pilaster")
            clickNamed("shelf-palette-2")
            tryVerify(function(){return scene.colors.name==="Midnight"})
            compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("structure-cancel")
            tryCompare(trim,"profile","cornice")
            compare(JSON.stringify(ctl.snapshot),before)
            clickNamed("arrange-menu");clickNamed("shelf-appearance");clickNamed("shelf-profile-crest")
            tryCompare(trim,"profile","crest")
            clickNamed("structure-apply")
            tryVerify(function(){return !ctl.structuralProposal&&Spatial.shelfProfile(ctl.snapshot,"root")==="crest"})
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            tryCompare(trim,"profile","cornice")
        }
        function test_nested_inventory_counts(){
            var scene=study.scene,ctl=study.controller
            var sample=Sample.inventoryFixture(),oldMode=scene.cubbyPreviewMode
            ctl.reset(sample)
            var parentId=sample.path[0]
            tryCompare(scene,"cubbyId",parentId)
            var before=JSON.stringify(ctl.snapshot)
            try{
                scene.cubbyPreviewMode="inventory"
                var face=findChild(scene,"cubby-inventory-parent-face")
                tryVerify(function(){face=findChild(scene,"cubby-inventory-parent-face");return !!face&&face.previewMode==="inventory"&&!!face.inventory})
                compare(face.inventory.items,20)
                compare(face.inventory.cubby,1)
                var label=findChild(face,"cubby-inventory-item-label")
                verify(!!label&&label.visible)
                compare(label.text,"1 cubbies · 20 items")
                compare(JSON.stringify(ctl.snapshot),before)
            }finally{scene.cubbyPreviewMode=oldMode}
        }
        function test_idle_hidden_and_populated_navigation(){
            var scene=study.scene,ctl=study.controller,oldTheme=Themes.Theme.index
            // Larger populated study; only the selected Shelf should render.
            var sample=Sample.populatedFixture(8)
            ctl.reset(sample);scene.viewPath=["root"];scene.restoreCamera()
            var before=JSON.stringify(ctl.snapshot),board=findChild(scene,"shelf-mixed-board")
            tryVerify(function(){board=findChild(scene,"shelf-mixed-board");return !!board&&board.paintPasses>0})
            verify(!findChild(scene,"archive-book-sample-1-org.example.Reader"))
            verify(!scene.motionClockActive);verify(!scene.busy)
            // Let scheduled initial paints settle before the sample window.
            wait(100)
            var paints=board.paintPasses,steps=scene.motionStepCount
            wait(250)
            compare(board.paintPasses,paints);compare(scene.motionStepCount,steps);verify(!scene.motionClockActive)
            try{
                study.visible=false
                wait(50)
                paints=board.paintPasses
                Themes.Theme.index=(oldTheme+1)%3
                wait(250)
                compare(board.paintPasses,paints);compare(scene.motionStepCount,steps);verify(!scene.motionClockActive)
                study.visible=true
                tryVerify(function(){return board.paintPasses>paints})
                compare(JSON.stringify(ctl.snapshot),before)
                verify(scene.openShelf("sample-1-root"))
                tryVerify(function(){return !!findChild(scene,"archive-book-sample-1-org.example.Reader")})
                verify(!findChild(scene,"archive-book-org.example.Reader"))
                verify(scene.openChild("sample-1-child"))
                tryCompare(scene,"cubbyId","sample-1-child")
                verify(scene.back());tryCompare(scene,"cubbyId","sample-1-root")
                compare(JSON.stringify(ctl.snapshot),before)
                console.log("B8 N2d idle probes: 250 ms visible and hidden, zero additional board paints or physics steps; hidden theme change repaints on show; selected hierarchy only.")
            }finally{study.visible=true;Themes.Theme.index=oldTheme}
        }
        function test_ornament_family_preview(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot),oldTheme=Themes.Theme.index
            try{
                Themes.Theme.index=1
                study.switchMode("arrange");scene.clearSelection()
                clickNamed("arrange-menu");clickNamed("shelf-appearance")
                clickNamed("shelf-family-astral")
                var mark=findChild(scene,"archive-backing-ornament")
                tryCompare(mark,"family","Astral")
                tryCompare(mark,"status",Image.Ready)
                var child=findChild(scene,"cubby-cubby-child"),childMark=findChild(child,"cubby-face-ornament")
                tryCompare(childMark,"family","Astral")
                compare(JSON.stringify(ctl.snapshot),before)
                clickNamed("shelf-family-none")
                tryCompare(mark,"family","None");verify(!mark.visible)
                clickNamed("shelf-family-inherit")
                tryCompare(mark,"family","Architectural")
                clickNamed("shelf-family-botanical")
                clickNamed("structure-apply")
                tryVerify(function(){return !ctl.structuralProposal&&Spatial.resolveAppearance(ctl.snapshot,"root",1).family==="Botanical"})
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                // Exercise all archived default images in the actual native
                // delegate. The second Shelf has an unobstructed upper backing.
                study.switchMode("browse")
                var other=Object.keys(ctl.snapshot.spatial.shelves).find(k=>k!=="root")
                verify(scene.openShelf(other))
                mark=findChild(scene,"archive-backing-ornament")
                var families=["Architectural","Astral","Botanical","Bestiary","Elemental · Water","Elemental · Air","Elemental · Earth","Elemental · Fire","Horological"]
                for(var i=0;i<families.length;i++){
                    verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:other,patch:{family:families[i]}}))
                    verify(ctl.applyStructure())
                    tryCompare(mark,"family",families[i]);tryCompare(mark,"status",Image.Ready)
                    verify(ctl.undo())
                }
                compare(JSON.stringify(ctl.snapshot),before)
            }finally{Themes.Theme.index=oldTheme}
        }
        function test_spatial_theme_comparison(){
            var scene=study.scene,ctl=study.controller,before=JSON.stringify(ctl.snapshot),oldTheme=Themes.Theme.index
            var covers=[]
            try{
                for(var i=0;i<3;i++){
                    Themes.Theme.index=i
                    tryVerify(function(){return scene.colors.name===Themes.Theme.palettes[i].name})
                    var book=findChild(scene,"archive-book-org.example.Reader")
                    var board=findChild(scene,"shelf-mixed-board")
                    var face=findChild(board,"flat-board-face")
                    verify(!!book&&!!board&&!!face&&face.visible)
                    verify(findChild(scene,"architectural-frame-detail").visible)
                    covers.push(String(book.coverColor))
                    compare(board.supportY,0)
                    // Read composed pixels in the actual board face, not just
                    // its QML colour property. Count a broad flat-fill region.
                    function matching(shot,item,c,inset){
                        var a=item.mapToItem(study,inset,inset),b=item.mapToItem(study,item.width-inset,item.height-inset)
                        var left=Math.max(0,Math.ceil(a.x*shot.width/study.width)),right=Math.min(shot.width-1,Math.floor(b.x*shot.width/study.width))
                        var top=Math.max(0,Math.ceil(a.y*shot.height/study.height)),bottom=Math.min(shot.height-1,Math.floor(b.y*shot.height/study.height))
                        var matched=0
                        for(var y=top;y<bottom;y++)for(var x=left;x<right;x++){
                            if(Math.abs(shot.red(x,y)-Math.round(c.r*255))<8&&Math.abs(shot.green(x,y)-Math.round(c.g*255))<8&&Math.abs(shot.blue(x,y)-Math.round(c.b*255))<8)matched++
                        }
                        return matched
                    }
                    var frame=null
                    tryVerify(function(){
                        frame=grabImage(study)
                        return matching(frame,face,face.fillColor,2)>20&&matching(frame,book,book.coverColor,8)>20
                    },3000,"Resolved board and book colours visible in composed frame")
                    verify(frame.width>0&&frame.height>0)
                    frame.save("archive-b8-native-shelf-"+Themes.Theme.palettes[i].name.toLowerCase()+".png")
                    compare(JSON.stringify(ctl.snapshot),before)
                }
                verify(covers[0]!==covers[1]&&covers[1]!==covers[2]&&covers[0]!==covers[2])
                Themes.Theme.index=1
                verify(ctl.proposeStructure({kind:"spatialAppearance",containerId:"root",patch:{palette:0}}))
                verify(ctl.applyStructure())
                tryVerify(function(){return scene.colors.name==="Evening"})
                var faceChild=findChild(scene,"cubby-cubby-child")
                verify(!!faceChild);compare(faceChild.colors.name,"Twilight")
                verify(scene.openChild("child"));tryVerify(function(){return scene.colors.name==="Twilight"})
                verify(scene.back());tryVerify(function(){return scene.colors.name==="Evening"})
                verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
                tryVerify(function(){return scene.colors.name==="Twilight"})
            }finally{Themes.Theme.index=oldTheme}
        }
        function test_shelf_input_and_support(){
            var scene=study.scene,ctl=study.controller
            var before=JSON.stringify(ctl.snapshot)
            var top=findChild(scene,"mixed-top-rack-1")
            tryVerify(function(){top=findChild(scene,"mixed-top-rack-1");return !!top&&!!findChild(top,"archive-book-org.example.Reader")&&!!findChild(top,"mixed-parcel")})
            var book=findChild(top,"archive-book-org.example.Reader"),parcel=findChild(top,"mixed-parcel")
            tryCompare(parcel,"imageStatus",Image.Ready)
            compare(book.y+book.height,top.supportY)
            compare(top.y+top.supportY,scene.moduleItem("rack-1").y)
            mouseClick(book,book.width/2,book.height/2)
            tryVerify(function(){return scene.message.indexOf("Reader")>=0})
            compare(JSON.stringify(ctl.snapshot),before)
            mouseClick(parcel,parcel.width/2,parcel.height/2)
            tryCompare(scene,"selectedScrollId","mixed-parcel")
            scene.forceActiveFocus();keyClick(Qt.Key_X,Qt.ControlModifier)
            tryVerify(function(){return !scene.busy&&ctl.snapshot.caseItems.some(r=>r.id==="mixed-parcel")})
            verify(ctl.undo());compare(JSON.stringify(ctl.snapshot),before)
            var other=Object.keys(ctl.snapshot.spatial.shelves).find(k=>k!=="root")
            scene.zoom=1.2;scene.pan=Qt.point(17,-9)
            var button=findChild(study,"open-shelf-"+other)
            verify(!!button);mouseClick(button,button.width/2,button.height/2)
            tryCompare(scene,"cubbyId",other)
            compare(scene.zoom,1)
            var first=findChild(study,"open-shelf-root")
            mouseClick(first,first.width/2,first.height/2)
            tryCompare(scene,"cubbyId","root")
            compare(scene.zoom,1.2);compare(scene.pan,Qt.point(17,-9))
            compare(JSON.stringify(ctl.snapshot),before)
            scene.zoom=1;scene.pan=Qt.point(0,0)
            tryVerify(function(){return !!findChild(scene,"archive-book-org.example.Notes")})
            tryVerify(function(){return !!findChild(scene,"archive-book-org.example.Reader")})
            // Wait for the actual composed cover rather than assuming a
            // delegate's existence means its scene-graph frame is ready.
            var frame=grabImage(study)
            verify(frame.width>0&&frame.height>0)
            frame.save("archive-b8-native-shelf.png")
            // Actual composed book pixels: stable interior cover region.
            top=findChild(scene,"mixed-top-rack-1");book=findChild(top,"archive-book-org.example.Reader")
            var p=book.mapToItem(study,book.width/2,book.height/2)
            verify(p.x>0&&p.y>0&&p.x<study.width&&p.y<study.height)
            var a=book.mapToItem(study,8,8),b=book.mapToItem(study,book.width-8,book.height-8)
            tryVerify(function(){
                frame=grabImage(study);frame.save("archive-b8-native-shelf.png")
                var matched=0
                var left=Math.max(0,Math.ceil(a.x*frame.width/study.width)),right=Math.min(frame.width-1,Math.floor(b.x*frame.width/study.width))
                var topY=Math.max(0,Math.ceil(a.y*frame.height/study.height)),bottom=Math.min(frame.height-1,Math.floor(b.y*frame.height/study.height))
                for(var y=topY;y<bottom;y++)for(var x=left;x<right;x++){
                    if(Math.abs(frame.red(x,y)-Math.round(book.coverColor.r*255))<8&&Math.abs(frame.green(x,y)-Math.round(book.coverColor.g*255))<8&&Math.abs(frame.blue(x,y)-Math.round(book.coverColor.b*255))<8)matched++
                }
                return matched>20
            },3000,"Book cover visible in actual composed frame")
        }
    }
}
