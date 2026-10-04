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
ln -sf "$SCRIPT_DIR/bin/omnisnap-shortcuts" "$BIN_DIR/omnisnap-shortcuts"

echo "Installing Desktop entry and applying KDE shortcuts..."
"$SCRIPT_DIR/bin/omnisnap-shortcuts" apply-defaults 2>/dev/null || true

echo "Omnisnap installed successfully!"
echo "Global shortcuts (Print, Meta+Print, Shift+Print) configured automatically."
