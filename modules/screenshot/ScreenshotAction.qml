pragma Singleton
import QtQuick

QtObject {
    id: root

    enum SnipAction {
        Copy,
        Edit,
        Search,
        CharRecognition
    }

    readonly property string fileUploadApiEndpoint: "https://uguu.se/upload"
    readonly property string lensBaseUrl: "https://lens.google.com/uploadbyurl?url="

    function escapeShellStr(str) {
        if (!str) return "''";
        return str.replace(/'/g, "'\\''");
    }

    function getScript(x, y, width, height, screenshotPath, action, saveDir = "") {
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);

        const cropBase = `magick '${escapeShellStr(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage`;
        const cleanup = `rm -f '${escapeShellStr(screenshotPath)}'`;

        const targetDir = saveDir === "" ? "~/Pictures/Screenshots" : saveDir;

        switch (action) {
            case ScreenshotAction.SnipAction.Copy: {
                return `set -euo pipefail; ` +
                    `SAVE_DIR='${escapeShellStr(targetDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && ` +
                    `${cropBase} "$saveFile" && ` +
                    `wl-copy -t image/png < "$saveFile"; ` +
                    `ACTION=$(notify-send "Screenshot Captured" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" --action="open=Open" --action="folder=Open Folder" 2>/dev/null || true); ` +
                    `if [ "$ACTION" = "open" ]; then xdg-open "$saveFile"; elif [ "$ACTION" = "folder" ]; then xdg-open "$SAVE_DIR"; fi; ` +
                    `${cleanup}`;
            }

            case ScreenshotAction.SnipAction.Edit: {
                return `set -euo pipefail; ` +
                    `SAVE_DIR='${escapeShellStr(targetDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && ` +
                    `TMPF=$(mktemp /tmp/omnisnap-edit-XXXXXX.png); ` +
                    `${cropBase} "$TMPF" && ` +
                    `swappy -f "$TMPF" -o "$saveFile" || true; ` +
                    `if [ -s "$saveFile" ]; then ` +
                    `    wl-copy -t image/png < "$saveFile"; ` +
                    `    notify-send "Screenshot Edited" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" 2>/dev/null || true; ` +
                    `fi; ` +
                    `rm -f "$TMPF"; ${cleanup}`;
            }

            case ScreenshotAction.SnipAction.Search: {
                return `set -euo pipefail; ` +
                    `TMPF=$(mktemp /tmp/omnisnap-search-XXXXXX.png); ` +
                    `${cropBase} "$TMPF" && ` +
                    `UPLOAD_URL=$(curl -sF files[]=@"$TMPF" '${root.fileUploadApiEndpoint}' | jq -r '.files[0].url' 2>/dev/null || true); ` +
                    `if [ -n "$UPLOAD_URL" ] && [ "$UPLOAD_URL" != "null" ]; then ` +
                    `    xdg-open "${root.lensBaseUrl}$UPLOAD_URL"; ` +
                    `else ` +
                    `    notify-send -u critical "Search Failed" "Could not upload screenshot for image search." -a "Omnisnap" 2>/dev/null || true; ` +
                    `fi; ` +
                    `rm -f "$TMPF"; ${cleanup}`;
            }

            case ScreenshotAction.SnipAction.CharRecognition: {
                return `set -euo pipefail; ` +
                    `TMPF=$(mktemp /tmp/omnisnap-ocr-XXXXXX.png); ` +
                    `${cropBase} -colorspace gray -type grayscale -contrast-stretch 0 -resize 300% "$TMPF" && ` +
                    `LANGS=$(tesseract --list-langs 2>/dev/null | awk 'NR>1 && $1!="osd" {print $1}' | tr '\\n' '+' | sed 's/\\+$//'); ` +
                    `if [ -n "$LANGS" ]; then ` +
                    `    TEXT=$(tesseract "$TMPF" stdout -l "$LANGS" 2>/dev/null || true); ` +
                    `else ` +
                    `    TEXT=$(tesseract "$TMPF" stdout 2>/dev/null || true); ` +
                    `fi; ` +
                    `if [ -n "$TEXT" ]; then ` +
                    `    printf "%s" "$TEXT" | wl-copy; ` +
                    `    notify-send "Text Recognized" "$TEXT" -a "Omnisnap" 2>/dev/null || true; ` +
                    `else ` +
                    `    notify-send "OCR Finished" "No text detected in selected region." -a "Omnisnap" 2>/dev/null || true; ` +
                    `fi; ` +
                    `rm -f "$TMPF"; ${cleanup}`;
            }

            default:
                return cleanup;
        }
    }

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
        const script = root.getScript(x, y, width, height, screenshotPath, action, saveDir);
        return script ? ["bash", "-c", script] : [];
    }
}
