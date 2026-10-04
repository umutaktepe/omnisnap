import QtQuick
import Quickshell
import ".."
import "."

Scope {
    id: root

    property bool active: false
    property var action: ScreenshotAction.SnipAction.Copy
    signal openSettingsRequested()
    signal activeWindowRequested()

    function edgesBin() {
        const base = Quickshell.shellDir || ".";
        if (base.indexOf("regionSelector") !== -1) {
            return base + "/../../../bin/omnisnap-edges";
        }
        return base + "/bin/omnisnap-edges";
    }

    function dismiss() {
        Quickshell.execDetached([edgesBin(), "restore"]);
        root.active = false;
        // If not running in daemon mode, quit quickshell
        if (Quickshell.env("OMNISNAP_DAEMON") !== "1" && Quickshell.env("OMNISNAP_INITIAL_ACTION") !== "") {
            Quickshell.execDetached(["kill", "-TERM", `${Quickshell.processId}`]);
        }
    }

    function openSettings() {
        Quickshell.execDetached([edgesBin(), "restore"]);
        root.openSettingsRequested();
        root.active = false;
    }

    function captureActiveWindow() {
        Quickshell.execDetached([edgesBin(), "restore"]);
        root.active = false;
        root.activeWindowRequested();
    }

    function screenshot() {
        Quickshell.execDetached([edgesBin(), "inhibit"]);
        root.action = ScreenshotAction.SnipAction.Copy;
        root.active = true;
    }

    function edit() {
        Quickshell.execDetached([edgesBin(), "inhibit"]);
        root.action = ScreenshotAction.SnipAction.Edit;
        root.active = true;
    }

    function search() {
        Quickshell.execDetached([edgesBin(), "inhibit"]);
        root.action = ScreenshotAction.SnipAction.Search;
        root.active = true;
    }

    function ocr() {
        Quickshell.execDetached([edgesBin(), "inhibit"]);
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
                onActiveWindowRequested: root.captureActiveWindow()
                onOpenSettingsRequested: root.openSettings()
            }
        }
    }
}
