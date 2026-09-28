import QtQuick
import "../../../theme"
import "../../../components"

Item {
    id: root

    required property real regionX
    required property real regionY
    required property real regionWidth
    required property real regionHeight
    required property real mouseX
    required property real mouseY

    property color color: Theme.selectionBorder
    property color overlayColor: Theme.overlayDarken
    property bool showAimLines: true

    // Darken overlay: huge border that covers the whole screen except the selection
    Rectangle {
        id: darkenOverlay
        z: 1
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: root.regionX - darkenOverlay.border.width
            topMargin: root.regionY - darkenOverlay.border.width
        }
        width: root.regionWidth + darkenOverlay.border.width * 2
        height: root.regionHeight + darkenOverlay.border.width * 2
        color: "transparent"
        border.color: root.overlayColor
        border.width: Math.max(root.width, root.height)
    }

    // Selection border
    Rectangle {
        id: selectionBorder
        z: 9
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Math.round(root.regionX) - borderWidth
            topMargin: Math.round(root.regionY) - borderWidth
        }
        width: Math.round(root.regionWidth) + borderWidth * 2
        height: Math.round(root.regionHeight) + borderWidth * 2
        border.color: root.color
        color: Theme.selectionFill
        property int borderWidth: 1
    }

    // Dimension label
    Rectangle {
        z: 10
        visible: root.regionWidth > 10 && root.regionHeight > 10
        anchors {
            top: selectionBorder.bottom
            right: selectionBorder.right
            topMargin: 6
        }
        color: Theme.surfaceHigh
        radius: 4
        border.width: 1
        border.color: Theme.outline
        implicitWidth: dimText.implicitWidth + 12
        implicitHeight: dimText.implicitHeight + 6

        StyledText {
            id: dimText
            anchors.centerIn: parent
            text: `${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}`
            font.pixelSize: 11
            color: Theme.primary
            font.bold: true
        }
    }

    // Aim lines (crosshairs)
    Rectangle {
        visible: root.showAimLines
        opacity: 0.3
        z: 2
        x: root.mouseX
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: root.color
    }

    Rectangle {
        visible: root.showAimLines
        opacity: 0.3
        z: 2
        y: root.mouseY
        anchors {
            left: parent.left
            right: parent.right
        }
        height: 1
        color: root.color
    }
}
