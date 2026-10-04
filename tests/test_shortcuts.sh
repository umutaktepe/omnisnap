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

    grep -q "_k_friendly_name=Omnisnap" "$test_kcfg" || {
        echo "FAIL: Missing _k_friendly_name=Omnisnap"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    grep -q "_launch=Print" "$test_kcfg" || {
        echo "FAIL: Missing _launch=Print shortcut"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    grep -q "Settings=Meta+Shift+Print" "$test_kcfg" || {
        echo "FAIL: Missing Settings=Meta+Shift+Print shortcut"
        rm -rf "$tmp_config_dir"
        exit 1
    }

    if [[ ! -f "$tmp_config_dir/omnisnap.desktop" ]]; then
        echo "FAIL: omnisnap.desktop not found in target directory"
        rm -rf "$tmp_config_dir"
        exit 1
    fi

    grep -q "X-KDE-Shortcuts=Print" "$tmp_config_dir/omnisnap.desktop" || {
        echo "FAIL: Installed desktop file missing X-KDE-Shortcuts=Print"
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

test_desktop_entry_kde_shortcuts() {
    local root_shortcut
    root_shortcut="$(awk -F'=' '/^\[Desktop Entry\]/{flag=1; next} /^\[/{flag=0} flag && /^X-KDE-Shortcuts=/{print $2}' "$DESKTOP_SRC")"
    if [[ "$root_shortcut" != "Print" ]]; then
        echo "FAIL: Root [Desktop Entry] does not have X-KDE-Shortcuts=Print (got '$root_shortcut')"
        exit 1
    fi

    local region_shortcut
    region_shortcut="$(awk -F'=' '/^\[Desktop Action Region\]/{flag=1; next} /^\[/{flag=0} flag && /^X-KDE-Shortcuts=/{print $2}' "$DESKTOP_SRC")"
    if [[ "$region_shortcut" != "Print" ]]; then
        echo "FAIL: [Desktop Action Region] does not have X-KDE-Shortcuts=Print (got '$region_shortcut')"
        exit 1
    fi

    local window_shortcut
    window_shortcut="$(awk -F'=' '/^\[Desktop Action Window\]/{flag=1; next} /^\[/{flag=0} flag && /^X-KDE-Shortcuts=/{print $2}' "$DESKTOP_SRC")"
    if [[ "$window_shortcut" != "Meta+Print" ]]; then
        echo "FAIL: [Desktop Action Window] does not have X-KDE-Shortcuts=Meta+Print (got '$window_shortcut')"
        exit 1
    fi

    local fullscreen_shortcut
    fullscreen_shortcut="$(awk -F'=' '/^\[Desktop Action FullScreen\]/{flag=1; next} /^\[/{flag=0} flag && /^X-KDE-Shortcuts=/{print $2}' "$DESKTOP_SRC")"
    if [[ "$fullscreen_shortcut" != "Shift+Print" ]]; then
        echo "FAIL: [Desktop Action FullScreen] does not have X-KDE-Shortcuts=Shift+Print (got '$fullscreen_shortcut')"
        exit 1
    fi

    local settings_shortcut
    settings_shortcut="$(awk -F'=' '/^\[Desktop Action Settings\]/{flag=1; next} /^\[/{flag=0} flag && /^X-KDE-Shortcuts=/{print $2}' "$DESKTOP_SRC")"
    if [[ "$settings_shortcut" != "Meta+Shift+Print" ]]; then
        echo "FAIL: [Desktop Action Settings] does not have X-KDE-Shortcuts=Meta+Shift+Print (got '$settings_shortcut')"
        exit 1
    fi

    echo "PASS: Desktop entry and desktop actions X-KDE-Shortcuts verified"
}

test_files_exist
test_help_and_subcommands
test_desktop_entry_kde_shortcuts
test_install_desktop_isolated
test_apply_defaults_isolated
test_set_and_get_shortcut

echo "All shortcut automation tests passed successfully."
