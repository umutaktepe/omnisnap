#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

THEME_DIR="$PROJECT_DIR/theme"
COMPONENTS_DIR="$PROJECT_DIR/components"

test_files_exist() {
    local files=(
        "$THEME_DIR/Theme.qml"
        "$THEME_DIR/qmldir"
        "$COMPONENTS_DIR/StyledText.qml"
        "$COMPONENTS_DIR/Icon.qml"
        "$COMPONENTS_DIR/IconButton.qml"
        "$COMPONENTS_DIR/Tooltip.qml"
        "$COMPONENTS_DIR/qmldir"
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
        "$THEME_DIR/Theme.qml"
        "$COMPONENTS_DIR/StyledText.qml"
        "$COMPONENTS_DIR/Icon.qml"
        "$COMPONENTS_DIR/IconButton.qml"
        "$COMPONENTS_DIR/Tooltip.qml"
    )

    for qml in "${qml_files[@]}"; do
        qmllint "$qml" || { echo "FAIL: qmllint failed on $qml"; exit 1; }
        echo "PASS: qmllint verified on $(basename "$qml")"
    done
}

test_theme_palette_properties() {
    local theme_file="$THEME_DIR/Theme.qml"

    grep -q "pragma Singleton" "$theme_file" || { echo "FAIL: Missing 'pragma Singleton' in Theme.qml"; exit 1; }
    grep -q "import QtQuick" "$theme_file" || { echo "FAIL: Missing 'import QtQuick' in Theme.qml"; exit 1; }
    grep -q "QtObject" "$theme_file" || { echo "FAIL: Missing 'QtObject' in Theme.qml"; exit 1; }

    local required_props=(
        'background: "#1e1e2e"'
        'surface: "#28283d"'
        'surfaceHigh: "#313244"'
        'primary: "#89b4fa"'
        'onPrimary: "#11111b"'
        'secondary: "#b4befe"'
        'onSecondary: "#11111b"'
        'outline: "#45475a"'
        'outlineVariant: "#585b70"'
        'text: "#cdd6f4"'
        'textMuted: "#a6adc8"'
        'overlayDarken: Qt.rgba(0, 0, 0, 0.6)'
        'selectionBorder: "#89b4fa"'
        'selectionFill: Qt.rgba(137 / 255, 180 / 255, 250 / 255, 0.15)'
    )

    for prop in "${required_props[@]}"; do
        if ! grep -Fq "$prop" "$theme_file"; then
            echo "FAIL: Missing property '$prop' in Theme.qml"
            exit 1
        fi
    done

    grep -q "singleton Theme 1.0 Theme.qml" "$THEME_DIR/qmldir" || { echo "FAIL: Theme singleton missing from theme/qmldir"; exit 1; }

    echo "PASS: Theme.qml palette properties and singleton structure verified"
}

test_styled_text_properties() {
    local text_file="$COMPONENTS_DIR/StyledText.qml"

    grep -q 'Theme.text' "$text_file" || { echo "FAIL: StyledText missing Theme.text color"; exit 1; }
    grep -q 'font.family: "Noto Sans, Inter, Roboto, sans-serif"' "$text_file" || { echo "FAIL: StyledText missing required font family"; exit 1; }
    grep -q 'font.pixelSize: 13' "$text_file" || { echo "FAIL: StyledText missing font.pixelSize: 13"; exit 1; }
    grep -q 'renderType: Text.NativeRendering' "$text_file" || { echo "FAIL: StyledText missing Text.NativeRendering"; exit 1; }

    echo "PASS: StyledText.qml properties and native rendering verified"
}

test_icon_mapping() {
    local icon_file="$COMPONENTS_DIR/Icon.qml"

    grep -q 'import Quickshell.Widgets' "$icon_file" || { echo "FAIL: Icon.qml missing import Quickshell.Widgets"; exit 1; }
    grep -q 'IconImage' "$icon_file" || { echo "FAIL: Icon.qml does not use IconImage"; exit 1; }
    grep -q 'Quickshell.iconPath' "$icon_file" || { echo "FAIL: Icon.qml does not use Quickshell.iconPath"; exit 1; }

    local required_icons=(
        "screenshot"
        "content_cut"
        "edit"
        "brush"
        "search"
        "image_search"
        "ocr"
        "text_fields"
        "fullscreen"
        "check"
        "close"
    )

    for icon_name in "${required_icons[@]}"; do
        if ! grep -q "\"$icon_name\"" "$icon_file"; then
            echo "FAIL: Missing icon mapping for '$icon_name' in Icon.qml"
            exit 1
        fi
    done

    echo "PASS: Icon.qml maps all 11 required system icons and uses Quickshell.Widgets IconImage"
}

test_icon_button_properties() {
    local btn_file="$COMPONENTS_DIR/IconButton.qml"

    grep -q 'signal clicked' "$btn_file" || { echo "FAIL: IconButton missing clicked signal"; exit 1; }
    grep -q 'hovered' "$btn_file" || { echo "FAIL: IconButton missing hovered state"; exit 1; }
    grep -q 'cursorShape: Qt.PointingHandCursor' "$btn_file" || { echo "FAIL: IconButton missing pointing hand cursor"; exit 1; }
    grep -q 'radius:' "$btn_file" || { echo "FAIL: IconButton missing radius property for round/rounded rectangle"; exit 1; }
    grep -q 'Icon {' "$btn_file" || { echo "FAIL: IconButton does not embed Icon component"; exit 1; }

    echo "PASS: IconButton.qml properties (hover, cursor, clicked, radius) verified"
}

test_tooltip_properties() {
    local tip_file="$COMPONENTS_DIR/Tooltip.qml"

    grep -q 'property Item target' "$tip_file" || { echo "FAIL: Tooltip missing target property"; exit 1; }
    grep -q 'anchors.bottom:' "$tip_file" || { echo "FAIL: Tooltip not positioned above target"; exit 1; }
    grep -q 'opacity' "$tip_file" || { echo "FAIL: Tooltip missing opacity property"; exit 1; }
    grep -q 'Behavior on opacity' "$tip_file" || { echo "FAIL: Tooltip missing smooth opacity transition"; exit 1; }

    echo "PASS: Tooltip.qml properties (positioning, target, fade) verified"
}

test_composite_integration_lint() {
    local tmp_qml
    tmp_qml="$(mktemp /tmp/test-components-XXXXXX.qml)"

    cat << 'EOF' > "$tmp_qml"
import QtQuick
import "../theme"
import "../components"

Item {
    width: 400
    height: 300

    StyledText {
        text: "Screenshot Options"
        font.pixelSize: 14
    }

    Row {
        spacing: 8

        IconButton {
            id: copyBtn
            icon: "content_cut"
            round: true
            onClicked: {}

            Tooltip {
                target: copyBtn
                text: "Copy Screenshot"
            }
        }

        IconButton {
            id: searchBtn
            icon: "image_search"
            isToggle: true
            checked: true
            onClicked: {}

            Tooltip {
                target: searchBtn
                text: "Search with Google Lens"
            }
        }

        IconButton {
            id: ocrBtn
            icon: "ocr"
            onClicked: {}

            Tooltip {
                target: ocrBtn
                text: "Extract Text"
            }
        }

        IconButton {
            id: closeBtn
            icon: "close"
            onClicked: {}

            Tooltip {
                target: closeBtn
                text: "Close"
            }
        }
    }
}
EOF

    # Place in a directory next to theme and components so relative paths resolve cleanly
    local harness_file="$PROJECT_DIR/tests/harness_test_components.qml"
    cp "$tmp_qml" "$harness_file"
    rm -f "$tmp_qml"

    qmllint "$harness_file" || { echo "FAIL: Composite integration qmllint failed"; rm -f "$harness_file"; exit 1; }
    rm -f "$harness_file"

    echo "PASS: Composite integration QML harness passed qmllint"
}

main() {
    echo "Running Component & Theme Test Suite..."
    test_files_exist
    test_qmllint_syntax
    test_theme_palette_properties
    test_styled_text_properties
    test_icon_mapping
    test_icon_button_properties
    test_tooltip_properties
    test_composite_integration_lint
    echo "All theme and component tests passed successfully."
}

main "$@"
