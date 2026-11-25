import QtQuick
import QtQuick.Window
import "../bar" as Bar
import "../themes" as Themes

Rectangle {
    id: desktop

    width: Screen.width
    height: Screen.height

    property int activeWorkspace: 1

    color: Themes.Theme.current.background

    Bar.ArchiveBar {
        id: archiveBar

        anchors.top: parent.top
        width: parent.width

        themes: Themes.Theme.palettes
        themeIndex: Themes.Theme.index
        activeWorkspace: desktop.activeWorkspace

        onThemeRequested: function(index) {
            Themes.Theme.index = index
        }

        onWorkspaceRequested: function(number) {
            desktop.activeWorkspace = number
        }
    }
}