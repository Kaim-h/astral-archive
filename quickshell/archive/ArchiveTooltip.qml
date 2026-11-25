import QtQuick
import "ArchiveView.mjs" as View

Rectangle {
    id: tip
    required property var colors
    property var record: null
    property bool expanded: false
    property point anchorPoint: Qt.point(0,0)
    objectName: "archive-tooltip"
    visible: record!==null
    width: Math.min(expanded?285:225,Math.max(1,parent.width-16))
    height: details.implicitHeight+14
    x: Math.max(4,Math.min(anchorPoint.x+12,parent.width-width-4))
    y: Math.max(4,Math.min(anchorPoint.y+12,parent.height-height-4))
    color: View.mix(colors.background,colors.panel,.38)
    border.color: colors.metal
    radius: 7
    z: 20
    Column {
        id: details
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 7
        y: 7
        spacing: 5
        Row {
            width: parent.width
            spacing: 7
            Rectangle {
                width: 29; height: 29; radius: 14.5
                color: tip.record?View.seal(tip.record):tip.colors.panel
                border.color: View.mix(tip.colors.metal,tip.colors.text,.24)
                Rectangle {
                    anchors.centerIn: parent
                    width: 21; height: 21; radius: 10.5
                    color: "transparent"; border.color: tip.colors.text
                    opacity: .48
                }
                Text {
                    anchors.centerIn: parent
                    text: tip.record?({code:"‹›",config:"⚙",logs:"≡",documents:"✒",system:"◇",other:"◈"}[View.purpose(tip.record)]):""
                    color: tip.colors.text
                    font.pixelSize: 13
                }
            }
            Column {
                width: parent.width-36
                Text {
                    width: parent.width
                    text: tip.record?tip.record.name:""
                    textFormat: Text.PlainText
                    color: tip.colors.text
                    font.pixelSize: 12; font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: tip.record&&tip.record.modified?"Modified · "+tip.record.modified:"Synthetic study record"
                    color: tip.colors.engraving
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
        Text {
            visible: tip.expanded&&!!tip.record
            width: parent.width
            color: tip.colors.text
            font.pixelSize: 11
            textFormat: Text.PlainText
            wrapMode: Text.WrapAnywhere
            text: tip.record?"Purpose · "+View.purpose(tip.record)+"\nType · "+(tip.record.fileType||"Unknown")+"\nExtension · "+(tip.record.extension||"Unknown")+"\nAdded · "+(tip.record.added||"Not available")+"\nSize · "+(tip.record.size||"Not available")+"\nPath · "+(tip.record.path||"Not available"):""
        }
        Text {
            width: parent.width
            color: tip.colors.engraving
            font.pixelSize: 9
            text: tip.expanded?"Sample data · click to close":"Click for details"
        }
    }
}
