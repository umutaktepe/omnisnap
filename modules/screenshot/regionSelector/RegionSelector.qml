import QtQuick
import Quickshell
import ".."
import "."

Scope {
    id: root

    property bool active: false
    property var action: ScreenshotAction.SnipAction.Copy

    function dismiss() {
        root.active = false;
        // If not running in daemon mode, quit quickshell
        if (Quickshell.env("OMNISNAP_DAEMON") !== "1" && Quickshell.env("OMNISNAP_INITIAL_ACTION") !== "") {
            Qt.quit();
        }
    }

    function screenshot() {
        root.action = ScreenshotAction.SnipAction.Copy;
        root.active = true;
    }

    function edit() {
        root.action = ScreenshotAction.SnipAction.Edit;
        root.active = true;
    }

    function search() {
        root.action = ScreenshotAction.SnipAction.Search;
        root.active = true;
    }

    function ocr() {
        root.action = ScreenshotAction.SnipAction.CharRecognition;
        root.active = true;
    }

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: loader
            required property ShellScreen modelData

            active: root.active
            sourceComponent: RegionSelection {
                screen: loader.modelData
                action: root.action
                onDismiss: root.dismiss()
            }
        }
    }
}
