import QtQuick
import QtTest
import "../archive" as Archive
import "../archive/ArchiveCore.mjs" as Core
Item {
    id:testRoot
    width:800;height:500
    Archive.ArchiveModel { id:controller }
    ArchiveNativeN2Study { id:study;anchors.fill:parent;visible:false }
    Archive.ArchiveInspectorFrame {
        id:sharedFrame
        visible:false
        colors:study.colors
        availableWidth:180;availableHeight:120
        preferredWidth:280;preferredHeight:200
        Archive.ArchiveInspectorScroll {
            id:sharedScroll
            anchors.fill:parent
            contentHeight:400
        }
    }
    TestCase {
        name:"ArchiveNativeN3r1"
        when:windowShown
        function init(){
            testRoot.width=800;testRoot.height=500
            controller.reset(Core.fixture())
            study.closeContext();study.closeMaterials();study.rackInspector=false
            study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange"
            study.scene.zoom=1;study.scene.pan=Qt.point(0,0);study.scene.clearSelection()
            study.scene.cubbyPreviewMode="veiled"
            study.scene.snapEnabled=false;study.scene.showGrid=false;study.scene.snapDistance=20
        }
        function cleanup(){
            // A failed assertion must not leave a modal overlay intercepting
            // the next test's actual pointer input.
            study.closeContext();study.closeMaterials();study.rackInspector=false
            study.controller.cancel()
            study.visible=false
            testRoot.width=800;testRoot.height=500
        }
        function waitForClickTarget(item,fx,fy){
            verify(!!item)
            var last=""
            // waitForRendering waits for a NEW frame swap, not proof that an
            // already-rendered item is visible. Idle software scenes need not
            // swap again. Instead process events and require stable geometry
            // and a point inside every clipping ancestor and the study.
            tryVerify(function(){
                if(!item.visible||!item.enabled||item.width<=0||item.height<=0){last="";return false}
                var x=item.width*fx,y=item.height*fy
                var p=item.mapToItem(study,x,y)
                if(p.x<0||p.y<0||p.x>=study.width||p.y>=study.height){last="";return false}
                for(var ancestor=item.parent;ancestor;ancestor=ancestor.parent){
                    if(!ancestor.clip)continue
                    var q=item.mapToItem(ancestor,x,y)
                    if(q.x<0||q.y<0||q.x>=ancestor.width||q.y>=ancestor.height){last="";return false}
                }
                var now=[p.x,p.y,item.width,item.height].join(",")
                var settled=last===now
                last=now
                return settled
            },2000,"Control not visible at a stable clickable point: "+item.objectName)
        }
        function clickControl(item,button){
            waitForClickTarget(item,.5,.5)
            // Real mouse delivery, not a direct signal or controller call.
            mouseClick(item,item.width/2,item.height/2,button||Qt.LeftButton)
        }
        function snap(){return JSON.stringify(controller.snapshot)}
        function proposal(){return {kind:"create",type:"cubby",cubbyId:"root",patch:{x:520,y:0,w:160,h:120}}}
        function view(){return {path:["root"],theme:1,cameras:{root:{zoom:1,x:12,y:-9}}}}
        function test_structural_preview_cancel_apply(){
            var before=snap(),revision=controller.archiveState.revision
            verify(controller.proposeStructure(proposal()))
            compare(snap(),before)
            compare(controller.archiveState.revision,revision)
            compare(controller.archiveState.history.length,0)
            verify(!controller.undo())
            controller.stage("root","rack-1",{r:64})
            verify(!controller.draft)
            controller.cancelStructure()
            compare(snap(),before)
            verify(controller.proposeStructure(proposal()))
            verify(controller.applyStructure())
            compare(controller.snapshot.cubbies.root.mods.length,2)
            verify(controller.undo())
            compare(snap(),before)
        }
        function test_checkpoint_round_trip(){
            verify(controller.proposeStructure(proposal()))
            compare(controller.exportCheckpoint(view()),"")
            verify(controller.applyStructure())
            var before=snap(),saved=controller.exportCheckpoint(view())
            verify(saved.length>0,controller.checkpointError)
            controller.reset(Core.fixture())
            var original=snap()
            verify(controller.importCheckpoint("{broken")===null)
            compare(snap(),original)
            var result=controller.importCheckpoint(saved)
            verify(!!result,controller.checkpointError)
            compare(snap(),before)
            compare(result.theme,1)
            compare(result.cameras.root.x,12)
            compare(controller.archiveState.history.length,0)
        }
        function test_occupied_delete_to_case(){
            var before=snap()
            verify(controller.proposeStructure({kind:"delete",cubbyId:"root",moduleId:"rack-1"}))
            compare(controller.structuralProposal.caseTransferCount,3)
            compare(snap(),before)
            controller.cancelStructure()
            compare(snap(),before)
            verify(controller.proposeStructure({kind:"delete",cubbyId:"root",moduleId:"rack-1"}))
            verify(controller.applyStructure())
            compare(controller.snapshot.cubbies.root.mods.length,0)
            compare(controller.snapshot.caseItems.length,3)
            verify(controller.snapshot.caseItems.every(function(v){return v.originStale}))
            verify(controller.undo());compare(snap(),before)
        }
        function test_actual_shelf_and_delete_controls(){
            study.visible=true
            study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"]
            study.scene.mode="arrange"
            study.scene.clearSelection()
            var before=JSON.stringify(study.controller.snapshot)
            mouseClick(study.scene,4,4,Qt.RightButton)
            var button=findChild(study,"add-shelf")
            verify(!!button&&button.visible&&button.enabled)
            mouseClick(button,button.width/2,button.height/2)
            tryVerify(function(){return !!study.controller.structuralProposal})
            verify(study.controller.structuralProposal.ok)
            compare(JSON.stringify(study.controller.snapshot),before)
            var apply=findChild(study,"structure-apply"),panel=findChild(study,"structure-panel")
            verify(panel.visible)
            tryVerify(function(){return panel.height<=study.scene.height-16&&panel.width<=study.width-16})
            var scroll=findChild(study,"structure-scroll")
            verify(scroll.clip)
            var widthBefore=study.controller.structuralProposal.command.patch.w
            clickControl(findChild(study,"structure-minus-w"))
            compare(study.controller.structuralProposal.command.patch.w,widthBefore-10)
            compare(JSON.stringify(study.controller.snapshot),before)
            verify(study.controller.structuralProposal.ok)
            clickControl(apply)
            tryVerify(function(){return study.controller.snapshot.cubbies.root.mods.length===2})
            var id=study.controller.snapshot.cubbies.root.mods[1].id
            tryVerify(function(){return !!study.scene.moduleItem(id)})
            var board=study.scene.moduleItem(id)
            compare(board.supportY,0);compare(board.height,15)
            mouseClick(board,board.width/2,board.height/2)
            compare(study.scene.selectedModuleId,id)
            mouseClick(board,board.width/2,board.height/2,Qt.RightButton)
            var edit=findChild(study,"edit-shelf")
            verify(edit.visible&&edit.enabled)
            mouseClick(edit,edit.width/2,edit.height/2)
            verify(!!study.controller.structuralProposal)
            var cancel=findChild(study,"structure-cancel")
            clickControl(cancel)
            verify(!study.controller.structuralProposal)
            mouseClick(board,board.width/2,board.height/2,Qt.RightButton)
            var del=findChild(study,"delete-fixture")
            mouseClick(del,del.width/2,del.height/2)
            verify(!!study.controller.structuralProposal)
            compare(study.controller.structuralProposal.caseTransferCount,0)
            clickControl(apply)
            compare(JSON.stringify(study.controller.snapshot.cubbies.root.mods),JSON.stringify(Core.fixture().cubbies.root.mods))
            study.visible=false
        }
        function test_rack_radius_slider(){
            study.visible=true;study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            var before=JSON.stringify(study.controller.snapshot)
            tryVerify(function(){return !!study.scene.moduleItem("rack-1")})
            var rack=study.scene.moduleItem("rack-1")
            verify(waitForRendering(rack,2000))
            mouseClick(rack,100,100,Qt.RightButton)
            tryCompare(study.scene,"selectedModuleId","rack-1")
            var entry=findChild(study,"edit-rack")
            tryCompare(study,"contextOpen",true)
            // A newly opened menu needs its first polish, unlike an idle
            // already-visible Back button. Frame swap is only a best-effort
            // barrier; geometry and the delivered input remain mandatory.
            waitForRendering(entry,250)
            clickControl(entry)
            tryVerify(function(){return study.rackInspector&&!study.contextOpen},
                      2000,"Rack menu click did not open inspector; selected="+study.scene.selectedModuleId+"; ready="+study.structureReady+"; menu="+study.contextOpen)
            var slider=findChild(study,"rack-radius-slider"),panel=findChild(study,"rack-inspector")
            tryVerify(function(){return slider.visible&&slider.width>18&&slider.height>0})
            waitForClickTarget(slider,9/slider.width,.5)
            var p=slider.mapToItem(panel,9,slider.height/2)
            verify(p.x>=0&&p.y>=0&&p.x<panel.width&&p.y<panel.height,
                   "Radius control is clipped: "+p.x+","+p.y+" in "+panel.width+"x"+panel.height)
            compare(slider.value,75)
            mouseClick(slider,9,slider.height/2)
            tryVerify(function(){return !!study.controller.draft},5000,
                      "No pointer draft; slider="+slider.value+"; rack="+study.scene.selectedModuleId+"; error="+study.controller.errorText)
            compare(study.controller.draft.proposed.r,38)
            compare(JSON.stringify(study.controller.snapshot),before)
            tryCompare(study.controller,"phase","attention",15000)
            verify(study.controller.radiusApprovalRequired)
            study.scene.forceActiveFocus();keyClick(Qt.Key_Escape)
            compare(JSON.stringify(study.controller.snapshot),before)
            verify(!study.controller.draft);verify(!slider.visible)
            // The rack-specific control has a keyboard equivalent as well.
            rack=study.scene.moduleItem("rack-1")
            mouseClick(rack,100,100,Qt.RightButton)
            tryCompare(study.scene,"selectedModuleId","rack-1")
            tryCompare(study,"contextOpen",true)
            waitForRendering(entry,250)
            clickControl(entry)
            tryVerify(function(){return study.rackInspector&&!study.contextOpen&&slider.visible&&slider.activeFocus},2000,
                      "Rack keyboard inspector not focused; selected="+study.scene.selectedModuleId+"; menu="+study.contextOpen)
            keyClick(Qt.Key_Home)
            tryVerify(function(){return !!study.controller.draft})
            compare(study.controller.draft.proposed.r,38)
            compare(JSON.stringify(study.controller.snapshot),before)
            keyClick(Qt.Key_Escape)
            verify(!study.controller.draft);verify(!slider.visible)
            compare(JSON.stringify(study.controller.snapshot),before)
            study.visible=false
        }
        function test_material_presets_and_local_override(){
            study.visible=true;study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            var original=JSON.stringify(study.controller.snapshot)
            var viewState=view()
            mouseClick(study.scene,4,4,Qt.RightButton)
            clickControl(findChild(study,"material-presets"))
            tryCompare(study,"materialPanel","roles")
            var quiet=findChild(study,"material-preset-quiet")
            clickControl(quiet)
            tryVerify(function(){return study.materialPreferences.scheme==="quiet"})
            compare(JSON.stringify(study.controller.snapshot),original)
            compare(study.controller.archiveState.history.length,0)
            compare(study.controller.exportCheckpoint(viewState),"")
            verify(!study.controller.undo())
            var input=findChild(study,"material-row-rack-input")
            input.text="#aabbcc"
            clickControl(findChild(study,"material-row-rack-apply"))
            compare(study.appearanceColors.materials.rack,"#aabbcc")
            compare(study.scene.colors.materials.rack,"#aabbcc")
            compare(JSON.stringify(study.controller.snapshot),original)
            var apply=findChild(study,"material-apply")
            clickControl(apply)
            compare(study.controller.snapshot.materials.scheme,"quiet")
            compare(study.controller.snapshot.materials.roleEdits[study.colors.name+":quiet"].rack,"#aabbcc")
            compare(study.controller.archiveState.history.length,1)
            verify(!study.materialProposal)
            verify(study.controller.exportCheckpoint(viewState).length>0)
            var inherited=JSON.stringify(study.controller.snapshot)
            var rack=study.scene.moduleItem("rack-1")
            verify(waitForRendering(rack,2000))
            mouseClick(rack,100,100,Qt.RightButton)
            tryCompare(study.scene,"selectedModuleId","rack-1")
            clickControl(findChild(study,"material-local"))
            var localInput=findChild(study,"material-row-color-input")
            localInput.text="#123456"
            clickControl(findChild(study,"material-row-color-apply"))
            compare(study.scene.moduleItem("rack-1").rack.color,"#123456")
            compare(JSON.stringify(study.controller.snapshot),inherited)
            clickControl(findChild(study,"material-row-color-reset"))
            verify(study.scene.moduleItem("rack-1").rack.color===null)
            localInput.text="#123456"
            clickControl(findChild(study,"material-row-color-apply"))
            clickControl(findChild(study,"material-cancel"))
            compare(JSON.stringify(study.controller.snapshot),inherited)
            verify(study.scene.moduleItem("rack-1").rack.color===null)
            compare(study.controller.archiveState.history.length,1)
            verify(study.controller.undo())
            compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function test_visual_color_picker(){
            study.visible=true;study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            var original=JSON.stringify(study.controller.snapshot)
            mouseClick(study.scene,4,4,Qt.RightButton)
            clickControl(findChild(study,"material-presets"))
            clickControl(findChild(study,"material-row-rack-swatch"))
            tryCompare(study,"materialPickerRole","rack")
            var plane=findChild(study,"material-row-rack-picker-sv")
            var hue=findChild(study,"material-row-rack-picker-hue")
            tryVerify(function(){return !!plane&&!!hue&&plane.visible&&hue.visible})
            verify(!findChild(study,"material-row-shelf-swatch").visible)
            waitForClickTarget(plane,.5,.4)
            mouseClick(plane,Math.round(plane.width*.5),Math.round(plane.height*.4))
            var first=study.appearanceColors.materials.rack
            verify(/^#[0-9a-f]{6}$/.test(first))
            verify(first!==study.colors.panel)
            compare(findChild(study,"material-row-rack-input").text,first)
            waitForClickTarget(hue,.65,.5)
            mouseClick(hue,Math.round(hue.width*.65),hue.height/2)
            var second=study.appearanceColors.materials.rack
            verify(second!==first)
            compare(findChild(study,"material-row-rack-input").text,second)
            compare(JSON.stringify(study.controller.snapshot),original)
            compare(study.controller.archiveState.history.length,0)
            hue.forceActiveFocus();keyClick(Qt.Key_Right)
            verify(study.appearanceColors.materials.rack!==second)
            var retained=study.appearanceColors.materials.rack
            var back=findChild(study,"material-picker-back"),inspector=findChild(study,"material-inspector")
            verify(!!back&&back.visible&&back.enabled)
            var p=back.mapToItem(inspector,back.width/2,back.height/2)
            verify(p.x>=0&&p.y>=0&&p.x<inspector.width&&p.y<inspector.height,"Back control outside inspector")
            clickControl(back)
            tryCompare(study,"materialPickerRole","")
            verify(findChild(study,"material-row-shelf-swatch").visible)
            compare(study.appearanceColors.materials.rack,retained)
            clickControl(findChild(study,"material-row-shelf-swatch"))
            tryCompare(study,"materialPickerRole","shelf")
            compare(study.appearanceColors.materials.rack,retained)
            clickControl(findChild(study,"material-cancel"))
            compare(JSON.stringify(study.controller.snapshot),original)
            verify(!study.materialProposal)
            study.visible=false
        }
        function test_shared_inspector_bounds(){
            var frame=sharedFrame,scroll=sharedScroll
            compare(frame.width,180)
            compare(frame.height,120)
            compare(scroll.contentWidth,scroll.width)
            verify(scroll.clip)
            compare(scroll.flickableDirection,Flickable.VerticalFlick)
            compare(scroll.boundsBehavior,Flickable.StopAtBounds)
            scroll.contentY=50
            scroll.resetPosition()
            compare(scroll.contentY,0)
            frame.availableWidth=90;frame.availableHeight=70
            compare(frame.width,90);compare(frame.height,70)
            frame.availableWidth=-1;frame.availableHeight=-1
            compare(frame.width,0);compare(frame.height,0)
            frame.availableWidth=180;frame.availableHeight=120
        }
        function test_cubby_interior_growth(){
            study.visible=true;study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            var original=JSON.stringify(study.controller.snapshot),c=study.controller.snapshot.cubbies.root
            var furniture=JSON.stringify(c.mods),w=c.w,h=c.h
            mouseClick(study.scene,4,4,Qt.RightButton)
            clickControl(findChild(study,"edit-cubby-interior"))
            tryVerify(function(){return !!study.controller.structuralProposal&&study.controller.structuralProposal.command.kind==="cubby"})
            clickControl(findChild(study,"cubby-plus-w"))
            compare(study.scene.displayCubby.w,w+50)
            compare(study.scene.displayCubby.h,h)
            compare(JSON.stringify(study.controller.snapshot),original)
            clickControl(findChild(study,"cubby-ratio-lock"))
            clickControl(findChild(study,"cubby-plus-h"))
            compare(study.scene.displayCubby.h,h+50)
            compare(study.scene.displayCubby.w,Math.round((h+50)*(w+50)/h))
            compare(JSON.stringify(study.scene.displayCubby.mods),furniture)
            var name=findChild(study,"cubby-name-input")
            name.forceActiveFocus();name.text="Expanded Archive";keyClick(Qt.Key_Return)
            compare(study.scene.displayCubby.name,"Expanded Archive")
            clickControl(findChild(study,"structure-apply"))
            compare(study.controller.snapshot.cubbies.root.name,"Expanded Archive")
            compare(JSON.stringify(study.controller.snapshot.cubbies.root.mods),furniture)
            compare(study.controller.archiveState.history.length,1)
            verify(study.controller.undo());compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function test_cubby_shrink_suggestion(){
            var fixture=Core.fixture()
            fixture.cubbies.root.mods[0].x=180
            study.visible=true;study.controller.reset(fixture)
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            var original=JSON.stringify(study.controller.snapshot)
            mouseClick(study.scene,4,4,Qt.RightButton)
            clickControl(findChild(study,"edit-cubby-interior"))
            var input=findChild(study,"cubby-input-w")
            input.forceActiveFocus();input.text="600";keyClick(Qt.Key_Return)
            tryVerify(function(){return !study.controller.structuralProposal.ok&&study.controller.structuralProposal.error.indexOf("Furniture needs at least")===0})
            verify(!findChild(study,"structure-apply").enabled)
            var suggest=findChild(study,"cubby-suggest")
            clickControl(suggest)
            tryVerify(function(){return study.controller.structuralProposal.ok})
            compare(study.scene.displayCubby.w,600)
            compare(study.scene.moduleItem("rack-1").rack.x,100)
            compare(study.scene.moduleItem("rack-1").rack.w,500)
            compare(JSON.stringify(study.controller.snapshot),original)
            clickControl(suggest)
            verify(!study.controller.structuralProposal.ok)
            compare(study.scene.moduleItem("rack-1").rack.x,180)
            clickControl(suggest)
            clickControl(findChild(study,"structure-cancel"))
            compare(JSON.stringify(study.controller.snapshot),original)
            compare(study.scene.moduleItem("rack-1").rack.x,180)
            mouseClick(study.scene,4,4,Qt.RightButton)
            clickControl(findChild(study,"edit-cubby-interior"))
            input=findChild(study,"cubby-input-w")
            input.forceActiveFocus();input.text="600";keyClick(Qt.Key_Return)
            clickControl(suggest)
            clickControl(findChild(study,"structure-apply"))
            compare(study.controller.snapshot.cubbies.root.w,600)
            compare(study.controller.snapshot.cubbies.root.mods[0].x,100)
            compare(JSON.stringify(study.controller.snapshot.cubbies.root.mods[0].cellMeta),JSON.stringify(fixture.cubbies.root.mods[0].cellMeta))
            compare(JSON.stringify(study.controller.snapshot.cubbies.root.mods[0].scrollCells),JSON.stringify(fixture.cubbies.root.mods[0].scrollCells))
            verify(study.controller.undo());compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function test_cubby_exterior_preview_modes(){
            var prepared=Core.editStructure(Core.session(Core.fixture()),proposal())
            verify(!prepared.error,prepared.error)
            var nested=prepared.snapshot.cubbies.root.mods[1]
            prepared=Core.editStructure(prepared,{kind:"create",type:"shelf",cubbyId:nested.childId,patch:{x:10,y:250,w:160,h:15}})
            verify(!prepared.error,prepared.error)
            study.visible=true;study.controller.reset(prepared.snapshot)
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            var original=JSON.stringify(study.controller.snapshot)
            var revision=study.controller.archiveState.revision
            tryVerify(function(){return !!study.scene.moduleItem(nested.id)})
            var face=study.scene.moduleItem(nested.id)
            tryCompare(face,"previewMode","veiled")
            var veil=findChild(face,"cubby-preview-veil"),inventory=findChild(face,"cubby-preview-inventory")
            verify(!!veil&&!!inventory)
            verify(veil.visible&&!inventory.visible)
            var modes=["inventory","closed","veiled"]
            for(var i=0;i<modes.length;i++){
                clickControl(face,Qt.RightButton)
                tryCompare(study.scene,"selectedModuleId",nested.id)
                clickControl(findChild(study,"cubby-mode-"+modes[i]))
                tryCompare(face,"previewMode",modes[i])
                compare(veil.visible,modes[i]==="veiled")
                compare(inventory.visible,modes[i]==="inventory")
                if(modes[i]==="inventory"){
                    compare(face.inventory.shelf,1)
                    compare(face.inventory.items,0)
                }
                compare(face.width,nested.w);compare(face.height,nested.h)
                compare(JSON.stringify(study.controller.snapshot),original)
                compare(study.controller.archiveState.revision,revision)
                compare(study.controller.archiveState.history.length,0)
                verify(!study.controller.structuralProposal)
            }
            // Closed is presentation only: Browse can still enter the face.
            clickControl(face,Qt.RightButton)
            clickControl(findChild(study,"cubby-mode-closed"))
            study.scene.mode="browse"
            clickControl(face)
            tryCompare(study.scene,"cubbyId",nested.childId)
            verify(study.scene.back())
            compare(study.scene.cubbyPreviewMode,"closed")
            compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function dragScene(item,x,y,dx,dy){
            var a=item.mapToItem(study.scene,x,y),b=item.mapToItem(study.scene,x+dx,y+dy)
            verify(a.x>=0&&a.y>=0&&a.x<study.scene.width&&a.y<study.scene.height,"Drag start outside scene")
            verify(b.x>=0&&b.y>=0&&b.x<study.scene.width&&b.y<study.scene.height,"Drag end outside scene")
            mousePress(study.scene,a.x,a.y,Qt.LeftButton)
            mouseMove(study.scene,b.x,b.y,40,Qt.LeftButton)
            mouseRelease(study.scene,b.x,b.y,Qt.LeftButton)
        }
        function test_grid_and_fixture_drag(){
            study.visible=true
            var prepared=Core.editStructure(Core.session(Core.fixture()),{kind:"create",type:"shelf",cubbyId:"root",patch:{x:40,y:430,w:180,h:15}})
            verify(!prepared.error,prepared.error)
            study.controller.reset(prepared.snapshot)
            study.scene.mode="arrange";study.scene.viewPath=["root"];study.scene.clearSelection()
            var id=prepared.snapshot.cubbies.root.mods[1].id,original=JSON.stringify(study.controller.snapshot)
            var revision=study.controller.archiveState.revision
            mouseClick(study.scene,4,4,Qt.RightButton)
            clickControl(findChild(study,"grid-snap-toggle"))
            verify(study.scene.snapEnabled&&!study.scene.showGrid)
            clickControl(findChild(study,"grid-guide-toggle"))
            verify(study.scene.snapEnabled&&study.scene.showGrid)
            var spacing=findChild(study,"grid-spacing-slider")
            spacing.forceActiveFocus();keyClick(Qt.Key_Right)
            compare(study.scene.snapDistance,21)
            keyClick(Qt.Key_Left);compare(study.scene.snapDistance,20)
            study.closeContext()
            compare(JSON.stringify(study.controller.snapshot),original)
            compare(study.controller.archiveState.revision,revision)
            var interior=findChild(study.scene,"cubby-interior"),grid=findChild(study.scene,"cubby-guide-grid")
            for(var i=0;i<2;i++){
                study.scene.zoom=i===0?.8:1.05;study.scene.pan=Qt.point(0,0)
                tryVerify(function(){return grid.visible&&!!findChild(grid,"grid-x-2")&&!!findChild(grid,"grid-y-2")})
                var xline=findChild(grid,"grid-x-2"),yline=findChild(grid,"grid-y-2")
                compare(xline.x,40);compare(yline.y,40)
                var a=interior.mapToItem(study.scene,0,0),b=xline.mapToItem(study.scene,0,0)
                verify(Math.abs(b.x-a.x-40*study.scene.camera.scale)<.01)
                var board=study.scene.moduleItem(id)
                waitForClickTarget(board,.5,.5)
                mouseClick(board,board.width/2,board.height/2,Qt.RightButton)
                tryCompare(study.scene,"selectedModuleId",id)
                clickControl(findChild(study,"edit-shelf"))
                var ghost=findChild(study.scene,"structural-ghost")
                tryVerify(function(){return ghost.visible&&ghost.width===180})
                dragScene(ghost,60,7,43,-9)
                var patch=study.controller.structuralProposal.command.patch
                compare(patch.x,80);compare(patch.y,420);compare(patch.w,180);verify(study.controller.structuralProposal.ok)
                dragScene(ghost,ghost.width-5,7,43,0)
                patch=study.controller.structuralProposal.command.patch
                compare(patch.w,220);compare(patch.x+patch.w,300)
                compare(ghost.height,15);verify(study.controller.structuralProposal.ok)
                compare(JSON.stringify(study.controller.snapshot),original)
                if(i===0)clickControl(findChild(study,"structure-cancel"))
                else {
                    clickControl(findChild(study,"structure-apply"))
                    compare(study.controller.snapshot.cubbies.root.mods[1].w,220)
                    compare(study.controller.snapshot.cubbies.root.mods[1].h,15)
                    verify(study.controller.undo())
                }
                compare(JSON.stringify(study.controller.snapshot),original)
            }
            study.scene.showGrid=false
            verify(study.scene.snapEnabled&&!grid.visible)
            study.scene.snapEnabled=false
            study.scene.showGrid=true
            verify(!study.scene.snapEnabled&&grid.visible)
            compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function test_rack_grid_move(){
            study.visible=true;study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            study.scene.snapEnabled=true;study.scene.snapDistance=20
            var original=JSON.stringify(study.controller.snapshot)
            for(var i=0;i<2;i++){
                study.scene.zoom=i===0?.8:1.05;study.scene.pan=Qt.point(0,12)
                tryVerify(function(){return !!study.scene.moduleItem("rack-1")})
                var rack=study.scene.moduleItem("rack-1")
                waitForClickTarget(rack,.3,.3)
                mouseClick(rack,150,120,Qt.LeftButton)
                tryCompare(study.scene,"selectedModuleId","rack-1")
                dragScene(rack,150,5,43,23)
                tryVerify(function(){return !!study.controller.draft})
                compare(study.controller.draft.proposed.x,40)
                compare(study.controller.draft.proposed.y,20)
                compare(study.controller.draft.proposed.w,500)
                compare(JSON.stringify(study.controller.snapshot),original)
                study.scene.forceActiveFocus();keyClick(Qt.Key_Escape)
                verify(!study.controller.draft)
                compare(JSON.stringify(study.controller.snapshot),original)
            }
            study.visible=false
        }
        function test_nested_collision_and_small_view(){
            var state=Core.editStructure(Core.session(Core.fixture()),proposal())
            verify(!state.error,state.error)
            var outer=state.snapshot.cubbies.root.mods[1],parentId=outer.childId
            state=Core.editStructure(state,{kind:"create",type:"cubby",cubbyId:parentId,patch:{x:20,y:20,w:160,h:120}})
            verify(!state.error,state.error)
            var nested=state.snapshot.cubbies[parentId].mods[0]
            state=Core.editStructure(state,{kind:"create",type:"shelf",cubbyId:parentId,patch:{x:20,y:160,w:200,h:15}})
            verify(!state.error,state.error)
            study.visible=true;study.controller.reset(state.snapshot)
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            verify(study.scene.openChild(parentId))
            study.scene.zoom=.85;study.scene.pan=Qt.point(-12,0)
            study.scene.snapEnabled=true;study.scene.showGrid=true;study.scene.snapDistance=20
            var original=JSON.stringify(study.controller.snapshot)
            var parentFootprint=JSON.stringify(study.controller.snapshot.cubbies.root.mods)
            var contents=JSON.stringify(study.controller.snapshot.cubbies[nested.childId])
            tryVerify(function(){return !!study.scene.moduleItem(nested.id)})
            var face=study.scene.moduleItem(nested.id)
            clickControl(face,Qt.RightButton)
            tryCompare(study.scene,"selectedModuleId",nested.id)
            clickControl(findChild(study,"edit-child"))
            var ghost=findChild(study.scene,"structural-ghost")
            tryVerify(function(){return ghost.visible&&ghost.width===160})
            // Deliberately overlap the board. Invalid preview is not committed.
            dragScene(ghost,60,40,0,140)
            tryCompare(ghost,"y",160)
            verify(!study.controller.structuralProposal.ok)
            verify(!findChild(study,"structure-apply").enabled)
            verify(!!study.controller.structuralProposal.error)
            compare(JSON.stringify(study.controller.snapshot),original)
            // Move back from the invalid position and resize the far corner.
            dragScene(ghost,60,40,0,-120)
            tryCompare(ghost,"y",40)
            verify(study.controller.structuralProposal.ok)
            dragScene(ghost,ghost.width-6,ghost.height-6,43,-20)
            tryCompare(ghost,"width",200)
            compare(ghost.height,100)
            verify(study.controller.structuralProposal.ok)
            compare(JSON.stringify(study.controller.snapshot),original)
            // The fixed footer survives a smaller viewport while the body clips.
            testRoot.width=640;testRoot.height=340
            var panel=findChild(study,"structure-panel"),apply=findChild(study,"structure-apply")
            tryVerify(function(){return panel.visible&&panel.height<=study.scene.height-16&&panel.width<=study.width-16})
            waitForClickTarget(apply,.5,.5)
            clickControl(apply)
            compare(study.controller.snapshot.cubbies[parentId].mods[0].y,40)
            compare(study.controller.snapshot.cubbies[parentId].mods[0].w,200)
            compare(study.controller.snapshot.cubbies[parentId].mods[0].h,100)
            compare(JSON.stringify(study.controller.snapshot.cubbies.root.mods),parentFootprint)
            compare(JSON.stringify(study.controller.snapshot.cubbies[nested.childId]),contents)
            compare(study.controller.archiveState.history.length,1)
            verify(study.controller.undo())
            compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function test_rack_out_of_bounds_guard(){
            study.visible=true;study.controller.reset(Core.fixture())
            study.scene.viewPath=["root"];study.scene.mode="arrange";study.scene.clearSelection()
            study.scene.zoom=.8;study.scene.snapEnabled=true
            var original=JSON.stringify(study.controller.snapshot)
            tryVerify(function(){return !!study.scene.moduleItem("rack-1")})
            var rack=study.scene.moduleItem("rack-1")
            clickControl(rack)
            tryCompare(study.scene,"selectedModuleId","rack-1")
            dragScene(rack,150,5,223,0)
            tryVerify(function(){return !!study.controller.draft})
            compare(study.controller.draft.proposed.x,220)
            compare(study.controller.phase,"invalid")
            verify(!study.controller.apply())
            compare(JSON.stringify(study.controller.snapshot),original)
            study.scene.forceActiveFocus();keyClick(Qt.Key_Escape)
            verify(!study.controller.draft)
            compare(JSON.stringify(study.controller.snapshot),original)
            study.visible=false
        }
        function test_reset_from_nested_path(){
            var state=Core.editStructure(Core.session(Core.fixture()),proposal())
            verify(!state.error,state.error)
            var child=state.snapshot.cubbies.root.mods[1].childId
            study.visible=true;study.controller.reset(state.snapshot)
            study.scene.viewPath=["root"];study.scene.mode="browse"
            verify(study.scene.openChild(child))
            compare(study.scene.cubbyId,child)
            study.controller.reset(Core.fixture())
            compare(study.scene.cubbyId,"root")
            compare(JSON.stringify(study.scene.viewPath),'["root"]')
            compare(study.scene.cubby.id,"root")
            tryVerify(function(){return !!study.scene.moduleItem("rack-1")})
            study.visible=false
        }
        function test_empty_shelf(){
            var before=snap()
            verify(controller.proposeStructure({kind:"create",type:"shelf",cubbyId:"root",patch:{x:0,y:430,w:280,h:15}}))
            compare(snap(),before)
            verify(controller.applyStructure())
            var m=controller.snapshot.cubbies.root.mods[1]
            compare(m.type,"shelf");compare(m.h,15)
            verify(controller.proposeStructure({kind:"shelf",cubbyId:"root",moduleId:m.id,patch:{x:20,w:300}}))
            verify(controller.applyStructure())
            compare(controller.snapshot.cubbies.root.mods[1].w,300)
            var saved=controller.exportCheckpoint(view());verify(saved.length>0,controller.checkpointError)
            verify(!!controller.importCheckpoint(saved),controller.checkpointError)
            compare(controller.snapshot.cubbies.root.mods[1].type,"shelf")
        }
    }
}
