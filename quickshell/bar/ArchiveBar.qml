import QtQuick //building the taskbar at the top of the screen
import "../widgets" as Widgets

Rectangle {
    id: bar

    property int themeIndex: 1
    property int activeWorkspace: 1
    property var themes: []

    signal workspaceRequested(int number)
    signal themeRequested(int index)

    height: 50

    color: themes[themeIndex].panel
    border.color: themes[themeIndex].metal 
    border.width: 1

    Widgets.WorkspaceIndicator {
        id: workspaces

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        activeWorkspace: bar.activeWorkspace

        activeColor: bar.themes[bar.themeIndex].metal
        inactiveColor: bar.themes[bar.themeIndex].background
        textColor: bar.themes[bar.themeIndex].text
        
        onWorkspaceRequested: function(number) {
            bar.workspaceRequested(number)
        }
    }

    Widgets.ClockDisplay {

        id: clock 

        anchors.right: selector.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        clockColor: bar.themes[bar.themeIndex].metal
        useElfish: false

    }

    Widgets.ThemeSelector{
        id: selector

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        themeIndex: bar.themeIndex
        themes: bar.themes
        
        onThemeRequested: function(index) {
            bar.themeRequested(index)
        }
    }
}