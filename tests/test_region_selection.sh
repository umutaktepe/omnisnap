#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMP_PROC_FILE="$PROJECT_DIR/modules/screenshot/TempScreenshotProcess.qml"
REGION_SELECTION_FILE="$PROJECT_DIR/modules/screenshot/regionSelector/RegionSelection.qml"
REGION_SELECTOR_FILE="$PROJECT_DIR/modules/screenshot/regionSelector/RegionSelector.qml"

test_files_exist() {
    local files=(
        "$TEMP_PROC_FILE"
        "$REGION_SELECTION_FILE"
        "$REGION_SELECTOR_FILE"
    )

    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "FAIL: Required file $f does not exist"
            exit 1
        fi
    done
    echo "PASS: All required screen freeze and region selection files exist"
}

test_qmllint_syntax() {
    if ! command -v qmllint >/dev/null 2>&1; then
        echo "FAIL: qmllint command not found"
        exit 1
    fi

    local qml_files=(
        "$TEMP_PROC_FILE"
        "$REGION_SELECTION_FILE"
        "$REGION_SELECTOR_FILE"
    )

    for qml in "${qml_files[@]}"; do
        qmllint "$qml" || { echo "FAIL: qmllint failed on $qml"; exit 1; }
        echo "PASS: qmllint verified on $(basename "$qml")"
    done
}

test_temp_screenshot_process_structure() {
    # Verify Process root element and screen property
    grep -q 'Process {' "$TEMP_PROC_FILE" || { echo "FAIL: TempScreenshotProcess.qml must be a Process component"; exit 1; }
    grep -q 'required property ShellScreen screen' "$TEMP_PROC_FILE" || { echo "FAIL: Missing required property ShellScreen screen"; exit 1; }

    # Verify screenshot path logic
    grep -q 'property string screenshotDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/omnisnap`' "$TEMP_PROC_FILE" || { echo "FAIL: Missing or incorrect screenshotDir property"; exit 1; }
    grep -q 'property string screenshotPath: `${screenshotDir}/screen-${screen.name}.png`' "$TEMP_PROC_FILE" || { echo "FAIL: Missing or incorrect screenshotPath property"; exit 1; }

    # Verify shell sanitization
    grep -q '_safeDir: screenshotDir.split' "$TEMP_PROC_FILE" || { echo "FAIL: Missing shell escaping for _safeDir"; exit 1; }
    grep -q '_safePath: screenshotPath.split' "$TEMP_PROC_FILE" || { echo "FAIL: Missing shell escaping for _safePath"; exit 1; }

    # Verify process execution command
    grep -q 'running: true' "$TEMP_PROC_FILE" || { echo "FAIL: TempScreenshotProcess must have running: true"; exit 1; }
    grep -q 'spectacle -b -n -m -o' "$TEMP_PROC_FILE" || { echo "FAIL: Missing spectacle background capture command"; exit 1; }

    echo "PASS: TempScreenshotProcess.qml structure, paths, escaping, and spectacle command verified"
}

test_region_selection_layershell_and_properties() {
    # Check Window type and base properties
    grep -q 'PanelWindow {' "$REGION_SELECTION_FILE" || { echo "FAIL: RegionSelection.qml must be a PanelWindow"; exit 1; }
    grep -q 'required property ShellScreen screen' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing required property ShellScreen screen in RegionSelection.qml"; exit 1; }
    grep -q 'property var action: ScreenshotAction.SnipAction.Copy' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing default property var action in RegionSelection.qml"; exit 1; }
    grep -q 'signal dismiss()' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing signal dismiss() in RegionSelection.qml"; exit 1; }
    grep -q 'visible: false' "$REGION_SELECTION_FILE" || { echo "FAIL: RegionSelection.qml must start hidden"; exit 1; }
    grep -q 'color: "transparent"' "$REGION_SELECTION_FILE" || { echo "FAIL: RegionSelection.qml background must be transparent"; exit 1; }

    # Check Wayland LayerShell Configuration
    grep -q 'WlrLayershell.namespace: "omnisnap"' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing WlrLayershell.namespace: \"omnisnap\""; exit 1; }
    grep -q 'WlrLayershell.layer: WlrLayer.Overlay' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing WlrLayershell.layer: WlrLayer.Overlay"; exit 1; }
    grep -q 'WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive"; exit 1; }
    grep -q 'exclusionMode: ExclusionMode.Ignore' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing exclusionMode: ExclusionMode.Ignore"; exit 1; }

    # Check full-screen anchors
    grep -q 'left: true' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing anchors.left: true"; exit 1; }
    grep -q 'right: true' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing anchors.right: true"; exit 1; }
    grep -q 'top: true' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing anchors.top: true"; exit 1; }
    grep -q 'bottom: true' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing anchors.bottom: true"; exit 1; }

    echo "PASS: RegionSelection.qml PanelWindow, LayerShell, and full-screen anchors verified"
}

test_geometry_and_monitor_scale() {
    # Check coordinate properties
    grep -q 'property real dragStartX: 0' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing dragStartX"; exit 1; }
    grep -q 'property real dragStartY: 0' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing dragStartY"; exit 1; }
    grep -q 'property real draggingX: 0' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing draggingX"; exit 1; }
    grep -q 'property real draggingY: 0' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing draggingY"; exit 1; }
    grep -q 'property bool dragging: false' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing dragging property"; exit 1; }

    # Check computed region metrics
    grep -q 'property real regionWidth: Math.abs(draggingX - dragStartX)' "$REGION_SELECTION_FILE" || { echo "FAIL: Incorrect regionWidth calculation"; exit 1; }
    grep -q 'property real regionHeight: Math.abs(draggingY - dragStartY)' "$REGION_SELECTION_FILE" || { echo "FAIL: Incorrect regionHeight calculation"; exit 1; }
    grep -q 'property real regionX: Math.min(dragStartX, draggingX)' "$REGION_SELECTION_FILE" || { echo "FAIL: Incorrect regionX calculation"; exit 1; }
    grep -q 'property real regionY: Math.min(dragStartY, draggingY)' "$REGION_SELECTION_FILE" || { echo "FAIL: Incorrect regionY calculation"; exit 1; }

    # Check DPI / monitor scaling formula
    grep -q 'readonly property real monitorScale:' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing monitorScale property"; exit 1; }
    grep -q 'frozenImage.sourceSize.width / root.screen.width' "$REGION_SELECTION_FILE" || { echo "FAIL: monitorScale must use frozenImage.sourceSize.width / root.screen.width"; exit 1; }
    grep -q 'root.screen.devicePixelRatio || 1.0' "$REGION_SELECTION_FILE" || { echo "FAIL: monitorScale fallback must be devicePixelRatio"; exit 1; }

    echo "PASS: Geometry calculation and HiDPI monitorScale verified"
}

test_snip_and_lifecycle_handling() {
    # Check TempScreenshotProcess hookup
    grep -q 'TempScreenshotProcess {' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing TempScreenshotProcess instantiation"; exit 1; }
    grep -q 'onExited:' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing onExited handler for screenshot process"; exit 1; }
    grep -q 'frozenImage.source = "file://" + proc.screenshotPath' "$REGION_SELECTION_FILE" || { echo "FAIL: onExited must set frozenImage.source"; exit 1; }
    grep -q 'mouseArea.forceActiveFocus()' "$REGION_SELECTION_FILE" || { echo "FAIL: onExited must force active focus on mouseArea"; exit 1; }

    # Check onDismiss temporary file cleanup
    grep -q 'onDismiss:' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing onDismiss handler"; exit 1; }
    grep -q 'Quickshell.execDetached(\["rm", "-f", proc.screenshotPath\])' "$REGION_SELECTION_FILE" || { echo "FAIL: onDismiss must clean up temp screenshot file"; exit 1; }

    # Check snip() logic
    grep -q 'function snip()' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing snip() function"; exit 1; }
    grep -q 'rw < 4 || rh < 4' "$REGION_SELECTION_FILE" || { echo "FAIL: snip() must fallback to full screen if rw < 4 || rh < 4"; exit 1; }
    grep -q 'root.mouseButton === Qt.RightButton && finalAction === ScreenshotAction.SnipAction.Copy' "$REGION_SELECTION_FILE" || { echo "FAIL: Right-click copy must switch to Edit action"; exit 1; }
    grep -q 'ScreenshotAction.getCommand(' "$REGION_SELECTION_FILE" || { echo "FAIL: snip() must invoke ScreenshotAction.getCommand"; exit 1; }
    grep -q 'Quickshell.execDetached(cmd)' "$REGION_SELECTION_FILE" || { echo "FAIL: snip() must execute command with Quickshell.execDetached"; exit 1; }

    # Check Escape triggers
    grep -q 'Shortcut {' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing Shortcut component for Escape"; exit 1; }
    grep -q 'sequence: "Escape"' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing sequence: \"Escape\""; exit 1; }
    grep -q 'Keys.onEscapePressed:' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing Keys.onEscapePressed on mouseArea"; exit 1; }

    # Check UI child components
    grep -q 'RectCornersSelectionDetails {' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing RectCornersSelectionDetails child"; exit 1; }
    grep -q 'CursorGuide {' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing CursorGuide child"; exit 1; }
    grep -q 'OptionsToolbar {' "$REGION_SELECTION_FILE" || { echo "FAIL: Missing OptionsToolbar child"; exit 1; }

    echo "PASS: Process hooks, snip logic, cleanup, escape handlers, and child components verified"
}

test_pointer_event_passthrough_and_screen_edges() {
    # 1. Verify RectCornersSelectionDetails has enabled: false
    grep -A 10 'RectCornersSelectionDetails {' "$REGION_SELECTION_FILE" | grep -q 'enabled: false' || {
        echo "FAIL: RectCornersSelectionDetails must have enabled: false"
        exit 1
    }

    # 2. Verify CursorGuide has enabled: false
    grep -A 10 'CursorGuide {' "$REGION_SELECTION_FILE" | grep -q 'enabled: false' || {
        echo "FAIL: CursorGuide must have enabled: false"
        exit 1
    }

    # 3. Verify OptionsToolbar has high z-index (z: 100) and is placed outside MouseArea
    grep -A 5 'OptionsToolbar {' "$REGION_SELECTION_FILE" | grep -q 'z: 100' || {
        echo "FAIL: OptionsToolbar must specify z: 100"
        exit 1
    }

    python3 -c "
with open('$REGION_SELECTION_FILE') as f:
    content = f.read()
mouse_area_idx = content.find('MouseArea {')
options_toolbar_idx = content.find('OptionsToolbar {')
if mouse_area_idx == -1 or options_toolbar_idx == -1:
    raise SystemExit('MouseArea or OptionsToolbar missing')
level = 0
mouse_area_end = -1
for i in range(mouse_area_idx, len(content)):
    if content[i] == '{':
        level += 1
    elif content[i] == '}':
        level -= 1
        if level == 0:
            mouse_area_end = i
            break
if options_toolbar_idx < mouse_area_end:
    raise SystemExit('OptionsToolbar is nested inside MouseArea')
" || { echo "FAIL: OptionsToolbar must be placed outside MouseArea"; exit 1; }

    # 4. Verify RegionSelector.qml invokes bin/omnisnap-edges inhibit on activation (screenshot, edit, search, ocr)
    grep -q 'omnisnap-edges' "$REGION_SELECTOR_FILE" || {
        echo "FAIL: RegionSelector.qml must reference omnisnap-edges"
        exit 1
    }

    for action in screenshot edit search ocr; do
        awk "/function $action\\(\\)/, /}/" "$REGION_SELECTOR_FILE" | grep -q 'inhibit' || {
            echo "FAIL: $action() in RegionSelector.qml must invoke omnisnap-edges inhibit"
            exit 1
        }
    done

    # 5. Verify RegionSelector.qml invokes bin/omnisnap-edges restore in dismiss()
    awk '/function dismiss\(\)/, /}/' "$REGION_SELECTOR_FILE" | grep -q 'restore' || {
        echo "FAIL: dismiss() in RegionSelector.qml must invoke omnisnap-edges restore"
        exit 1
    }

    # 6. Verify RegionSelector.qml terminates oneshot Quickshell via kill -TERM Quickshell.processId
    grep -q 'Quickshell.processId' "$REGION_SELECTOR_FILE" || {
        echo "FAIL: RegionSelector.qml must reference Quickshell.processId"
        exit 1
    }
    grep -q 'Quickshell.execDetached(\["kill", "-TERM", `${Quickshell.processId}`\])' "$REGION_SELECTOR_FILE" || {
        echo "FAIL: RegionSelector.qml must invoke Quickshell.execDetached with kill -TERM Quickshell.processId"
        exit 1
    }

    echo "PASS: Pointer event passthrough, UI hierarchy isolation, and screen edge inhibitor integration verified"
}

test_regression_suite() {
    echo "Running complete regression test suite..."
    bash "$PROJECT_DIR/tests/test_cli.sh"
    bash "$PROJECT_DIR/tests/test_action_pipeline.sh"
    bash "$PROJECT_DIR/tests/test_components.sh"
    bash "$PROJECT_DIR/tests/test_selection_details.sh"
    bash "$PROJECT_DIR/tests/test_toolbar.sh"
    echo "PASS: All regression suites passed successfully."
}

main() {
    echo "Running Screen Freeze Engine & Region Selection Test Suite..."
    test_files_exist
    test_qmllint_syntax
    test_temp_screenshot_process_structure
    test_region_selection_layershell_and_properties
    test_geometry_and_monitor_scale
    test_snip_and_lifecycle_handling
    test_pointer_event_passthrough_and_screen_edges
    test_regression_suite
    echo "All screen freeze engine and region selection tests passed successfully."
}

main "$@"
