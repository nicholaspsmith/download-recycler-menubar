#!/bin/bash
# Build Download Recycler.app in ./build/ via StatusItemKit's shared bundler
# (requires ../StatusItemKit checked out as a sibling).
set -euo pipefail
cd "$(dirname "$0")/.."
exec ../StatusItemKit/scripts/make-app.sh DownloadRecycler "Download Recycler"
