#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BIN_DIR="${OMNISNAP_BIN_TARGET:-$HOME/.local/bin}"
BIN_TARGET="$BIN_DIR"
DESKTOP_TARGET="${OMNISNAP_DESKTOP_TARGET:-$HOME/.local/share/applications}"

mkdir -p "$BIN_DIR" "$DESKTOP_TARGET"

echo "Installing Omnisnap to $BIN_DIR..."
ln -sf "$SCRIPT_DIR/bin/omnisnap" "$BIN_DIR/omnisnap"
ln -sf "$SCRIPT_DIR/bin/omnisnap-edges" "$BIN_DIR/omnisnap-edges"

echo "Installing Desktop entry to $DESKTOP_TARGET..."
sed "s|Exec=omnisnap|Exec=$BIN_DIR/omnisnap|g" "$SCRIPT_DIR/omnisnap.desktop" > "$DESKTOP_TARGET/omnisnap.desktop"

echo "Omnisnap installed successfully!"
echo "You can now bind 'omnisnap region' to the PrintScreen key in KDE System Settings -> Shortcuts."
