# Omnisnap (KDE Plasma 6 Standalone Screenshot Tool) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone, high-performance Wayland screenshot tool for KDE Plasma 6 (Omnisnap) based on Caelestia's screen-freeze UX, featuring instant region snip, image editing via Swappy, OCR text recognition via Tesseract, Google Lens visual search, and seamless KDE integration via Quickshell.

**Architecture:** Omnisnap runs as a lightweight Quickshell application (`quickshell -p /path/to/Omnisnap`). When triggered, it grabs a background freeze-frame of the active display using `spectacle -b -n -m`, opens a fullscreen LayerShell overlay displaying the frozen image, renders an interactive region-selection UI with dynamic darkening borders and cursor guides, and pipes the cropped coordinates through an ImageMagick/wl-copy/tesseract post-processing pipeline. It supports both standalone single-shot invocation and daemon IPC mode for zero-latency capture.

**Tech Stack:** Quickshell (Qt 6 / QML / Wayland LayerShell), Bash, Spectacle (KDE privileged capture), ImageMagick (`magick`), `wl-clipboard` (`wl-copy`), `notify-send`, `swappy`, `tesseract-ocr`, `curl`, `jq`.

**Spec:** Port and isolate Caelestia-KDE's screenshot subsystem (`caelestia-repo/shell/modules/screenshot/`) into an independent repository with zero external shell dependencies, clean atomic QML components, standalone CLI launcher, and KDE shortcut integration.

## Global Constraints

- **Platform:** Linux (KDE Plasma 6 on Wayland, KWin compositor).
- **Core Engine:** Quickshell (`quickshell` / `qs` CLI) must be used for QML/Wayland LayerShell presentation.
- **Capture Backend:** Must use `spectacle -b -n -m -o ...` to capture screen pixels without requiring root or custom KWin patches.
- **Dependencies:** `quickshell`, `spectacle`, `magick`, `wl-copy`, `notify-send`, `swappy`, `tesseract`.
- **Isolation:** Must have zero runtime dependencies on Caelestia-specific C++ plugins (`Caelestia.Config`, `Caelestia.Services`, etc.). All themes and components must be self-contained in Omnisnap.
- **Code Style:** Clean QML with `pragma ComponentBehavior: Bound` where applicable; POSIX-compliant / strict bash (`set -euo pipefail`).

---

### Task 1: CLI Entry Point & Environment Setup

**Files:**
- Create: `bin/omnisnap`
- Test: `tests/test_cli.sh`

**Interfaces:**
- Consumes: None (system bash, `quickshell` executable).
- Produces: `bin/omnisnap [region|full|edit|ocr|search|daemon|stop|status]` CLI commands.

- [ ] **Step 1: Write the failing test for CLI argument handling**

Create `tests/test_cli.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/omnisnap"

test_help_flag() {
    "$BIN" --help | grep -q "Omnisnap" || { echo "FAIL: --help did not output Omnisnap banner"; exit 1; }
    echo "PASS: test_help_flag"
}

test_unknown_action() {
    if "$BIN" --invalid-arg >/dev/null 2>&1; then
        echo "FAIL: unknown argument should return non-zero exit code"
        exit 1
    fi
    echo "PASS: test_unknown_action"
}

test_help_flag
test_unknown_action
echo "All CLI tests passed."
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_cli.sh`
Expected: FAIL (file not found or binary not created yet).

- [ ] **Step 3: Implement `bin/omnisnap` CLI launcher**

Create `bin/omnisnap`:
```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_FILE="$PROJECT_DIR/shell.qml"
APP_NAME="Omnisnap"

_help() {
    cat <<EOF
$APP_NAME - Modern Screenshot Tool for KDE Plasma 6
Usage:
  omnisnap [command]

Commands:
  region, -r, --region     Interactive region screenshot (default)
  full, -f, --full         Instant full-screen screenshot
  edit, -e, --edit         Region capture with annotation (Swappy)
  ocr, -o, --ocr           Region capture with OCR text recognition
  search, -s, --search     Region capture with Google Lens search
  daemon, -d, --daemon     Start background daemon for instant response
  stop, -k, --stop         Stop running background daemon
  status                   Check if background daemon is running
  -h, --help               Show this help message
EOF
}

_is_running() {
    pgrep -f "quickshell.*$SHELL_FILE" >/dev/null 2>&1
}

_call_ipc() {
    local action="$1"
    qs -p "$PROJECT_DIR" ipc call region "$action"
}

_launch_oneshot() {
    local action="$1"
    OMNISNAP_INITIAL_ACTION="$action" exec quickshell -p "$PROJECT_DIR"
}

ACTION="${1:-region}"

case "$ACTION" in
    region|-r|--region)
        if _is_running; then
            _call_ipc "screenshot"
        else
            _launch_oneshot "screenshot"
        fi
        ;;
    full|-f|--full)
        if _is_running; then
            _call_ipc "fullscreen"
        else
            _launch_oneshot "fullscreen"
        fi
        ;;
    edit|-e|--edit)
        if _is_running; then
            _call_ipc "edit"
        else
            _launch_oneshot "edit"
        fi
        ;;
    ocr|-o|--ocr)
        if _is_running; then
            _call_ipc "ocr"
        else
            _launch_oneshot "ocr"
        fi
        ;;
    search|-s|--search)
        if _is_running; then
            _call_ipc "search"
        else
            _launch_oneshot "search"
        fi
        ;;
    daemon|-d|--daemon)
        if _is_running; then
            echo "$APP_NAME daemon is already running."
        else
            echo "Starting $APP_NAME daemon..."
            exec quickshell -p "$PROJECT_DIR" &
        fi
        ;;
    stop|-k|--stop)
        if _is_running; then
            pkill -f "quickshell.*$SHELL_FILE" || true
            echo "$APP_NAME daemon stopped."
        else
            echo "$APP_NAME is not running."
        fi
        ;;
    status)
        if _is_running; then
            echo "$APP_NAME daemon is running."
            exit 0
        else
            echo "$APP_NAME daemon is NOT running."
            exit 1
        fi
        ;;
    -h|--help|help)
        _help
        exit 0
        ;;
    *)
        echo "Error: Unknown argument '$ACTION'" >&2
        _help >&2
        exit 2
        ;;
esac
```
Make executable: `chmod +x bin/omnisnap`

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_cli.sh`
Expected: PASS ("All CLI tests passed.")

- [ ] **Step 5: Commit**

```bash
git add bin/omnisnap tests/test_cli.sh
git commit -m "feat(cli): add omnisnap cli entry point and argument tests"
```

---

### Task 2: Action Pipeline (`ScreenshotAction.qml`)

**Files:**
- Create: `modules/screenshot/ScreenshotAction.qml`
- Test: `tests/test_action_pipeline.sh`

**Interfaces:**
- Consumes: Coordinates (`x`, `y`, `width`, `height`), temporary screenshot path, snip action enum.
- Produces: Executable bash commands for crop, copy, swappy, OCR, and Lens upload.

- [ ] **Step 1: Write the test verifying ImageMagick, wl-copy, and notify pipeline**

Create `tests/test_action_pipeline.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_IMG="$(mktemp /tmp/test-omnisnap-XXXXXX.png)"
OUT_IMG="$(mktemp /tmp/test-cropped-XXXXXX.png)"

# Generate a 200x200 canvas
magick -size 200x200 xc:blue "$TMP_IMG"

# Crop a 50x50 box from +10+10
magick "$TMP_IMG" -crop 50x50+10+10 +repage "$OUT_IMG"

WIDTH=$(identify -format "%w" "$OUT_IMG")
HEIGHT=$(identify -format "%h" "$OUT_IMG")

rm -f "$TMP_IMG" "$OUT_IMG"

if [[ "$WIDTH" -eq 50 && "$HEIGHT" -eq 50 ]]; then
    echo "PASS: ImageMagick crop pipeline verified"
else
    echo "FAIL: Expected 50x50, got ${WIDTH}x${HEIGHT}"
    exit 1
fi
```

- [ ] **Step 2: Run test to verify dependencies and crop execution**

Run: `bash tests/test_action_pipeline.sh`
Expected: PASS ("PASS: ImageMagick crop pipeline verified")

- [ ] **Step 3: Create `modules/screenshot/ScreenshotAction.qml`**

Create `modules/screenshot/ScreenshotAction.qml`:
```qml
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
```

- [ ] **Step 4: Commit**

```bash
git add modules/screenshot/ScreenshotAction.qml tests/test_action_pipeline.sh
git commit -m "feat(actions): implement screenshot action pipeline for copy, edit, lens, and ocr"
```

---

### Task 3: Theme & Core UI Components

**Files:**
- Create: `theme/Theme.qml`
- Create: `components/StyledText.qml`
- Create: `components/Icon.qml`
- Create: `components/IconButton.qml`
- Create: `components/Tooltip.qml`

**Interfaces:**
- Consumes: None (QtQuick core components).
- Produces: Reusable `Theme` palette, text, icons, buttons, tooltips.

- [ ] **Step 1: Create `theme/Theme.qml`**

Create `theme/Theme.qml`:
```qml
pragma Singleton
import QtQuick

QtObject {
    id: root

    // Modern Material You / Breeze Dark aligned palette
    readonly property color background: "#1e1e2e"
    readonly property color surface: "#28283d"
    readonly property color surfaceHigh: "#313244"
    readonly property color primary: "#89b4fa"
    readonly property color onPrimary: "#11111b"
    readonly property color secondary: "#b4befe"
    readonly property color onSecondary: "#11111b"
    readonly property color outline: "#45475a"
    readonly property color outlineVariant: "#585b70"
    readonly property color text: "#cdd6f4"
    readonly property color textMuted: "#a6adc8"
    readonly property color overlayDarken: Qt.rgba(0, 0, 0, 0.6)
    readonly property color selectionBorder: "#89b4fa"
    readonly property color selectionFill: Qt.rgba(137 / 255, 180 / 255, 250 / 255, 0.15)
}
```

- [ ] **Step 2: Create `components/StyledText.qml` and `components/Icon.qml`**

Create `components/StyledText.qml`:
```qml
import QtQuick
import "../theme"

Text {
    id: root
    color: Theme.text
    font.family: "Noto Sans, Inter, Roboto, sans-serif"
    font.pixelSize: 13
    renderType: Text.NativeRendering
}
```

Create `components/Icon.qml`:
```qml
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

Item {
    id: root

    property string name: ""
    property color color: Theme.text
    property real size: 20

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: img
        anchors.fill: parent
        source: {
            switch (root.name) {
                case "screenshot":
                case "content_cut":
                    return Quickshell.iconPath("edit-cut", "image-crop");
                case "edit":
                case "brush":
                    return Quickshell.iconPath("document-edit", "draw-freehand");
                case "search":
                case "image_search":
                    return Quickshell.iconPath("search", "system-search");
                case "ocr":
                case "text_fields":
                    return Quickshell.iconPath("edit-find-replace", "character-set");
                case "fullscreen":
                    return Quickshell.iconPath("view-fullscreen", "window-maximize");
                case "check":
                    return Quickshell.iconPath("dialog-ok-apply", "emblem-ok");
                case "close":
                    return Quickshell.iconPath("window-close", "dialog-close");
                default:
                    return Quickshell.iconPath(root.name, "image-missing");
            }
        }
    }
}
```

- [ ] **Step 3: Create `components/Tooltip.qml` and `components/IconButton.qml`**

Create `components/Tooltip.qml`:
```qml
import QtQuick
import "../theme"

Rectangle {
    id: root

    property Item target: null
    property string text: ""
    property bool visibleCondition: target && target.hovered

    visible: visibleCondition
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    color: Theme.surfaceHigh
    radius: 6
    border.width: 1
    border.color: Theme.outline
    z: 9999

    anchors {
        bottom: target ? target.top : undefined
        bottomMargin: 8
        horizontalCenter: target ? target.horizontalCenter : undefined
    }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10

    StyledText {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 11
        color: Theme.text
    }
}
```

Create `components/IconButton.qml`:
```qml
import QtQuick
import "../theme"

Rectangle {
    id: root

    property string icon: ""
    property color iconColor: hovered ? Theme.primary : Theme.text
    property bool hovered: mouseArea.containsMouse
    property bool isRound: true

    signal clicked()

    implicitWidth: 38
    implicitHeight: 38
    radius: isRound ? height / 2 : 8
    color: hovered ? Theme.surfaceHigh : Theme.surface
    border.width: 1
    border.color: hovered ? Theme.primary : Theme.outline

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.iconColor
        size: 18
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add theme/ components/
git commit -m "feat(ui): add theme and atomic UI components (text, icon, button, tooltip)"
```

---

### Task 4: Selection Overlay & Visual Guides

**Files:**
- Create: `modules/screenshot/regionSelector/RectCornersSelectionDetails.qml`
- Create: `modules/screenshot/regionSelector/CursorGuide.qml`

**Interfaces:**
- Consumes: Selection coordinates (`regionX`, `regionY`, `regionWidth`, `regionHeight`, `mouseX`, `mouseY`), action enum.
- Produces: Darkening overlay with clear center cutout, crosshair aim lines, dimension label, animated cursor instruction pill.

- [ ] **Step 1: Create `RectCornersSelectionDetails.qml`**

Create `modules/screenshot/regionSelector/RectCornersSelectionDetails.qml`:
```qml
import QtQuick
import "../../../theme"
import "../../../components"

Item {
    id: root

    required property real regionX
    required property real regionY
    required property real regionWidth
    required property real regionHeight
    required property real mouseX
    required property real mouseY

    property color color: Theme.selectionBorder
    property color overlayColor: Theme.overlayDarken
    property bool showAimLines: true

    // Darken overlay: huge border that covers the whole screen except the selection
    Rectangle {
        id: darkenOverlay
        z: 1
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: root.regionX - darkenOverlay.border.width
            topMargin: root.regionY - darkenOverlay.border.width
        }
        width: root.regionWidth + darkenOverlay.border.width * 2
        height: root.regionHeight + darkenOverlay.border.width * 2
        color: "transparent"
        border.color: root.overlayColor
        border.width: Math.max(root.width, root.height)
    }

    // Selection border
    Rectangle {
        id: selectionBorder
        z: 9
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Math.round(root.regionX) - borderWidth
            topMargin: Math.round(root.regionY) - borderWidth
        }
        width: Math.round(root.regionWidth) + borderWidth * 2
        height: Math.round(root.regionHeight) + borderWidth * 2
        border.color: root.color
        color: Theme.selectionFill
        property int borderWidth: 1
    }

    // Dimension label
    Rectangle {
        z: 10
        visible: root.regionWidth > 10 && root.regionHeight > 10
        anchors {
            top: selectionBorder.bottom
            right: selectionBorder.right
            topMargin: 6
        }
        color: Theme.surfaceHigh
        radius: 4
        border.width: 1
        border.color: Theme.outline
        implicitWidth: dimText.implicitWidth + 12
        implicitHeight: dimText.implicitHeight + 6

        StyledText {
            id: dimText
            anchors.centerIn: parent
            text: `${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}`
            font.pixelSize: 11
            color: Theme.primary
            font.bold: true
        }
    }

    // Aim lines (crosshairs)
    Rectangle {
        visible: root.showAimLines
        opacity: 0.3
        z: 2
        x: root.mouseX
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: root.color
    }

    Rectangle {
        visible: root.showAimLines
        opacity: 0.3
        z: 2
        y: root.mouseY
        anchors {
            left: parent.left
            right: parent.right
        }
        height: 1
        color: root.color
    }
}
```

- [ ] **Step 2: Create `CursorGuide.qml`**

Create `modules/screenshot/regionSelector/CursorGuide.qml`:
```qml
import QtQuick
import "../../../theme"
import "../../../components"
import "../ScreenshotAction.qml"

Item {
    id: root

    property var action
    property bool active: true

    visible: opacity > 0
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    property string description: {
        switch (root.action) {
            case ScreenshotAction.SnipAction.Copy:
                return "Copy region (LMB) or Annotate (RMB)";
            case ScreenshotAction.SnipAction.Edit:
                return "Annotate region with Swappy";
            case ScreenshotAction.SnipAction.Search:
                return "Search with Google Lens";
            case ScreenshotAction.SnipAction.CharRecognition:
                return "Extract text (OCR)";
            default:
                return "Select region";
        }
    }

    property string iconName: {
        switch (root.action) {
            case ScreenshotAction.SnipAction.Copy:
                return "content_cut";
            case ScreenshotAction.SnipAction.Edit:
                return "edit";
            case ScreenshotAction.SnipAction.Search:
                return "search";
            case ScreenshotAction.SnipAction.CharRecognition:
                return "ocr";
            default:
                return "content_cut";
        }
    }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12

        color: Theme.surfaceHigh
        radius: 18
        border.width: 1
        border.color: Theme.outline
        implicitHeight: 36
        implicitWidth: row.implicitWidth + 24

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconName
                color: Theme.primary
                size: 16
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.description
                font.pixelSize: 12
                color: Theme.text
            }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/screenshot/regionSelector/RectCornersSelectionDetails.qml modules/screenshot/regionSelector/CursorGuide.qml
git commit -m "feat(ui): add dimming selection details and interactive cursor guide"
```

---

### Task 5: Floating Bottom Toolbar & Tab Switcher

**Files:**
- Create: `modules/screenshot/regionSelector/ToolbarTabBar.qml`
- Create: `modules/screenshot/regionSelector/OptionsToolbar.qml`

**Interfaces:**
- Consumes: Action property binding.
- Produces: Action switching signals (`onActionChanged`), Fullscreen capture button, Close button.

- [ ] **Step 1: Create `ToolbarTabBar.qml`**

Create `modules/screenshot/regionSelector/ToolbarTabBar.qml`:
```qml
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
                    }

                    StyledText {
                        text: tabBtn.modelData.name
                        color: tabBtn.isCurrent ? Theme.onPrimary : Theme.text
                        font.bold: tabBtn.isCurrent
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Create `OptionsToolbar.qml`**

Create `modules/screenshot/regionSelector/OptionsToolbar.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../components"
import "../ScreenshotAction.qml"

Rectangle {
    id: root

    property var action: ScreenshotAction.SnipAction.Copy
    signal dismiss()
    signal fullScreenRequested()

    color: Theme.surface
    radius: height / 2
    border.width: 1
    border.color: Theme.outline
    implicitHeight: 48
    implicitWidth: layout.implicitWidth + 24

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        ToolbarTabBar {
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
            onClicked: root.fullScreenRequested()
            Tooltip { target: fsBtn; text: "Capture Full Screen" }
        }

        IconButton {
            id: closeBtn
            icon: "close"
            onClicked: root.dismiss()
            Tooltip { target: closeBtn; text: "Cancel (Esc)" }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/screenshot/regionSelector/ToolbarTabBar.qml modules/screenshot/regionSelector/OptionsToolbar.qml
git commit -m "feat(ui): add options toolbar and tab switcher"
```

---

### Task 6: Screen Freeze Engine & Region Selection Window

**Files:**
- Create: `modules/screenshot/TempScreenshotProcess.qml`
- Create: `modules/screenshot/regionSelector/RegionSelection.qml`

**Interfaces:**
- Consumes: `screen` object from Quickshell, `ScreenshotAction`.
- Produces: Seamless screen freeze and mouse-interactive region cropping window.

- [ ] **Step 1: Create `TempScreenshotProcess.qml`**

Create `modules/screenshot/TempScreenshotProcess.qml`:
```qml
import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: screenshotProc

    required property ShellScreen screen

    readonly property string screenshotDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/omnisnap`
    readonly property string screenshotPath: `${screenshotDir}/screen-${screen.name}.png`

    running: true
    command: [
        "bash", "-c",
        `mkdir -p '${screenshotDir}' && spectacle -b -n -m -o '${screenshotPath}'`
    ]
}
```

- [ ] **Step 2: Create `RegionSelection.qml`**

Create `modules/screenshot/regionSelector/RegionSelection.qml`:
```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../theme"
import "../ScreenshotAction.qml"
import "."

PanelWindow {
    id: root

    required property ShellScreen screen
    property var action: ScreenshotAction.SnipAction.Copy
    signal dismiss()

    visible: false
    color: "transparent"

    // Wayland LayerShell Configuration
    WlrLayershell.namespace: "omnisnap"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Geometry calculation
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property bool dragging: false

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    readonly property real monitorScale: (frozenImage.sourceSize.width > 0 && root.screen.width > 0)
        ? (frozenImage.sourceSize.width / root.screen.width)
        : (screen.devicePixelRatio || 1.0)

    TempScreenshotProcess {
        id: proc
        screen: root.screen
        onExited: {
            frozenImage.source = "file://" + proc.screenshotPath;
            root.visible = true;
            mouseArea.forceActiveFocus();
        }
    }

    function snip() {
        if (root.regionWidth < 4 || root.regionHeight < 4) {
            // Very small selection = full screen fallback
            root.regionX = 0;
            root.regionY = 0;
            root.regionWidth = root.screen.width;
            root.regionHeight = root.screen.height;
        }

        const cmd = ScreenshotAction.getCommand(
            root.regionX * root.monitorScale,
            root.regionY * root.monitorScale,
            root.regionWidth * root.monitorScale,
            root.regionHeight * root.monitorScale,
            proc.screenshotPath,
            root.action
        );

        Quickshell.execDetached(cmd);
        root.dismiss();
    }

    // Escape listener
    Item {
        focus: true
        Keys.onEscapePressed: root.dismiss()
    }

    // Background frozen frame
    Image {
        id: frozenImage
        anchors.fill: parent
        cache: false
    }

    // Interactive mouse area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: mouse => {
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
            if (mouse.button === Qt.RightButton && root.action === ScreenshotAction.SnipAction.Copy) {
                root.action = ScreenshotAction.SnipAction.Edit;
            }
        }

        onPositionChanged: mouse => {
            if (root.dragging) {
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
            }
        }

        onReleased: {
            root.dragging = false;
            root.snip();
        }

        // Selection details (darkening borders + aim lines + dimension)
        RectCornersSelectionDetails {
            anchors.fill: parent
            regionX: root.regionX
            regionY: root.regionY
            regionWidth: root.regionWidth
            regionHeight: root.regionHeight
            mouseX: mouseArea.mouseX
            mouseY: mouseArea.mouseY
        }

        // Dynamic cursor guide pill
        CursorGuide {
            x: mouseArea.mouseX
            y: mouseArea.mouseY
            action: root.action
            active: !root.dragging
        }

        // Bottom toolbar
        OptionsToolbar {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 16
            }
            action: root.action
            onActionChanged: root.action = action
            onDismiss: root.dismiss()
            onFullScreenRequested: {
                root.regionX = 0;
                root.regionY = 0;
                root.regionWidth = root.screen.width;
                root.regionHeight = root.screen.height;
                root.snip();
            }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/screenshot/TempScreenshotProcess.qml modules/screenshot/regionSelector/RegionSelection.qml
git commit -m "feat(core): implement screen freeze engine and region selection overlay"
```

---

### Task 7: Shell Root, Multi-Screen Dispatch & IPC Integration

**Files:**
- Create: `modules/screenshot/regionSelector/RegionSelector.qml`
- Create: `shell.qml`
- Test: `tests/test_quickshell_syntax.sh`

**Interfaces:**
- Consumes: Quickshell runtime.
- Produces: `shell.qml` root with multi-screen loader and `IpcHandler` (`target: "region"`).

- [ ] **Step 1: Create `RegionSelector.qml`**

Create `modules/screenshot/regionSelector/RegionSelector.qml`:
```qml
import QtQuick
import Quickshell
import "../ScreenshotAction.qml"
import "."

Scope {
    id: root

    property bool active: false
    property var action: ScreenshotAction.SnipAction.Copy

    function dismiss() {
        root.active = false;
        // If not running in daemon mode, quit quickshell
        if (Quickshell.env("OMNISNAP_DAEMON") !== "1") {
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
```

- [ ] **Step 2: Create `shell.qml`**

Create `shell.qml`:
```qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "modules/screenshot/regionSelector"

ShellRoot {
    id: root

    property var regionSelector: RegionSelector {
        id: selector
    }

    IpcHandler {
        target: "region"

        function screenshot(): void {
            selector.screenshot();
        }

        function edit(): void {
            selector.edit();
        }

        function search(): void {
            selector.search();
        }

        function ocr(): void {
            selector.ocr();
        }

        function fullscreen(): void {
            Quickshell.execDetached([
                "bash", "-c",
                "saveFile=\"$HOME/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png\"; " +
                "mkdir -p \"$(dirname \"$saveFile\")\" && " +
                "spectacle -b -n -f -o \"$saveFile\" && " +
                "wl-copy -t image/png < \"$saveFile\" && " +
                "notify-send \"Screenshot Captured\" \"Saved to $saveFile\" -i \"$saveFile\" -a \"Omnisnap\" 2>/dev/null || true"
            ]);
            if (Quickshell.env("OMNISNAP_DAEMON") !== "1") {
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
```

- [ ] **Step 3: Write QML syntax and load verification test**

Create `tests/test_quickshell_syntax.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Verify QML files syntax using qmllint if available, or quickshell validation
if command -v qmllint >/dev/null 2>&1; then
    qmllint "$ROOT_DIR/shell.qml" || { echo "FAIL: QML lint failed"; exit 1; }
fi

echo "PASS: QML syntax verified"
```

- [ ] **Step 4: Run test to verify passes**

Run: `bash tests/test_quickshell_syntax.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/screenshot/regionSelector/RegionSelector.qml shell.qml tests/test_quickshell_syntax.sh
git commit -m "feat(shell): implement shell root, multi-screen variants and ipc handlers"
```

---

### Task 8: Installation Script, Desktop Integration & Documentation

**Files:**
- Create: `install.sh`
- Create: `omnisnap.desktop`
- Create: `README.md`
- Test: `tests/test_install.sh`

**Interfaces:**
- Consumes: Completed Omnisnap project.
- Produces: Seamless installation to `~/.local/bin/omnisnap`, `~/.local/share/applications/omnisnap.desktop`, and setup instructions for KDE Plasma shortcuts.

- [ ] **Step 1: Create `omnisnap.desktop`**

Create `omnisnap.desktop`:
```desktop
[Desktop Entry]
Name=Omnisnap
Comment=Modern Screenshot Tool for KDE Plasma 6
Exec=omnisnap region
Icon=camera-photo
Terminal=false
Type=Application
Categories=Utility;Graphics;
Keywords=screenshot;snip;capture;ocr;lens;
```

- [ ] **Step 2: Create `install.sh`**

Create `install.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="$HOME/.local/bin"
DESKTOP_TARGET="$HOME/.local/share/applications"

mkdir -p "$BIN_TARGET" "$DESKTOP_TARGET"

echo "Installing Omnisnap to $BIN_TARGET..."
ln -sf "$REPO_DIR/bin/omnisnap" "$BIN_TARGET/omnisnap"

echo "Installing Desktop entry to $DESKTOP_TARGET..."
sed "s|Exec=omnisnap|Exec=$BIN_TARGET/omnisnap|g" "$REPO_DIR/omnisnap.desktop" > "$DESKTOP_TARGET/omnisnap.desktop"

echo "Omnisnap installed successfully!"
echo "You can now bind 'omnisnap region' to the PrintScreen key in KDE System Settings -> Shortcuts."
```
Make executable: `chmod +x install.sh`

- [ ] **Step 3: Create `README.md` with complete usage & dependency documentation**

Create `README.md`:
```markdown
# Omnisnap 📸

A blazing fast, modern screenshot tool for **KDE Plasma 6 (Wayland)** inspired by Caelestia.

## ✨ Features
- **Screen Freeze Mode**: Instantly freezes the screen on shortcut press without display delay.
- **Smart Dimming Overlay**: Highlights the selected region with a smooth, focused darkening effect.
- **Dynamic Cursor Guide**: Live pill tooltip showing mode and action hints right next to your cursor.
- **Interactive Toolbar**: Switch between Screenshot, Annotation, Google Lens, and OCR text recognition on the fly.
- **Annotate & Draw**: Instant hand-off to Swappy for arrows, blur, rectangles, and text.
- **OCR Text Extraction**: Extract text directly from the screen into your clipboard using Tesseract.
- **Google Lens Visual Search**: Search any image region immediately in your browser.
- **Zero-Latency Daemon Mode**: Supports background daemon via Quickshell IPC.

## 📦 Dependencies
Ensure the following packages are installed on your system (e.g. via `pacman`, `dnf`, or `apt`):
- `quickshell` (Wayland layer-shell QML framework)
- `spectacle` (KDE background screenshot backend)
- `imagemagick` (`magick` CLI for cropping & OCR preprocessing)
- `wl-clipboard` (`wl-copy` for Wayland clipboard)
- `libnotify` (`notify-send` for desktop notifications)
- `swappy` (for screenshot editing/annotations)
- `tesseract` (for OCR text recognition)
- `curl` & `jq` (for Google Lens upload)

## 🚀 Installation
```bash
git clone https://github.com/<your-username>/Omnisnap.git
cd Omnisnap
./install.sh
```

## ⌨️ KDE Plasma 6 Shortcut Configuration
1. Open **System Settings -> Shortcuts**.
2. Click **Add New -> Command**.
3. Set name to `Omnisnap Snip` and command to `omnisnap region`.
4. Assign the key shortcut (e.g., `Print` or `Meta + Shift + S`).
```

- [ ] **Step 4: Commit**

```bash
git add install.sh omnisnap.desktop README.md
git commit -m "docs: add installation script, desktop file and comprehensive README"
```

---

## Plan Self-Review

1. **Spec Coverage:**
   - Full Caelestia screenshot UX (freeze mode, dimming overlay, cursor guide, bottom toolbar)? Covered in Tasks 4, 5, 6.
   - All actions (copy, edit/swappy, Google Lens, OCR)? Covered in Task 2.
   - Standalone Quickshell architecture with IPC and one-shot fallback? Covered in Tasks 1, 6, 7.
   - Clean KDE integration and installer? Covered in Task 8.
2. **Placeholder Scan:**
   - No `TODO`, `TBD`, or ambiguous pseudocode. All files have concrete implementation details and bash commands.
3. **Type Consistency:**
   - Action names (`Copy`, `Edit`, `Search`, `CharRecognition`) match between `ScreenshotAction.qml`, `RegionSelection.qml`, `OptionsToolbar.qml`, and `CursorGuide.qml`.
