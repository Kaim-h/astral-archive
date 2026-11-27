import QtQuick

// One lintel-bounded inscription implementation for live and moving fronts.
Text {
    required property var inscription
    required property string shelfName
    required property var colors
    x:inscription.x+4;y:inscription.y
    width:Math.max(0,inscription.w-8);height:inscription.h
    text:shelfName.toUpperCase()
    color:colors.text
    font.family:"serif";font.pixelSize:Math.max(1,inscription.h*.78)
    fontSizeMode:Text.HorizontalFit;minimumPixelSize:1
    horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
    elide:Text.ElideRight;clip:true
}
