# Omnisnap: Fix Region Capture Pipeline and Inhibit KDE Screen Edges Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix region capture failure on mouse release (ensuring screenshots reliably save, copy to clipboard, and notify) and automatically inhibit KDE Plasma KWin screen edges/hot corners while the Omnisnap overlay is open, cleanly restoring them upon dismiss.

**Architecture:** A lightweight helper script `bin/omnisnap-edges` manages KWin screen edge state via `kreadconfig6`/`kwriteconfig6` and DBus (`org.kde.KWin.reconfigure` + `org.kde.kwin.Effects.reconfigureEffect`), called by `RegionSelector.qml` on activation and dismiss. In `RegionSelection.qml`, visual overlay items are marked `enabled: false` and the toolbar is separated from `MouseArea` to guarantee unhindered pointer tracking, while `ScreenshotAction.qml` runs notification action listeners asynchronously so the file save, clipboard copy, and temporary file cleanups execute without stalling.

**Tech Stack:** Bash (`set -euo pipefail`), Quickshell (QtQuick/QML, LayerShell Wayland), KDE Plasma 6 (KWin DBus, `kwriteconfig6`, `kreadconfig6`), ImageMagick, `wl-clipboard`, `libnotify` (`notify-send`).

**Spec:** User feedback reporting: 1) Mouse release does not save, copy, or trigger notification, 2) KDE screen edges (hot corners e.g. top-left overview) activate while dragging region.

## Global Constraints
- Target environment: Linux, KDE Plasma 6 on Wayland (KWin compositor).
- Zero dependencies on Caelestia C++ plugins; rely entirely on native CLI/DBus tools (`kreadconfig6`, `kwriteconfig6`, `gdbus`, `quickshell`).
- All shell scripts must use `set -euo pipefail`.
- Quickshell must cleanly exit in oneshot mode without leaving zombie processes.
- All existing tests in `tests/` must continue to pass.

---

### Task 1: Screen Edge Inhibitor (`bin/omnisnap-edges`)

**Files:**
- Create: `bin/omnisnap-edges`
- Create: `tests/test_screen_edges.sh`

**Interfaces:**
- Consumes: KDE tools `kreadconfig6`, `kwriteconfig6`, `gdbus` / `qdbus`.
- Produces: CLI script with subcommands:
  - `omnisnap-edges inhibit`: Backs up current `[ElectricBorders]` and `[Effect-overview]` corner bindings to `${XDG_RUNTIME_DIR:-/tmp}/omnisnap/stolen-screen-edges.json`, sets them to `None` / `9`, and triggers KWin reconfigure.
  - `omnisnap-edges restore`: Restores original corner bindings from the backup file, triggers KWin reconfigure, and deletes the backup file.
  - `omnisnap-edges recover`: Restores state if a backup file exists (used on startup for crash recovery).

- [ ] **Step 1: Write the test for screen edge inhibition**

Create `tests/test_screen_edges.sh`:
```bash
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

    # Run inhibit
    "$EDGES_BIN" inhibit
    local state_file="$test_runtime_dir/omnisnap/stolen-screen-edges.json"
    if [[ ! -f "$state_file" ]]; then
        echo "FAIL: Expected state file $state_file was not created"
        rm -rf "$test_runtime_dir"
        exit 1
    fi

    # Run restore
    "$EDGES_BIN" restore
    if [[ -f "$state_file" ]]; then
        echo "FAIL: State file $state_file should be removed after restore"
        rm -rf "$test_runtime_dir"
        exit 1
    fi

    rm -rf "$test_runtime_dir"
    echo "PASS: State backup and restore cycle verified"
}

test_executable_exists
test_help_and_subcommands
test_state_backup_and_restore

echo "All screen edge inhibitor tests passed."
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_screen_edges.sh`
Expected: FAIL with "bin/omnisnap-edges is not executable or does not exist"

- [ ] **Step 3: Implement `bin/omnisnap-edges`**

Create `bin/omnisnap-edges` (with `chmod +x`):
```bash
#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/omnisnap"
STATE_FILE="$RUNTIME_DIR/stolen-screen-edges.json"

_log() {
    echo "[omnisnap-edges] $*" >&2
}

_reconfigure_kwin() {
    if [[ "${OMNISNAP_TEST_MODE:-0}" == "1" ]]; then
        return 0
    fi
    # Reconfigure KWin and the overview effect
    gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null 2>&1 || true
    gdbus call --session --dest org.kde.KWin --object-path /Effects --method org.kde.kwin.Effects.reconfigureEffect "overview" >/dev/null 2>&1 || true
}

_read_entry() {
    local group="$1" key="$2"
    if command -v kreadconfig6 >/dev/null 2>&1; then
        kreadconfig6 --file kwinrc --group "$group" --key "$key" 2>/dev/null || true
    else
        echo ""
    fi
}

_write_entry() {
    local group="$1" key="$2" value="$3"
    if [[ "${OMNISNAP_TEST_MODE:-0}" == "1" ]]; then
        return 0
    fi
    if command -v kwriteconfig6 >/dev/null 2>&1; then
        if [[ -z "$value" || "$value" == "__DELETE__" ]]; then
            kwriteconfig6 --file kwinrc --group "$group" --key "$key" --delete 2>/dev/null || true
        else
            kwriteconfig6 --file kwinrc --group "$group" --key "$key" "$value" 2>/dev/null || true
        fi
    fi
}

cmd_inhibit() {
    mkdir -p "$RUNTIME_DIR"
    if [[ -f "$STATE_FILE" ]]; then
        # Already inhibited, do not overwrite original state
        return 0
    fi

    local overview_border
    overview_border="$(_read_entry "Effect-overview" "BorderActivate")"

    local top_left top_right bottom_left bottom_right
    top_left="$(_read_entry "ElectricBorders" "TopLeft")"
    top_right="$(_read_entry "ElectricBorders" "TopRight")"
    bottom_left="$(_read_entry "ElectricBorders" "BottomLeft")"
    bottom_right="$(_read_entry "ElectricBorders" "BottomRight")"

    cat <<EOF > "$STATE_FILE"
{
  "Effect-overview": {
    "BorderActivate": "${overview_border:-__DELETE__}"
  },
  "ElectricBorders": {
    "TopLeft": "${top_left:-__DELETE__}",
    "TopRight": "${top_right:-__DELETE__}",
    "BottomLeft": "${bottom_left:-__DELETE__}",
    "BottomRight": "${bottom_right:-__DELETE__}"
  }
}
EOF

    # Set overview corner to 9 (ElectricNone) and ElectricBorders to None
    _write_entry "Effect-overview" "BorderActivate" "9"
    _write_entry "ElectricBorders" "TopLeft" "None"
    _write_entry "ElectricBorders" "TopRight" "None"
    _write_entry "ElectricBorders" "BottomLeft" "None"
    _write_entry "ElectricBorders" "BottomRight" "None"

    _reconfigure_kwin
}

cmd_restore() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 0
    fi

    if command -v jq >/dev/null 2>&1; then
        local ob tl tr bl br
        ob="$(jq -r '."Effect-overview"."BorderActivate" // "__DELETE__"' "$STATE_FILE")"
        tl="$(jq -r '."ElectricBorders"."TopLeft" // "__DELETE__"' "$STATE_FILE")"
        tr="$(jq -r '."ElectricBorders"."TopRight" // "__DELETE__"' "$STATE_FILE")"
        bl="$(jq -r '."ElectricBorders"."BottomLeft" // "__DELETE__"' "$STATE_FILE")"
        br="$(jq -r '."ElectricBorders"."BottomRight" // "__DELETE__"' "$STATE_FILE")"

        _write_entry "Effect-overview" "BorderActivate" "$ob"
        _write_entry "ElectricBorders" "TopLeft" "$tl"
        _write_entry "ElectricBorders" "TopRight" "$tr"
        _write_entry "ElectricBorders" "BottomLeft" "$bl"
        _write_entry "ElectricBorders" "BottomRight" "$br"
    fi

    rm -f "$STATE_FILE"
    _reconfigure_kwin
}

cmd_recover() {
    if [[ -f "$STATE_FILE" ]]; then
        _log "Recovering screen edge settings from previous session..."
        cmd_restore
    fi
}

case "${1:-}" in
    inhibit)
        cmd_inhibit
        ;;
    restore)
        cmd_restore
        ;;
    recover)
        cmd_recover
        ;;
    -h|--help|help)
        cat <<EOF
Usage: omnisnap-edges [inhibit|restore|recover]
Manage KWin screen edges for Omnisnap screenshot sessions.
EOF
        ;;
    *)
        echo "Error: Unknown action '${1:-}'" >&2
        exit 1
        ;;
esac
```
Ensure permissions: `chmod +x bin/omnisnap-edges`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_screen_edges.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add bin/omnisnap-edges tests/test_screen_edges.sh
git commit -m "feat(edges): add kwin screen edge inhibitor and restoration tool"
```

---

### Task 2: Fix Pointer Event Passthrough & Quickshell Lifecycle

**Files:**
- Modify: `modules/screenshot/regionSelector/RegionSelection.qml`
- Modify: `modules/screenshot/regionSelector/RegionSelector.qml`
- Modify: `tests/test_region_selection.sh`

**Interfaces:**
- Consumes: `bin/omnisnap-edges` via `Quickshell.execDetached`.
- Produces: Reliable mouse dragging and release events; `enabled: false` on cosmetic overlays (`RectCornersSelectionDetails`, `CursorGuide`); toolbar as a sibling over `MouseArea`; clean process termination on dismiss in oneshot mode.

- [ ] **Step 1: Write tests for event transparency and lifecycle**

Update `tests/test_region_selection.sh` to check:
1. `RectCornersSelectionDetails` has `enabled: false` or does not swallow mouse events.
2. `CursorGuide` has `enabled: false`.
3. `RegionSelector.qml` invokes `omnisnap-edges inhibit` on activation and `omnisnap-edges restore` on dismiss.
4. `RegionSelector.qml` terminates oneshot Quickshell cleanly using `Quickshell.processId`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_region_selection.sh`
Expected: FAIL

- [ ] **Step 3: Update `RegionSelection.qml` and `RegionSelector.qml`**

In `modules/screenshot/regionSelector/RegionSelection.qml`:
1. Move `RectCornersSelectionDetails` and `CursorGuide` outside or set `enabled: false` so they never intercept pointer clicks/drags.
2. Move `OptionsToolbar` to be a sibling above `MouseArea` with higher `z: 100` so it receives its own clicks without breaking full-screen drag on the rest of the canvas.
3. In `snip()`: ensure local variables `rx, ry, rw, rh` are cleanly clamped and do not reassign bound properties directly.

In `modules/screenshot/regionSelector/RegionSelector.qml`:
1. In `screenshot()`, `edit()`, `search()`, `ocr()`: execute `omnisnap-edges inhibit` before setting `root.active = true`.
2. In `dismiss()`: execute `omnisnap-edges restore`, set `root.active = false`, and if in oneshot mode (`Quickshell.env("OMNISNAP_DAEMON") !== "1"`), call `Quickshell.execDetached(["kill", "-TERM", `${Quickshell.processId}`])`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_region_selection.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add modules/screenshot/regionSelector/RegionSelection.qml modules/screenshot/regionSelector/RegionSelector.qml tests/test_region_selection.sh
git commit -m "fix(ui): ensure pointer event passthrough and integrate screen edge inhibitor"
```

---

### Task 3: Non-Blocking Notification & Post-Processing Pipeline

**Files:**
- Modify: `modules/screenshot/ScreenshotAction.qml`
- Modify: `tests/test_action_pipeline.sh`

**Interfaces:**
- Consumes: ImageMagick `magick`, `wl-copy`, `notify-send`.
- Produces: Asynchronous, non-blocking notification handling where file save and clipboard copy complete immediately without waiting for user action clicks.

- [ ] **Step 1: Write test for asynchronous notification execution**

Update `tests/test_action_pipeline.sh` to verify:
1. `ScreenshotAction.qml` does not block `set -euo pipefail` script on `--action` user interaction.
2. `wl-copy` runs immediately after crop.
3. Notification with actions runs in a background subshell or without stalling subsequent cleanup.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_action_pipeline.sh`
Expected: FAIL

- [ ] **Step 3: Update `ScreenshotAction.qml`**

Modify `modules/screenshot/ScreenshotAction.qml` in `Copy` action:
```bash
set -euo pipefail;
SAVE_DIR='${escapeShellStr(targetDir)}';
SAVE_DIR="${SAVE_DIR/#\~/$HOME}";
mkdir -p "$SAVE_DIR" &&
saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" &&
${cropBase} "$saveFile" &&
wl-copy -t image/png < "$saveFile" &&
(
    ACTION=$(notify-send "Screenshot Captured" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" --action="open=Open" --action="folder=Open Folder" 2>/dev/null || true);
    if [ "$ACTION" = "open" ]; then xdg-open "$saveFile"; elif [ "$ACTION" = "folder" ]; then xdg-open "$SAVE_DIR"; fi
) &
${cleanup}
```
This guarantees:
1. Crop and save are completed synchronously.
2. `wl-copy` copies image to clipboard immediately.
3. Background temporary file `${cleanup}` is removed without waiting.
4. Notification with `--action` runs in the background `( ... ) &` without holding up the script or blocking Quickshell.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_action_pipeline.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add modules/screenshot/ScreenshotAction.qml tests/test_action_pipeline.sh
git commit -m "fix(pipeline): make notification action listener asynchronous"
```

---

### Task 4: CLI Integration, Installer Update & End-to-End Verification

**Files:**
- Modify: `bin/omnisnap`
- Modify: `install.sh`
- Modify: `tests/test_cli.sh`
- Modify: `tests/test_install.sh`

**Interfaces:**
- Consumes: `bin/omnisnap-edges recover` on CLI startup.
- Produces: Integrated CLI that recovers any orphaned screen edge states and links `bin/omnisnap-edges` during installation.

- [ ] **Step 1: Write tests for installer and CLI recovery**

Update `tests/test_cli.sh` and `tests/test_install.sh` to check:
1. `bin/omnisnap` runs `omnisnap-edges recover` when starting.
2. `install.sh` installs `bin/omnisnap-edges` to `~/.local/bin/omnisnap-edges`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_cli.sh && bash tests/test_install.sh`
Expected: FAIL

- [ ] **Step 3: Update `bin/omnisnap` and `install.sh`**

In `bin/omnisnap`:
Call `"$PROJECT_DIR/bin/omnisnap-edges" recover 2>/dev/null || true` before starting oneshot or daemon modes, ensuring that even if a previous crash occurred, the user's screen edges are never permanently lost.

In `install.sh`:
Add symlink for `bin/omnisnap-edges` -> `~/.local/bin/omnisnap-edges`.

- [ ] **Step 4: Run all test suites**

Run:
```bash
bash tests/test_cli.sh
bash tests/test_action_pipeline.sh
bash tests/test_components.sh
bash tests/test_selection_details.sh
bash tests/test_toolbar.sh
bash tests/test_region_selection.sh
bash tests/test_screen_edges.sh
bash tests/test_quickshell_syntax.sh
bash tests/test_install.sh
```
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add bin/omnisnap install.sh tests/test_cli.sh tests/test_install.sh
git commit -m "feat(integration): integrate screen edge recovery in cli and installer"
```
