import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../theme"
import ".."
import "."

PanelWindow {
    id: root

    required property ShellScreen screen
    property var action: ScreenshotAction.SnipAction.Copy
    signal dismiss()

    visible: false
    color: "transparent"

    // Wayland LayerShell Configuration
    WlrLayershell.namespace: "omnisnap"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Geometry & state calculation
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property bool dragging: false
    property var mouseButton: null
    property bool snipExecuted: false

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    readonly property real monitorScale: (frozenImage.sourceSize.width > 0 && root.screen.width > 0)
        ? (frozenImage.sourceSize.width / root.screen.width)
        : (root.screen.devicePixelRatio || 1.0)

    TempScreenshotProcess {
        id: proc
        screen: root.screen
        onExited: {
            frozenImage.source = "file://" + proc.screenshotPath;
            root.visible = true;
            mouseArea.forceActiveFocus();
        }
    }

    onDismiss: {
        if (!root.snipExecuted && proc.screenshotPath) {
            Quickshell.execDetached(["rm", "-f", proc.screenshotPath]);
        }
    }

    function snip() {
        root.snipExecuted = true;
        let rx = root.regionX;
        let ry = root.regionY;
        let rw = root.regionWidth;
        let rh = root.regionHeight;

        // Very small selection = fallback to full screen
        if (rw < 4 || rh < 4) {
            rx = 0;
            ry = 0;
            rw = root.screen.width;
            rh = root.screen.height;
        }

        let finalAction = root.action;
        if (root.mouseButton === Qt.RightButton && finalAction === ScreenshotAction.SnipAction.Copy) {
            finalAction = ScreenshotAction.SnipAction.Edit;
        }

        const cmd = ScreenshotAction.getCommand(
            rx * root.monitorScale,
            ry * root.monitorScale,
            rw * root.monitorScale,
            rh * root.monitorScale,
            proc.screenshotPath,
            finalAction
        );

        if (cmd && cmd.length > 0) {
            Quickshell.execDetached(cmd);
        }
        root.dismiss();
    }

    // Escape listener
    Shortcut {
        sequence: "Escape"
        onActivated: root.dismiss()
    }

    // Background frozen frame
    Image {
        id: frozenImage
        anchors.fill: parent
        cache: false
    }

    // Interactive mouse area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        focus: root.visible

        Keys.onEscapePressed: event => {
            event.accepted = true;
            root.dismiss();
        }

        onPressed: mouse => {
            root.mouseButton = mouse.button;
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
        }

        onPositionChanged: mouse => {
            if (root.dragging) {
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
            }
        }

        onReleased: mouse => {
            root.dragging = false;
            root.snip();
        }

        // Selection details (darkening borders + aim lines + dimension badge)
        RectCornersSelectionDetails {
            anchors.fill: parent
            regionX: root.regionX
            regionY: root.regionY
            regionWidth: root.regionWidth
            regionHeight: root.regionHeight
            mouseX: mouseArea.mouseX
            mouseY: mouseArea.mouseY
        }

        // Dynamic cursor guide pill
        CursorGuide {
            x: mouseArea.mouseX
            y: mouseArea.mouseY
            action: (root.mouseButton === Qt.RightButton && root.action === ScreenshotAction.SnipAction.Copy)
                ? ScreenshotAction.SnipAction.Edit
                : root.action
            active: !root.dragging
        }

        // Bottom toolbar
        OptionsToolbar {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 16
            }
            action: root.action
            onActionChanged: newAction => root.action = newAction
            onDismiss: root.dismiss()
            onFullScreenRequested: {
                root.regionX = 0;
                root.regionY = 0;
                root.regionWidth = root.screen.width;
                root.regionHeight = root.screen.height;
                root.snip();
            }
        }
    }
}
