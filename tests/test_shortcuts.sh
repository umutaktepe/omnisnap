#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SHORTCUTS_BIN="$PROJECT_DIR/bin/omnisnap-shortcuts"
DESKTOP_SRC="$PROJECT_DIR/omnisnap.desktop"

echo "Running Omnisnap Shortcut Automation & Sync Test Suite..."

test_files_exist() {
    if [[ ! -f "$SHORTCUTS_BIN" ]]; then
        echo "FAIL: $SHORTCUTS_BIN does not exist"
        exit 1
    fi

    if [[ ! -x "$SHORTCUTS_BIN" ]]; then
        echo "FAIL: $SHORTCUTS_BIN is not executable"
        exit 1
    fi

    if [[ ! -f "$DESKTOP_SRC" ]]; then
        echo "FAIL: $DESKTOP_SRC does not exist"
        exit 1
    fi

    echo "PASS: Shortcut script and desktop source exist and are executable"
}

test_help_and_subcommands() {
    local help_out
    help_out="$("$SHORTCUTS_BIN" --help 2>&1 || true)"
    echo "$help_out" | grep -q "install-desktop" || { echo "FAIL: Missing install-desktop in help"; exit 1; }
    echo "$help_out" | grep -q "apply-defaults" || { echo "FAIL: Missing apply-defaults in help"; exit 1; }
    echo "$help_out" | grep -q "set" || { echo "FAIL: Missing set in help"; exit 1; }
    echo "$help_out" | grep -q "get" || { echo "FAIL: Missing get in help"; exit 1; }

    echo "PASS: Subcommands and help output verified"
}

test_install_desktop_isolated() {
    local tmp_app_dir
    tmp_app_dir="$(mktemp -d /tmp/omnisnap-app-test-XXXXXX)"
    
    OMNISNAP_DESKTOP_TARGET="$tmp_app_dir" "$SHORTCUTS_BIN" install-desktop >/dev/null 2>&1 || {
        echo "FAIL: install-desktop failed"
        rm -rf "$tmp_app_dir"
        exit 1
    }

    if [[ ! -f "$tmp_app_dir/omnisnap.desktop" ]]; then
        echo "FAIL: omnisnap.desktop was not created in target directory"
        rm -rf "$tmp_app_dir"
        exit 1
    fi

    grep -q "Actions=Region;FullScreen;Window;Settings;" "$tmp_app_dir/omnisnap.desktop" || {
        echo "FAIL: Desktop file missing Actions definitions"
        rm -rf "$tmp_app_dir"
        exit 1
    }

    rm -rf "$tmp_app_dir"
    echo "PASS: Desktop file installation and Actions header verified"
}

test_apply_defaults_isolated() {
    local tmp_config_dir
    tmp_config_dir="$(mktemp -d /tmp/omnisnap-cfg-test-XXXXXX)"
    local test_kcfg="$tmp_config_dir/kglobalshortcutsrc"
    touch "$test_kcfg"

    OMNISNAP_TEST_KCONFIG="$test_kcfg" OMNISNAP_DESKTOP_TARGET="$tmp_config_dir" "$SHORTCUTS_BIN" apply-defaults >/dev/null 2>&1 || {
        echo "FAIL: apply-defaults failed"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    grep -q "\[services\]\[omnisnap.desktop\]" "$test_kcfg" || {
        echo "FAIL: Missing [services][omnisnap.desktop] group in kglobalshortcutsrc"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    grep -q "Region=Print" "$test_kcfg" || {
        echo "FAIL: Missing Region=Print shortcut"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    grep -q "Window=Meta+Print" "$test_kcfg" || {
        echo "FAIL: Missing Window=Meta+Print shortcut"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    grep -q "FullScreen=Shift+Print" "$test_kcfg" || {
        echo "FAIL: Missing FullScreen=Shift+Print shortcut"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    rm -rf "$tmp_config_dir"
    echo "PASS: apply-defaults writes correct desktop actions to kglobalshortcutsrc"
}

test_set_and_get_shortcut() {
    local tmp_config_dir
    tmp_config_dir="$(mktemp -d /tmp/omnisnap-cfg-test-XXXXXX)"
    local test_kcfg="$tmp_config_dir/kglobalshortcutsrc"
    touch "$test_kcfg"

    OMNISNAP_TEST_KCONFIG="$test_kcfg" OMNISNAP_DESKTOP_TARGET="$tmp_config_dir" "$SHORTCUTS_BIN" set "Region" "Ctrl+F10" >/dev/null 2>&1 || {
        echo "FAIL: set Region Ctrl+F10 failed"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    local val
    val="$(OMNISNAP_TEST_KCONFIG="$test_kcfg" OMNISNAP_DESKTOP_TARGET="$tmp_config_dir" "$SHORTCUTS_BIN" get "Region" 2>/dev/null || true)"
    echo "$val" | grep -q "Ctrl+F10" || {
        echo "FAIL: get Region did not return Ctrl+F10 (got '$val')"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    rm -rf "$tmp_config_dir"
    echo "PASS: set and get shortcut verified"
}

test_files_exist
test_help_and_subcommands
test_install_desktop_isolated
test_apply_defaults_isolated
test_set_and_get_shortcut

echo "All shortcut automation tests passed successfully."
