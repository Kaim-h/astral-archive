import QtQuick
import QtTest
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveSpatial.mjs" as Spatial
import "ArchiveB8ShelfFixture.mjs" as Sample

Item {
    width:1366;height:900
    ArchiveNativeN2Study {id:study;anchors.fill:parent;spatialEnabled:true;initialSnapshot:Sample.fixture()}
    TestCase {
        name:"ArchiveB8Shelf"
        when:windowShown
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
