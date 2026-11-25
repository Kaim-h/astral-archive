import QtQuick
import QtTest
import "../archive" as Archive
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveView.mjs" as View
import "../themes" as Themes

Item {
    id:root
    width:1366;height:768
    ArchiveNativeN2Study {id:study;anchors.fill:parent}
    TestCase {
        name:"ArchiveNativeN3"
        when:windowShown
        function init(){
            study.scene.abortGesture()
            study.controller.reset(View.fixture())
            study.scene.viewPath=["root"]
            study.scene.mode="browse"
            study.scene.clearSelection()
            study.scene.caseDock.pinned=false
            study.scene.caseDock.hoverOpen=false
            study.scene.caseDock.dismissed=false
            study.scene.motion.notice="";study.scene.message=""
            study.scene.zoom=1;study.scene.pan=Qt.point(0,0)
            root.width=1366;root.height=768
            tryVerify(function(){return rack()!==null})
        }
        function rack(){return study.scene.moduleItem("rack-1")}
        function snapshot(){return JSON.stringify(study.controller.snapshot)}
        function source(id){return Core.owners(study.controller.snapshot).find(function(e){return e.id===id})}
        function at(item,x,y){return item.mapToItem(study.scene,x,y)}
        function glyph(id){var g=rack().scrollItem(id);verify(!!g);return at(g,g.width/2,g.height/2)}
        function caseGlyph(id){
            study.scene.caseDock.pinned=true
            tryVerify(function(){return findChild(study.scene.caseDock,"scroll-"+id)!==null})
            var g=findChild(study.scene.caseDock,"scroll-"+id)
            return at(g,g.width/2,g.height/2)
        }
        function emptyCell(){
            var m=Core.rackAt(study.controller.snapshot,"root","rack-1")
            var c=Core.geometry(m).cells.find(function(q){return q.area>14000&&!(m.scrollCells[q.key]||[]).length})
            verify(!!c);return c
        }
        function click(p,mods){mouseClick(study.scene,p.x,p.y,Qt.LeftButton,mods||Qt.NoModifier)}
        function press(p){mousePress(study.scene,p.x,p.y,Qt.LeftButton)}
        function move(p){mouseMove(study.scene,p.x,p.y,30,Qt.LeftButton)}
        function release(p){mouseRelease(study.scene,p.x,p.y,Qt.LeftButton)}
        function idle(){tryCompare(study.scene.motion,"busy",false,15000)}
        function test_live_tether_cancel(){
            var before=snapshot(),start=glyph("test-a"),e=source("test-a")
            var cell=Core.geometry(rack().rack).cells.find(function(q){return q.key===e.key})
            var target=at(rack(),cell.cx,cell.cy-12)
            press(start);move(target)
            tryVerify(function(){return study.scene.busy&&study.scene.motion.activeCells===1})
            tryVerify(function(){return study.scene.motion.stepCount>3})
            compare(snapshot(),before)
            var paint=rack().masonryPaints
            wait(100);compare(rack().masonryPaints,paint)
            study.scene.forceActiveFocus();keyClick(Qt.Key_Escape);release(target);idle()
            compare(snapshot(),before)
            var steps=study.scene.motion.stepCount;wait(70);compare(study.scene.motion.stepCount,steps)
        }
        function test_group_case_round_trip(){
            var before=snapshot(),ids=["test-a","test-b"]
            click(glyph(ids[0]));click(glyph(ids[1]),Qt.ControlModifier)
            compare(study.scene.selectedIds.length,2)
            var pill=findChild(study.scene.caseDock,"case-pill"),p=at(pill,pill.width/2,pill.height/2)
            press(glyph(ids[0]));move(p)
            tryVerify(function(){return study.scene.motion.carried.length===2})
            verify(study.scene.caseDock.expanded)
            compare(snapshot(),before)
            release(p);idle()
            compare(source(ids[0]).where,"case");compare(source(ids[1]).where,"case")
            var after=snapshot()
            click(caseGlyph(ids[0]));click(caseGlyph(ids[1]),Qt.ShiftModifier)
            compare(study.scene.selectedIds.length,2)
            var c=emptyCell(),target=at(rack(),c.cx,c.cy)
            press(caseGlyph(ids[0]));move(target)
            tryVerify(function(){return study.scene.motion.carried.length===2})
            compare(snapshot(),after);release(target);idle()
            compare(source(ids[0]).where,"rack");compare(source(ids[1]).key,c.key)
            verify(study.controller.undo());compare(snapshot(),after)
            verify(study.controller.undo());compare(snapshot(),before)
        }
        function test_void_top_return(){
            var before=snapshot(),c=emptyCell()
            click(caseGlyph("case-note"));verify(study.scene.prepareInsertion())
            study.scene.caseDock.hoverOpen=false
            mouseClick(rack(),c.cx,c.cy,Qt.LeftButton)
            tryVerify(function(){return !!study.scene.insertionMark})
            verify(!!study.scene.insertionContext.atlas.regions.length)
            verify(study.scene.insertPrepared(false));idle()
            compare(source("case-note").key,c.key)
            verify(study.controller.undo());compare(snapshot(),before)
            click(caseGlyph("case-note"));verify(study.scene.prepareInsertion())
            study.scene.caseDock.hoverOpen=false
            mouseClick(rack(),c.cx,c.cy,Qt.LeftButton)
            verify(study.scene.insertPrepared(true));idle()
            compare(source("case-note").key,c.key)
            verify(study.controller.undo());compare(snapshot(),before)
            click(caseGlyph("case-note"));verify(study.scene.returnOrigin());idle()
            compare(source("case-note").cubbyId,"child")
            verify(study.controller.undo());compare(snapshot(),before)
        }
        function test_resize_handle_cancel(){
            var before=snapshot()
            study.scene.mode="arrange";study.scene.selectedModuleId="rack-1"
            var a=at(rack(),rack().width-7,rack().height-7),b=Qt.point(a.x-16,a.y-10)
            press(a);move(b)
            tryVerify(function(){return study.controller.draft!==null})
            verify(rack().width<500)
            compare(rack().width,study.controller.draft.proposed.w)
            compare(snapshot(),before);release(b)
            study.controller.cancel();compare(rack().width,500);compare(snapshot(),before)
        }
        function test_depth_only_review_controls(){
            study.controller.reset(Core.fixture())
            study.scene.mode="arrange";study.scene.selectedModuleId="rack-1"
            verify(study.controller.paintCell("root","rack-1","-1:3",null,20))
            var before=snapshot(),meta=Core.rackAt(study.controller.snapshot,"root","rack-1").cellMeta["-1:3"]
            study.edit({w:400,h:320})
            tryCompare(study.controller,"phase","attention",15000)
            tryVerify(function(){return study.activeIssue&&study.activeIssue.cellId===meta.id})
            var reason=findChild(study,"cell-style-review-reason")
            verify(!!reason&&reason.text.indexOf("recess")>=0)
            var relocate=findChild(study,"relocate-cell-style"),discard=findChild(study,"discard-cell-style")
            verify(!!relocate&&!!discard)
            relocate.clicked()
            compare(study.pickId,"paint:"+meta.id)
            study.chooseCell("0:0")
            tryCompare(study.controller,"phase","ready",15000)
            verify(study.controller.apply())
            var moved=Core.rackAt(study.controller.snapshot,"root","rack-1").cellMeta["0:0"]
            compare(moved.id,meta.id);compare(moved.depth,20)
            verify(study.controller.undo());compare(snapshot(),before)
            study.edit({w:400,h:320})
            tryCompare(study.controller,"phase","attention",15000)
            findChild(study,"discard-cell-style").clicked()
            tryCompare(study.controller,"phase","ready",15000)
            verify(study.controller.apply())
            verify(!Object.values(Core.rackAt(study.controller.snapshot,"root","rack-1").cellMeta).some(function(v){return v.id===meta.id}))
            verify(study.controller.undo());compare(snapshot(),before)
        }
        function test_paint_and_split_controls(){
            var original=snapshot(),m=Core.rackAt(study.controller.snapshot,"root","rack-1"),identity=m.cellMeta["1:1"].id
            verify(study.controller.paintCell("root",m.id,"1:1","#9a7e61",12))
            compare(Core.rackAt(study.controller.snapshot,"root",m.id).cellMeta["1:1"].id,identity)
            compare(Core.rackAt(study.controller.snapshot,"root",m.id).cellMeta["1:1"].depth,12)
            verify(study.controller.undo());compare(snapshot(),original)
            study.controller.reset(Core.fixture());study.scene.mode="arrange";study.scene.selectedModuleId="rack-1"
            study.controller.stage("root","rack-1",{r:38})
            tryCompare(study.controller,"phase","attention",15000)
            tryVerify(function(){return !!findChild(study,"split-case-test-b")})
            findChild(study,"split-case-test-b").clicked()
            verify(study.controller.preview.caseOverflow.some(function(e){return e.id==="test-b"}))
            tryVerify(function(){return !!findChild(study,"split-hex-test-c")})
            findChild(study,"split-hex-test-c").clicked()
            var issue=study.activeIssue,target=issue.options.find(function(key){return Core.geometry(rack().rack).cells.find(function(c){return c.key===key}).area>3600})
            verify(!!target)
            study.chooseCell(target)
            tryCompare(study.controller,"phase","ready",15000)
            verify(study.controller.radiusApprovalRequired)
            study.controller.approveRadius(true);verify(study.controller.apply())
            compare(source("test-b").where,"case");compare(source("test-c").key,target)
            verify(study.controller.undo());compare(snapshot(),JSON.stringify(Core.fixture()))
        }
        function test_z_capture_render(){
            study.scene.clearSelection()
            study.scene.caseDock.pinned=false;study.scene.caseDock.hoverOpen=false
            mouseMove(study,1,1,20)
            wait(300)
            verify(rack().masonryPaints>0)
            var pill=findChild(study.scene.caseDock,"case-pill"),world=study.scene.worldItem
            var bottom=world.mapToItem(study.scene,0,world.height),top=pill.mapToItem(study.scene,0,0)
            verify(bottom.y<top.y,"Default camera fit must not cover the cubby inscription")
            var inscription=findChild(world,"cubby-inscription"),label=findChild(world,"cubby-inscription-label")
            verify(!!inscription&&!!label)
            compare(label.text,study.scene.cubby.name)
            verify(label.width>=label.implicitWidth,"Default main-hall name should not be truncated")
            verify(!label.truncated)
            verify(inscription.width<=world.width-20)
            grabImage(study).save("archive-native-n3.png")
            study.scene.caseDock.pinned=true;wait(100)
            grabImage(study).save("archive-native-n3-case.png")
        }
        function test_zz_capture_parity_matrix(){
            // Same fixture and 1366x768 viewport as browser reference script.
            // Capture actual native surfaces, not generated approximations.
            var original=snapshot(),priorTheme=Themes.Theme.index
            study.scene.caseDock.pinned=false;study.scene.caseDock.hoverOpen=false
            study.scene.caseDock.dismissed=false
            study.scene.clearSelection()
            mouseMove(study,1,1,20)
            try{
                Themes.Theme.index=0
                study.scene.cubbyPreviewMode="inventory"
                var face=study.scene.moduleItem("cubby-child")
                tryVerify(function(){return !!face&&face.previewMode==="inventory"&&face.inventory.items===1})
                wait(200)
                grabImage(study).save("archive-native-n3-evening-inventory.png")
                compare(snapshot(),original)
                Themes.Theme.index=2
                study.scene.cubbyPreviewMode="closed"
                tryCompare(face,"previewMode","closed")
                wait(200)
                grabImage(study).save("archive-native-n3-midnight-closed.png")
                compare(snapshot(),original)
                Themes.Theme.index=1
                study.scene.cubbyPreviewMode="veiled"
                verify(study.scene.openChild("child"))
                tryVerify(function(){return !!study.scene.moduleItem("rack-child")})
                var childRack=study.scene.moduleItem("rack-child")
                tryCompare(childRack,"scrollCount",1)
                wait(200)
                grabImage(study).save("archive-native-n3-twilight-child.png")
                compare(snapshot(),original)
                verify(study.scene.back())
            }finally{
                Themes.Theme.index=priorTheme
                study.scene.cubbyPreviewMode="veiled"
            }
        }
    }
}
