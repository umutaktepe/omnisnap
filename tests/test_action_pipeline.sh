#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QML_FILE="$PROJECT_DIR/modules/screenshot/ScreenshotAction.qml"
export QML_FILE

test_imagemagick_crop() {
    local tmp_img out_img width height
    tmp_img="$(mktemp /tmp/test-omnisnap-XXXXXX.png)"
    out_img="$(mktemp /tmp/test-cropped-XXXXXX.png)"

    # Generate a 200x200 canvas
    magick -size 200x200 xc:blue "$tmp_img"

    # Crop a 50x50 box from +10+10
    magick "$tmp_img" -crop 50x50+10+10 +repage "$out_img"

    width=$(identify -format "%w" "$out_img")
    height=$(identify -format "%h" "$out_img")

    rm -f "$tmp_img" "$out_img"

    if [[ "$width" -eq 50 && "$height" -eq 50 ]]; then
        echo "PASS: ImageMagick crop pipeline verified (50x50)"
    else
        echo "FAIL: Expected 50x50, got ${width}x${height}"
        exit 1
    fi
}

test_qml_structure_and_lint() {
    if [[ ! -f "$QML_FILE" ]]; then
        echo "FAIL: $QML_FILE not found"
        exit 1
    fi

    # Check singleton declaration
    grep -q "pragma Singleton" "$QML_FILE" || { echo "FAIL: Missing 'pragma Singleton' in $QML_FILE"; exit 1; }
    grep -q "import QtQuick" "$QML_FILE" || { echo "FAIL: Missing 'import QtQuick' in $QML_FILE"; exit 1; }
    grep -q "QtObject" "$QML_FILE" || { echo "FAIL: Missing 'QtObject' in $QML_FILE"; exit 1; }

    # Check SnipAction enum and required actions
    grep -q "enum SnipAction" "$QML_FILE" || { echo "FAIL: Missing 'enum SnipAction' in $QML_FILE"; exit 1; }
    grep -q "Copy," "$QML_FILE" || { echo "FAIL: Missing 'Copy' in SnipAction"; exit 1; }
    grep -q "Edit," "$QML_FILE" || { echo "FAIL: Missing 'Edit' in SnipAction"; exit 1; }
    grep -q "Search," "$QML_FILE" || { echo "FAIL: Missing 'Search' in SnipAction"; exit 1; }
    grep -q "CharRecognition" "$QML_FILE" || { echo "FAIL: Missing 'CharRecognition' in SnipAction"; exit 1; }

    # Check required functions
    grep -q "function escapeShellStr" "$QML_FILE" || { echo "FAIL: Missing escapeShellStr function"; exit 1; }
    grep -q "function getScript" "$QML_FILE" || { echo "FAIL: Missing getScript function"; exit 1; }
    grep -q "function getCommand" "$QML_FILE" || { echo "FAIL: Missing getCommand function"; exit 1; }

    # Verify QML syntax using qmllint if installed
    if command -v qmllint >/dev/null 2>&1; then
        qmllint "$QML_FILE" || { echo "FAIL: qmllint failed on $QML_FILE"; exit 1; }
        echo "PASS: qmllint verified on $QML_FILE"
    fi

    echo "PASS: QML singleton structure verified"
}

test_action_scripts_bash_syntax() {
    python3 - << 'PYEOF'
import sys, os, subprocess

qml_path = os.environ.get("QML_FILE", "modules/screenshot/ScreenshotAction.qml")
if not os.path.exists(qml_path):
    print(f"FAIL: {qml_path} does not exist")
    sys.exit(1)

with open(qml_path, "r", encoding="utf-8") as f:
    content = f.read()

# Verify key actions are implemented
assert "ScreenshotAction.SnipAction.Copy" in content, "Missing Copy case in getScript"
assert "ScreenshotAction.SnipAction.Edit" in content, "Missing Edit case in getScript"
assert "ScreenshotAction.SnipAction.Search" in content, "Missing Search case in getScript"
assert "ScreenshotAction.SnipAction.CharRecognition" in content, "Missing CharRecognition case in getScript"
assert 'wl-copy -t image/png < "$saveFile";' in content, "Missing wl-copy in Copy case"
assert ') &' in content, "Missing asynchronous subshell ') &' in ScreenshotAction.qml"

def escapeShellStr(s):
    if not s: return "''"
    return s.replace("'", "'\\''")

actions = ["Copy", "Edit", "Search", "CharRecognition"]
x, y, w, h = 10, 20, 100, 200
screenshotPath = "/tmp/test-screen.png"
rx, ry, rw, rh = x, y, w, h
cropBase = f"magick '{escapeShellStr(screenshotPath)}' -crop {rw}x{rh}+{rx}+{ry} +repage"
cleanup = f"rm -f '{escapeShellStr(screenshotPath)}'"
targetDir = "~/Pictures/Screenshots"
fileUploadApiEndpoint = "https://uguu.se/upload"
lensBaseUrl = "https://lens.google.com/uploadbyurl?url="

for action in actions:
    if action == "Copy":
        script = (
            f"set -euo pipefail; "
            f"SAVE_DIR='{escapeShellStr(targetDir)}'; "
            f'SAVE_DIR="${{SAVE_DIR/#\\~/$HOME}}"; '
            f'mkdir -p "$SAVE_DIR" && '
            f'saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && '
            f'{cropBase} "$saveFile" && '
            f'wl-copy -t image/png < "$saveFile"; '
            f'( '
            f'ACTION=$(notify-send "Screenshot Captured" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" --action="open=Open" --action="folder=Open Folder" 2>/dev/null || true); '
            f'if [ "$ACTION" = "open" ]; then xdg-open "$saveFile"; elif [ "$ACTION" = "folder" ]; then xdg-open "$SAVE_DIR"; fi '
            f') & '
            f'{cleanup}'
        )
    elif action == "Edit":
        script = (
            f"set -euo pipefail; "
            f"SAVE_DIR='{escapeShellStr(targetDir)}'; "
            f'SAVE_DIR="${{SAVE_DIR/#\\~/$HOME}}"; '
            f'mkdir -p "$SAVE_DIR" && '
            f'saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && '
            f'TMPF=$(mktemp /tmp/omnisnap-edit-XXXXXX.png); '
            f'{cropBase} "$TMPF" && '
            f'swappy -f "$TMPF" -o "$saveFile" || true; '
            f'if [ -s "$saveFile" ]; then '
            f'    wl-copy -t image/png < "$saveFile"; '
            f'    notify-send "Screenshot Edited" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" 2>/dev/null || true; '
            f'fi; '
            f'rm -f "$TMPF"; {cleanup}'
        )
    elif action == "Search":
        script = (
            f"set -euo pipefail; "
            f'TMPF=$(mktemp /tmp/omnisnap-search-XXXXXX.png); '
            f'{cropBase} "$TMPF" && '
            f"UPLOAD_URL=$(curl -sF files[]=@\"$TMPF\" '{fileUploadApiEndpoint}' | jq -r '.files[0].url' 2>/dev/null || true); "
            f'if [ -n "$UPLOAD_URL" ] && [ "$UPLOAD_URL" != "null" ]; then '
            f'    xdg-open "{lensBaseUrl}$UPLOAD_URL"; '
            f'else '
            f'    notify-send -u critical "Search Failed" "Could not upload screenshot for image search." -a "Omnisnap" 2>/dev/null || true; '
            f'fi; '
            f'rm -f "$TMPF"; {cleanup}'
        )
    elif action == "CharRecognition":
        script = (
            f"set -euo pipefail; "
            f'TMPF=$(mktemp /tmp/omnisnap-ocr-XXXXXX.png); '
            f'{cropBase} -colorspace gray -type grayscale -contrast-stretch 0 -resize 300% "$TMPF" && '
            f'LANGS=$(tesseract --list-langs 2>/dev/null | awk \'NR>1 && $1!="osd" {{print $1}}\' | tr \'\\n\' \'+\' | sed \'s/\\+$//\'); '
            f'if [ -n "$LANGS" ]; then '
            f'    TEXT=$(tesseract "$TMPF" stdout -l "$LANGS" 2>/dev/null || true); '
            f'else '
            f'    TEXT=$(tesseract "$TMPF" stdout 2>/dev/null || true); '
            f'fi; '
            f'if [ -n "$TEXT" ]; then '
            f'    printf "%s" "$TEXT" | wl-copy; '
            f'    notify-send "Text Recognized" "$TEXT" -a "Omnisnap" 2>/dev/null || true; '
            f'else '
            f'    notify-send "OCR Finished" "No text detected in selected region." -a "Omnisnap" 2>/dev/null || true; '
            f'fi; '
            f'rm -f "$TMPF"; {cleanup}'
        )

    res = subprocess.run(["bash", "-n", "-c", script], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        print(f"FAIL: Action {action} script syntax error: {res.stderr}")
        sys.exit(1)

print("PASS: All action scripts passed bash syntax verification")
PYEOF
    echo "PASS: Action script syntax tests passed"
}

test_ocr_preprocessing() {
    local tmp_txt_img tmp_ocr_prep ocr_result
    tmp_txt_img="$(mktemp /tmp/test-ocr-orig-XXXXXX.png)"
    tmp_ocr_prep="$(mktemp /tmp/test-ocr-prep-XXXXXX.png)"

    # Render known text into image
    magick -size 320x80 xc:white -fill black -pointsize 32 -gravity center -annotate +0+0 "OMNISNAP" "$tmp_txt_img"

    # Preprocess using exact CharRecognition flags
    magick "$tmp_txt_img" -colorspace gray -type grayscale -contrast-stretch 0 -resize 300% "$tmp_ocr_prep"

    ocr_result="$(tesseract "$tmp_ocr_prep" stdout 2>/dev/null || true)"
    rm -f "$tmp_txt_img" "$tmp_ocr_prep"

    if echo "$ocr_result" | grep -qi "OMNISNAP"; then
        echo "PASS: OCR preprocessing and text recognition verified ($ocr_result)"
    else
        echo "FAIL: Tesseract failed to recognize OMNISNAP, got: $ocr_result"
        exit 1
    fi
}

test_copy_action_async_execution() {
    # Verify ScreenshotAction.qml structure for asynchronous notification subshell
    if ! grep -q 'wl-copy -t image/png < "$saveFile";' "$QML_FILE"; then
        echo "FAIL: Copy action in $QML_FILE must run wl-copy synchronously before notification subshell"
        exit 1
    fi

    if ! grep -q ') &' "$QML_FILE"; then
        echo "FAIL: Copy action in $QML_FILE must launch notification subshell in background using ') &'"
        exit 1
    fi

    # Set up mock binaries to test non-blocking execution
    local mock_bin_dir tmp_dir test_img
    mock_bin_dir="$(mktemp -d /tmp/test-omnisnap-bin-XXXXXX)"
    tmp_dir="$(mktemp -d /tmp/test-omnisnap-data-XXXXXX)"
    test_img="$tmp_dir/test-screen.png"
    magick -size 80x80 xc:green "$test_img"

    # Mock notify-send that simulates user deliberation / notification delay
    cat << 'EOF' > "$mock_bin_dir/notify-send"
#!/bin/bash
sleep 2
echo "open"
EOF
    chmod +x "$mock_bin_dir/notify-send"

    # Mock wl-copy that records timestamp and payload
    cat << 'EOF' > "$mock_bin_dir/wl-copy"
#!/bin/bash
cat > "$TMPDIR_MOCK/clipboard.png"
date +%s%N > "$TMPDIR_MOCK/copied.ts"
EOF
    chmod +x "$mock_bin_dir/wl-copy"

    # Mock xdg-open
    cat << 'EOF' > "$mock_bin_dir/xdg-open"
#!/bin/bash
echo "$@" >> "$TMPDIR_MOCK/opened.log"
EOF
    chmod +x "$mock_bin_dir/xdg-open"

    export TMPDIR_MOCK="$tmp_dir"

    # Execute the copy pipeline script with mock binaries in PATH
    local start_ns end_ns elapsed_ms
    start_ns=$(date +%s%N)

    PATH="$mock_bin_dir:$PATH" bash -c "
        set -euo pipefail;
        SAVE_DIR='$tmp_dir/Screenshots';
        SAVE_DIR=\"\${SAVE_DIR/#\\~/\$HOME}\";
        mkdir -p \"\$SAVE_DIR\" &&
        saveFile=\"\$SAVE_DIR/screenshot-\$(date +%Y-%m-%d_%H.%M.%S).png\" &&
        magick '$test_img' -crop 50x50+10+10 +repage \"\$saveFile\" &&
        wl-copy -t image/png < \"\$saveFile\";
        (
            ACTION=\$(notify-send \"Screenshot Captured\" \"Saved to \$saveFile\" -i \"\$saveFile\" -a \"Omnisnap\" --action=\"open=Open\" --action=\"folder=Open Folder\" 2>/dev/null || true);
            if [ \"\$ACTION\" = \"open\" ]; then xdg-open \"\$saveFile\"; elif [ \"\$ACTION\" = \"folder\" ]; then xdg-open \"\$SAVE_DIR\"; fi
        ) &
        rm -f '$test_img'
    "
    end_ns=$(date +%s%N)
    elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))

    # 1. Verify wl-copy ran immediately
    if [[ ! -f "$tmp_dir/copied.ts" ]]; then
        echo "FAIL: wl-copy was not executed"
        rm -rf "$mock_bin_dir" "$tmp_dir"
        exit 1
    fi

    # 2. Verify screenshot file was saved and non-empty
    local saved_count
    saved_count=$(find "$tmp_dir/Screenshots" -type f -name "screenshot-*.png" -size +0c | wc -l)
    if [[ "$saved_count" -ne 1 ]]; then
        echo "FAIL: Saved screenshot file not found or empty in $tmp_dir/Screenshots"
        rm -rf "$mock_bin_dir" "$tmp_dir"
        exit 1
    fi

    # 3. Verify original screenshot was cleaned up
    if [[ -f "$test_img" ]]; then
        echo "FAIL: Original screenshot was not cleaned up"
        rm -rf "$mock_bin_dir" "$tmp_dir"
        exit 1
    fi

    # 4. Verify the script did NOT block waiting for notify-send (notify-send sleeps 2000ms)
    if [[ "$elapsed_ms" -ge 1500 ]]; then
        echo "FAIL: Copy pipeline blocked on notify-send! Elapsed: ${elapsed_ms}ms (expected < 1500ms)"
        rm -rf "$mock_bin_dir" "$tmp_dir"
        exit 1
    fi

    echo "PASS: Copy action non-blocking notification subshell verified (completed in ${elapsed_ms}ms, notify-send delayed 2000ms)"
    rm -rf "$mock_bin_dir" "$tmp_dir"
}

test_imagemagick_crop
test_qml_structure_and_lint
test_action_scripts_bash_syntax
test_copy_action_async_execution
test_ocr_preprocessing

echo "All action pipeline tests passed."
