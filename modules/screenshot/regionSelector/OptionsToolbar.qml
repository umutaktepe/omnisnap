import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../components"
import ".."

Rectangle {
    id: root

    property var action: ScreenshotAction.SnipAction.Copy
    signal dismiss()
    signal fullScreenRequested()
    signal openSettingsRequested()

    color: Theme.surface
    radius: height / 2
    border.width: 1
    border.color: Theme.outline
    implicitHeight: 48
    implicitWidth: layout.implicitWidth + 24

    onActionChanged: {
        switch (root.action) {
            case ScreenshotAction.SnipAction.Copy:
                if (tabBar.currentIndex !== 0) tabBar.currentIndex = 0;
                break;
            case ScreenshotAction.SnipAction.Edit:
                if (tabBar.currentIndex !== 1) tabBar.currentIndex = 1;
                break;
            case ScreenshotAction.SnipAction.Search:
                if (tabBar.currentIndex !== 2) tabBar.currentIndex = 2;
                break;
            case ScreenshotAction.SnipAction.CharRecognition:
                if (tabBar.currentIndex !== 3) tabBar.currentIndex = 3;
                break;
            default:
                if (tabBar.currentIndex !== 0) tabBar.currentIndex = 0;
                break;
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        ToolbarTabBar {
            id: tabBar
            tabs: [
                { "icon": "content_cut", "name": "Screenshot" },
                { "icon": "edit", "name": "Annotate" },
                { "icon": "search", "name": "Google Lens" },
                { "icon": "ocr", "name": "OCR Text" }
            ]
            currentIndex: {
                switch (root.action) {
                    case ScreenshotAction.SnipAction.Copy: return 0;
                    case ScreenshotAction.SnipAction.Edit: return 1;
                    case ScreenshotAction.SnipAction.Search: return 2;
                    case ScreenshotAction.SnipAction.CharRecognition: return 3;
                    default: return 0;
                }
            }
            onTabClicked: index => {
                if (index === 0) root.action = ScreenshotAction.SnipAction.Copy;
                else if (index === 1) root.action = ScreenshotAction.SnipAction.Edit;
                else if (index === 2) root.action = ScreenshotAction.SnipAction.Search;
                else if (index === 3) root.action = ScreenshotAction.SnipAction.CharRecognition;
            }
        }

        Rectangle {
            width: 1
            height: 24
            color: Theme.outline
        }

        IconButton {
            id: fsBtn
            icon: "fullscreen"
            round: true
            onClicked: root.fullScreenRequested()
            Tooltip { target: fsBtn; text: "Capture Full Screen" }
        }

        IconButton {
            id: settingsBtn
            icon: "settings"
            round: true
            onClicked: root.openSettingsRequested()
            Tooltip { target: settingsBtn; text: "Ayarlar" }
        }

        IconButton {
            id: closeBtn
            icon: "close"
            round: true
            onClicked: root.dismiss()
            Tooltip { target: closeBtn; text: "Cancel (Esc)" }
        }
    }
}
