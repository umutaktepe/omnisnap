import QtQuick
import Quickshell
import Quickshell.Io
import "modules/screenshot/regionSelector"

ShellRoot {
    id: root

    RegionSelector {
        id: selector
    }

    IpcHandler {
        target: "region"

        function screenshot() {
            selector.screenshot();
        }

        function edit() {
            selector.edit();
        }

        function search() {
            selector.search();
        }

        function ocr() {
            selector.ocr();
        }

        function fullscreen() {
            Quickshell.execDetached([
                "bash", "-c",
                "saveFile=\"$HOME/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png\"; " +
                "mkdir -p \"$(dirname \"$saveFile\")\" && " +
                "spectacle -b -n -f -o \"$saveFile\" && " +
                "wl-copy -t image/png < \"$saveFile\" && " +
                "notify-send \"Screenshot Captured\" \"Saved to $saveFile\" -i \"$saveFile\" -a \"Omnisnap\" 2>/dev/null || true"
            ]);
            if (Quickshell.env("OMNISNAP_DAEMON") !== "1" && Quickshell.env("OMNISNAP_INITIAL_ACTION") !== "") {
                Qt.quit();
            }
        }
    }

    Component.onCompleted: {
        const initAction = Quickshell.env("OMNISNAP_INITIAL_ACTION");
        if (initAction === "screenshot") {
            selector.screenshot();
        } else if (initAction === "edit") {
            selector.edit();
        } else if (initAction === "search") {
            selector.search();
        } else if (initAction === "ocr") {
            selector.ocr();
        } else if (initAction === "fullscreen") {
            Quickshell.execDetached([
                "bash", "-c",
                "saveFile=\"$HOME/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png\"; " +
                "mkdir -p \"$(dirname \"$saveFile\")\" && " +
                "spectacle -b -n -f -o \"$saveFile\" && " +
                "wl-copy -t image/png < \"$saveFile\" && " +
                "notify-send \"Screenshot Captured\" \"Saved to $saveFile\" -i \"$saveFile\" -a \"Omnisnap\" 2>/dev/null || true"
            ]);
            Qt.quit();
        }
    }
}
