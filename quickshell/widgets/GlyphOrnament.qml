import QtQuick

Text {
    id: ornament

    property real glyphSpacing: 0
    property real glyphLineHeight: 1.0

    font.letterSpacing: glyphSpacing

    lineHeight: glyphLineHeight
    lineHeightMode: Text.ProportionalHeight

    wrapMode: Text.NoWrap

    property string pattern: "✧"
    property string glyphFont: "monospace"
    property int glyphSize: 10

    text: pattern
    textFormat: Text.PlainText

    color: "#91ada1"

    font.family: glyphFont
    font.pixelSize: glyphSize

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}