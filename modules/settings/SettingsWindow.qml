import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../theme"
import "../../components"
import "../config"

FloatingWindow {
    id: root

    title: "Omnisnap Ayarları"
    visible: false

    implicitWidth: 640
    implicitHeight: 520
    minimumSize.width: 580
    minimumSize.height: 480
    color: Theme.background

    property bool isStandalone: false
    property int currentTab: 0
    property bool saveSuccess: false

    function show() {
        root.visible = true;
    }

    function hide() {
        root.close();
    }

    function close() {
        root.visible = false;
        if (root.isStandalone && !Quickshell.env("OMNISNAP_DAEMON")) {
            Qt.quit();
        }
    }

    Timer {
        id: feedbackTimer
        interval: 2500
        onTriggered: root.saveSuccess = false
    }

    Keys.onEscapePressed: root.close()

    Item {
        id: container
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ================= HEADER =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                color: Theme.surface
                border.width: 0

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.outline
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 12

                    Icon {
                        name: "screenshot"
                        size: 24
                        color: Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        StyledText {
                            text: "Omnisnap Ayarları"
                            font.bold: true
                            font.pixelSize: 14
                            color: Theme.text
                        }

                        StyledText {
                            text: "Ekran yakalama, çözünürlük ve çıktı tercihleri"
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }

                    IconButton {
                        icon: "close"
                        iconSize: 16
                        type: IconButton.ButtonType.Text
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.close()
                    }
                }
            }

            // ================= TAB NAVIGATION =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: Theme.background

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.outline
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Görüntü ve Çözünürlük", icon: "insert-image" },
                            { name: "Kayıt ve Pano", icon: "document-save" },
                            { name: "Arayüz ve Seçim", icon: "preferences-system" },
                            { name: "OCR ve Metin", icon: "draw-text" }
                        ]

                        delegate: Rectangle {
                            id: tabItem
                            required property int index
                            required property var modelData

                            readonly property bool isSelected: root.currentTab === tabItem.index

                            height: 32
                            width: tabRow.implicitWidth + 24
                            radius: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: isSelected ? Theme.primary : (tabMouseArea.containsMouse ? Theme.surfaceHigh : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                id: tabRow
                                anchors.centerIn: parent
                                spacing: 6

                                Icon {
                                    name: tabItem.modelData.icon
                                    size: 14
                                    color: tabItem.isSelected ? Theme.textOnPrimary : Theme.textMuted
                                }

                                StyledText {
                                    text: tabItem.modelData.name
                                    font.pixelSize: 12
                                    font.bold: tabItem.isSelected
                                    color: tabItem.isSelected ? Theme.textOnPrimary : Theme.text
                                }
                            }

                            MouseArea {
                                id: tabMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = tabItem.index
                            }
                        }
                    }
                }
            }

            // ================= MAIN CONTENT TABS =================
            StackLayout {
                id: tabsStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentTab

                // --------- TAB 0: Görüntü ve Çözünürlük ---------
                ScrollView {
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 16
                        anchors.margins: 16

                        // 1. Maksimum Çözünürlük
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: resCol.implicitHeight + 24
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            ColumnLayout {
                                id: resCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                ColumnLayout {
                                    spacing: 2
                                    StyledText {
                                        text: "Maksimum Çözünürlük Sınırı"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Görüntü belirtilen boyutları aşıyorsa orantılı olarak küçültülür."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                GridLayout {
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                    Layout.fillWidth: true

                                    Repeater {
                                        model: [
                                            { label: "Orijinal (Sınırsız)", value: "", desc: "Yeniden boyutlandırma yok" },
                                            { label: "1080p Full HD", value: "1920x1080>", desc: "Maksimum 1920x1080" },
                                            { label: "2K Quad HD", value: "2560x1440>", desc: "Maksimum 2560x1440" },
                                            { label: "720p HD", value: "1280x720>", desc: "Maksimum 1280x720" }
                                        ]

                                        delegate: Rectangle {
                                            id: resCard
                                            required property int index
                                            required property var modelData

                                            readonly property bool isCurrent: Config.maxResolution === resCard.modelData.value

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 46
                                            radius: 6
                                            color: isCurrent ? Theme.surfaceHigh : Theme.background
                                            border.width: isCurrent ? 2 : 1
                                            border.color: isCurrent ? Theme.primary : Theme.outline

                                            Behavior on color { ColorAnimation { duration: 100 } }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 8

                                                Rectangle {
                                                    width: 14
                                                    height: 14
                                                    radius: 7
                                                    color: "transparent"
                                                    border.width: 2
                                                    border.color: resCard.isCurrent ? Theme.primary : Theme.outlineVariant

                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        width: 6
                                                        height: 6
                                                        radius: 3
                                                        color: Theme.primary
                                                        visible: resCard.isCurrent
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 0

                                                    StyledText {
                                                        text: resCard.modelData.label
                                                        font.pixelSize: 12
                                                        font.bold: resCard.isCurrent
                                                        color: resCard.isCurrent ? Theme.primary : Theme.text
                                                    }

                                                    StyledText {
                                                        text: resCard.modelData.desc
                                                        font.pixelSize: 10
                                                        color: Theme.textMuted
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Config.maxResolution = resCard.modelData.value
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Çıktı Formatı
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: formatRow.implicitHeight + 24
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                id: formatRow
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: "Çıktı Formatı"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Kaydedilen görselin dosya biçimi."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                Row {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter

                                    Repeater {
                                        model: [
                                            { label: "PNG", value: "png" },
                                            { label: "JPG", value: "jpg" },
                                            { label: "WebP", value: "webp" }
                                        ]

                                        delegate: Rectangle {
                                            id: fmtBtn
                                            required property int index
                                            required property var modelData

                                            readonly property bool isSelected: Config.fileFormat === fmtBtn.modelData.value

                                            width: 60
                                            height: 32
                                            radius: 6
                                            color: isSelected ? Theme.primary : Theme.surfaceHigh
                                            border.width: 1
                                            border.color: isSelected ? Theme.primary : Theme.outline

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: fmtBtn.modelData.label
                                                font.pixelSize: 12
                                                font.bold: fmtBtn.isSelected
                                                color: fmtBtn.isSelected ? Theme.textOnPrimary : Theme.text
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Config.fileFormat = fmtBtn.modelData.value
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Görsel Kalitesi
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: qualityRow.implicitHeight + 24
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                id: qualityRow
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 16

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: "Görsel Kalitesi"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "JPEG ve WebP için sıkıştırma oranı (%1 - 100)."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                RowLayout {
                                    spacing: 10
                                    Layout.alignment: Qt.AlignVCenter

                                    Slider {
                                        id: qualitySlider
                                        from: 10
                                        to: 100
                                        stepSize: 5
                                        value: Config.imageQuality
                                        onMoved: Config.imageQuality = Math.round(value)

                                        background: Rectangle {
                                            x: qualitySlider.leftPadding
                                            y: qualitySlider.topPadding + qualitySlider.availableHeight / 2 - height / 2
                                            implicitWidth: 120
                                            implicitHeight: 6
                                            width: qualitySlider.availableWidth
                                            height: implicitHeight
                                            radius: 3
                                            color: Theme.surfaceHigh

                                            Rectangle {
                                                width: qualitySlider.visualPosition * parent.width
                                                height: parent.height
                                                color: Theme.primary
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: qualitySlider.leftPadding + qualitySlider.visualPosition * (qualitySlider.availableWidth - width)
                                            y: qualitySlider.topPadding + qualitySlider.availableHeight / 2 - height / 2
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            radius: 8
                                            color: qualitySlider.pressed ? Theme.secondary : Theme.primary
                                            border.color: Theme.outline
                                        }
                                    }

                                    Rectangle {
                                        width: 44
                                        height: 26
                                        radius: 4
                                        color: Theme.surfaceHigh
                                        border.width: 1
                                        border.color: Theme.outline

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: Config.imageQuality + "%"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Theme.primary
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --------- TAB 1: Kayıt ve Pano ---------
                ScrollView {
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 12
                        anchors.margins: 16

                        // Kayıt Dizini
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: dirCol.implicitHeight + 24
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            ColumnLayout {
                                id: dirCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                StyledText {
                                    text: "Kayıt Dizini"
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: Theme.text
                                }
                                StyledText {
                                    text: "Ekran görüntülerinin kaydedileceği dosya yolu."
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    TextField {
                                        id: saveDirField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        text: Config.saveDirectory
                                        color: Theme.text
                                        font.pixelSize: 12
                                        leftPadding: 10
                                        rightPadding: 10
                                        placeholderText: "~/Pictures/Screenshots"
                                        placeholderTextColor: Theme.textMuted

                                        background: Rectangle {
                                            color: Theme.background
                                            radius: 6
                                            border.width: 1
                                            border.color: saveDirField.activeFocus ? Theme.primary : Theme.outline
                                        }

                                        onTextEdited: Config.saveDirectory = text
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 64
                                        Layout.preferredHeight: 34
                                        radius: 6
                                        color: Theme.surfaceHigh
                                        border.width: 1
                                        border.color: Theme.outline

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: "Varsayılan"
                                            font.pixelSize: 11
                                            color: Theme.text
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Config.saveDirectory = "~/Pictures/Screenshots";
                                                saveDirField.text = "~/Pictures/Screenshots";
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Panoya Kopyala Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        text: "Panoya Kopyala"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Yakalama sonrası görseli doğrudan sistem panosuna aktarır."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                Rectangle {
                                    id: clipSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: Config.copyToClipboard ? Theme.primary : Theme.surfaceHigh
                                    border.width: 1
                                    border.color: Config.copyToClipboard ? Theme.primary : Theme.outline

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: Config.copyToClipboard ? parent.width - width - 3 : 3
                                        y: 3
                                        color: Config.copyToClipboard ? Theme.textOnPrimary : Theme.textMuted

                                        Behavior on x { NumberAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.copyToClipboard = !Config.copyToClipboard
                                    }
                                }
                            }
                        }

                        // Diske Kaydet Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        text: "Diske Kaydet"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Görseli otomatik olarak belirtilen kayıt dizinine kaydeder."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                Rectangle {
                                    id: saveSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: Config.saveToFile ? Theme.primary : Theme.surfaceHigh
                                    border.width: 1
                                    border.color: Config.saveToFile ? Theme.primary : Theme.outline

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: Config.saveToFile ? parent.width - width - 3 : 3
                                        y: 3
                                        color: Config.saveToFile ? Theme.textOnPrimary : Theme.textMuted

                                        Behavior on x { NumberAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.saveToFile = !Config.saveToFile
                                    }
                                }
                            }
                        }
                    }
                }

                // --------- TAB 2: Arayüz ve Seçim ---------
                ScrollView {
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 12
                        anchors.margins: 16

                        // Kılavuz Çizgileri Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        text: "Kılavuz Çizgileri ve İmleç Yardımı"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Seçim sırasında ekran eksen kılavuzlarını ve koordinat rozetini gösterir."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                Rectangle {
                                    id: guidesSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: Config.showGuides ? Theme.primary : Theme.surfaceHigh
                                    border.width: 1
                                    border.color: Config.showGuides ? Theme.primary : Theme.outline

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: Config.showGuides ? parent.width - width - 3 : 3
                                        y: 3
                                        color: Config.showGuides ? Theme.textOnPrimary : Theme.textMuted

                                        Behavior on x { NumberAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.showGuides = !Config.showGuides
                                    }
                                }
                            }
                        }

                        // KWin Kenar Engelleme Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        text: "KWin Ekran Kenarı Engelleme"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Seçim sırasında ekran köşelerindeki KWin Hot Corners tetikleyicilerini engeller."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                Rectangle {
                                    id: edgeSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: Config.inhibitScreenEdges ? Theme.primary : Theme.surfaceHigh
                                    border.width: 1
                                    border.color: Config.inhibitScreenEdges ? Theme.primary : Theme.outline

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: Config.inhibitScreenEdges ? parent.width - width - 3 : 3
                                        y: 3
                                        color: Config.inhibitScreenEdges ? Theme.textOnPrimary : Theme.textMuted

                                        Behavior on x { NumberAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.inhibitScreenEdges = !Config.inhibitScreenEdges
                                    }
                                }
                            }
                        }

                        // Deklanşör Sesi Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        text: "Deklanşör Sesi"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Görsel yakalandığında kamera deklanşör ses efektini çalar."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                Rectangle {
                                    id: soundSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: Config.shutterSound ? Theme.primary : Theme.surfaceHigh
                                    border.width: 1
                                    border.color: Config.shutterSound ? Theme.primary : Theme.outline

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: Config.shutterSound ? parent.width - width - 3 : 3
                                        y: 3
                                        color: Config.shutterSound ? Theme.textOnPrimary : Theme.textMuted

                                        Behavior on x { NumberAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.shutterSound = !Config.shutterSound
                                    }
                                }
                            }
                        }
                    }
                }

                // --------- TAB 3: OCR ve Metin ---------
                ScrollView {
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 12
                        anchors.margins: 16

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ocrCol.implicitHeight + 24
                            color: Theme.surface
                            radius: 8
                            border.width: 1
                            border.color: Theme.outline

                            ColumnLayout {
                                id: ocrCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                ColumnLayout {
                                    spacing: 2
                                    StyledText {
                                        text: "Tesseract OCR Dilleri"
                                        font.bold: true
                                        font.pixelSize: 13
                                        color: Theme.text
                                    }
                                    StyledText {
                                        text: "Metin tanıma motoru için dil kodları (boş bırakılırsa tüm kurulu diller kullanılır)."
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }

                                TextField {
                                    id: ocrField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    text: Config.ocrLanguages
                                    color: Theme.text
                                    font.pixelSize: 12
                                    leftPadding: 10
                                    rightPadding: 10
                                    placeholderText: "Örn: tur+eng (Boş = Otomatik / Tümü)"
                                    placeholderTextColor: Theme.textMuted

                                    background: Rectangle {
                                        color: Theme.background
                                        radius: 6
                                        border.width: 1
                                        border.color: ocrField.activeFocus ? Theme.primary : Theme.outline
                                    }

                                    onTextEdited: Config.ocrLanguages = text
                                }

                                Row {
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { label: "Otomatik (Tümü)", val: "" },
                                            { label: "Türkçe + İngilizce", val: "tur+eng" },
                                            { label: "Yalnızca Türkçe", val: "tur" },
                                            { label: "Yalnızca İngilizce", val: "eng" }
                                        ]

                                        delegate: Rectangle {
                                            id: presetChip
                                            required property int index
                                            required property var modelData

                                            readonly property bool isSelected: Config.ocrLanguages === presetChip.modelData.val

                                            height: 26
                                            width: chipText.implicitWidth + 16
                                            radius: 13
                                            color: isSelected ? Theme.primary : Theme.surfaceHigh
                                            border.width: 1
                                            border.color: isSelected ? Theme.primary : Theme.outline

                                            StyledText {
                                                id: chipText
                                                anchors.centerIn: parent
                                                text: presetChip.modelData.label
                                                font.pixelSize: 11
                                                font.bold: presetChip.isSelected
                                                color: presetChip.isSelected ? Theme.textOnPrimary : Theme.text
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Config.ocrLanguages = presetChip.modelData.val;
                                                    ocrField.text = presetChip.modelData.val;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= FOOTER =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                color: Theme.surface

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Theme.outline
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Feedback Banner
                    RowLayout {
                        spacing: 6
                        opacity: root.saveSuccess ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Icon {
                            name: "check"
                            size: 16
                            color: "#a6e3a1"
                        }

                        StyledText {
                            text: "Ayarlar başarıyla kaydedildi!"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#a6e3a1"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Kapat Button
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 34
                        radius: 6
                        color: closeMouseArea.containsMouse ? Theme.surfaceHigh : "transparent"
                        border.width: 1
                        border.color: Theme.outline

                        StyledText {
                            anchors.centerIn: parent
                            text: "Kapat"
                            font.pixelSize: 12
                            color: Theme.text
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }

                    // Kaydet Button
                    Rectangle {
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 34
                        radius: 6
                        color: saveMouseArea.pressed ? Theme.secondary : Theme.primary

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                name: "document-save"
                                size: 14
                                color: Theme.textOnPrimary
                            }

                            StyledText {
                                text: "Kaydet"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textOnPrimary
                            }
                        }

                        MouseArea {
                            id: saveMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.save();
                                root.saveSuccess = true;
                                feedbackTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
