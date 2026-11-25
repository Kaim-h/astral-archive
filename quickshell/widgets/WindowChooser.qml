import QtQuick

// Illustrated, keyboard-driven list of windows for ONE application.
// Keyboard focus stays in the launcher's Index TextInput.
Rectangle {
    id: chooser
    property string appTitle: "Application"
    property var windows: []
    property int selectedIndex: 0
    property color panelColor: "#263c37"
    property color backdropColor: "#121e23"
    property color metalColor: "#8c6e5a"
    property color accentColor: "#91ada1"
    property color textColor: "#e6e1d8"

    signal windowRequested(string address)
    signal launchAgainRequested()
    signal dismissed()

    width: 410
    height: 293
    radius: 8
    color: panelColor
    border.width: 2
    border.color: metalColor

    onWindowsChanged: selectedIndex = 0

    function moveSelection(delta) {
        // The final row is an explicit "Launch again" action.
        selectedIndex = Math.max(0, Math.min(windows.length, selectedIndex + delta));
        if (selectedIndex < windows.length)
            windowList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
    function choose(index) {
        if (index < 0 || index > windows.length) return;
        selectedIndex = index;
        if (index === windows.length) {
            launchAgainRequested();
        } else if (windows[index].address) {
            windowRequested(windows[index].address);
        }
    }
    function acceptSelection() { choose(selectedIndex); }

    Text {
        id: header
        anchors.top: parent.top
        anchors.topMargin: 15
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 40
        elide: Text.ElideRight
        text: chooser.appTitle + " · " + chooser.windows.length + " windows"
        color: chooser.textColor
        font.pixelSize: 15
        font.family: "serif"
        font.bold: true
    }
    Text {
        anchors.top: header.bottom
        anchors.topMargin: 5
        anchors.left: header.left
        text: "↑↓ choose  ·  Enter open  ·  Esc back"
        color: chooser.accentColor
        font.pixelSize: 10
    }
    Text {
        anchors.centerIn: parent
        visible: chooser.windows.length === 0
        text: "No windows currently open"
        color: chooser.textColor
        font.pixelSize: 12
    }
    ListView {
        id: windowList
        anchors.top: parent.top
        anchors.topMargin: 66
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.right: parent.right
        anchors.rightMargin: 13
        height: 169
        clip: true
        spacing: 4
        model: chooser.windows
        delegate: Rectangle {
            required property int index
            required property var modelData
            width: windowList.width
            height: 47
            radius: 4
            color: chooser.selectedIndex === index ? chooser.backdropColor : "transparent"
            border.color: chooser.selectedIndex === index ? chooser.accentColor : "transparent"
            border.width: 1
            opacity: modelData.address ? 1 : 0.5

            Text {
                anchors.top: parent.top
                anchors.topMargin: 7
                anchors.left: parent.left
                anchors.leftMargin: 8
                width: parent.width - 16
                elide: Text.ElideRight
                text: modelData.title
                color: chooser.textColor
                font.pixelSize: 12
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: "Workspace " + modelData.workspaceName
                      + (modelData.address ? "" : " · loading")
                color: chooser.accentColor
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                onClicked: chooser.choose(index)
            }
        }
    }
    Rectangle {
        id: launchAgain
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.right: parent.right
        anchors.rightMargin: 13
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        height: 30
        radius: 4
        color: chooser.selectedIndex === chooser.windows.length
                ? chooser.backdropColor : "transparent"
        border.color: chooser.selectedIndex === chooser.windows.length
                      ? chooser.accentColor : chooser.metalColor
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: "✧  Launch application again"
            color: chooser.textColor
            font.pixelSize: 12
        }
        MouseArea { anchors.fill: parent; onClicked: chooser.choose(chooser.windows.length) }
    }
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 13
        anchors.right: parent.right
        anchors.rightMargin: 13
        width: 22
        height: 22
        radius: 3
        color: "transparent"
        border.color: chooser.metalColor
        Text { anchors.centerIn: parent; text: "×"; color: chooser.textColor; font.pixelSize: 17 }
        MouseArea { anchors.fill: parent; onClicked: chooser.dismissed() }
    }
}
