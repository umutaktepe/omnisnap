#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REGION_SELECTOR_DIR="$PROJECT_DIR/modules/screenshot/regionSelector"
TAB_BAR_FILE="$REGION_SELECTOR_DIR/ToolbarTabBar.qml"
TOOLBAR_FILE="$REGION_SELECTOR_DIR/OptionsToolbar.qml"

test_files_exist() {
    local files=(
        "$TAB_BAR_FILE"
        "$TOOLBAR_FILE"
    )

    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "FAIL: Required file $f does not exist"
            exit 1
        fi
    done
    echo "PASS: All required toolbar files exist"
}

test_qmllint_syntax() {
    if ! command -v qmllint >/dev/null 2>&1; then
        echo "FAIL: qmllint command not found"
        exit 1
    fi

    local qml_files=(
        "$TAB_BAR_FILE"
        "$TOOLBAR_FILE"
    )

    for qml in "${qml_files[@]}"; do
        qmllint "$qml" || { echo "FAIL: qmllint failed on $qml"; exit 1; }
        echo "PASS: qmllint verified on $(basename "$qml")"
    done
}

test_toolbar_tab_bar_properties_and_delegates() {
    # Check properties and signals
    grep -q 'property int currentIndex: 0' "$TAB_BAR_FILE" || { echo "FAIL: Missing property int currentIndex: 0 in ToolbarTabBar.qml"; exit 1; }
    grep -q 'required property var tabs' "$TAB_BAR_FILE" || { echo "FAIL: Missing required property var tabs in ToolbarTabBar.qml"; exit 1; }
    grep -q 'signal tabClicked(int index)' "$TAB_BAR_FILE" || { echo "FAIL: Missing signal tabClicked(int index) in ToolbarTabBar.qml"; exit 1; }

    # Check Repeater and delegates
    grep -q 'Repeater {' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing Repeater"; exit 1; }
    grep -q 'model: root.tabs' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing model: root.tabs"; exit 1; }

    # Check active tab styling
    grep -q 'Theme.primary' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing Theme.primary for active tab background"; exit 1; }
    grep -q 'Theme.textOnPrimary' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing Theme.textOnPrimary for active tab foreground"; exit 1; }
    grep -q 'Behavior on color' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing smooth animated color transition"; exit 1; }

    # Check mouse interaction
    grep -q 'root.currentIndex = tabBtn.index' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml must update currentIndex on click"; exit 1; }
    grep -q 'root.tabClicked(tabBtn.index)' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml must emit tabClicked on click"; exit 1; }
    grep -q 'cursorShape: Qt.PointingHandCursor' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing pointing hand cursor"; exit 1; }

    # Check Icon and StyledText
    grep -q 'Icon {' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing Icon component"; exit 1; }
    grep -q 'StyledText {' "$TAB_BAR_FILE" || { echo "FAIL: ToolbarTabBar.qml missing StyledText component"; exit 1; }

    echo "PASS: ToolbarTabBar.qml properties, delegates, styling, and click handling verified"
}

test_options_toolbar_properties_and_controls() {
    # Check action property and signals
    grep -q 'property var action: ScreenshotAction.SnipAction.Copy' "$TOOLBAR_FILE" || { echo "FAIL: Missing default property var action in OptionsToolbar.qml"; exit 1; }
    grep -q 'signal dismiss()' "$TOOLBAR_FILE" || { echo "FAIL: Missing signal dismiss() in OptionsToolbar.qml"; exit 1; }
    grep -q 'signal fullScreenRequested()' "$TOOLBAR_FILE" || { echo "FAIL: Missing signal fullScreenRequested() in OptionsToolbar.qml"; exit 1; }
    grep -q 'signal activeWindowRequested()' "$TOOLBAR_FILE" || { echo "FAIL: Missing signal activeWindowRequested() in OptionsToolbar.qml"; exit 1; }
    grep -q 'signal openSettingsRequested()' "$TOOLBAR_FILE" || { echo "FAIL: Missing signal openSettingsRequested() in OptionsToolbar.qml"; exit 1; }
    grep -q 'captureModeMenu' "$TOOLBAR_FILE" || { echo "FAIL: Missing captureModeMenu popover in OptionsToolbar.qml"; exit 1; }
    grep -q 'Aktif Pencere' "$TOOLBAR_FILE" || { echo "FAIL: Missing Aktif Pencere option in captureModeMenu"; exit 1; }

    # Check pill container styling
    grep -q 'color: Theme.surface' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing Theme.surface background"; exit 1; }
    grep -q 'radius: height / 2' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing radius: height / 2"; exit 1; }
    grep -q 'border.color: Theme.outline' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing border.color: Theme.outline"; exit 1; }

    # Check vertical separator
    grep -q 'width: 1' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing vertical separator line"; exit 1; }

    # Check Fullscreen IconButton
    grep -q 'icon: "fullscreen"' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing fullscreen IconButton"; exit 1; }
    grep -q 'root.fullScreenRequested()' "$TOOLBAR_FILE" || { echo "FAIL: Fullscreen button must emit fullScreenRequested()"; exit 1; }

    # Check Settings IconButton
    grep -q 'icon: "settings"' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing settings IconButton"; exit 1; }
    grep -q 'root.openSettingsRequested()' "$TOOLBAR_FILE" || { echo "FAIL: Settings button must emit openSettingsRequested()"; exit 1; }

    # Check Close IconButton
    grep -q 'icon: "close"' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing close IconButton"; exit 1; }
    grep -q 'root.dismiss()' "$TOOLBAR_FILE" || { echo "FAIL: Close button must emit dismiss()"; exit 1; }

    # Check Tooltips
    grep -q 'Tooltip {' "$TOOLBAR_FILE" || { echo "FAIL: OptionsToolbar.qml missing Tooltip components"; exit 1; }
    grep -q 'Capture Full Screen' "$TOOLBAR_FILE" || { echo "FAIL: Missing 'Capture Full Screen' tooltip text"; exit 1; }
    grep -q 'Ayarlar' "$TOOLBAR_FILE" || { echo "FAIL: Missing 'Ayarlar' tooltip text"; exit 1; }
    grep -q 'Cancel' "$TOOLBAR_FILE" || { echo "FAIL: Missing 'Cancel' tooltip text"; exit 1; }

    echo "PASS: OptionsToolbar.qml pill container, separator, buttons, and tooltips verified"
}

test_action_enum_mappings_and_tabs() {
    # Check 4 tab names and icons
    grep -q '"Screenshot"' "$TOOLBAR_FILE" || { echo "FAIL: Missing Screenshot tab in OptionsToolbar.qml"; exit 1; }
    grep -q '"Annotate"' "$TOOLBAR_FILE" || { echo "FAIL: Missing Annotate tab in OptionsToolbar.qml"; exit 1; }
    grep -q '"Google Lens"' "$TOOLBAR_FILE" || { echo "FAIL: Missing Google Lens tab in OptionsToolbar.qml"; exit 1; }
    grep -q '"OCR Text"' "$TOOLBAR_FILE" || { echo "FAIL: Missing OCR Text tab in OptionsToolbar.qml"; exit 1; }

    grep -q '"content_cut"' "$TOOLBAR_FILE" || { echo "FAIL: Missing content_cut icon in OptionsToolbar.qml"; exit 1; }
    grep -q '"edit"' "$TOOLBAR_FILE" || { echo "FAIL: Missing edit icon in OptionsToolbar.qml"; exit 1; }
    grep -q '"search"' "$TOOLBAR_FILE" || { echo "FAIL: Missing search icon in OptionsToolbar.qml"; exit 1; }
    grep -q '"ocr"' "$TOOLBAR_FILE" || { echo "FAIL: Missing ocr icon in OptionsToolbar.qml"; exit 1; }

    # Check action enum mappings
    grep -q 'ScreenshotAction.SnipAction.Copy' "$TOOLBAR_FILE" || { echo "FAIL: Missing Copy action mapping in OptionsToolbar.qml"; exit 1; }
    grep -q 'ScreenshotAction.SnipAction.Edit' "$TOOLBAR_FILE" || { echo "FAIL: Missing Edit action mapping in OptionsToolbar.qml"; exit 1; }
    grep -q 'ScreenshotAction.SnipAction.Search' "$TOOLBAR_FILE" || { echo "FAIL: Missing Search action mapping in OptionsToolbar.qml"; exit 1; }
    grep -q 'ScreenshotAction.SnipAction.CharRecognition' "$TOOLBAR_FILE" || { echo "FAIL: Missing CharRecognition action mapping in OptionsToolbar.qml"; exit 1; }

    # Check tab click action assignment
    grep -q 'root.action = ScreenshotAction.SnipAction.Copy' "$TOOLBAR_FILE" || { echo "FAIL: Missing tab click to Copy assignment"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.Edit' "$TOOLBAR_FILE" || { echo "FAIL: Missing tab click to Edit assignment"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.Search' "$TOOLBAR_FILE" || { echo "FAIL: Missing tab click to Search assignment"; exit 1; }
    grep -q 'root.action = ScreenshotAction.SnipAction.CharRecognition' "$TOOLBAR_FILE" || { echo "FAIL: Missing tab click to CharRecognition assignment"; exit 1; }

    echo "PASS: Tab definitions, icons, action enums, and bidirectional mapping verified"
}

test_composite_integration_lint() {
    local harness_file="$PROJECT_DIR/tests/harness_test_toolbar.qml"

    cat << 'EOF' > "$harness_file"
import QtQuick
import "../theme"
import "../components"
import "../modules/screenshot"
import "../modules/screenshot/regionSelector"

Item {
    id: root
    width: 800
    height: 600

    property var action: ScreenshotAction.SnipAction.Copy
    property bool dismissed: false
    property bool fullScreenRequested: false
    property bool settingsRequested: false

    ToolbarTabBar {
        id: customTabBar
        tabs: [
            { "icon": "content_cut", "name": "Tab 1" },
            { "icon": "edit", "name": "Tab 2" }
        ]
        currentIndex: 0
        onTabClicked: index => {
            console.log("Tab clicked:", index);
        }
    }

    OptionsToolbar {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16

        action: root.action
        onActionChanged: root.action = toolbar.action
        onDismiss: root.dismissed = true
        onFullScreenRequested: root.fullScreenRequested = true
        onOpenSettingsRequested: root.settingsRequested = true
    }
}
EOF

    qmllint "$harness_file" || { echo "FAIL: Composite integration qmllint failed"; rm -f "$harness_file"; exit 1; }
    rm -f "$harness_file"

    echo "PASS: Composite integration QML harness passed qmllint"
}

main() {
    echo "Running Toolbar & Tab Switcher Test Suite..."
    test_files_exist
    test_qmllint_syntax
    test_toolbar_tab_bar_properties_and_delegates
    test_options_toolbar_properties_and_controls
    test_action_enum_mappings_and_tabs
    test_composite_integration_lint
    echo "All toolbar and tab switcher tests passed successfully."
}

main "$@"
