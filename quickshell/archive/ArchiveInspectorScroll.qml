import QtQuick

// Shared scroll policy. Fixed headers and actions belong outside this item.
Flickable {
    id:viewport
    contentWidth:width
    flickableDirection:Flickable.VerticalFlick
    boundsBehavior:Flickable.StopAtBounds
    clip:true
    function resetPosition(){
        cancelFlick()
        contentX=originX
        contentY=originY
    }
}
