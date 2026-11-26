import QtQuick
import QtTest
import "../themes" as Themes
import "../archive/ArchiveCore.mjs" as Core
import "../archive/ArchiveSpatial.mjs" as Spatial
import "ArchiveB8ShelfFixture.mjs" as Sample

Item {
    width:1366;height:900
    ArchiveNativeN2Study {id:study;anchors.fill:parent;spatialEnabled:true;initialSnapshot:Sample.fixture()}
    TestCase {
        name:"ArchiveB8Shelf"
        when:windowShown
        function init(){study.scene.abortGesture();study.closeContext();study.closeMaterials();study.controller.reset(Sample.fixture());study.scene.mode="browse";study.scene.zoom=1;study.scene.pan=Qt.point(0,0);study.scene.clearSelection()}
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
