#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"

xcodebuild -scheme "Leader Key" -configuration Release build \
  -skipPackagePluginValidation \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates
