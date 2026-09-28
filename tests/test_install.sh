#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Running Installation and Desktop Integration Test Suite..."

TEST_TMPDIR=$(mktemp -d /tmp/omnisnap_test_install_XXXXXX)
cleanup() {
    rm -rf "$TEST_TMPDIR"
}
trap cleanup EXIT

BIN_TARGET="$TEST_TMPDIR/bin"
DESKTOP_TARGET="$TEST_TMPDIR/share/applications"

export OMNISNAP_BIN_TARGET="$BIN_TARGET"
export OMNISNAP_DESKTOP_TARGET="$DESKTOP_TARGET"

test_installer_execution() {
    echo "Testing install.sh execution..."
    "$REPO_DIR/install.sh"
    echo "PASS: install.sh executed with return code 0"
}

test_bin_symlink() {
    echo "Testing binary symlink in BIN_TARGET..."
    local symlink="$BIN_TARGET/omnisnap"

    if [[ ! -e "$symlink" ]]; then
        echo "FAIL: $symlink does not exist"
        exit 1
    fi

    if [[ ! -L "$symlink" ]]; then
        echo "FAIL: $symlink is not a symbolic link"
        exit 1
    fi

    if [[ ! -x "$symlink" ]]; then
        echo "FAIL: $symlink is not executable"
        exit 1
    fi

    local resolved_target
    resolved_target="$(readlink -f "$symlink")"
    local expected_target
    expected_target="$(readlink -f "$REPO_DIR/bin/omnisnap")"

    if [[ "$resolved_target" != "$expected_target" ]]; then
        echo "FAIL: Symlink target mismatch: $resolved_target != $expected_target"
        exit 1
    fi

    echo "PASS: Binary symlink verified ($symlink -> $resolved_target)"
}

test_desktop_entry() {
    echo "Testing desktop entry in DESKTOP_TARGET..."
    local desktop_file="$DESKTOP_TARGET/omnisnap.desktop"

    if [[ ! -f "$desktop_file" ]]; then
        echo "FAIL: $desktop_file does not exist"
        exit 1
    fi

    grep -q "^\[Desktop Entry\]" "$desktop_file" || {
        echo "FAIL: Missing [Desktop Entry] section in $desktop_file"
        exit 1
    }

    grep -q "^Name=Omnisnap" "$desktop_file" || {
        echo "FAIL: Missing Name=Omnisnap in $desktop_file"
        exit 1
    }

    grep -q "^Type=Application" "$desktop_file" || {
        echo "FAIL: Missing Type=Application in $desktop_file"
        exit 1
    }

    grep -q "^Categories=Utility;Graphics;" "$desktop_file" || {
        echo "FAIL: Missing Categories in $desktop_file"
        exit 1
    }

    local expected_exec="Exec=$BIN_TARGET/omnisnap region"
    if ! grep -q "^$expected_exec$" "$desktop_file"; then
        echo "FAIL: Missing expected Exec line '$expected_exec' in $desktop_file"
        exit 1
    fi

    if command -v desktop-file-validate >/dev/null 2>&1; then
        desktop-file-validate "$desktop_file"
        echo "PASS: desktop-file-validate passed"
    fi

    echo "PASS: Desktop file structure and Exec path verified"
}

test_cli_via_symlink() {
    echo "Testing CLI invocation via installed symlink..."
    local symlink="$BIN_TARGET/omnisnap"

    local help_out
    help_out=$("$symlink" --help)

    if ! echo "$help_out" | grep -q "Omnisnap"; then
        echo "FAIL: Help output missing Omnisnap banner"
        exit 1
    fi

    if ! echo "$help_out" | grep -q "Usage:"; then
        echo "FAIL: Help output missing Usage information"
        exit 1
    fi

    echo "PASS: CLI executed successfully via installed symlink"
}

test_regression_suites() {
    echo "Running complete project regression test suites..."
    local suites=(
        "$SCRIPT_DIR/test_cli.sh"
        "$SCRIPT_DIR/test_action_pipeline.sh"
        "$SCRIPT_DIR/test_components.sh"
        "$SCRIPT_DIR/test_selection_details.sh"
        "$SCRIPT_DIR/test_toolbar.sh"
        "$SCRIPT_DIR/test_region_selection.sh"
        "$SCRIPT_DIR/test_quickshell_syntax.sh"
    )

    for suite in "${suites[@]}"; do
        if [[ ! -f "$suite" ]]; then
            echo "FAIL: Regression test suite $suite not found"
            exit 1
        fi
        echo "--- Running $(basename "$suite") ---"
        bash "$suite"
        echo "PASS: $(basename "$suite")"
    done

    echo "PASS: All project regression test suites passed successfully"
}

test_installer_execution
test_bin_symlink
test_desktop_entry
test_cli_via_symlink
test_regression_suites

echo "All installation and desktop integration tests passed successfully!"
