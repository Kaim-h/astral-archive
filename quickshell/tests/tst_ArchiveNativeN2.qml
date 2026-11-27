import QtQuick
import QtTest
import "../archive" as Archive
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveView.mjs" as View
import "../themes" as Themes

Item {
    id: root
    width:1100
    height:720
    ArchiveNativeN2Study { id:study; anchors.fill:parent }
    TestCase {
        name:"ArchiveNativeN2"
        when:windowShown
        SignalSpy { id:childActivation; signalName:"activated" }
        function init() {
            study.controller.reset(View.fixture())
            study.scene.viewPath=["root"]
            study.scene.clearSelection()
            study.scene.mode="browse"
            study.scene.setZoom(1)
            study.scene.pan=Qt.point(0,0)
            study.scene.caseDock.pinned=false
            study.scene.caseDock.hoverOpen=false
            root.width=1100;root.height=720
        }
        function rack(){return study.scene.moduleItem("rack-1")}
        function test_geometry_and_camera() {
            tryVerify(function(){return rack()!==null})
            var m=Core.rackAt(study.controller.snapshot,"root","rack-1")
            compare(rack().width,m.w)
            compare(rack().cellCount,Core.geometry(m).cells.length)
            compare(rack().scrollCount,View.records(m).length)
            var record=m.scrollCells["1:1"][0],glyph=rack().scrollItem(record.id)
            verify(glyph!==null)
            compare(glyph.x+glyph.width/2,record.x)
            compare(glyph.y+glyph.height/2,record.y)
            compare(glyph.width,record.r*2)
            compare(rack().hitRecord(record.x,record.y).id,record.id)
            var before=JSON.stringify(study.controller.snapshot)
            study.scene.setZoom(1.5);study.scene.pan=Qt.point(23,-19)
            compare(JSON.stringify(study.controller.snapshot),before)
            verify(study.scene.worldItem.scale>0)
            var old=Themes.Theme.index
            Themes.Theme.index=(old+1)%3
            compare(rack().colors.name,Themes.Theme.current.name)
            Themes.Theme.index=old
        }
        function test_navigation_and_tooltip() {
            tryVerify(function(){return rack()!==null&&study.scene.moduleItem("cubby-child")!==null})
            var before=JSON.stringify(study.controller.snapshot)
            var m=Core.rackAt(study.controller.snapshot,"root","rack-1"),record=m.scrollCells["1:1"][0]
            mouseClick(rack(),record.x,record.y)
            tryCompare(study.scene.tooltip,"expanded",true)
            compare(study.scene.tooltip.record.id,record.id)
            verify(study.scene.tooltip.x>=0&&study.scene.tooltip.y>=0)
            verify(study.scene.tooltip.x+study.scene.tooltip.width<=study.scene.width)
            mouseClick(rack(),record.x,record.y)
            tryCompare(study.scene.tooltip,"expanded",false)
            var child=study.scene.moduleItem("cubby-child")
            study.scene.mode="arrange"
            mouseClick(child,child.width/2,child.height/2)
            compare(study.scene.cubbyId,"root")
            compare(study.scene.selectedModuleId,"cubby-child")
            verify(study.scene.enterSelected())
            compare(study.scene.cubbyId,"child")
            tryVerify(function(){return study.scene.moduleItem("rack-child")!==null})
            verify(study.scene.back())
            compare(study.scene.cubbyId,"root")
            var scene=study.scene
            scene.mode="browse"
            verify(!scene.spatialStyle)
            // The legacy Flow still sizes the header from implicitHeight.
            // Delegate existence does not establish the final mapped hit point.
            var previous=null,last="",first="",settled=""
            function hitGeometry(item){
                var p=item.mapToItem(scene,item.width/2,item.height/2)
                var q=item.mapToItem(root,item.width/2,item.height/2)
                return {point:p,signature:[p.x,p.y,q.x,q.y,scene.width,scene.height,item.width,item.height].join("|")}
            }
            tryVerify(function(){
                child=scene.moduleItem("cubby-child")
                if(!child||!child.visible||!child.enabled||!child.browse||child.width<=0||child.height<=0){
                    previous=null;last="";return false
                }
                var g=hitGeometry(child),p=g.point
                if(!first)first=g.signature
                var ok=previous===child&&last===g.signature&&scene.cubbyId==="root"&&
                    p.x>=0&&p.x<scene.width&&p.y>=0&&p.y<scene.height&&
                    scene.committedFixtureAt(p.x,p.y)==="cubby-child"&&
                    !scene.caseDock.containsDrop(scene.caseDock.mapFromItem(scene,p.x,p.y))
                previous=child;last=g.signature;settled=g.signature
                return ok
            },3000,"legacy Browse child settled and unobstructed")
            childActivation.target=child
            childActivation.clear()
            verify(childActivation.valid)
            console.log("legacy Browse child before click",JSON.stringify({first:first,settled:settled,mode:scene.mode,
                path:scene.viewPath,caseExpanded:scene.caseDock.expanded,busy:scene.busy,
                draft:!!scene.controller.draft,proposal:!!scene.controller.structuralProposal,bookDrag:!!scene.bookDrag}))
            // One actual click, no retry or alternate navigation path.
            mouseClick(child,child.width/2,child.height/2)
            console.log("legacy Browse child after click",JSON.stringify({path:scene.viewPath,
                activationCount:childActivation.valid?childActivation.count:null,busy:scene.busy,
                selected:scene.selectedModuleId,caseExpanded:scene.caseDock.expanded}))
            compare(scene.cubbyId,"child")
            compare(JSON.stringify(study.controller.snapshot),before)
        }
        function test_preview_partition_and_small_view() {
            tryVerify(function(){return rack()!==null})
            study.scene.mode="arrange"
            study.scene.selectedModuleId="rack-1"
            var before=JSON.stringify(study.controller.snapshot)
            study.controller.stage("root","rack-1",{w:480,h:390,r:52})
            compare(rack().rack.w,480)
            compare(rack().rack.r,52)
            study.controller.stage("root","rack-1",{w:470,h:380,r:38})
            compare(rack().rack.w,470)
            compare(rack().rack.r,38)
            var view=study.controller.preview
            compare(rack().scrollCount+view.caseOverflow.length+view.unresolved.length,View.records(Core.rackAt(study.controller.snapshot,"root","rack-1")).length)
            study.controller.choose("test-a","case")
            compare(study.scene.caseDock.recordCount,study.controller.snapshot.caseItems.length+1)
            verify(study.scene.caseDock.isPending("test-a"))
            verify(rack().scrollItem("test-a")===null)
            root.width=1024;root.height=600
            verify(study.scene.caseDock.width<=study.scene.width)
            study.controller.cancel()
            compare(study.scene.caseDock.recordCount,study.controller.snapshot.caseItems.length)
            compare(JSON.stringify(study.controller.snapshot),before)
            compare(rack().rack.w,500)
            compare(rack().rack.r,75)
        }
    }
}
