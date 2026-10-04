#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SHELL_FILE="$PROJECT_DIR/shell.qml"
REGION_SELECTOR_FILE="$PROJECT_DIR/modules/screenshot/regionSelector/RegionSelector.qml"

echo "Running Quickshell Syntax, Multi-Screen & IPC Integration Test Suite..."

test_files_exist() {
    local files=(
        "$SHELL_FILE"
        "$REGION_SELECTOR_FILE"
        "$PROJECT_DIR/theme/Theme.qml"
        "$PROJECT_DIR/components/StyledText.qml"
        "$PROJECT_DIR/components/Icon.qml"
        "$PROJECT_DIR/components/IconButton.qml"
        "$PROJECT_DIR/components/Tooltip.qml"
        "$PROJECT_DIR/modules/screenshot/ScreenshotAction.qml"
        "$PROJECT_DIR/modules/screenshot/TempScreenshotProcess.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/RectCornersSelectionDetails.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/CursorGuide.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/ToolbarTabBar.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/OptionsToolbar.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/RegionSelection.qml"
    )

    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "FAIL: Required file $f does not exist"
            exit 1
        fi
    done
    echo "PASS: All required QML files exist"
}

test_qmllint_syntax() {
    if ! command -v qmllint >/dev/null 2>&1; then
        echo "FAIL: qmllint command not found"
        exit 1
    fi

    local qml_files=(
        "$SHELL_FILE"
        "$REGION_SELECTOR_FILE"
        "$PROJECT_DIR/modules/screenshot/regionSelector/RegionSelection.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/OptionsToolbar.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/ToolbarTabBar.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/RectCornersSelectionDetails.qml"
        "$PROJECT_DIR/modules/screenshot/regionSelector/CursorGuide.qml"
        "$PROJECT_DIR/modules/screenshot/TempScreenshotProcess.qml"
        "$PROJECT_DIR/modules/screenshot/ScreenshotAction.qml"
        "$PROJECT_DIR/components/Tooltip.qml"
        "$PROJECT_DIR/components/IconButton.qml"
        "$PROJECT_DIR/components/Icon.qml"
        "$PROJECT_DIR/components/StyledText.qml"
        "$PROJECT_DIR/theme/Theme.qml"
    )

    for qml in "${qml_files[@]}"; do
        qmllint "$qml" || { echo "FAIL: qmllint failed on $qml"; exit 1; }
        echo "PASS: qmllint verified on $(basename "$qml")"
    done
}

test_region_selector_structure() {
    grep -q 'Scope {' "$REGION_SELECTOR_FILE" || { echo "FAIL: RegionSelector must be a Scope component"; exit 1; }
    grep -q 'property bool active: false' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing property bool active"; exit 1; }
    grep -q 'property var action: ScreenshotAction.SnipAction.Copy' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing property var action"; exit 1; }

    # Verify control functions
    grep -q 'function dismiss()' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing dismiss() function"; exit 1; }
    grep -q 'root.active = false' "$REGION_SELECTOR_FILE" || { echo "FAIL: dismiss() must deactivate root.active"; exit 1; }
    grep -q 'OMNISNAP_DAEMON' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing OMNISNAP_DAEMON check in dismiss()"; exit 1; }
    grep -q 'Quickshell.processId' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing Quickshell.processId in dismiss()"; exit 1; }

    grep -q 'function screenshot()' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing screenshot() function"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.Copy' "$REGION_SELECTOR_FILE" || { echo "FAIL: screenshot() must set Copy action"; exit 1; }

    grep -q 'function edit()' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing edit() function"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.Edit' "$REGION_SELECTOR_FILE" || { echo "FAIL: edit() must set Edit action"; exit 1; }

    grep -q 'function search()' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing search() function"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.Search' "$REGION_SELECTOR_FILE" || { echo "FAIL: search() must set Search action"; exit 1; }

    grep -q 'function ocr()' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing ocr() function"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.CharRecognition' "$REGION_SELECTOR_FILE" || { echo "FAIL: ocr() must set CharRecognition action"; exit 1; }

    # Verify Multi-Screen Variants and Loader
    grep -q 'Variants {' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing Variants block"; exit 1; }
    grep -q 'model: Quickshell.screens' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing model: Quickshell.screens"; exit 1; }
    grep -q 'delegate: Loader {' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing delegate: Loader"; exit 1; }
    grep -q 'required property ShellScreen modelData' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing required property ShellScreen modelData"; exit 1; }
    grep -q 'active: root.active' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing active: root.active on Loader"; exit 1; }
    grep -q 'sourceComponent: RegionSelection {' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing sourceComponent: RegionSelection"; exit 1; }
    grep -q 'screen: loader.modelData' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing screen binding in RegionSelection"; exit 1; }
    grep -q 'action: root.action' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing action binding in RegionSelection"; exit 1; }
    grep -q 'onDismiss: root.dismiss()' "$REGION_SELECTOR_FILE" || { echo "FAIL: Missing onDismiss: root.dismiss()"; exit 1; }

    echo "PASS: RegionSelector.qml Scope, actions, Variants, and Loader delegate verified"
}

test_shell_structure() {
    grep -q 'ShellRoot {' "$SHELL_FILE" || { echo "FAIL: shell.qml must have ShellRoot root element"; exit 1; }
    grep -q 'RegionSelector {' "$SHELL_FILE" || { echo "FAIL: Missing RegionSelector in shell.qml"; exit 1; }
    grep -q 'id: selector' "$SHELL_FILE" || { echo "FAIL: RegionSelector must have id: selector"; exit 1; }

    # Verify IpcHandler and target
    grep -q 'IpcHandler {' "$SHELL_FILE" || { echo "FAIL: Missing IpcHandler in shell.qml"; exit 1; }
    grep -q 'target: "region"' "$SHELL_FILE" || { echo "FAIL: IpcHandler must have target: \"region\""; exit 1; }

    # Verify IPC actions
    grep -q 'function screenshot()' "$SHELL_FILE" || { echo "FAIL: Missing screenshot() IPC handler"; exit 1; }
    grep -q 'selector.screenshot()' "$SHELL_FILE" || { echo "FAIL: IPC screenshot() must call selector.screenshot()"; exit 1; }

    grep -q 'function edit()' "$SHELL_FILE" || { echo "FAIL: Missing edit() IPC handler"; exit 1; }
    grep -q 'selector.edit()' "$SHELL_FILE" || { echo "FAIL: IPC edit() must call selector.edit()"; exit 1; }

    grep -q 'function search()' "$SHELL_FILE" || { echo "FAIL: Missing search() IPC handler"; exit 1; }
    grep -q 'selector.search()' "$SHELL_FILE" || { echo "FAIL: IPC search() must call selector.search()"; exit 1; }

    grep -q 'function ocr()' "$SHELL_FILE" || { echo "FAIL: Missing ocr() IPC handler"; exit 1; }
    grep -q 'selector.ocr()' "$SHELL_FILE" || { echo "FAIL: IPC ocr() must call selector.ocr()"; exit 1; }

    grep -q 'function window()' "$SHELL_FILE" || { echo "FAIL: Missing window() IPC handler"; exit 1; }
    grep -q 'spectacle -b -n -a -o' "$SHELL_FILE" || { echo "FAIL: window() must execute spectacle active window capture"; exit 1; }
    grep -q 'function fullscreen()' "$SHELL_FILE" || { echo "FAIL: Missing fullscreen() IPC handler"; exit 1; }
    grep -q 'Quickshell.execDetached' "$SHELL_FILE" || { echo "FAIL: Missing Quickshell.execDetached in shell.qml"; exit 1; }
    grep -q 'spectacle -b -n -f -o' "$SHELL_FILE" || { echo "FAIL: fullscreen() must execute spectacle fullscreen capture"; exit 1; }
    grep -q 'wl-copy -t image/png' "$SHELL_FILE" || { echo "FAIL: fullscreen() must copy to clipboard with wl-copy"; exit 1; }

    # Verify startup action trigger
    grep -q 'Component.onCompleted:' "$SHELL_FILE" || { echo "FAIL: Missing Component.onCompleted in shell.qml"; exit 1; }
    grep -q 'OMNISNAP_INITIAL_ACTION' "$SHELL_FILE" || { echo "FAIL: Missing OMNISNAP_INITIAL_ACTION check"; exit 1; }

    echo "PASS: shell.qml ShellRoot, RegionSelector, IpcHandler, and Component.onCompleted verified"
}

test_regression_suites() {
    echo "Running complete regression test suite..."
    local regression_tests=(
        "$SCRIPT_DIR/test_cli.sh"
        "$SCRIPT_DIR/test_action_pipeline.sh"
        "$SCRIPT_DIR/test_components.sh"
        "$SCRIPT_DIR/test_selection_details.sh"
        "$SCRIPT_DIR/test_toolbar.sh"
        "$SCRIPT_DIR/test_region_selection.sh"
    )

    for suite in "${regression_tests[@]}"; do
        if [[ ! -x "$suite" && ! -f "$suite" ]]; then
            echo "FAIL: Test suite $suite does not exist"
            exit 1
        fi
        bash "$suite" || { echo "FAIL: Regression test suite $suite failed"; exit 1; }
    done

    echo "PASS: All regression test suites passed successfully"
}

test_files_exist
test_qmllint_syntax
test_region_selector_structure
test_shell_structure
test_regression_suites

echo "All Quickshell syntax, multi-screen variants, and IPC tests passed successfully."
