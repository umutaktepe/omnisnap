import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../components"
import ".."

Rectangle {
    id: root

    property var action: ScreenshotAction.SnipAction.Copy
    property bool modeMenuOpen: false
    signal dismiss()
    signal fullScreenRequested()
    signal activeWindowRequested()
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
            onClicked: root.modeMenuOpen = !root.modeMenuOpen
            Tooltip { target: fsBtn; text: "Capture Full Screen / Active Window" }

            // Capture Mode Popover (Full Screen / Active Window)
            Rectangle {
                id: captureModeMenu
                visible: root.modeMenuOpen
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                anchors {
                    bottom: parent.top
                    bottomMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }

                width: 154
                height: modeLayout.implicitHeight + 12
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.outline
                z: 200

                ColumnLayout {
                    id: modeLayout
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: fsItemMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Icon {
                                name: "fullscreen"
                                size: 16
                                color: Theme.text
                            }

                            StyledText {
                                text: "Tüm Ekran"
                                font.pixelSize: 12
                                color: Theme.text
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: fsItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.modeMenuOpen = false;
                                root.fullScreenRequested();
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: winItemMouse.containsMouse ? Theme.surfaceHigh : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Icon {
                                name: "desktop_windows"
                                size: 16
                                color: Theme.text
                            }

                            StyledText {
                                text: "Aktif Pencere"
                                font.pixelSize: 12
                                color: Theme.text
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: winItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.modeMenuOpen = false;
                                root.activeWindowRequested();
                            }
                        }
                    }
                }
            }
        }

        IconButton {
            id: settingsBtn
            icon: "settings"
            round: true
            onClicked: {
                root.modeMenuOpen = false;
                root.openSettingsRequested();
            }
            Tooltip { target: settingsBtn; text: "Ayarlar" }
        }

        IconButton {
            id: closeBtn
            icon: "close"
            round: true
            onClicked: {
                root.modeMenuOpen = false;
                root.dismiss();
            }
            Tooltip { target: closeBtn; text: "Cancel (Esc)" }
        }
    }
}
