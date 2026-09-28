#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="${OMNISNAP_BIN_TARGET:-$HOME/.local/bin}"
DESKTOP_TARGET="${OMNISNAP_DESKTOP_TARGET:-$HOME/.local/share/applications}"

mkdir -p "$BIN_TARGET" "$DESKTOP_TARGET"

echo "Installing Omnisnap to $BIN_TARGET..."
ln -sf "$REPO_DIR/bin/omnisnap" "$BIN_TARGET/omnisnap"

echo "Installing Desktop entry to $DESKTOP_TARGET..."
sed "s|Exec=omnisnap|Exec=$BIN_TARGET/omnisnap|g" "$REPO_DIR/omnisnap.desktop" > "$DESKTOP_TARGET/omnisnap.desktop"

echo "Omnisnap installed successfully!"
echo "You can now bind 'omnisnap region' to the PrintScreen key in KDE System Settings -> Shortcuts."
