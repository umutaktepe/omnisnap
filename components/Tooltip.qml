import QtQuick
import "../theme"

Item {
    id: root

    property Item target: parent
    property string text: ""
    property int delay: 300
    property int spacing: 6
    property bool tooltipVisible: false

    readonly property bool isTargetHovered: Boolean(
        target && (
            target.hovered !== undefined ? target.hovered :
            (target.containsMouse !== undefined ? target.containsMouse : false)
        )
    )

    anchors.bottom: target ? (target === parent ? parent.top : target.top) : undefined
    anchors.bottomMargin: spacing
    anchors.horizontalCenter: target ? (target === parent ? parent.horizontalCenter : target.horizontalCenter) : undefined

    implicitWidth: backgroundRect.implicitWidth
    implicitHeight: backgroundRect.implicitHeight
    width: implicitWidth
    height: implicitHeight

    z: 9999
    visible: opacity > 0
    opacity: tooltipVisible ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Timer {
        id: delayTimer
        interval: root.delay
        repeat: false
        onTriggered: {
            if (root.isTargetHovered) {
                root.tooltipVisible = true;
            }
        }
    }

    onIsTargetHoveredChanged: {
        if (isTargetHovered) {
            if (delay > 0) {
                delayTimer.restart();
            } else {
                tooltipVisible = true;
            }
        } else {
            delayTimer.stop();
            tooltipVisible = false;
        }
    }

    Rectangle {
        id: backgroundRect

        implicitWidth: label.implicitWidth + 16
        implicitHeight: label.implicitHeight + 8

        color: Theme.surfaceHigh
        border.color: Theme.outlineVariant
        border.width: 1
        radius: 4

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.text
            font.pixelSize: 12
        }
    }
}
