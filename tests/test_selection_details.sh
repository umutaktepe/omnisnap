#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REGION_SELECTOR_DIR="$PROJECT_DIR/modules/screenshot/regionSelector"
RECT_FILE="$REGION_SELECTOR_DIR/RectCornersSelectionDetails.qml"
CURSOR_FILE="$REGION_SELECTOR_DIR/CursorGuide.qml"

test_files_exist() {
    local files=(
        "$RECT_FILE"
        "$CURSOR_FILE"
    )

    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "FAIL: Required file $f does not exist"
            exit 1
        fi
    done
    echo "PASS: All required files exist"
}

test_qmllint_syntax() {
    if ! command -v qmllint >/dev/null 2>&1; then
        echo "FAIL: qmllint command not found"
        exit 1
    fi

    local qml_files=(
        "$RECT_FILE"
        "$CURSOR_FILE"
    )

    for qml in "${qml_files[@]}"; do
        qmllint "$qml" || { echo "FAIL: qmllint failed on $qml"; exit 1; }
        echo "PASS: qmllint verified on $(basename "$qml")"
    done
}

test_rect_corners_selection_details_properties() {
    # Verify required properties
    local required_props=(
        "required property real regionX"
        "required property real regionY"
        "required property real regionWidth"
        "required property real regionHeight"
        "required property real mouseX"
        "required property real mouseY"
    )

    for prop in "${required_props[@]}"; do
        if ! grep -Fq "$prop" "$RECT_FILE"; then
            echo "FAIL: Missing '$prop' in RectCornersSelectionDetails.qml"
            exit 1
        fi
    done

    # Verify darkenOverlay geometry and styling
    grep -q 'id: darkenOverlay' "$RECT_FILE" || { echo "FAIL: Missing id: darkenOverlay"; exit 1; }
    grep -q 'border.width: Math.max(root.width, root.height)' "$RECT_FILE" || { echo "FAIL: Missing screen-sized border calculation in darkenOverlay"; exit 1; }
    grep -q 'Theme.overlayDarken' "$RECT_FILE" || { echo "FAIL: Missing Theme.overlayDarken color in darkenOverlay"; exit 1; }
    grep -q 'leftMargin: root.regionX - darkenOverlay.border.width' "$RECT_FILE" || { echo "FAIL: Missing leftMargin calculation in darkenOverlay"; exit 1; }
    grep -q 'topMargin: root.regionY - darkenOverlay.border.width' "$RECT_FILE" || { echo "FAIL: Missing topMargin calculation in darkenOverlay"; exit 1; }
    grep -q 'width: root.regionWidth + darkenOverlay.border.width \* 2' "$RECT_FILE" || { echo "FAIL: Missing width calculation in darkenOverlay"; exit 1; }
    grep -q 'height: root.regionHeight + darkenOverlay.border.width \* 2' "$RECT_FILE" || { echo "FAIL: Missing height calculation in darkenOverlay"; exit 1; }
    grep -q 'color: "transparent"' "$RECT_FILE" || { echo "FAIL: darkenOverlay center must be transparent"; exit 1; }

    # Verify selectionBorder geometry and styling
    grep -q 'id: selectionBorder' "$RECT_FILE" || { echo "FAIL: Missing id: selectionBorder"; exit 1; }
    grep -q 'Theme.selectionFill' "$RECT_FILE" || { echo "FAIL: Missing Theme.selectionFill in selectionBorder"; exit 1; }
    grep -q 'Theme.selectionBorder' "$RECT_FILE" || { echo "FAIL: Missing Theme.selectionBorder default in RectCornersSelectionDetails.qml"; exit 1; }
    grep -q 'width: Math.round(root.regionWidth) + borderWidth \* 2' "$RECT_FILE" || { echo "FAIL: Missing width calculation in selectionBorder"; exit 1; }
    grep -q 'height: Math.round(root.regionHeight) + borderWidth \* 2' "$RECT_FILE" || { echo "FAIL: Missing height calculation in selectionBorder"; exit 1; }

    # Verify dimension badge indicator
    grep -q 'visible: root.regionWidth > 10 && root.regionHeight > 10' "$RECT_FILE" || { echo "FAIL: Missing visibility threshold (w > 10 && h > 10) for dimension indicator"; exit 1; }
    grep -q 'top: selectionBorder.bottom' "$RECT_FILE" || { echo "FAIL: Dimension badge must anchor top to selectionBorder.bottom"; exit 1; }
    grep -q 'right: selectionBorder.right' "$RECT_FILE" || { echo "FAIL: Dimension badge must anchor right to selectionBorder.right"; exit 1; }
    grep -q 'StyledText' "$RECT_FILE" || { echo "FAIL: Dimension badge must use StyledText"; exit 1; }
    grep -q '${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}' "$RECT_FILE" || { echo "FAIL: Missing dimension string '${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}'"; exit 1; }

    # Verify crosshair aim lines
    grep -q 'showAimLines' "$RECT_FILE" || { echo "FAIL: Missing showAimLines property in RectCornersSelectionDetails.qml"; exit 1; }
    grep -q 'opacity: 0.3' "$RECT_FILE" || { echo "FAIL: Aim lines must have opacity: 0.3"; exit 1; }
    grep -q 'x: root.mouseX' "$RECT_FILE" || { echo "FAIL: Vertical aim line must track root.mouseX"; exit 1; }
    grep -q 'y: root.mouseY' "$RECT_FILE" || { echo "FAIL: Horizontal aim line must track root.mouseY"; exit 1; }

    echo "PASS: RectCornersSelectionDetails.qml properties, overlays, borders, badge, and aim lines verified"
}

test_cursor_guide_properties() {
    # Verify core properties
    grep -q 'property var action' "$CURSOR_FILE" || { echo "FAIL: Missing property var action in CursorGuide.qml"; exit 1; }
    grep -q 'property bool active' "$CURSOR_FILE" || { echo "FAIL: Missing property bool active in CursorGuide.qml"; exit 1; }
    grep -q 'Behavior on opacity' "$CURSOR_FILE" || { echo "FAIL: Missing smooth opacity Behavior in CursorGuide.qml"; exit 1; }

    # Verify pill badge styling
    grep -q 'Theme.surfaceHigh' "$CURSOR_FILE" || { echo "FAIL: Missing Theme.surfaceHigh background in pill badge"; exit 1; }
    grep -q 'radius: 18' "$CURSOR_FILE" || { echo "FAIL: Pill badge must have radius: 18"; exit 1; }
    grep -q 'border.color: Theme.outline' "$CURSOR_FILE" || { echo "FAIL: Pill badge missing border.color: Theme.outline"; exit 1; }

    # Verify mode descriptions
    local required_descriptions=(
        "Copy region (LMB) or Annotate (RMB)"
        "Annotate region with Swappy"
        "Search with Google Lens"
        "Extract text (OCR)"
    )

    for desc in "${required_descriptions[@]}"; do
        if ! grep -Fq "$desc" "$CURSOR_FILE"; then
            echo "FAIL: Missing mode description '$desc' in CursorGuide.qml"
            exit 1
        fi
    done

    # Verify mode icon names
    local required_icons=(
        "content_cut"
        "edit"
        "search"
        "ocr"
    )

    for icon in "${required_icons[@]}"; do
        if ! grep -Fq "\"$icon\"" "$CURSOR_FILE"; then
            echo "FAIL: Missing icon name '$icon' in CursorGuide.qml"
            exit 1
        fi
    done

    # Verify Icon and StyledText components
    grep -q 'Icon {' "$CURSOR_FILE" || { echo "FAIL: CursorGuide.qml must render an Icon component"; exit 1; }
    grep -q 'StyledText {' "$CURSOR_FILE" || { echo "FAIL: CursorGuide.qml must render a StyledText component"; exit 1; }

    echo "PASS: CursorGuide.qml properties, pill styling, mode mappings, and animations verified"
}

test_composite_integration_lint() {
    local harness_file="$PROJECT_DIR/tests/harness_test_selection_details.qml"

    cat << 'EOF' > "$harness_file"
import QtQuick
import "../theme"
import "../components"
import "../modules/screenshot"
import "../modules/screenshot/regionSelector"

Item {
    id: root
    width: 1920
    height: 1080

    property real regX: 100
    property real regY: 100
    property real regW: 400
    property real regH: 300
    property var action: ScreenshotAction.SnipAction.Copy

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        RectCornersSelectionDetails {
            anchors.fill: parent
            regionX: root.regX
            regionY: root.regY
            regionWidth: root.regW
            regionHeight: root.regH
            mouseX: mouseArea.mouseX
            mouseY: mouseArea.mouseY
        }

        CursorGuide {
            x: mouseArea.mouseX
            y: mouseArea.mouseY
            action: root.action
            active: true
        }
    }
}
EOF

    qmllint "$harness_file" || { echo "FAIL: Composite integration qmllint failed"; rm -f "$harness_file"; exit 1; }
    rm -f "$harness_file"

    echo "PASS: Composite integration QML harness passed qmllint"
}

main() {
    echo "Running Selection Details & Cursor Guide Test Suite..."
    test_files_exist
    test_qmllint_syntax
    test_rect_corners_selection_details_properties
    test_cursor_guide_properties
    test_composite_integration_lint
    echo "All selection details and cursor guide tests passed successfully."
}

main "$@"
