#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS_DIR="$PROJECT_DIR/modules/settings"
QMLDIR_FILE="$SETTINGS_DIR/qmldir"
SETTINGS_QML="$SETTINGS_DIR/SettingsWindow.qml"

echo "Running Omnisnap Settings Window Syntax & Integration Test Suite..."

test_files_exist() {
    if [[ ! -f "$QMLDIR_FILE" ]]; then
        echo "FAIL: $QMLDIR_FILE does not exist"
        exit 1
    fi

    if [[ ! -f "$SETTINGS_QML" ]]; then
        echo "FAIL: $SETTINGS_QML does not exist"
        exit 1
    fi

    echo "PASS: Required settings files exist"
}

test_qmldir() {
    grep -q "SettingsWindow 1.0 SettingsWindow.qml" "$QMLDIR_FILE" || {
        echo "FAIL: qmldir does not declare SettingsWindow 1.0 SettingsWindow.qml"
        exit 1
    }
    echo "PASS: Settings qmldir verified"
}

test_settings_structure() {
    grep -q "FloatingWindow" "$SETTINGS_QML" || { echo "FAIL: SettingsWindow must use FloatingWindow"; exit 1; }
    grep -q "Config.save()" "$SETTINGS_QML" || { echo "FAIL: SettingsWindow must call Config.save()"; exit 1; }
    grep -q "1920x1080>" "$SETTINGS_QML" || { echo "FAIL: Missing 1920x1080> resolution option"; exit 1; }
    grep -q "2560x1440>" "$SETTINGS_QML" || { echo "FAIL: Missing 2560x1440> resolution option"; exit 1; }
    grep -q "1280x720>" "$SETTINGS_QML" || { echo "FAIL: Missing 1280x720> resolution option"; exit 1; }
    grep -q "copyToClipboard" "$SETTINGS_QML" || { echo "FAIL: Missing copyToClipboard binding"; exit 1; }
    grep -q "saveToFile" "$SETTINGS_QML" || { echo "FAIL: Missing saveToFile binding"; exit 1; }
    grep -q "showGuides" "$SETTINGS_QML" || { echo "FAIL: Missing showGuides binding"; exit 1; }
    grep -q "inhibitScreenEdges" "$SETTINGS_QML" || { echo "FAIL: Missing inhibitScreenEdges binding"; exit 1; }
    grep -q "shutterSound" "$SETTINGS_QML" || { echo "FAIL: Missing shutterSound binding"; exit 1; }
    grep -q "ocrLanguages" "$SETTINGS_QML" || { echo "FAIL: Missing ocrLanguages binding"; exit 1; }
    grep -q "Escape" "$SETTINGS_QML" || { echo "FAIL: Missing Escape key handling"; exit 1; }

    echo "PASS: SettingsWindow structure and configuration bindings verified"
}

test_qmllint_syntax() {
    if ! command -v qmllint >/dev/null 2>&1; then
        echo "FAIL: qmllint command not found"
        exit 1
    fi

    qmllint -I "$PROJECT_DIR/theme" -I "$PROJECT_DIR/components" -I "$PROJECT_DIR/modules/config" "$SETTINGS_QML" || {
        echo "FAIL: qmllint failed on $SETTINGS_QML"
        exit 1
    }
    echo "PASS: qmllint verified on $(basename "$SETTINGS_QML")"
}

test_files_exist
test_qmldir
test_settings_structure
test_qmllint_syntax

echo "All settings window tests passed successfully."
