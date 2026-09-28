import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../components"

Item {
    id: root

    property int currentIndex: 0
    required property var tabs

    signal tabClicked(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: 38

    Row {
        id: row
        spacing: 4

        Repeater {
            model: root.tabs

            delegate: Rectangle {
                id: tabBtn
                required property int index
                required property var modelData

                readonly property bool isCurrent: tabBtn.index === root.currentIndex

                implicitHeight: 34
                implicitWidth: contentRow.implicitWidth + 20
                radius: height / 2

                color: isCurrent ? Theme.primary : "transparent"
                border.width: isCurrent ? 0 : 1
                border.color: isCurrent ? "transparent" : Theme.outline

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = tabBtn.index;
                        root.tabClicked(tabBtn.index);
                    }
                }

                RowLayout {
                    id: contentRow
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        name: tabBtn.modelData.icon
                        size: 15
                        color: tabBtn.isCurrent ? Theme.onPrimary : Theme.text
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        text: tabBtn.modelData.name
                        color: tabBtn.isCurrent ? Theme.onPrimary : Theme.text
                        font.bold: tabBtn.isCurrent
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
