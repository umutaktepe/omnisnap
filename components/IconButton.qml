import QtQuick
import "../theme"

Rectangle {
    id: root

    enum ButtonType {
        Filled,
        Tonal,
        Text
    }

    property string icon: ""
    property int iconSize: 20
    property bool round: false
    property bool isToggle: false
    property bool checked: false
    property real padding: 4
    property int type: IconButton.ButtonType.Filled

    readonly property alias hovered: mouseArea.containsMouse
    readonly property alias pressed: mouseArea.pressed

    property color baseColor: "transparent"
    property color hoverColor: Theme.surfaceHigh
    property color checkedColor: Theme.surfaceHigh
    property color pressedColor: Theme.outline

    signal clicked()

    implicitWidth: 32
    implicitHeight: 32

    radius: round ? Math.min(width, height) / 2 : 6

    color: {
        if (checked) return checkedColor;
        if (mouseArea.pressed) return pressedColor;
        if (mouseArea.containsMouse) return hoverColor;
        if (type === IconButton.ButtonType.Text) return "transparent";
        return baseColor;
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    border.width: checked ? 1 : 0
    border.color: Theme.primary

    Icon {
        id: iconItem
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (root.isToggle) {
                root.checked = !root.checked;
            }
            root.clicked();
        }
    }
}
