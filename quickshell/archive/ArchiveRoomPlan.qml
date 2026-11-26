import QtQuick
import "ArchiveView.mjs" as View
import "ArchiveRoomProjection.mjs" as Projection

// Isolated native plan and perspective: one Room, shared geometry/openings.
// No separate arrangement model or continuous paint loop.
Item {
    id:plan
    required property var snapshot
    required property string roomId
    required property var colors
    required property var palettes
    required property int desktopPalette
    property string selectedShelf:""
    property bool perspective:false
    property bool arranging:false
    property var rotationPreview:null
    signal turnShelf(string shelfId)
    readonly property var perspectiveData:visible&&perspective?View.roomPerspective(snapshot,planData,width,height):null
    signal inspectShelf(string shelfId)
    readonly property var planData:View.roomPlan(snapshot,roomId)
    readonly property real planScale:planData?Math.max(.001,Math.min(Math.max(1,width-64)/planData.room.w,Math.max(1,height-100)/planData.room.h)):1
    readonly property point planOrigin:planData?Qt.point((width-planData.room.w*planScale)/2,(height-planData.room.h*planScale)/2):Qt.point(0,0)
    function pointFor(x,y){
        if(perspective&&perspectiveData){var p=Projection.project([x,y,0],perspectiveData.frame);return p?Qt.point(p[0],p[1]):Qt.point(-1,-1)}
        return Qt.point(planOrigin.x+x*planScale,planOrigin.y+y*planScale)
    }
    function floorAt(x,y){
        return perspective&&perspectiveData?Projection.floorInverse(x,y,perspectiveData.frame):{x:(x-planOrigin.x)/planScale,y:(y-planOrigin.y)/planScale}
    }
    function hit(x,y){
        if(perspective)return View.roomPerspectiveHit(perspectiveData,x,y)
        var p=floorAt(x,y);return p?View.roomPlanHit(planData,p.x,p.y):""
    }
    onRoomIdChanged:selectedShelf=""
    onPlanDataChanged:if(!planData||!planData.shelves.some(v=>v.id===selectedShelf))selectedShelf=""
    Rectangle {anchors.fill:parent;color:plan.colors.background}
    Text {
        anchors.top:parent.top;anchors.topMargin:8;anchors.horizontalCenter:parent.horizontalCenter
        color:plan.colors.text;font.pixelSize:16
        text:plan.planData?plan.planData.room.name+(plan.perspective?" · Perspective":" · Room plan"):"Room plan"
    }
    Canvas {
        id:art
        objectName:"room-plan-art"
        anchors.fill:parent
        function refresh(){if(visible&&available)requestPaint()}
        Connections {
            target:plan
            function onPlanDataChanged(){art.refresh()}
            function onColorsChanged(){art.refresh()}
            function onPalettesChanged(){art.refresh()}
            function onDesktopPaletteChanged(){art.refresh()}
            function onPlanOriginChanged(){art.refresh()}
            function onPlanScaleChanged(){art.refresh()}
            function onSelectedShelfChanged(){art.refresh()}
            function onPerspectiveDataChanged(){art.refresh()}
            function onPerspectiveChanged(){art.refresh()}
            function onRotationPreviewChanged(){art.refresh()}
        }
        onWidthChanged:refresh()
        onHeightChanged:refresh()
        onAvailableChanged:refresh()
        onVisibleChanged:refresh()
        onPaint:{
            if(!visible)return
            var ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height)
            var data=plan.planData;if(!data)return
            function polygon(points,fill){
                ctx.beginPath();ctx.moveTo(points[0][0],points[0][1])
                for(var i=1;i<points.length;i++)ctx.lineTo(points[i][0],points[i][1])
                ctx.closePath();ctx.fillStyle=fill;ctx.fill()
            }
            function outline(box,color){
                var a=plan.pointFor(box.x,box.y),b=plan.pointFor(box.x+box.w,box.y),
                    c=plan.pointFor(box.x+box.w,box.y+box.h),d=plan.pointFor(box.x,box.y+box.h)
                ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.lineTo(c.x,c.y);ctx.lineTo(d.x,d.y);ctx.closePath()
                ctx.lineWidth=1.5;ctx.strokeStyle=color;ctx.stroke()
            }
            if(plan.perspective){
                var scene=plan.perspectiveData;if(!scene)return
                polygon(scene.floor,plan.colors.panel)
                for(var face of scene.faces)polygon(face.points,View.roomPerspectiveColor(plan.snapshot,face,plan.palettes,plan.desktopPalette,plan.colors))
                var selected=data.shelves.find(v=>v.id===plan.selectedShelf)
                if(selected)outline(selected.box,plan.colors.text)
                if(plan.rotationPreview)outline(plan.rotationPreview,plan.colors.engraving)
                return
            }
            var r=data.room,k=plan.planScale,o=plan.planOrigin
            ctx.save();ctx.translate(o.x,o.y);ctx.scale(k,k)
            var wall=3/k
            ctx.fillStyle=plan.colors.panel;ctx.fillRect(0,0,r.w,r.h)
            ctx.strokeStyle=plan.colors.metal;ctx.lineWidth=wall
            ctx.strokeRect(0,0,r.w,r.h)
            for(var opening of data.openings){
                ctx.strokeStyle=plan.colors.panel;ctx.lineWidth=wall+2/k
                ctx.beginPath()
                if(opening.side==="north"||opening.side==="south"){
                    var y=opening.side==="north"?0:r.h
                    ctx.moveTo(opening.start,y);ctx.lineTo(opening.end,y)
                }else{
                    var x=opening.side==="west"?0:r.w
                    ctx.moveTo(x,opening.start);ctx.lineTo(x,opening.end)
                }
                ctx.stroke()
            }
            for(var shelf of data.shelves){
                var palette=View.spatialPalette(plan.snapshot,shelf.id,plan.palettes,plan.desktopPalette)
                var box=shelf.box
                for(var layer of shelf.glyph.layers){
                    var fill=layer.role==="frame"?palette.metal:layer.role==="recess"?palette.background:palette.panel
                    polygon(layer.points,fill)
                }
                var lip=shelf.glyph.front
                ctx.beginPath();ctx.moveTo(lip[0][0],lip[0][1]);ctx.lineTo(lip[1][0],lip[1][1])
                ctx.strokeStyle=palette.engraving;ctx.lineWidth=1.5/k;ctx.stroke()
                if(plan.selectedShelf===shelf.id){
                    ctx.strokeStyle=plan.colors.text;ctx.lineWidth=1/k
                    var inset=Math.min(.5/k,box.w/4,box.h/4)
                    ctx.strokeRect(box.x+inset,box.y+inset,box.w-2*inset,box.h-2*inset)
                }
            }
            ctx.restore()
            if(plan.rotationPreview)outline(plan.rotationPreview,plan.colors.engraving)
        }
    }
    Repeater {
        model:plan.visible&&!plan.perspective&&plan.planData?plan.planData.shelves:[]
        Text {
            required property var modelData
            readonly property var box:modelData.box
            x:plan.pointFor(box.x,box.y).x;y:plan.pointFor(box.x,box.y).y
            width:box.w*plan.planScale;height:box.h*plan.planScale
            color:View.spatialPalette(plan.snapshot,modelData.id,plan.palettes,plan.desktopPalette).text
            text:width>=70&&height>=15?modelData.name:""
            font.pixelSize:Math.max(1,Math.min(12,height*.55))
            horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight;clip:true
        }
    }
    MouseArea {
        anchors.fill:parent
        onClicked:function(mouse){plan.selectedShelf=plan.hit(mouse.x,mouse.y)}
        onDoubleClicked:function(mouse){var id=plan.hit(mouse.x,mouse.y);if(id&&!plan.arranging)plan.inspectShelf(id)}
    }
    Row {
        anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:8
        spacing:6
        ArchiveButton {
            colors:plan.colors
            objectName:"plan-inspect-shelf"
            label:"Inspect selected Shelf"
            visible:!plan.arranging
            enabled:!!plan.selectedShelf
            onClicked:plan.inspectShelf(plan.selectedShelf)
        }
        ArchiveButton {
            colors:plan.colors
            objectName:"plan-turn-shelf"
            label:"Rotate selected Shelf 90°"
            visible:plan.arranging
            enabled:!!plan.selectedShelf
            onClicked:plan.turnShelf(plan.selectedShelf)
        }
    }
}
