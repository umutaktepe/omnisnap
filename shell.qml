import QtQuick
import Quickshell
import Quickshell.Io
import "modules/screenshot/regionSelector"
import "modules/settings"
import "modules/config"

ShellRoot {
    id: root

    RegionSelector {
        id: selector
        onOpenSettingsRequested: {
            if (Quickshell.env("OMNISNAP_DAEMON") !== "1") {
                settingsWindow.isStandalone = true;
            }
            settingsWindow.show();
        }
    }

    SettingsWindow {
        id: settingsWindow
    }

    function captureDirect(isWindow) {
        const modeFlag = isWindow ? "-a" : "-f";
        const title = isWindow ? "Window Captured" : "Screenshot Captured";
        const targetDir = Config.saveDirectory || "~/Pictures/Screenshots";
        const ext = Config.fileFormat ? Config.fileFormat.toLowerCase() : "png";
        const maxRes = Config.maxResolution ? Config.maxResolution.trim() : "";
        const resizeArg = (maxRes !== "") ? ` -resize '${maxRes.replace(/'/g, "'\\''")}'` : "";

        const saveCmd = Config.saveToFile ?
            `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).${ext}" && ` +
            `magick "$TMPF"${resizeArg} "$saveFile"` :
            `saveFile="$(mktemp /tmp/omnisnap-clip-XXXXXX.${ext})" && ` +
            `magick "$TMPF"${resizeArg} "$saveFile"`;

        const clipboardCmd = Config.copyToClipboard ?
            `wl-copy -t image/png < "$saveFile"; ` : "";

        const soundCmd = Config.shutterSound ?
            `( canberra-gtk-play -i screen-capture 2>/dev/null || true ) & ` : "";

        const notifyCleanup = (!Config.saveToFile) ? `rm -f "$saveFile"; ` : "";

        const script = `set -euo pipefail; ` +
            `SAVE_DIR='${targetDir.replace(/'/g, "'\\''")}'; ` +
            `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
            `mkdir -p "$SAVE_DIR" && ` +
            `TMPF=$(mktemp /tmp/omnisnap-raw-XXXXXX.png); ` +
            (isWindow ? `spectacle -b -n -a -o "$TMPF" && ` : `spectacle -b -n -f -o "$TMPF" && `) +
            `${saveCmd} && ` +
            `${soundCmd}` +
            `${clipboardCmd}` +
            `( ` +
            `ACTION=$(notify-send "${title}" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" --action="open=Open" --action="folder=Open Folder" 2>/dev/null || true); ` +
            `if [ "$ACTION" = "open" ]; then xdg-open "$saveFile"; elif [ "$ACTION" = "folder" ]; then xdg-open "$SAVE_DIR"; fi; ` +
            `${notifyCleanup}` +
            `) & ` +
            `rm -f "$TMPF"`;

        Quickshell.execDetached(["bash", "-c", script]);
        if (Quickshell.env("OMNISNAP_DAEMON") !== "1" && Quickshell.env("OMNISNAP_INITIAL_ACTION") !== "") {
            Qt.quit();
        }
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

        function settings() {
            settingsWindow.show();
        }

        function window() {
            root.captureDirect(true);
        }

        function fullscreen() {
            root.captureDirect(false);
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
        } else if (initAction === "settings") {
            settingsWindow.isStandalone = true;
            settingsWindow.show();
        } else if (initAction === "window") {
            root.captureDirect(true);
        } else if (initAction === "fullscreen") {
            root.captureDirect(false);
        }
    }
}
