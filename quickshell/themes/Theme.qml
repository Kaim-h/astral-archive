pragma Singleton //palate data
import QtQuick

QtObject {
    id: theme
    property int index: 1

    readonly property var palettes: [
        {
            name: "Evening",
            symbol: "☀",
            background: "#343c43",
            panel: "#3f524f",
            metal: "#c2aa78",
            engraving: "#b7a2c8",
            text: "#f0f0e8"
        },
        {
            name: "Twilight",
            symbol: "✦",
            background: "#121e23",
            panel: "#263c37",
            metal: "#8c6e5a",
            engraving: "#91ada1",
            text: "#e6e1d8"
        },
        {
            name: "Midnight",
            symbol: "☾",
            background: "#080f10",
            panel: "#101c1b",
            metal: "#869c9c",
            engraving: "#568f80",
            text: "#dadfd9"
        }
    ]

    readonly property var current: palettes[index]
}