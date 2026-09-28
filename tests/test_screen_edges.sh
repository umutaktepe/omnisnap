#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EDGES_BIN="$PROJECT_DIR/bin/omnisnap-edges"

test_executable_exists() {
    if [[ ! -x "$EDGES_BIN" ]]; then
        echo "FAIL: $EDGES_BIN is not executable or does not exist"
        exit 1
    fi
    echo "PASS: $EDGES_BIN exists and is executable"
}

test_help_and_subcommands() {
    "$EDGES_BIN" --help | grep -q "inhibit" || { echo "FAIL: Missing inhibit command in help"; exit 1; }
    "$EDGES_BIN" --help | grep -q "restore" || { echo "FAIL: Missing restore command in help"; exit 1; }
    "$EDGES_BIN" --help | grep -q "recover" || { echo "FAIL: Missing recover command in help"; exit 1; }
    echo "PASS: Subcommands and help output verified"
}

test_state_backup_and_restore() {
    export OMNISNAP_TEST_MODE=1
    local test_runtime_dir
    test_runtime_dir="$(mktemp -d /tmp/omnisnap-test-runtime-XXXXXX)"
    export XDG_RUNTIME_DIR="$test_runtime_dir"
    local test_config_dir="$test_runtime_dir/config"
    mkdir -p "$test_config_dir"
    export XDG_CONFIG_HOME="$test_config_dir"
    local state_file="$test_runtime_dir/omnisnap/stolen-screen-edges.json"

    # Run inhibit
    "$EDGES_BIN" inhibit
    if [[ ! -f "$state_file" ]]; then
        echo "FAIL: Expected state file $state_file was not created"
        rm -rf "$test_runtime_dir"
        exit 1
    fi

    # Verify JSON content is valid
    jq . "$state_file" >/dev/null 2>&1 || {
        echo "FAIL: State file $state_file is not valid JSON"
        rm -rf "$test_runtime_dir"
        exit 1
    }

    # Run restore
    "$EDGES_BIN" restore
    if [[ -f "$state_file" ]]; then
        echo "FAIL: State file $state_file should be removed after restore"
        rm -rf "$test_runtime_dir"
        exit 1
    fi

    # Run restore again when no state file exists (should exit cleanly 0)
    "$EDGES_BIN" restore

    # Test recover subcommand
    "$EDGES_BIN" inhibit
    if [[ ! -f "$state_file" ]]; then
        echo "FAIL: State file $state_file not created for recover test"
        rm -rf "$test_runtime_dir"
        exit 1
    fi

    "$EDGES_BIN" recover
    if [[ -f "$state_file" ]]; then
        echo "FAIL: State file $state_file should be removed after recover"
        rm -rf "$test_runtime_dir"
        exit 1
    fi

    rm -rf "$test_runtime_dir"
    echo "PASS: State backup, restore, and recover cycle verified"
}

test_executable_exists
test_help_and_subcommands
test_state_backup_and_restore

echo "All screen edge inhibitor tests passed."
