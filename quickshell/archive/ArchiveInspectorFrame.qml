import QtQuick
import "ArchiveView.mjs" as View

// Common chrome and bounded dimensions; callers own interaction and content.
Rectangle {
    id:frame
    required property var colors
    required property real availableWidth
    required property real availableHeight
    property real preferredWidth:280
    property real preferredHeight:200
    property real panelMix:.90
    width:Math.max(0,Math.min(availableWidth,preferredWidth))
    height:Math.max(0,Math.min(availableHeight,preferredHeight))
    radius:7
    clip:true
    color:View.mix(colors.background,colors.panel,panelMix)
    border.color:colors.metal
}
