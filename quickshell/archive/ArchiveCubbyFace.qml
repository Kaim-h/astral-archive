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
    property int depth: 1
    property bool selected: false
    property bool browse: true
    property string previewMode:"veiled"
    readonly property var inventory:previewMode==="inventory"?View.cubbyPreviewSummary(child):null
    signal activated(string moduleId, string childId)
    objectName: "cubby-" + module.id
    x: module.x
    y: module.y
    width: module.w
    height: module.h
    readonly property real frame: Math.min(Number(child.b)||11,width/4,height/4)

    Rectangle {
        anchors.fill: parent
        color: View.frameColor(face.child,face.colors,face.depth)
        border.color: face.selected?face.colors.engraving:View.mix(face.colors.metal,face.colors.text,.16)
        border.width: face.selected?2:1
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
                    opacity: .27
                    radius: 2
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            visible:face.previewMode==="veiled"
            color: View.backingColor(face.child,face.colors,face.depth)
            opacity: .38
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
                width:parent.width
                text:face.inventory?face.inventory.cubby+" cubbies · "+face.inventory.items+" items":""
                font.pixelSize:Math.max(9,Math.min(13,face.width/18))
                color:face.colors.text;opacity:.65
                horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
            }
        }
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
