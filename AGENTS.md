# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

# Leader Key Development Guide

## Build & Test Commands

- Debug build: `swift build`
- Release build: `swift build -c release`
- Run all tests: `swift test`
- Release app bundle: `scripts/bundle.sh`
- Debug app bundle: `scripts/bundle.sh --debug`
- Install and launch: `IDENTITY='Apple Development: Your Name (TEAMID)' scripts/install-local.sh`
- Format: `swift format --parallel --in-place --recursive 'Leader Key' 'Leader KeyTests' Package.swift`
- Lint: `swift format lint --parallel --strict --recursive 'Leader Key' 'Leader KeyTests' Package.swift`

Swift Package Manager builds the executable and runs tests without launching the
app. There is no Xcode project. Bundling uses `Resources/Info.plist`, compiles
`Resources/Assets.xcassets` with `actool`, copies dependency resource bundles, and
signs `build/Leader Key.app`. Bundling defaults to ad-hoc signing; set `IDENTITY`
for certificate signing. `VERSION` and `BUILD` override the app's version numbers.
The local installer requires `IDENTITY` and backs up any existing installed app.

## Architecture Overview

Leader Key is a macOS menu bar application that provides customizable keyboard shortcuts via a popup overlay. It runs as a background app (accessory activation policy) with no Settings window — all configuration is done via JSON files.

**Key Components:**

- `LeaderKey`: Application entry point; creates and retains the delegate and runs the event loop
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
- The `LeaderKeyTests` Swift package test target imports the `Leader_Key` executable target directly
- Tests use isolated temporary directories injected via initializer parameters
- `UserConfigTests`: Config loading, directory creation, parse errors, validation
- `UserSettingsTests`: Default values, parsing, invalid value fallbacks, shortcut parsing, round-trip save/load
- `ConfigValidatorTests`: Pure validation logic

