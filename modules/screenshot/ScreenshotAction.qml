pragma Singleton
import QtQuick
import "../config"

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

    function getScript(x, y, width, height, screenshotPath, action, saveDir = "", maxResOverride = null) {
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);

        const activeMaxRes = (maxResOverride !== null && maxResOverride !== undefined) ? maxResOverride : Config.maxResolution;
        const resizeArg = (activeMaxRes && activeMaxRes.trim() !== "") ? ` -resize '${escapeShellStr(activeMaxRes.trim())}'` : "";
        const cropBase = `magick '${escapeShellStr(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage${resizeArg}`;
        const cleanup = `rm -f '${escapeShellStr(screenshotPath)}'`;

        const targetDir = (saveDir !== "") ? saveDir : Config.saveDirectory;
        const effectiveAction = (action !== undefined && action !== null) ? action : ScreenshotAction.SnipAction.Copy;
        const ext = Config.fileFormat ? Config.fileFormat.toLowerCase() : "png";

        switch (effectiveAction) {
            case ScreenshotAction.SnipAction.Copy: {
                const saveCmd = Config.saveToFile ?
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).${ext}" && ` +
                    `${cropBase} "$saveFile"` :
                    `saveFile="$(mktemp /tmp/omnisnap-clip-XXXXXX.${ext})" && ` +
                    `${cropBase} "$saveFile"`;

                const clipboardCmd = Config.copyToClipboard ?
                    `wl-copy -t image/${ext === "jpg" ? "jpeg" : ext} < "$saveFile"; ` : "";

                const notifyCleanup = (!Config.saveToFile) ? `rm -f "$saveFile"; ` : "";

                return `set -euo pipefail; ` +
                    `SAVE_DIR='${escapeShellStr(targetDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `${saveCmd} && ` +
                    `${clipboardCmd}` +
                    `( ` +
                    `ACTION=$(notify-send "Screenshot Captured" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" --action="open=Open" --action="folder=Open Folder" 2>/dev/null || true); ` +
                    `if [ "$ACTION" = "open" ]; then xdg-open "$saveFile"; elif [ "$ACTION" = "folder" ]; then xdg-open "$SAVE_DIR"; fi; ` +
                    `${notifyCleanup}` +
                    `) & ` +
                    `${cleanup}`;
            }

            case ScreenshotAction.SnipAction.Edit: {
                const clipboardCmd = Config.copyToClipboard ?
                    `wl-copy -t image/${ext === "jpg" ? "jpeg" : ext} < "$saveFile"; ` : "";

                return `set -euo pipefail; ` +
                    `SAVE_DIR='${escapeShellStr(targetDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).${ext}" && ` +
                    `TMPF=$(mktemp /tmp/omnisnap-edit-XXXXXX.${ext}); ` +
                    `${cropBase} "$TMPF" && ` +
                    `swappy -f "$TMPF" -o "$saveFile" || true; ` +
                    `if [ -s "$saveFile" ]; then ` +
                    `    ${clipboardCmd}` +
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
                const langArg = (Config.ocrLanguages && Config.ocrLanguages.trim() !== "") ? `-l '${escapeShellStr(Config.ocrLanguages.trim())}'` : "";
                return `set -euo pipefail; ` +
                    `TMPF=$(mktemp /tmp/omnisnap-ocr-XXXXXX.png); ` +
                    `${cropBase} -colorspace gray -type grayscale -contrast-stretch 0 -resize 300% "$TMPF" && ` +
                    `if [ -n "${langArg}" ]; then ` +
                    `    TEXT=$(tesseract "$TMPF" stdout ${langArg} 2>/dev/null || true); ` +
                    `else ` +
                    `    LANGS=$(tesseract --list-langs 2>/dev/null | awk 'NR>1 && $1!="osd" {print $1}' | tr '\\n' '+' | sed 's/\\+$//'); ` +
                    `    if [ -n "$LANGS" ]; then TEXT=$(tesseract "$TMPF" stdout -l "$LANGS" 2>/dev/null || true); else TEXT=$(tesseract "$TMPF" stdout 2>/dev/null || true); fi; ` +
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

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "", maxResOverride = null) {
        const script = root.getScript(x, y, width, height, screenshotPath, action, saveDir, maxResOverride);
        return script ? ["bash", "-c", script] : [];
    }
}
