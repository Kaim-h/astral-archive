import QtQuick
import "ArchiveView.mjs" as View

// A nested cubby face has its own parent footprint. Exterior modes reveal
// only faint structure, immediate inventory counts, or the closed recess.
// No miniature file hit targets, names, or recursive scene rendering.
Item {
    id: face
    required property var module
    required property var child
    required property var colors
    property string ornamentFamily:"None"
    property bool spatialStyle:false
    property string glazingStyle:"linework"
    readonly property var glazingPolicy:({linework:[.38,.27],subtle:[.68,.19],moderate:[.53,.30],clearer:[.20,.52],graded:[.43,.32],combined:[.34,.46]})[glazingStyle]||[.38,.27]
    property int depth: 1
    property bool selected: false
    property bool browse: true
    property string previewMode:"veiled"
    readonly property var inventory:previewMode==="inventory"?View.cubbyPreviewSummary(child):null
    signal activated(string moduleId, string childId)
    activeFocusOnTab:spatialStyle
    Accessible.role:Accessible.Button
    Accessible.name:child.name||"Sub-cubby"
    Accessible.onPressAction:activated(module.id,module.childId)
    Keys.onReturnPressed:function(event){face.activated(face.module.id,face.module.childId);event.accepted=true}
    Keys.onSpacePressed:function(event){face.activated(face.module.id,face.module.childId);event.accepted=true}
    objectName: "cubby-" + module.id
    x: module.x
    y: module.y
    width: module.w
    height: module.h
    readonly property real frame: Math.min(Number(child.b)||11,width/4,height/4)

    Rectangle {
        anchors.fill: parent
        color: View.frameColor(face.child,face.colors,face.depth)
        border.color: face.selected||face.activeFocus?face.colors.engraving:View.mix(face.colors.metal,face.colors.text,.16)
        border.width: face.selected||face.activeFocus?2:1
        radius: 2
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: face.frame
        color: View.backingColor(face.child,face.colors,face.depth)
        border.color: View.mix(face.colors.metal,face.colors.panel,.45)
        clip: true
        Item {
            id: silhouette
            objectName:"cubby-preview-veil"
            visible:face.previewMode==="veiled"
            width: face.child.w
            height: face.child.h
            scale: Math.min(parent.width/width,parent.height/height)
            transformOrigin: Item.TopLeft
            x: (parent.width-width*scale)/2
            y: (parent.height-height*scale)/2
            Repeater {
                model: silhouette.visible?face.child.mods:[]
                Rectangle {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    width: modelData.w
                    height: modelData.h
                    color: View.mix(face.colors.engraving,face.colors.panel,.5)
                    border.color: face.colors.engraving
                    opacity: face.spatialStyle?face.glazingPolicy[1]:.27
                    radius: 2
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            visible:face.previewMode==="veiled"
            color: View.backingColor(face.child,face.colors,face.depth)
            opacity:face.spatialStyle?face.glazingPolicy[0]:.38
        }
        Rectangle {
            anchors.fill:parent;visible:face.spatialStyle&&face.previewMode==="veiled"
            color:"transparent"
            border.color:View.mix(face.colors.metal,face.colors.engraving,.26)
            border.width:1
            opacity:.7
            gradient:Gradient {
                GradientStop {position:0;color:Qt.rgba(1,1,1,face.glazingStyle==="graded"?.15:.045)}
                GradientStop {position:.45;color:Qt.rgba(1,1,1,.015)}
                GradientStop {position:1;color:Qt.rgba(0,0,0,face.glazingStyle==="graded"?.14:.03)}
            }
        }
        ArchiveFamilyMark {
            objectName:"cubby-face-ornament"
            family:face.previewMode==="inventory"?"None":face.ornamentFamily
            colors:face.colors;exterior:true
            emblemKey:face.child.appearance&&face.child.appearance.emblem||""
        }
        Column {
            objectName:"cubby-preview-inventory"
            visible:face.previewMode==="inventory"
            anchors.centerIn:parent
            width:Math.max(0,parent.width-6)
            spacing:2
            Text {
                width:parent.width
                text:face.inventory?face.inventory.rack+" racks · "+face.inventory.shelf+" shelves":""
                font.pixelSize:Math.max(9,Math.min(13,face.width/18))
                color:face.colors.text;opacity:.82
                horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
            }
            Text {
                objectName:"cubby-inventory-item-label"
                width:parent.width
                text:face.inventory?face.inventory.cubby+" cubbies · "+face.inventory.items+" items":""
                font.pixelSize:Math.max(9,Math.min(13,face.width/18))
                color:face.colors.text;opacity:.65
                horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
            }
        }
    }
    Repeater {
        model:face.spatialStyle&&face.previewMode==="veiled"?[.27,.73]:[]
        Rectangle {
            required property real modelData
            x:face.frame*.30;y:face.height*modelData-height/2
            width:Math.max(2,face.frame*.44);height:Math.min(14,face.height*.12)
            radius:1;color:face.colors.metal;opacity:.72
        }
    }
    Rectangle {
        visible:face.spatialStyle&&face.previewMode==="veiled"
        x:face.width-face.frame*.68;y:face.height*.5-height/2
        width:Math.max(2,face.frame*.36);height:Math.min(20,face.height*.16)
        radius:2;color:face.colors.metal;opacity:.82
    }
    Rectangle {
        height: 17
        width: Math.min(parent.width-12, label.implicitWidth+22)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -2
        color: View.mix(face.colors.metal,face.colors.panel,.35)
        border.color: View.mix(face.colors.metal,face.colors.panel,.36)
        radius: 5
        Text {
            id: label
            anchors.centerIn: parent
            width: parent.width-10
            text: face.child.name||"Sub-cubby"
            color: face.colors.text
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: face.browse?Qt.PointingHandCursor:Qt.ArrowCursor
        onClicked: face.activated(face.module.id,face.module.childId)
    }
}
