pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property color background: "#1e1e2e"
    readonly property color surface: "#28283d"
    readonly property color surfaceHigh: "#313244"
    readonly property color primary: "#89b4fa"
    readonly property color onPrimary: "#11111b"
    readonly property color secondary: "#b4befe"
    readonly property color onSecondary: "#11111b"
    readonly property color outline: "#45475a"
    readonly property color outlineVariant: "#585b70"
    readonly property color text: "#cdd6f4"
    readonly property color textMuted: "#a6adc8"
    readonly property color overlayDarken: Qt.rgba(0, 0, 0, 0.6)
    readonly property color selectionBorder: "#89b4fa"
    readonly property color selectionFill: Qt.rgba(137 / 255, 180 / 255, 250 / 255, 0.15)
}
