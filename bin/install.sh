#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
APP_PATH="$BUILD_DIR/Build/Products/Release/Leader Key.app"

"$SCRIPT_DIR/release-build.sh"

rm -rf "/Applications/Leader Key.app"
cp -R "$APP_PATH" "/Applications/Leader Key.app"
echo "Installed to /Applications/Leader Key.app"
