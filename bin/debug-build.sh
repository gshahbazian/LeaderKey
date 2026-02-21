#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"

echo "Linting..."
swift format lint --parallel --strict --recursive "$PROJECT_DIR/Leader Key" "$PROJECT_DIR/Leader KeyTests"

echo "Building..."
xcodebuild -scheme "Leader Key" -configuration Debug build \
  -skipPackagePluginValidation \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
