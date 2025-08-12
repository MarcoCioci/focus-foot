#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_SRC="./scripts/focus_or_spawn_terminal.sh"
SCRIPT_DST="$HOME/.local/bin/focus_or_spawn_terminal.sh"
DESKTOP_SRC="./desktop/foot-smart.desktop"
DESKTOP_DST="$HOME/.local/share/applications/foot-smart.desktop"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"

install -m 0755 "$SCRIPT_SRC" "$SCRIPT_DST"
install -m 0644 "$DESKTOP_SRC" "$DESKTOP_DST"

update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

echo "Installed:"
echo "  - $SCRIPT_DST"
echo "  - $DESKTOP_DST"
echo
echo "You can now find 'Smart Foot Terminal' in your app launcher."
echo "Tip: Add it to Favorites for quick access."
