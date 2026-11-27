import QtQuick
import "ArchiveCore.mjs" as Core
import "ArchiveView.mjs" as View

Item {
    id: rackView
    required property var rack
    required property var colors
    property string phase: "idle"
    property var unresolved: []
    property var eligibleKeys: []
    property string selectedCell: ""
    property string selectedScroll: ""
    property var selectedIds: []
    property var motionRecords: null
    property var motionPositions: ({})
    property bool insertionMode: false
    property bool locked: false
    property var voidData: null
    property var lockedMark: null
    signal gestureStarted(var record,real lx,real ly,int modifiers)
    signal gestureMoved(real lx,real ly)
    signal gestureReleased(real lx,real ly)
    signal gestureCanceled()
    signal cellPoint(string key,real lx,real ly,int modifiers)
    signal pointerHover(real lx,real ly)
    signal resizeStarted(string action,real lx,real ly)
    signal resizeMoved(real lx,real ly)
    signal resizeReleased()
    signal resizeCanceled()
    property bool selected: false
    property bool browse: true
    readonly property var cells: Core.geometry(rack).cells
    readonly property var scrollRecords: motionRecords!==null ? motionRecords : View.records(rack)
    readonly property var markerData: View.markers(cells, unresolved)
    readonly property int scrollCount: scrollRepeater.count
    readonly property int cellCount: cells.length
    readonly property int markerCount: markerRepeater.count
    property int masonryPaints: 0
    signal rackPressed(string rackId, string key)
    signal scrollPressed(var record, real localX, real localY)
    signal scrollHovered(var record, real localX, real localY)
    objectName: "rack-" + rack.id
    x: rack.x
    y: rack.y
    width: rack.w
    height: rack.h

    function scrollItem(id) {
        for (var i = 0; i < scrollRepeater.count; ++i) {
            var item = scrollRepeater.itemAt(i)
            if (item && item.record.id === id) return item
        }
        return null
    }
    function hitRecord(x,y) { return View.hitScroll(scrollRecords,x,y) }
    function hitCell(x,y) {
        for (var i=0;i<cells.length;++i)
            if (Core.interiorDistance({x:x,y:y},cells[i].poly)>=-0.000001) return cells[i]
        return null
    }

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: View.rackColor(rackView.rack, rackView.colors)
        border.color: View.mix(rackView.colors.metal, rackView.colors.text, .16)
        border.width: 1
    }
    // Static masonry canvas: no Timer and no animation. Scroll transforms
    // remain separate scene-graph items; N3 may update them independently.
    Canvas {
        id: masonry
        objectName: "rack-masonry"
        readonly property real resolution: Math.max(1,Math.min(2,2048/Math.max(1,rackView.width),2048/Math.max(1,rackView.height)))
        width:rackView.width*resolution
        height:rackView.height*resolution
        scale:1/resolution
        transformOrigin:Item.TopLeft
        smooth:true
        antialiasing: true
        renderTarget: Canvas.Image
        function polygon(ctx, points) {
            if (!points.length) return
            ctx.beginPath()
            ctx.moveTo(points[0].x, points[0].y)
            for (var i=1;i<points.length;i++) ctx.lineTo(points[i].x,points[i].y)
            ctx.closePath()
        }
        onAvailableChanged: if (available) requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.save();ctx.clearRect(0,0,width,height);ctx.scale(resolution,resolution)
            var p = rackView.colors
            var g = Core.geometry(rackView.rack)
            ctx.fillStyle = View.mix(p.background,p.panel,.17)
            ctx.fillRect(g.box.x,g.box.y,g.box.w,g.box.h)
            for (var i=0;i<g.cells.length;i++) {
                var c=g.cells[i],meta=rackView.rack.cellMeta[c.key]
                polygon(ctx,c.poly)
                ctx.fillStyle=View.wallColor(meta,p)
                ctx.fill()
                if(c.innerPoly.length>=3){
                    polygon(ctx,c.innerPoly)
                    ctx.fillStyle=View.recessColor(meta,p)
                    ctx.fill()
                }
                var blocked=rackView.markerData.cells.some(function(m){return m.key===c.key})
                if(blocked||rackView.eligibleKeys.indexOf(c.key)>=0||rackView.selectedCell===c.key){
                    polygon(ctx,c.poly)
                    ctx.fillStyle=blocked?(rackView.phase==="pending"?"rgba(200,170,100,.14)":"rgba(213,91,80,.19)"):"rgba(145,173,161,.16)"
                    ctx.fill()
                    ctx.strokeStyle=blocked?(rackView.phase==="pending"?"#ddc293":"#e1a09a"):p.engraving
                    ctx.lineWidth=1.4
                    ctx.stroke()
                }
            }
            var edges=View.seams(g.cells)
            ctx.beginPath()
            for(var j=0;j<edges.length;j++){
                ctx.moveTo(edges[j].a.x,edges[j].a.y)
                ctx.lineTo(edges[j].b.x,edges[j].b.y)
            }
            ctx.strokeStyle=View.mix(p.metal,p.text,.22)
            ctx.lineWidth=1.15
            ctx.stroke()
            ctx.restore()
            rackView.masonryPaints++
        }
    }
    onRackChanged: masonry.requestPaint()
    onColorsChanged: masonry.requestPaint()
    onPhaseChanged: masonry.requestPaint()
    onUnresolvedChanged: masonry.requestPaint()
    onEligibleKeysChanged: masonry.requestPaint()
    onSelectedCellChanged: masonry.requestPaint()

    Canvas {
        id: voidOverlay
        anchors.fill: parent
        visible: !!rackView.voidData || !!rackView.lockedMark
        antialiasing: true
        function trace(ctx,path) {
            var tokens=path.match(/[MQZ]|-?\d+(?:\.\d+)?/g)||[],i=0
            ctx.beginPath()
            while(i<tokens.length){
                var cmd=tokens[i++]
                if(cmd==="M"){ctx.moveTo(Number(tokens[i++]),Number(tokens[i++]))}
                else if(cmd==="Q"){ctx.quadraticCurveTo(Number(tokens[i++]),Number(tokens[i++]),Number(tokens[i++]),Number(tokens[i++]))}
                else if(cmd==="Z")ctx.closePath()
                else break
            }
        }
        onAvailableChanged: if(available)requestPaint()
        onPaint: {
            var ctx=getContext("2d"),v=rackView.voidData,mark=rackView.lockedMark
            ctx.clearRect(0,0,width,height)
            if(v&&v.region){
                ctx.save()
                masonry.polygon(ctx,Core.wall(v.cell));ctx.clip()
                trace(ctx,v.region.path);ctx.fillStyle=rackView.colors.engraving;ctx.globalAlpha=.26;ctx.fill();ctx.globalAlpha=1
                ctx.strokeStyle=rackView.colors.engraving;ctx.lineWidth=1;ctx.stroke()
                ctx.restore()
                ctx.globalCompositeOperation="destination-out"
                for(var i=0;i<v.records.length;i++){var s=v.records[i];ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,2*Math.PI);ctx.fill()}
                ctx.globalCompositeOperation="source-over"
            }
            if(mark){ctx.beginPath();ctx.arc(mark.x,mark.y,mark.r,0,2*Math.PI);ctx.strokeStyle="#e4c98b";ctx.lineWidth=1.5;ctx.stroke()}
        }
    }
    onVoidDataChanged:voidOverlay.requestPaint()
    onLockedMarkChanged:voidOverlay.requestPaint()
    Repeater {
        id: scrollRepeater
        model: rackView.scrollRecords
        ArchiveScrollEnd {
            required property var modelData
            record: modelData
            colors: rackView.colors
            x: (rackView.motionPositions[record.id]?rackView.motionPositions[record.id].x:record.x) - visualRadius
            y: (rackView.motionPositions[record.id]?rackView.motionPositions[record.id].y:record.y) - visualRadius
            selected: rackView.selectedIds.indexOf(record.id)>=0 || rackView.selectedScroll === record.id
        }
    }
    Repeater {
        id: markerRepeater
        model: rackView.markerData.cells
        Rectangle {
            required property var modelData
            width: 30
            height: 18
            x: modelData.x-width/2
            y: modelData.y-height/2
            radius: 5
            color: rackView.phase==="pending"?"#645335":"#7b393b"
            border.color: rackView.phase==="pending"?"#ddc293":"#e1a09a"
            Text {
                anchors.centerIn: parent
                color: "#ffe5d8"
                font.pixelSize: 10
                font.bold: true
                text: (rackView.phase==="pending"?"… ":"! ")+parent.modelData.count
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        color: "transparent"
        border.width: rackView.selected||rackView.phase!=="idle"?2:0
        border.color: rackView.phase==="ready"?"#8fc3a4":rackView.phase==="pending"?"#cbb17b":rackView.phase==="idle"?rackView.colors.engraving:"#dc9289"
        radius: 2
    }
    Rectangle {
        width: Math.min(parent.width-12, plaque.implicitWidth+20)
        height: 16
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -2
        color: View.mix(rackView.colors.metal,rackView.colors.panel,.35)
        border.color: View.mix(rackView.colors.metal,rackView.colors.panel,.36)
        radius: 5
        Text {
            id: plaque
            anchors.centerIn: parent
            text: "hex rack"+(rackView.markerData.missing?" · ! "+rackView.markerData.missing:"")
            color: rackView.colors.text
            font.pixelSize: 9
            font.bold:true
        }
    }
    Rectangle {
        visible: !rackView.browse&&rackView.selected
        width:15;height:15
        anchors.right:parent.right;anchors.bottom:parent.bottom
        radius:2;color:rackView.colors.engraving
        opacity:.8
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing:true
        acceptedButtons: Qt.LeftButton
        property string action: ""
        cursorShape: rackView.browse ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed:function(mouse){
            action=""
            if(rackView.locked){mouse.accepted=false;return}
            if(!rackView.browse&&rackView.selected&&(mouse.x>width-18&&mouse.y>height-18||mouse.y<10)){
                action="resize";rackView.resizeStarted(mouse.y<10?"move":"size",mouse.x,mouse.y)
            }else if(rackView.browse&&rackView.phase==="idle"&&!rackView.insertionMode){
                var record=rackView.hitRecord(mouse.x,mouse.y)
                if(record){action="scroll";rackView.gestureStarted(record,mouse.x,mouse.y,mouse.modifiers)}
            }
        }
        onPositionChanged: function(mouse) {
            if(pressed&&action==="scroll"){rackView.gestureMoved(mouse.x,mouse.y);return}
            if(pressed&&action==="resize"){rackView.resizeMoved(mouse.x,mouse.y);return}
            if(rackView.insertionMode)rackView.pointerHover(mouse.x,mouse.y)
            else rackView.scrollHovered(rackView.browse&&rackView.phase==="idle"&&!rackView.locked?rackView.hitRecord(mouse.x,mouse.y):null,mouse.x,mouse.y)
        }
        onExited:{rackView.scrollHovered(null,0,0);rackView.pointerHover(-1,-1)}
        onReleased:function(mouse){
            if(action==="scroll")rackView.gestureReleased(mouse.x,mouse.y)
            else if(action==="resize")rackView.resizeReleased()
        }
        onCanceled:{if(action==="scroll")rackView.gestureCanceled();else if(action==="resize")rackView.resizeCanceled();action=""}
        onClicked: function(mouse) {
            if(action!==""){action="";return}
            var cell=rackView.hitCell(mouse.x,mouse.y)
            rackView.rackPressed(rackView.rack.id,cell?cell.key:"")
            rackView.cellPoint(cell?cell.key:"",mouse.x,mouse.y,mouse.modifiers)
        }
    }
}
