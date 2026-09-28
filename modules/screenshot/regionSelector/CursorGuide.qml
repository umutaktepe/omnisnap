import QtQuick
import "../../../theme"
import "../../../components"
import ".."

Item {
    id: root

    property var action
    property bool active: true

    visible: opacity > 0
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    property string description: {
        switch (root.action) {
            case ScreenshotAction.SnipAction.Copy:
                return "Copy region (LMB) or Annotate (RMB)";
            case ScreenshotAction.SnipAction.Edit:
                return "Annotate region with Swappy";
            case ScreenshotAction.SnipAction.Search:
                return "Search with Google Lens";
            case ScreenshotAction.SnipAction.CharRecognition:
                return "Extract text (OCR)";
            default:
                return "Select region";
        }
    }

    property string iconName: {
        switch (root.action) {
            case ScreenshotAction.SnipAction.Copy:
                return "content_cut";
            case ScreenshotAction.SnipAction.Edit:
                return "edit";
            case ScreenshotAction.SnipAction.Search:
                return "search";
            case ScreenshotAction.SnipAction.CharRecognition:
                return "ocr";
            default:
                return "content_cut";
        }
    }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12

        color: Theme.surfaceHigh
        radius: 18
        border.width: 1
        border.color: Theme.outline
        implicitHeight: 36
        implicitWidth: row.implicitWidth + 24

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconName
                color: Theme.primary
                size: 16
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.description
                font.pixelSize: 12
                color: Theme.text
            }
        }
    }
}
