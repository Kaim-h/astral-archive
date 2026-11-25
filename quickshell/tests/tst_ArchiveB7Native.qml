import QtQuick
import QtTest
import "../archive/representation" as B7
import "../archive/representation/B7Layout.mjs" as Layout
import "../themes" as Themes

Item {
    id:root
    width:1100;height:650
    ArchiveB7RepresentationStudy {id:study;anchors.fill:parent}
    Item {
        id:atlas
        anchors.fill:parent;visible:false
        Repeater {
            id:images
            model:Layout.assetEntries()
            B7.B7AssetImage {
                required property var modelData
                required property int index
                assetId:modelData.id;edge:modelData.edge;canonicalSvg:true
                x:(index%8)*66;y:Math.floor(index/8)*66
                width:64;height:64
            }
        }
    }
    Item {
        visible:false
        Repeater {
            id:rasters
            model:Layout.assetEntries().filter(e=>Layout.assetFor(e.id).family==="sculpture")
            B7.B7AssetImage {
                required property var modelData
                assetId:modelData.id
                width:64;height:64
            }
        }
    }
    TestCase {
        name:"ArchiveB7Native"
        when:windowShown
        function init(){
            study.studyPage="objects";study.selectedId="";study.frameProfile="bronze"
            study.artworkLedge=false;study.secondarySupports=false
            Themes.Theme.index=1
            findChild(study,"b7-upright-holder").resetSlots()
        }
        function clickItem(item){
            verify(!!item)
            tryVerify(function(){return item.visible&&item.enabled&&item.width>0&&item.height>0})
            mouseClick(item,item.width/2,item.height/2)
        }
        function test_all_svg_decode(){
            compare(images.count,64)
            for(var i=0;i<images.count;i++){
                var image=images.itemAt(i)
                tryCompare(image,"status",Image.Ready,2000,"Qt could not decode "+image.assetId+(image.edge?" edge":" face"))
                verify(image.sourceSize.width>0&&image.sourceSize.height>0)
            }
        }
        function test_sculpture_raster_derivatives(){
            compare(rasters.count,16)
            for(var i=0;i<rasters.count;i++){
                var image=rasters.itemAt(i),v=Layout.assetFor(image.assetId).geometry.viewport
                verify(image.raster)
                tryCompare(image,"status",Image.Ready,2000,"Missing sculpture derivative: "+image.assetId)
                compare(image.sourceSize.width,v[2]*4)
                compare(image.sourceSize.height,v[3]*4)
            }
        }
        function test_actual_supported_selection(){
            var board=findChild(study,"b7-board")
            var original=JSON.stringify(study.sampleRecords)
            for(var i=1;i<study.sampleRecords.length;i++){
                var symbol=findChild(study,study.sampleRecords[i].id)
                verify(!!symbol)
                tryCompare(symbol,"imageStatus",Image.Ready)
                var bottom=symbol.mapToItem(board,symbol.width/2,symbol.height)
                verify(Math.abs(bottom.y-board.supportY)<.001)
                var p=symbol.placement,anchor=Layout.assetFor(symbol.assetId).geometry.contact
                var box=Layout.assetFor(symbol.assetId).geometry.viewport
                verify(Math.abs(p.image.y+(anchor[1]-box[1])*symbol.artScale-symbol.supportY)<.001)
                mouseClick(symbol,symbol.width/2,symbol.height/2)
                tryCompare(study,"selectedId",symbol.record.id)
            }
            compare(JSON.stringify(study.sampleRecords),original)
        }
        function test_secondary_supports_and_metadata(){
            var original=JSON.stringify(study.sampleRecords),board=findChild(study,"b7-board")
            clickItem(findChild(study,"b7-toggle-ledge"))
            tryCompare(study,"artworkLedge",true)
            var ledge=findChild(study,"b7-artwork-ledge"),frame=findChild(study,"b7-mounted-artwork")
            verify(ledge.visible)
            compare(frame.mapToItem(ledge,frame.width/2,frame.height).y,ledge.supportY)
            clickItem(findChild(study,"b7-toggle-supports"))
            tryCompare(study,"secondarySupports",true)
            for(var i=1;i<study.sampleRecords.length;i++){
                var r=study.sampleRecords[i],support=findChild(study,"support-"+r.id),symbol=findChild(support,r.id)
                tryCompare(support,"mode",i===3?"tray":"plinth")
                compare(support.mapToItem(board,support.width/2,support.height).y,board.supportY)
                compare(symbol.mapToItem(support,symbol.width/2,symbol.height).y,0)
                verify(symbol.x>=0&&symbol.x+symbol.width<=support.width)
                compare(support.lipItem.visible,i===3)
                if(i===3){verify(support.lipItem.y<0);verify(support.lipItem.z>symbol.z)}
                clickItem(symbol)
                tryCompare(study,"selectedId",r.id)
            }
            // Hover the actual compact plaque, then move into the expanded
            // register; neither operation changes support geometry or identity.
            for(var j=0;j<study.sampleRecords.length;j++){
                var record=study.sampleRecords[j],plaque=findChild(study,"metadata-"+record.id)
                verify(!!plaque)
                var before=JSON.stringify(study.sampleRecords)
                mouseMove(plaque,plaque.width/2,plaque.height/2,30)
                tryCompare(plaque,"expanded",true)
                var panel=plaque.panelItem
                verify(panel.visible&&panel.width>plaque.width)
                compare(panel.recordId,record.id)
                compare(panel.recordName,record.name)
                var p=panel.mapToItem(study,0,0),q=panel.mapToItem(study,panel.width,panel.height)
                verify(p.x>=0&&p.y>=0&&q.x<=study.width&&q.y<=study.height)
                mouseMove(panel,12,12,30)
                wait(180)
                verify(plaque.expanded,"Moving within metadata must not dismiss it")
                compare(JSON.stringify(study.sampleRecords),before)
                mouseMove(study,2,2,30)
                tryCompare(plaque,"expanded",false)
            }
            var artPlaque=findChild(study,"metadata-b7-artwork")
            artPlaque.forceActiveFocus()
            tryCompare(artPlaque,"expanded",true)
            keyClick(Qt.Key_Escape);tryCompare(artPlaque,"expanded",false)
            compare(JSON.stringify(study.sampleRecords),original)
            study.selectedId="";mouseMove(study,2,2,30);wait(150)
            grabImage(study).save("archive-b7-native-supports.png")
        }
        function test_upright_pointer_and_keyboard(){
            clickItem(findChild(study,"b7-show-upright"))
            tryCompare(study,"studyPage","upright")
            var holder=findChild(study,"b7-upright-holder"),cradle=findChild(study,"b7-presentation-cradle")
            var board=findChild(study,"b7-upright-board")
            compare(holder.y+holder.height,board.y+board.supportY)
            compare(cradle.y+cradle.height,board.y+board.supportY)
            var original=JSON.stringify(holder.slots)
            var a=findChild(holder,"b7-slot-0"),b=findChild(holder,"b7-slot-1"),vacant=findChild(holder,"b7-slot-2")
            clickItem(a)
            tryCompare(holder,"selectedId","b7-record-a")
            verify(a.presented)
            compare(cradle.record.id,"b7-record-a")
            tryCompare(cradle,"imageStatus",Image.Ready)
            verify(Math.abs(cradle.facePlacement.box.y+cradle.facePlacement.box.height-cradle.floor)<.001)
            compare(JSON.stringify(holder.slots),original)
            keyClick(Qt.Key_Escape)
            tryCompare(holder,"selectedId","")
            verify(!a.presented)
            compare(JSON.stringify(holder.slots),original)
            function drag(from,to){
                var start=from.mapToItem(holder,from.width/2,from.height/2),end=to.mapToItem(holder,to.width/2,to.height/2)
                mousePress(holder,start.x,start.y,Qt.LeftButton)
                mouseMove(holder,end.x,end.y,40,Qt.LeftButton)
                tryCompare(holder,"dragActive",true)
                compare(JSON.stringify(holder.slots),original)
                mouseRelease(holder,end.x,end.y,Qt.LeftButton)
            }
            drag(a,vacant)
            tryVerify(function(){return holder.slots[0]===null&&holder.slots[2].id==="b7-record-a"})
            compare(holder.slots[1].id,"b7-ledger-a")
            original=JSON.stringify(holder.slots)
            drag(vacant,b)
            tryVerify(function(){return holder.slots[1].id==="b7-record-a"&&holder.slots[2].id==="b7-ledger-a"})
            original=JSON.stringify(holder.slots)
            // Keyboard move preserves identity and accepts a vacant destination.
            b.forceActiveFocus();keyClick(Qt.Key_Space)
            compare(holder.keyboardSource,1)
            keyClick(Qt.Key_Left);keyClick(Qt.Key_Return)
            tryVerify(function(){return holder.slots[0].id==="b7-record-a"&&holder.slots[1]===null})
            original=JSON.stringify(holder.slots)
            a.forceActiveFocus();keyClick(Qt.Key_Space);keyClick(Qt.Key_Escape)
            compare(holder.keyboardSource,-1)
            compare(JSON.stringify(holder.slots),original)
            // Drop outside the holder cannot silently remove the file.
            var start=a.mapToItem(holder,a.width/2,a.height/2)
            mousePress(holder,start.x,start.y,Qt.LeftButton)
            mouseMove(holder,holder.width+8,start.y,40,Qt.LeftButton)
            mouseRelease(holder,holder.width+8,start.y,Qt.LeftButton)
            compare(JSON.stringify(holder.slots),original)
            holder.resetSlots()
            clickItem(findChild(holder,"b7-slot-3"))
            tryCompare(holder,"selectedId","b7-tablet-a")
            tryCompare(cradle,"imageStatus",Image.Ready)
            wait(150)
            var capture=grabImage(study)
            verify(capture.width>0&&capture.height>0)
            capture.save("archive-b7-native-upright.png")
            clickItem(findChild(study,"b7-return-presentation"))
            tryCompare(holder,"selectedId","")
            compare(JSON.stringify(holder.slots),JSON.stringify(study.uprightRecords))
        }
        function test_metadata_focus_on_context_change(){
            var plaque=findChild(study,"metadata-b7-artwork")
            plaque.forceActiveFocus()
            tryCompare(plaque,"activeFocus",true)
            tryCompare(plaque,"expanded",true)
            clickItem(findChild(study,"b7-show-upright"))
            tryCompare(study,"studyPage","upright")
            tryCompare(plaque,"expanded",false)
            verify(!plaque.activeFocus)
            var holder=findChild(study,"b7-upright-holder"),slot=findChild(holder,"b7-slot-0")
            clickItem(slot)
            tryCompare(holder,"selectedId","b7-record-a")
            var metadata=findChild(study,"metadata-b7-record-a")
            verify(!!metadata)
            metadata.forceActiveFocus()
            tryCompare(metadata,"expanded",true)
            var ret=findChild(study,"b7-return-presentation")
            ret.forceActiveFocus()
            keyClick(Qt.Key_Return)
            tryCompare(holder,"selectedId","")
            tryCompare(slot,"activeFocus",true)
            verify(!metadata.expanded&&!metadata.activeFocus)
            compare(JSON.stringify(holder.slots),JSON.stringify(study.uprightRecords))
        }
        function test_frame_profiles_and_capture(){
            var frame=findChild(study,"b7-mounted-artwork")
            tryCompare(frame,"imageStatus",Image.Ready)
            var original=JSON.stringify(study.sampleRecords)
            for(var i=0;i<3;i++){
                study.frameProfile=["bronze","stone","slim"][i]
                tryVerify(function(){return frame.apertureItem.width>0&&frame.apertureItem.height>0})
                compare(frame.apertureItem.width,frame.geometry.aperture[2])
                mouseClick(frame,frame.width/2,frame.height/2)
                tryCompare(study,"selectedId","b7-artwork")
            }
            compare(JSON.stringify(study.sampleRecords),original)
            study.frameProfile="bronze";study.selectedId="";Themes.Theme.index=1
            wait(150)
            // Qt Quick Test's TestImage.save is void. CI checks the file.
            var capture=grabImage(study)
            verify(capture.width>0&&capture.height>0)
            capture.save("archive-b7-native-first.png")
        }
    }
}
