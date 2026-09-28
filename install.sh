#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2026 Nicholas Smith

# Build Download Recycler.app and symlink it into ~/Applications (rebuilds
# propagate; SMAppService accepts a symlink there for Start at Login).
# Retires the legacy launchd agent this app replaces and migrates its config.
set -euo pipefail

# Menubarn release rule — every push is a release. Arm the pre-push hook in
# every Menubarn repo cloned beside this one (local git config, so a fresh
# clone has none until this runs). StatusItemKit README, "Releases".
RELEASE_KIT="$(cd "$(dirname "$0")/.." && pwd)/StatusItemKit/scripts/release/adopt.sh"
if [ -x "$RELEASE_KIT" ]; then
    "$RELEASE_KIT" --hooks-only || echo "Release hook: adopt.sh failed" >&2
else
    echo "Release hook: StatusItemKit not found beside this repo — clone it and re-run" >&2
fi

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

# Ask to turn on Start at Login. SMAppService can only register the calling
# process's own bundle, so this runs the installed binary's headless --login.
APP="$HOME/Applications/$APP_NAME"
BIN="$APP/Contents/MacOS/DownloadRecycler"
PROC="${APP##*/}/Contents/MacOS/DownloadRecycler"   # matches the symlink-resolved path too
if [ "$("$BIN" --login status 2>/dev/null)" = "on" ]; then
    echo "Start at Login: already on"
elif [ -t 0 ]; then
    read -r -p "Start Download Recycler at login? [Y/n] " answer
    case "$answer" in
        [nN]*) echo "Start at Login: left off (turn it on from the menu)" ;;
        *) if "$BIN" --login on >/dev/null; then
               echo "Start at Login: on"
           else
               echo "Start at Login: could not register (turn it on from the menu)" >&2
           fi ;;
    esac
else
    echo "Start at Login: off (not asked: no terminal). Turn it on from the menu, or run"
    echo "    \"$BIN\" --login on"
fi

# `open` on a running app only activates it, so quit the old build first or the
# new one never launches. Wait for it to go so both don't briefly sit in the bar.
if pgrep -f "$PROC" >/dev/null; then
    osascript -e "tell application id \"$(defaults read "$APP/Contents/Info" CFBundleIdentifier)\" to quit" >/dev/null 2>&1 || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -f "$PROC" >/dev/null || break; sleep 0.5; done
    pkill -f "$PROC" 2>/dev/null || true
    sleep 1
fi
/usr/bin/open "$APP"

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
