import QtQuick
Item {
    id: icon
    property color ink: "#c2aa78"
    width: 19
    height: 15
    Rectangle { x:4; y:3; width:11; height:9; radius:2; color:"transparent"; border.color:icon.ink }
    Rectangle { x:1; y:2; width:5; height:11; radius:2.5; color:"transparent"; border.color:icon.ink }
    Rectangle { x:13; y:2; width:5; height:11; radius:2.5; color:"transparent"; border.color:icon.ink }
    Rectangle { x:6; y:6.5; width:7; height:1; color:icon.ink }
}
