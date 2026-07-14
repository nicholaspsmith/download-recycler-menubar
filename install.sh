#!/usr/bin/env bash
# Build Download Recycler.app and symlink it into ~/Applications (rebuilds
# propagate; SMAppService accepts a symlink there for Start at Login).
# Retires the legacy launchd agent this app replaces and migrates its config.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Download Recycler.app"

"$SRC_DIR/scripts/build-app.sh"

mkdir -p "$HOME/Applications"
ln -sfn "$SRC_DIR/build/$APP_NAME" "$HOME/Applications/$APP_NAME"
echo "Linked $HOME/Applications/$APP_NAME -> $SRC_DIR/build/$APP_NAME"

# --- migrate the legacy config, then retire the old agent + script ----------
LEGACY_CONF="$HOME/background_scripts/download_recycler.conf"
if [ -f "$LEGACY_CONF" ]; then
    DAYS="$(grep '^DAYS_TO_KEEP=' "$LEGACY_CONF" | cut -d= -f2 | tr -d ' ' || true)"
    if [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        defaults write com.nicholaspsmith.DownloadRecycler daysToKeep -int "$DAYS"
        echo "Migrated retention setting from legacy config: $DAYS days."
    fi
fi

LEGACY_LABEL="com.user.downloadrecycler"
LEGACY_PLIST="$HOME/Library/LaunchAgents/$LEGACY_LABEL.plist"
if [ -f "$LEGACY_PLIST" ]; then
    launchctl bootout "gui/$(id -u)/$LEGACY_LABEL" 2>/dev/null || true
    rm -f "$LEGACY_PLIST"
    rm -f "$HOME/background_scripts/download_recycler.sh"
    echo "Retired legacy $LEGACY_LABEL launchd agent."
fi

open "$HOME/Applications/$APP_NAME"

cat <<'EOF'

Download Recycler is running in the menu bar (green dot = active).

First run: macOS will ask for access to your Downloads folder — allow it.

Menu options
  - Enabled: master on/off toggle (gray dot when paused)
  - Run Now: sweep immediately
  - Keep Files For: 7 / 14 / 30 / 60 / 90 days
  - Open Log: audit what was trashed (~/Library/Logs/download-recycler.log)
  - Start at Login: SMAppService (no launchd agent needed)

Files are moved to the Trash (restorable), never deleted directly.
EOF
