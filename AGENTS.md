# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

# Leader Key Development Guide

## Build & Test Commands

- Debug build: `bin/debug-build.sh`
- Release build: `bin/release-build.sh`
- Run all tests: `bin/test.sh`

## Architecture Overview

Leader Key is a macOS menu bar application that provides customizable keyboard shortcuts via a popup overlay. It runs as a background app (accessory activation policy) with no Settings window — all configuration is done via JSON files.

**Key Components:**

- `AppDelegate`: Application lifecycle, global shortcut registration via `KeyboardShortcuts`
- `Controller`: Central event handling, manages key sequences, popup window, and cheatsheet display
- `UserConfig`: Reads/writes `config.json` (key bindings tree) with validation and conflict detection
- `UserSettings`: Reads/writes `settings.json` (app preferences) with typed properties and defaults
- `UserState`: Tracks navigation through key sequences
- `StatusItem`: Menu bar icon and dropdown menu — the only persistent UI surface
- `MainWindow`: Base class for the popup window (only `Breadcrumbs` theme is used)

**Configuration:**

All configuration lives under `~/.config/leaderkey/`:

| File | Purpose |
|---|---|
| `config.json` | Key bindings / action tree |
| `settings.json` | App preferences (activation shortcut, cheatsheet behavior, modifier keys, etc.) |

- `UserConfig` manages `config.json`: loading, saving, validation, file conflict detection
- `UserSettings` manages `settings.json`: typed properties with sensible defaults, sparse/partial files supported
- Both accept an injectable directory path in their initializer for testing
- `ConfigValidator` ensures no duplicate key conflicts in the action tree
- Actions support: applications, URLs, commands, folders

**Menu Bar:**

The status item menu provides:
- About Leader Key
- Launch at Login toggle (via `SMAppService` directly)
- Edit Config / Edit Settings (opens files in default editor)
- Reveal Config in Finder / Reload Config
- Quit

**Testing Architecture:**

- Uses XCTest with custom `TestAlertManager` for alert assertions
- Tests use isolated temporary directories injected via initializer parameters
- `UserConfigTests`: Config loading, directory creation, parse errors, validation
- `UserSettingsTests`: Default values, parsing, invalid value fallbacks, shortcut parsing, round-trip save/load
- `ConfigValidatorTests`: Pure validation logic

## Code Style Guidelines

- **Imports**: Group Foundation/AppKit imports first, then third-party libraries (Combine, Defaults, KeyboardShortcuts)
- **Naming**: Use descriptive camelCase for variables/functions, PascalCase for types
- **Types**: Use explicit type annotations for public properties and parameters
- **Error Handling**: Use appropriate error handling with do/catch blocks and alerts
- **Extensions**: Create extensions for additional functionality on existing types
- **State Management**: Use @Published and ObservableObject for reactive UI updates
- **Testing**: Create separate test cases with descriptive names, use XCTAssert\* methods
- **Access Control**: Use appropriate access modifiers (private, fileprivate, internal)
- **Documentation**: Use comments for complex logic or non-obvious implementations

Follow Swift idioms and default formatting (4-space indentation, spaces around operators).
