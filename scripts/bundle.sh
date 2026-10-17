#!/usr/bin/env bash
# Usage: IDENTITY='Apple Development: Your Name (TEAMID)' scripts/bundle.sh [--debug]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.0.1}"
BUILD="${BUILD:-1}"
IDENTITY="${IDENTITY:--}"
CONFIG=release
case "${1:-}" in
  --debug) CONFIG=debug ;;
  "") ;;
  *) echo 'Usage: scripts/bundle.sh [--debug]' >&2; exit 1 ;;
esac
[[ "$#" -le 1 ]] || { echo 'Usage: scripts/bundle.sh [--debug]' >&2; exit 1; }

swift build -c "$CONFIG"
BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"

APP='build/Leader Key.app'
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/leaderkey" "$APP/Contents/MacOS/leaderkey"
cp Resources/Info.plist "$APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD" "$APP/Contents/Info.plist"

ICON_OUT="$(mktemp -d)"
trap 'rm -rf "$ICON_OUT"' EXIT
xcrun actool "$PWD/Resources/Assets.xcassets" --compile "$ICON_OUT" \
  --platform macosx --minimum-deployment-target 15.0 --app-icon AppIcon \
  --accent-color AccentColor --output-partial-info-plist "$ICON_OUT/partial.plist"
cp "$ICON_OUT/Assets.car" "$ICON_OUT/AppIcon.icns" "$APP/Contents/Resources/"

# SwiftPM dependencies load their localizations and privacy manifests from these bundles.
for bundle in "$BIN_PATH"/*.bundle; do
  [[ -d "$bundle" ]] || continue
  ditto "$bundle" "$APP/Contents/Resources/$(basename "$bundle")"
done

codesign --force --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"
echo "built $APP ($CONFIG, $VERSION build $BUILD)"
