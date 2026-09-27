#!/usr/bin/env bash
set -euo pipefail

BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/omnisnap"

test_executable_bit() {
    if [[ ! -x "$BIN" ]]; then
        echo "FAIL: $BIN is not executable"
        exit 1
    fi
    echo "PASS: test_executable_bit"
}

test_help_flag() {
    "$BIN" --help | grep -q "Omnisnap" || { echo "FAIL: --help did not output Omnisnap banner"; exit 1; }
    "$BIN" -h | grep -q "Usage:" || { echo "FAIL: -h did not output usage"; exit 1; }
    "$BIN" help | grep -q "Usage:" || { echo "FAIL: help did not output usage"; exit 1; }
    echo "PASS: test_help_flag"
}

test_unknown_action() {
    for invalid_arg in "--invalid-arg" "-x" "foobar" "--not-real"; do
        set +e
        err_output=$("$BIN" "$invalid_arg" 2>&1 >/dev/null)
        status=$?
        set -e
        if [[ $status -ne 2 ]]; then
            echo "FAIL: unknown argument '$invalid_arg' should return exit code 2, got $status"
            exit 1
        fi
        if ! echo "$err_output" | grep -q "Unknown argument"; then
            echo "FAIL: unknown argument error message not found in stderr for '$invalid_arg'"
            exit 1
        fi
        if ! echo "$err_output" | grep -q "Usage:"; then
            echo "FAIL: usage instructions not found in stderr for '$invalid_arg'"
            exit 1
        fi
    done
    echo "PASS: test_unknown_action"
}

test_status_when_not_running() {
    # Ensure daemon is stopped
    pkill -f "quickshell.*Omnisnap" >/dev/null 2>&1 || true
    set +e
    out=$("$BIN" status 2>&1)
    status=$?
    set -e
    if [[ $status -ne 1 ]]; then
        echo "FAIL: status should return exit code 1 when not running, got $status"
        exit 1
    fi
    if ! echo "$out" | grep -q "NOT running"; then
        echo "FAIL: status output did not indicate not running"
        exit 1
    fi
    echo "PASS: test_status_when_not_running"
}

test_executable_bit
test_help_flag
test_unknown_action
test_status_when_not_running
echo "All CLI tests passed."
