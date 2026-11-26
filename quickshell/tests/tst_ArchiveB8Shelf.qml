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
            mouseClick(item,item.width/2,item.height/2)
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
                tryVerify(function(){return study.roomProgress>0&&study.roomProgress<1})
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
                tryVerify(function(){
                    shot=grabImage(study)
                    var x=Math.floor(pt.x*shot.width/study.width),y=Math.floor(pt.y*shot.height/study.height)
                    return x>=0&&y>=0&&x<shot.width&&y<shot.height&&Math.abs(shot.red(x,y)-parseInt(expected.slice(1,3),16))<10&&Math.abs(shot.green(x,y)-parseInt(expected.slice(3,5),16))<10&&Math.abs(shot.blue(x,y)-parseInt(expected.slice(5,7),16))<10
                },3000,"Actual composed perspective face role color")
                shot.save(name)
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
                    var post=g.parts[0].points,inside=frame.mapToItem(study,(post[0][0]+post[1][0])/2,g.aperture.y+g.aperture.h/2)
                    var outside=frame.mapToItem(study,1,g.aperture.y+g.aperture.h/2)
                    var shot=null
                    function pixel(point,c){
                        var x=Math.floor(point.x*shot.width/study.width),y=Math.floor(point.y*shot.height/study.height),hex=String(c)
                        return x>=0&&y>=0&&x<shot.width&&y<shot.height&&Math.abs(shot.red(x,y)-parseInt(hex.slice(1,3),16))<10&&Math.abs(shot.green(x,y)-parseInt(hex.slice(3,5),16))<10&&Math.abs(shot.blue(x,y)-parseInt(hex.slice(5,7),16))<10
                    }
                    tryVerify(function(){
                        shot=grabImage(study)
                        if(!pixel(inside,frame.frameColor)||!pixel(outside,scene.colors.background))return false
                        if(profile==="crest"){
                            var center=frame.mapToItem(study,g.w/2,g.inscription.y/2)
                            var corner=frame.mapToItem(study,4,g.inscription.y/2)
                            return pixel(center,View.mix(String(frame.frameColor),scene.colors.metal,.16))&&pixel(corner,scene.colors.background)
                        }
                        return true
                    },3000,"Actual profile post, raised crest and open overhang space")
                    shot.save("archive-b8-native-shelf-profile-"+profile+".png")
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
