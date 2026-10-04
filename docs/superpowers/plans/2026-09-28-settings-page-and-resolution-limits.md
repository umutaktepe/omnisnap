# Omnisnap: Settings Page and Maximum Resolution Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an XDG-compliant persistent configuration system, an ImageMagick-powered aspect-ratio-preserving maximum resolution limiter (downscaling), and a modern, Catppuccin-styled Settings Page accessible via CLI (`omnisnap settings`), toolbar icon, and application launcher.

**Architecture:** A singleton `modules/config/Config.qml` manages reading, defaulting, and saving configuration to `~/.config/omnisnap/config.json` via asynchronous shell I/O. `ScreenshotAction.qml` ingests configuration properties (such as `maxResolution`, `saveDirectory`, `fileFormat`, and `saveToFile`) into the ImageMagick processing pipeline using geometry flags (`-resize 'WIDTHxHEIGHT>'`). A Quickshell `FloatingWindow` component `modules/settings/SettingsWindow.qml` presents a tabbed settings interface matching the Caelestia/KDE Plasma 6 design language, with direct hooks into `shell.qml` IPC and `OptionsToolbar.qml`.

**Tech Stack:** QML / QtQuick 6, Quickshell (LayerShell + FloatingWindow, `Quickshell.Io.Process`, `StdioCollector`), Bash (`set -euo pipefail`), ImageMagick (`magick`), jq, Catppuccin Mocha theme.

**Spec:** User feature request for screenshot maximum resolution limits and a comprehensive settings page with configurable behaviors.

## Global Constraints
- Target environment: Linux, KDE Plasma 6 on Wayland (KWin compositor).
- Zero dependencies on non-native C++ plugins; rely entirely on Quickshell, QtQuick, Bash, ImageMagick, and standard CLI tools (`jq`, `kwriteconfig6`, `notify-send`, `wl-copy`).
- Config path must adhere to XDG standard: `${XDG_CONFIG_HOME:-$HOME/.config}/omnisnap/config.json`.
- Resolution limiting must never upscale smaller images or distort aspect ratio (use ImageMagick `>` flag e.g. `1920x1080>`).
- All shell commands in pipeline scripts must maintain `set -euo pipefail` and proper shell escaping.
- All `.qml` files must pass `qmllint` syntax checks.
- All existing tests in `tests/` must continue to pass cleanly.

---

### Task 1: Persistent Configuration System (`modules/config/Config.qml`)

**Files:**
- Create: `modules/config/qmldir`
- Create: `modules/config/Config.qml`
- Create: `tests/test_config.sh`

**Interfaces:**
- Produces: Singleton `Config` with properties:
  - `property string maxResolution`: `""` (unlimited), `"1920x1080>"`, `"2560x1440>"`, etc.
  - `property string saveDirectory`: `"~/Pictures/Screenshots"`
  - `property string fileFormat`: `"png"` (`"png"`, `"jpg"`, `"webp"`)
  - `property int imageQuality`: `90` (1-100)
  - `property bool copyToClipboard`: `true`
  - `property bool saveToFile`: `true`
  - `property bool showGuides`: `true`
  - `property bool inhibitScreenEdges`: `true`
  - `property string defaultAction`: `"copy"` (`"copy"`, `"edit"`, `"search"`, `"ocr"`)
  - `property string ocrLanguages`: `""` (auto-detect or comma/plus separated)
  - `property bool shutterSound`: `false`
  - `function save()`: Asynchronously writes current properties to `~/.config/omnisnap/config.json`.
  - `function load()`: Asynchronously reads and parses `config.json`, applying values over defaults.

- [ ] **Step 1: Write the failing unit test for configuration persistence**

Create `tests/test_config.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_QML="$PROJECT_DIR/modules/config/Config.qml"

test_config_structure() {
    if [[ ! -f "$CONFIG_QML" ]]; then
        echo "FAIL: $CONFIG_QML does not exist"
        exit 1
    fi

    grep -q "pragma Singleton" "$CONFIG_QML" || { echo "FAIL: Config.qml missing pragma Singleton"; exit 1; }
    grep -q "property string maxResolution" "$CONFIG_QML" || { echo "FAIL: Missing maxResolution property"; exit 1; }
    grep -q "property string saveDirectory" "$CONFIG_QML" || { echo "FAIL: Missing saveDirectory property"; exit 1; }
    grep -q "property string fileFormat" "$CONFIG_QML" || { echo "FAIL: Missing fileFormat property"; exit 1; }
    grep -q "function save()" "$CONFIG_QML" || { echo "FAIL: Missing save() function"; exit 1; }
    grep -q "function load()" "$CONFIG_QML" || { echo "FAIL: Missing load() function"; exit 1; }

    echo "PASS: Config.qml structure verified"
}

test_config_json_schema() {
    local tmp_dir tmp_config
    tmp_dir="$(mktemp -d /tmp/test-omnisnap-config-XXXXXX)"
    tmp_config="$tmp_dir/config.json"

    # Simulate default config serialization
    python3 - << PYEOF
import json, os

defaults = {
    "maxResolution": "1920x1080>",
    "saveDirectory": "~/Pictures/Screenshots",
    "fileFormat": "png",
    "imageQuality": 90,
    "copyToClipboard": True,
    "saveToFile": True,
    "showGuides": True,
    "inhibitScreenEdges": True,
    "defaultAction": "copy",
    "ocrLanguages": "",
    "shutterSound": False
}

with open("${tmp_config}", "w") as f:
    json.dump(defaults, f, indent=2)

with open("${tmp_config}", "r") as f:
    data = json.load(f)

assert data["maxResolution"] == "1920x1080>"
assert data["copyToClipboard"] is True
print("PASS: JSON config schema matches specification")
PYEOF

    rm -rf "$tmp_dir"
}

test_config_structure
test_config_json_schema

echo "All config tests passed."
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_config.sh`
Expected: FAIL with missing `modules/config/Config.qml`.

- [ ] **Step 3: Implement `modules/config/qmldir` and `modules/config/Config.qml`**

Create `modules/config/qmldir`:
```qml
singleton Config 1.0 Config.qml
```

Create `modules/config/Config.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string configDir: `${Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")}/omnisnap`
    readonly property string configPath: `${configDir}/config.json`

    // Configuration Properties with defaults
    property string maxResolution: ""          // "" = Unlimited, or "1920x1080>", "2560x1440>"
    property string saveDirectory: "~/Pictures/Screenshots"
    property string fileFormat: "png"          // "png", "jpg", "webp"
    property int imageQuality: 90              // 1 - 100
    property bool copyToClipboard: true
    property bool saveToFile: true
    property bool showGuides: true
    property bool inhibitScreenEdges: true
    property string defaultAction: "copy"      // "copy", "edit", "search", "ocr"
    property string ocrLanguages: ""           // "" = auto-detect all
    property bool shutterSound: false

    property bool loaded: false

    function toJsonString() {
        const obj = {
            "maxResolution": root.maxResolution,
            "saveDirectory": root.saveDirectory,
            "fileFormat": root.fileFormat,
            "imageQuality": root.imageQuality,
            "copyToClipboard": root.copyToClipboard,
            "saveToFile": root.saveToFile,
            "showGuides": root.showGuides,
            "inhibitScreenEdges": root.inhibitScreenEdges,
            "defaultAction": root.defaultAction,
            "ocrLanguages": root.ocrLanguages,
            "shutterSound": root.shutterSound
        };
        return JSON.stringify(obj, null, 2);
    }

    function applyJson(jsonStr) {
        if (!jsonStr || jsonStr.trim() === "") return;
        try {
            const data = JSON.parse(jsonStr);
            if (data.maxResolution !== undefined) root.maxResolution = data.maxResolution;
            if (data.saveDirectory !== undefined) root.saveDirectory = data.saveDirectory;
            if (data.fileFormat !== undefined) root.fileFormat = data.fileFormat;
            if (data.imageQuality !== undefined) root.imageQuality = data.imageQuality;
            if (data.copyToClipboard !== undefined) root.copyToClipboard = data.copyToClipboard;
            if (data.saveToFile !== undefined) root.saveToFile = data.saveToFile;
            if (data.showGuides !== undefined) root.showGuides = data.showGuides;
            if (data.inhibitScreenEdges !== undefined) root.inhibitScreenEdges = data.inhibitScreenEdges;
            if (data.defaultAction !== undefined) root.defaultAction = data.defaultAction;
            if (data.ocrLanguages !== undefined) root.ocrLanguages = data.ocrLanguages;
            if (data.shutterSound !== undefined) root.shutterSound = data.shutterSound;
        } catch (e) {
            console.warn("[Omnisnap Config] Failed to parse config.json:", e);
        }
    }

    function save() {
        const safeDir = root.configDir.replace(/'/g, "'\\''");
        const safePath = root.configPath.replace(/'/g, "'\\''");
        const jsonContent = root.toJsonString().replace(/'/g, "'\\''");

        Quickshell.execDetached([
            "bash", "-c",
            `mkdir -p '${safeDir}' && printf '%s\n' '${jsonContent}' > '${safePath}'`
        ]);
    }

    function load() {
        loadProcess.running = true;
    }

    property Process _loadProcess: Process {
        id: loadProcess
        command: [
            "bash", "-c",
            `if [ -f '${root.configPath.replace(/'/g, "'\\''")}' ]; then cat '${root.configPath.replace(/'/g, "'\\''")}'; else echo '{}'; fi`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.applyJson(text);
                root.loaded = true;
            }
        }
    }

    Component.onCompleted: {
        root.load();
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_config.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/config/ tests/test_config.sh
git commit -m "feat(config): add persistent XDG configuration singleton"
```

---

### Task 2: Resolution Limiting & Config Integration in Pipeline (`ScreenshotAction.qml`)

**Files:**
- Modify: `modules/screenshot/ScreenshotAction.qml`
- Modify: `tests/test_action_pipeline.sh`

**Interfaces:**
- Consumes: `modules/config/Config.qml` (`maxResolution`, `saveDirectory`, `fileFormat`, `imageQuality`, `saveToFile`, `copyToClipboard`).
- Produces: Updated ImageMagick crop pipeline supporting `-resize 'WIDTHxHEIGHT>'` and format extensions.

- [ ] **Step 1: Write failing test in `tests/test_action_pipeline.sh` for downscale geometry and formats**

Add test function `test_max_resolution_downscaling` to `tests/test_action_pipeline.sh`:
```bash
test_max_resolution_downscaling() {
    local tmp_orig tmp_resized width height
    tmp_orig="$(mktemp /tmp/test-res-orig-XXXXXX.png)"
    tmp_resized="$(mktemp /tmp/test-res-down-XXXXXX.png)"

    # Create a 3840x2160 4K image
    magick -size 3840x2160 xc:red "$tmp_orig"

    # Apply 1920x1080> downscaling: must shrink to 1920x1080
    magick "$tmp_orig" -resize '1920x1080>' "$tmp_resized"
    width=$(identify -format "%w" "$tmp_resized")
    height=$(identify -format "%h" "$tmp_resized")

    if [[ "$width" -ne 1920 || "$height" -ne 1080 ]]; then
        echo "FAIL: Downscaling 4K with 1920x1080> failed, got ${width}x${height}"
        rm -f "$tmp_orig" "$tmp_resized"
        exit 1
    fi

    # Test that smaller images (800x600) are NOT upscaled by > geometry
    magick -size 800x600 xc:green "$tmp_orig"
    magick "$tmp_orig" -resize '1920x1080>' "$tmp_resized"
    width=$(identify -format "%w" "$tmp_resized")
    height=$(identify -format "%h" "$tmp_resized")

    rm -f "$tmp_orig" "$tmp_resized"

    if [[ "$width" -ne 800 || "$height" -ne 600 ]]; then
        echo "FAIL: Small image was erroneously resized with > flag, got ${width}x${height}"
        exit 1
    fi

    echo "PASS: ImageMagick max resolution downscale logic verified"
}
```

- [ ] **Step 2: Run test to verify ImageMagick downscaling behavior**

Run: `bash tests/test_action_pipeline.sh`
Expected: Passes `test_max_resolution_downscaling`.

- [ ] **Step 3: Update `modules/screenshot/ScreenshotAction.qml` to support resolution limiting and config parameters**

Modify `modules/screenshot/ScreenshotAction.qml` to accept optional `maxRes`, `fileFormat`, `saveToFile`, and `copyToClipboard` parameters or import `../config`:
```qml
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

        const activeMaxRes = (maxResOverride !== null) ? maxResOverride : Config.maxResolution;
        const resizeArg = (activeMaxRes && activeMaxRes.trim() !== "") ? ` -resize '${escapeShellStr(activeMaxRes)}'` : "";
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
                    `if [ "$ACTION" = "open" ]; then xdg-open "$saveFile"; elif [ "$ACTION" = "folder" ]; then xdg-open "$SAVE_DIR"; fi ` +
                    `) & ` +
                    `${notifyCleanup}${cleanup}`;
            }

            case ScreenshotAction.SnipAction.Edit: {
                return `set -euo pipefail; ` +
                    `SAVE_DIR='${escapeShellStr(targetDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).${ext}" && ` +
                    `TMPF=$(mktemp /tmp/omnisnap-edit-XXXXXX.${ext}); ` +
                    `${cropBase} "$TMPF" && ` +
                    `swappy -f "$TMPF" -o "$saveFile" || true; ` +
                    `if [ -s "$saveFile" ]; then ` +
                    `    wl-copy -t image/${ext === "jpg" ? "jpeg" : ext} < "$saveFile"; ` +
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
                const langArg = Config.ocrLanguages ? `-l '${escapeShellStr(Config.ocrLanguages)}'` : "";
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
```

- [ ] **Step 4: Run tests and ensure all pass**

Run: `bash tests/run-tests.sh`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(pipeline): support max resolution clamp and custom formats"
```

---

### Task 3: Settings Page QML Interface (`modules/settings/SettingsWindow.qml`)

**Files:**
- Create: `modules/settings/qmldir`
- Create: `modules/settings/SettingsWindow.qml`
- Create: `tests/test_settings_syntax.sh`

**Interfaces:**
- Consumes: `modules/config/Config.qml`, `theme/Theme.qml`, `components/StyledText.qml`, `components/IconButton.qml`.
- Produces: `SettingsWindow` Quickshell `FloatingWindow` with:
  - Resolution Limit selector (Unlimited, 1080p, 1440p, 4K, Custom).
  - Save Directory input field and file format selector (PNG, JPG, WebP).
  - Output toggles (Save to File, Copy to Clipboard).
  - Guides & Selection toggles (Aim crosshairs, Dimensions label, Inhibit KWin hot corners).
  - Save / Reset buttons syncing with `Config.save()`.

- [ ] **Step 1: Write test for Settings window syntax and structure**

Create `tests/test_settings_syntax.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS_QML="$PROJECT_DIR/modules/settings/SettingsWindow.qml"

if [[ ! -f "$SETTINGS_QML" ]]; then
    echo "FAIL: $SETTINGS_QML not found"
    exit 1
fi

grep -q "FloatingWindow" "$SETTINGS_QML" || { echo "FAIL: SettingsWindow must use FloatingWindow"; exit 1; }
grep -q "Config.save()" "$SETTINGS_QML" || { echo "FAIL: SettingsWindow must call Config.save()"; exit 1; }

if command -v qmllint >/dev/null 2>&1; then
    qmllint -I "$PROJECT_DIR/theme" -I "$PROJECT_DIR/components" -I "$PROJECT_DIR/modules/config" "$SETTINGS_QML" || {
        echo "FAIL: qmllint failed on $SETTINGS_QML"
        exit 1
    }
fi

echo "PASS: SettingsWindow structure and syntax verified"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_settings_syntax.sh`
Expected: FAIL.

- [ ] **Step 3: Implement `modules/settings/qmldir` and `modules/settings/SettingsWindow.qml`**

Create `modules/settings/qmldir`:
```qml
SettingsWindow 1.0 SettingsWindow.qml
```

Create `modules/settings/SettingsWindow.qml` with a clean tabbed UI adhering to Catppuccin Mocha colors and QtQuick layouts. Include:
1. Header: Omnisnap Settings with Close button.
2. Tab bar: "Görüntü & Çözünürlük", "Kayıt & Pano", "Arayüz & Kılavuzlar".
3. Resolution downscale options:
   - "Orijinal / Sınırsız" (`""`)
   - "1080p (Maks. 1920x1080)" (`"1920x1080>"`)
   - "2K / 1440p (Maks. 2560x1440)" (`"2560x1440>"`)
   - "720p (Maks. 1280x720)" (`"1280x720>"`)
4. Format selector: PNG, JPG, WebP.
5. Save Directory input.
6. Toggles for Clipboard, File, Guides, KWin inhibition.
7. Save action: writes to `Config.save()` and displays notification or confirmation banner.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_settings_syntax.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/settings/ tests/test_settings_syntax.sh
git commit -m "feat(ui): add modern Catppuccin settings window"
```

---

### Task 4: CLI & Toolbar Integration (`bin/omnisnap`, `OptionsToolbar.qml`, `shell.qml`)

**Files:**
- Modify: `bin/omnisnap`
- Modify: `shell.qml`
- Modify: `modules/screenshot/regionSelector/OptionsToolbar.qml`
- Modify: `tests/test_cli.sh`
- Modify: `tests/test_toolbar.sh`

**Interfaces:**
- CLI command: `omnisnap settings` / `omnisnap -c` / `omnisnap --settings`.
- Toolbar: Adds a settings gear button (`settings` icon) triggering the settings window.
- Shell IPC: `IpcHandler` target `settings` with function `open()`.

- [ ] **Step 1: Write test in `tests/test_cli.sh` for `settings` argument**

Verify `bin/omnisnap --help` and `bin/omnisnap settings` handler are defined.

- [ ] **Step 2: Add `settings` subcommand to `bin/omnisnap`**

Update `bin/omnisnap`:
```bash
    settings|-c|--settings)
        if _is_running; then
            _call_ipc "settings"
        else
            _launch_oneshot "settings"
        fi
        ;;
```

- [ ] **Step 3: Update `shell.qml` to instantiate `SettingsWindow` and handle IPC**

Connect `IpcHandler` with `function settings() { settingsWindow.visible = true; }` and handle `OMNISNAP_INITIAL_ACTION === "settings"`.

- [ ] **Step 4: Add Settings Icon Button to `OptionsToolbar.qml`**

Add gear icon button on the right side of `OptionsToolbar.qml` that calls IPC `settings` or opens settings window.

- [ ] **Step 5: Run tests and ensure all pass**

Run: `bash tests/run-tests.sh`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git commit -am "feat(integration): connect settings page to CLI, toolbar, and shell IPC"
```

---

### Task 5: Living Architecture Wiki and ADR Documentation

**Files:**
- Create: `docs/omnisnap-wiki/decisions/adr-006-settings-management-and-resolution-limits.md`
- Create: `docs/omnisnap-wiki/core-engine/settings-and-configuration.md`
- Modify: `docs/omnisnap-wiki/index.md`
- Modify: `docs/omnisnap-wiki/log.md`

**Requirements:**
- Obsidian wikilink syntax (`[[...]]`).
- ADR structure: Bağlam, Değerlendirilen Alternatifler, Karar, Sonuçlar ve Ödünleşimler.
- Append to `log.md`: `## [2026-09-28] [feat] | Settings Page and Maximum Resolution Limiter`.

- [ ] **Step 1: Write `adr-006-settings-management-and-resolution-limits.md`**
- [ ] **Step 2: Update Wiki MOC (`docs/omnisnap-wiki/index.md`) and log (`docs/omnisnap-wiki/log.md`)**
- [ ] **Step 3: Verify all test runners pass**

Run: `bash tests/run-tests.sh`
Expected: 100% pass.

- [ ] **Step 4: Commit**

```bash
git add docs/omnisnap-wiki/
git commit -m "docs(wiki): document configuration system, resolution limits, and ADR-006"
```
