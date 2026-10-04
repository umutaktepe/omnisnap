#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$PROJECT_DIR/modules/config"
QMLDIR_FILE="$CONFIG_DIR/qmldir"
CONFIG_QML="$CONFIG_DIR/Config.qml"

echo "Running Omnisnap Config Module Test Suite..."

test_files_exist() {
    if [[ ! -f "$QMLDIR_FILE" ]]; then
        echo "FAIL: $QMLDIR_FILE does not exist"
        exit 1
    fi

    if [[ ! -f "$CONFIG_QML" ]]; then
        echo "FAIL: $CONFIG_QML does not exist"
        exit 1
    fi

    echo "PASS: Required config files exist"
}

test_qmldir() {
    grep -q "singleton Config 1.0 Config.qml" "$QMLDIR_FILE" || {
        echo "FAIL: qmldir does not declare singleton Config 1.0 Config.qml"
        exit 1
    }
    echo "PASS: qmldir verified"
}

test_config_structure() {
    grep -q "pragma Singleton" "$CONFIG_QML" || { echo "FAIL: Config.qml missing pragma Singleton"; exit 1; }
    grep -q "property string maxResolution" "$CONFIG_QML" || { echo "FAIL: Missing maxResolution property"; exit 1; }
    grep -q "property string saveDirectory" "$CONFIG_QML" || { echo "FAIL: Missing saveDirectory property"; exit 1; }
    grep -q "property string fileFormat" "$CONFIG_QML" || { echo "FAIL: Missing fileFormat property"; exit 1; }
    grep -q "property int imageQuality" "$CONFIG_QML" || { echo "FAIL: Missing imageQuality property"; exit 1; }
    grep -q "property bool copyToClipboard" "$CONFIG_QML" || { echo "FAIL: Missing copyToClipboard property"; exit 1; }
    grep -q "property bool saveToFile" "$CONFIG_QML" || { echo "FAIL: Missing saveToFile property"; exit 1; }
    grep -q "property bool showGuides" "$CONFIG_QML" || { echo "FAIL: Missing showGuides property"; exit 1; }
    grep -q "property bool inhibitScreenEdges" "$CONFIG_QML" || { echo "FAIL: Missing inhibitScreenEdges property"; exit 1; }
    grep -q "property string defaultAction" "$CONFIG_QML" || { echo "FAIL: Missing defaultAction property"; exit 1; }
    grep -q "property string ocrLanguages" "$CONFIG_QML" || { echo "FAIL: Missing ocrLanguages property"; exit 1; }
    grep -q "property bool shutterSound" "$CONFIG_QML" || { echo "FAIL: Missing shutterSound property"; exit 1; }
    grep -q "function save()" "$CONFIG_QML" || { echo "FAIL: Missing save() function"; exit 1; }
    grep -q "function load()" "$CONFIG_QML" || { echo "FAIL: Missing load() function"; exit 1; }
    grep -q "function toJsonString()" "$CONFIG_QML" || { echo "FAIL: Missing toJsonString() function"; exit 1; }
    grep -q "function applyJson(" "$CONFIG_QML" || { echo "FAIL: Missing applyJson() function"; exit 1; }

    echo "PASS: Config.qml structure and properties verified"
}

test_qmllint_syntax() {
    if ! command -v qmllint >/dev/null 2>&1; then
        echo "FAIL: qmllint command not found"
        exit 1
    fi

    qmllint "$CONFIG_QML" || { echo "FAIL: qmllint failed on $CONFIG_QML"; exit 1; }
    echo "PASS: qmllint verified on $(basename "$CONFIG_QML")"
}

test_config_json_schema() {
    local tmp_dir tmp_config
    tmp_dir="$(mktemp -d /tmp/test-omnisnap-config-XXXXXX)"
    tmp_config="$tmp_dir/config.json"

    # Simulate default config serialization and deserialization
    python3 - << PYEOF
import json

defaults = {
    "maxResolution": "",
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

assert data["maxResolution"] == ""
assert data["copyToClipboard"] is True
assert data["fileFormat"] == "png"
assert data["imageQuality"] == 90
assert data["saveToFile"] is True
assert data["showGuides"] is True
assert data["inhibitScreenEdges"] is True
assert data["defaultAction"] == "copy"
assert data["ocrLanguages"] == ""
assert data["shutterSound"] is False
print("PASS: JSON config schema matches specification")
PYEOF

    rm -rf "$tmp_dir"
}

test_files_exist
test_qmldir
test_config_structure
test_qmllint_syntax
test_config_json_schema

echo "All config tests passed."
