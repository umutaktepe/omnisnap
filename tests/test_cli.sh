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
    "$BIN" --help | grep -q "settings" || { echo "FAIL: --help did not output settings command"; exit 1; }
    "$BIN" --help | grep -q -- "-c, --settings" || { echo "FAIL: --help did not document -c, --settings flags"; exit 1; }
    "$BIN" --help | grep -q "window" || { echo "FAIL: --help did not output window command"; exit 1; }
    "$BIN" --help | grep -q -- "-w, --window" || { echo "FAIL: --help did not document -w, --window flags"; exit 1; }
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

test_screen_edge_recovery_on_start() {
    local test_tmp
    test_tmp=$(mktemp -d /tmp/omnisnap_test_cli_edge_XXXXXX)
    local mock_bin="$test_tmp/bin"
    mkdir -p "$mock_bin"

    local log_file="$test_tmp/edges.log"

    # Mock omnisnap-edges to log arguments
    cat <<EOF > "$mock_bin/omnisnap-edges"
#!/usr/bin/env bash
echo "\$*" >> "$log_file"
EOF
    chmod +x "$mock_bin/omnisnap-edges"

    # Mock quickshell to terminate immediately
    cat <<EOF > "$mock_bin/quickshell"
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$mock_bin/quickshell"

    # Test oneshot invocation (e.g., region)
    PATH="$mock_bin:$PATH" OMNISNAP_PROJECT_DIR="$test_tmp" "$BIN" region >/dev/null 2>&1 || true

    if [[ ! -f "$log_file" ]] || ! grep -q "^recover" "$log_file"; then
        echo "FAIL: bin/omnisnap did not invoke 'omnisnap-edges recover' on oneshot startup"
        rm -rf "$test_tmp"
        exit 1
    fi

    # Reset log file and test daemon invocation
    rm -f "$log_file"
    PATH="$mock_bin:$PATH" OMNISNAP_PROJECT_DIR="$test_tmp" "$BIN" daemon >/dev/null 2>&1 || true

    if [[ ! -f "$log_file" ]] || ! grep -q "^recover" "$log_file"; then
        echo "FAIL: bin/omnisnap did not invoke 'omnisnap-edges recover' on daemon startup"
        rm -rf "$test_tmp"
        exit 1
    fi

    # End-to-end crash recovery test with real omnisnap-edges
    local runtime_dir="$test_tmp/runtime"
    mkdir -p "$runtime_dir/omnisnap"
    local state_file="$runtime_dir/omnisnap/stolen-screen-edges.json"
    cat <<EOF > "$state_file"
{
  "Effect-overview": { "BorderActivate": "9" }
}
EOF

    local saved_test_mode="${OMNISNAP_TEST_MODE:-}"
    local saved_runtime="${XDG_RUNTIME_DIR:-}"
    local saved_config="${XDG_CONFIG_HOME:-}"
    export OMNISNAP_TEST_MODE=1
    export XDG_RUNTIME_DIR="$runtime_dir"
    export XDG_CONFIG_HOME="$test_tmp/config"
    mkdir -p "$test_tmp/config"

    # Ensure no daemon is running that might intercept the command
    pkill -f "quickshell.*$BIN" >/dev/null 2>&1 || true

    PATH="$mock_bin:$PATH" "$BIN" region >/dev/null 2>&1 || true

    # Restore environment variables
    if [[ -n "$saved_test_mode" ]]; then
        export OMNISNAP_TEST_MODE="$saved_test_mode"
    else
        unset OMNISNAP_TEST_MODE
    fi
    if [[ -n "$saved_runtime" ]]; then
        export XDG_RUNTIME_DIR="$saved_runtime"
    else
        unset XDG_RUNTIME_DIR
    fi
    if [[ -n "$saved_config" ]]; then
        export XDG_CONFIG_HOME="$saved_config"
    else
        unset XDG_CONFIG_HOME
    fi

    if [[ -f "$state_file" ]]; then
        echo "FAIL: Stale screen edges state file was not cleaned up by recover on omnisnap start"
        rm -rf "$test_tmp"
        exit 1
    fi

    rm -rf "$test_tmp"
    echo "PASS: test_screen_edge_recovery_on_start"
}

test_settings_subcommands() {
    local test_tmp
    test_tmp=$(mktemp -d /tmp/omnisnap_test_cli_settings_XXXXXX)
    local mock_bin="$test_tmp/bin"
    mkdir -p "$mock_bin"

    local log_qs="$test_tmp/qs.log"
    local log_quickshell="$test_tmp/quickshell.log"

    cat << 'EOF' > "$mock_bin/omnisnap-edges"
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$mock_bin/omnisnap-edges"

    cat << EOF > "$mock_bin/quickshell"
#!/usr/bin/env bash
echo "quickshell init_action=\${OMNISNAP_INITIAL_ACTION:-} args=\$*" >> "$log_quickshell"
exit 0
EOF
    chmod +x "$mock_bin/quickshell"

    cat << EOF > "$mock_bin/qs"
#!/usr/bin/env bash
echo "qs args=\$*" >> "$log_qs"
exit 0
EOF
    chmod +x "$mock_bin/qs"

    # 1. Test oneshot dispatch for all aliases (settings, -c, --settings, config)
    cat << 'EOF' > "$mock_bin/pgrep"
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$mock_bin/pgrep"

    for cmd in settings -c --settings config; do
        rm -f "$log_quickshell"
        PATH="$mock_bin:$PATH" "$BIN" "$cmd" >/dev/null 2>&1 || true
        if [[ ! -f "$log_quickshell" ]] || ! grep -q "init_action=settings" "$log_quickshell"; then
            echo "FAIL: bin/omnisnap '$cmd' did not launch quickshell with OMNISNAP_INITIAL_ACTION=settings in oneshot mode"
            rm -rf "$test_tmp"
            exit 1
        fi
    done

    # 2. Test IPC dispatch when daemon is running
    cat << 'EOF' > "$mock_bin/pgrep"
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$mock_bin/pgrep"

    for cmd in settings -c --settings config; do
        rm -f "$log_qs"
        PATH="$mock_bin:$PATH" "$BIN" "$cmd" >/dev/null 2>&1 || true
        if [[ ! -f "$log_qs" ]] || ! grep -q "ipc call region settings" "$log_qs"; then
            echo "FAIL: bin/omnisnap '$cmd' did not call 'qs ... ipc call region settings' when daemon is running"
            rm -rf "$test_tmp"
            exit 1
        fi
    done

    rm -rf "$test_tmp"
    echo "PASS: test_settings_subcommands"
}

test_window_subcommands() {
    local test_tmp
    test_tmp=$(mktemp -d /tmp/omnisnap_test_cli_window_XXXXXX)
    local mock_bin="$test_tmp/bin"
    mkdir -p "$mock_bin"

    local log_qs="$test_tmp/qs.log"
    local log_quickshell="$test_tmp/quickshell.log"

    cat << 'EOF' > "$mock_bin/omnisnap-edges"
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$mock_bin/omnisnap-edges"

    cat << EOF > "$mock_bin/quickshell"
#!/usr/bin/env bash
echo "quickshell init_action=\${OMNISNAP_INITIAL_ACTION:-} args=\$*" >> "$log_quickshell"
exit 0
EOF
    chmod +x "$mock_bin/quickshell"

    cat << EOF > "$mock_bin/qs"
#!/usr/bin/env bash
echo "qs args=\$*" >> "$log_qs"
exit 0
EOF
    chmod +x "$mock_bin/qs"

    # 1. Test oneshot dispatch for all window aliases (window, -w, --window, active)
    cat << 'EOF' > "$mock_bin/pgrep"
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$mock_bin/pgrep"

    for cmd in window -w --window active; do
        rm -f "$log_quickshell"
        PATH="$mock_bin:$PATH" "$BIN" "$cmd" >/dev/null 2>&1 || true
        if [[ ! -f "$log_quickshell" ]] || ! grep -q "init_action=window" "$log_quickshell"; then
            echo "FAIL: bin/omnisnap '$cmd' did not launch quickshell with OMNISNAP_INITIAL_ACTION=window in oneshot mode"
            rm -rf "$test_tmp"
            exit 1
        fi
    done

    # 2. Test IPC dispatch when daemon is running
    cat << 'EOF' > "$mock_bin/pgrep"
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$mock_bin/pgrep"

    for cmd in window -w --window active; do
        rm -f "$log_qs"
        PATH="$mock_bin:$PATH" "$BIN" "$cmd" >/dev/null 2>&1 || true
        if [[ ! -f "$log_qs" ]] || ! grep -q "ipc call region window" "$log_qs"; then
            echo "FAIL: bin/omnisnap '$cmd' did not call 'qs ... ipc call region window' when daemon is running"
            rm -rf "$test_tmp"
            exit 1
        fi
    done

    rm -rf "$test_tmp"
    echo "PASS: test_window_subcommands"
}

test_executable_bit
test_help_flag
test_unknown_action
test_status_when_not_running
test_screen_edge_recovery_on_start
test_settings_subcommands
test_window_subcommands
echo "All CLI tests passed."
