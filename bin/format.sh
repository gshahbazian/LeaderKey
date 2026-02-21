#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

swift format --parallel --in-place --recursive "$PROJECT_DIR/Leader Key" "$PROJECT_DIR/Leader KeyTests"
