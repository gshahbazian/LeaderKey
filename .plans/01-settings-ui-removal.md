# Plan: Remove Settings UI & Migrate to File-Based Configuration

## Overview

Remove the entire Settings window UI. All configuration lives in two files under
`~/.config/leaderkey/`:

| File | Purpose |
|---|---|
| `config.json` | Key bindings / action tree (same filename as before) |
| `settings.json` | App preferences (currently stored in UserDefaults) |

The menu bar status item becomes the only UI surface for the app (besides the
popup itself). Quick-access settings move into the menu; everything else is
edited by the user in `settings.json`.

---

## Phase 1 — Move config directory to `~/.config/leaderkey/`

**Goal:** Adopt the XDG-style config path. Drop support for the configurable
config directory preference (`Defaults[.configDir]`).

### Steps

1. **`UserConfig.swift`** — Change `defaultDirectory()` to return
   `~/.config/leaderkey/`. Remove the `Defaults[.configDir]` indirection; the
   path is now hard-coded. The file stays named `config.json`.
2. **Remove `configDir` default key** from `Defaults.swift`.
3. **Update `StatusItem`** — "Show config in Finder" should reveal
   `~/.config/leaderkey/` in Finder.

---

## Phase 2 — Introduce `settings.json`

**Goal:** Replace UserDefaults-backed preferences with a JSON file that lives
next to the keybindings file

### `settings.json` schema

```json
{
  "activation_shortcut": "control+space",
  "modifier_keys": "control_group_option_sticky",
  "cheatsheet": {
    "auto_open": "after_delay",
    "delay_ms": 2000,
    "expand_groups": false,
    "show_app_icons": true,
    "show_favicons": true,
    "show_details": true
  },
  "reactivate_behavior": "hide",
  "screen": "primary"
}
```

### Key reference

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `activation_shortcut` | string | `"control+space"` | Modifiers (`command`, `shift`, `control`, `option`) joined with `+` followed by a key name, e.g. `"control+space"`, `"command+shift+k"` | The global keyboard shortcut that triggers the Leader Key popup |
| `modifier_keys` | string | `"control_group_option_sticky"` | `"control_group_option_sticky"`, `"option_group_control_sticky"` | Which modifier key activates group sequences and which activates sticky mode |
| `cheatsheet.auto_open` | string | `"after_delay"` | `"always"`, `"after_delay"`, `"never"` | When to automatically show the cheatsheet overlay |
| `cheatsheet.delay_ms` | int | `2000` | Any positive integer | Milliseconds to wait before showing cheatsheet (only used when `auto_open` is `"after_delay"`) |
| `cheatsheet.expand_groups` | bool | `false` | `true`, `false` | Whether to show expanded subgroup contents in the cheatsheet |
| `cheatsheet.show_app_icons` | bool | `true` | `true`, `false` | Whether to show application icons next to app shortcuts |
| `cheatsheet.show_favicons` | bool | `true` | `true`, `false` | Whether to show website favicons next to URL shortcuts |
| `cheatsheet.show_details` | bool | `true` | `true`, `false` | Whether to show the action value (path, URL, command) next to each shortcut |
| `reactivate_behavior` | string | `"hide"` | `"hide"`, `"reset"`, `"nothing"` | What happens when the activation shortcut is pressed while the popup is already open. Hide dismisses it, reset returns to root, nothing ignores the keypress. |
| `screen` | string | `"primary"` | `"primary"`, `"mouse"`, `"active_window"` | Which screen to show the popup on |

### Steps

1. **Create `UserSettings.swift`** — A new class (similar pattern to
   `UserConfig`) that:
   - Reads/writes `~/.config/leaderkey/settings.json`
   - Exposes typed properties for each setting with sensible defaults when
     keys are missing (the file can be sparse / partial)
   - Writes a default `settings.json` on first launch if none exists
2. **Migrate all consumers off `Defaults`** — `Controller`, `Cheatsheet`,
   and any other code that reads from `Defaults` for these settings should
   read from the shared `UserSettings` instance directly instead. No bridge
   layer — `Defaults` keys for these settings get deleted outright.
3. **Activation shortcut** — Currently managed by the `KeyboardShortcuts`
   framework and stored in UserDefaults. We need to:
   - Define a string encoding for shortcuts in `settings.json`
   - On settings load, programmatically call `KeyboardShortcuts.setShortcut()`
     to register the configured shortcut
   - Remove the `KeyboardShortcuts.Recorder` UI dependency

---

## Phase 3 — Enhance the menu bar

**Goal:** Expose commonly-toggled settings directly in the status item menu.

### New menu structure

```
About Leader Key
────────────────
Launch at Login      ✓
────────────────
Edit Config              (opens config.json in default app)
Edit Settings            (opens settings.json in default app)
Reveal Config in Finder
Reload Config
────────────────
Quit Leader Key
```

### Steps

1. **`StatusItem.swift`** — Rebuild the menu:
   - Add "Launch at Login" toggle item (calls `SMAppService` directly, not
     backed by `settings.json`).
   - Add "Edit Config" — opens `config.json` with `NSWorkspace.open()`.
   - Add "Edit Settings" — opens `settings.json` with `NSWorkspace.open()`.
   - Keep "Reveal Config in Finder", "Reload Config", "Quit".
   - Remove "Settings…" and "Check for Updates…" items.
2. **Menu actions** — Launch at Login toggle calls `SMAppService` directly
   to register/unregister. No settings.json involvement.
3. **`AppDelegate.swift`** — Remove the `handlePreferences` callback wiring
   for the status item.

---

## Phase 4 — Remove the Settings UI

**Goal:** Delete all settings panel code and the Settings SPM dependency.

### Files to delete

- `Leader Key/Settings.swift` (pane identifiers)
- `Leader Key/Settings/GeneralPane.swift`
- `Leader Key/Settings/AdvancedPane.swift`
- `Leader Key/Views/ConfigOutlineEditorView.swift` (config editor, only used by GeneralPane)
- `Leader Key/Views/ConfigEditorShared.swift` (only used by ConfigOutlineEditorView)
- `Leader Key/Views/KeyButton.swift` (only used by ConfigOutlineEditorView)
- `Leader Key/Views/KeyCapture.swift` (only used by ConfigOutlineEditorView)
- `Leader Key/Theme.swift` (theme enum and class lookup)
- `Leader Key/Themes/MysteryBox.swift`
- `Leader Key/Themes/Mini.swift`
- `Leader Key/Themes/ForTheHorde.swift`
- `Leader Key/Themes/Cheater.swift`
- Keep `Leader Key/Themes/Breadcrumbs.swift` — this is the only theme
- `Leader Key/URLSchemeHandler.swift` (URL scheme feature removed entirely)
- `Leader KeyTests/URLSchemeTests.swift` (tests for removed feature)
- `Leader KeyTests/KeyboardLayoutTests.swift` (tests for removed feature)

### Code to remove from existing files

| File | What to remove |
|---|---|
| `AppDelegate.swift` | `import Settings`, `import Sparkle`, `settingsWindowController` lazy property, `showSettings()` method, `settingsMenuItemActionHandler()`, `windowWillClose` settings-window logic, activation policy switching tied to settings window. Remove theme selection logic — hard-code Breadcrumbs as the only theme. Remove `Defaults.updates(.showMenuBarIcon)` stream — menu bar icon is always shown. Remove all URL scheme handling code (`handleURL()`, URL event registration, etc.). Remove `SPUStandardUserDriverDelegate` conformance, `updaterController` outlet, `updateLocationIdentifier`, all Sparkle delegate methods (`standardUserDriverWillHandleShowingUpdate`, `standardUserDriverDidReceiveUserAttention`, `standardUserDriverWillFinishUpdateSession`), and update notification handling. First-launch auto-open-settings logic (lines 129-131) — replace with: if no activation shortcut is set, write a default one to `settings.json`. |
| `StatusItem.swift` | `import Sparkle`, `handleCheckForUpdates` callback, "Check for Updates..." menu item, `checkForUpdates()` method. |
| `Controller.swift` | Remove force-English keyboard layout logic in `charForEvent()` — always use the active keyboard layout as-is. |
| `MainMenu.swift` | "Settings…" menu item (⌘, shortcut). Consider removing the entire Edit menu too if it was only for the config outline editor. |
| `Main.storyboard` | "Check for Updates..." menu item, `SPUStandardUpdaterController` custom object, and its outlet connection. |
| `Info.plist` | Remove `SUFeedURL`, `SUPublicEDKey` keys, and `leaderkey://` URL scheme registration. |

### SPM dependency to remove

- Remove the `Settings` package (`XCRemoteSwiftPackageReference "Settings"`)
  from the Xcode project / `Package.resolved`.
- Remove the `Sparkle` package (`XCRemoteSwiftPackageReference "Sparkle"`)
  from the Xcode project / `Package.resolved`.
- Remove the `LaunchAtLogin` package — replaced by direct `SMAppService` calls.
- Audit whether `KeyboardShortcuts` is still needed as a dependency after we
  remove the Recorder UI. (It likely is — we still use it to register global
  shortcuts programmatically.)

---

## Phase 5 — Clean up Defaults.swift

**Goal:** Remove default keys that are now sourced from `settings.json`.

### Keys to remove from `Defaults.Keys`

- `configDir` (hard-coded path now)
- `showMenuBarIcon` (removed — menu bar icon is always shown)
- `theme` (removed — Breadcrumbs is hard-coded)
- `modifierKeyConfiguration` (from settings.json)
- `autoOpenCheatsheet` (from settings.json)
- `cheatsheetDelayMS` (from settings.json)
- `expandGroupsInCheatsheet` (from settings.json)
- `showAppIconsInCheatsheet` (from settings.json)
- `showFaviconsInCheatsheet` (from settings.json)
- `showDetailsInCheatsheet` (from settings.json)
- `reactivateBehavior` (from settings.json)
- `screen` (from settings.json)
- `forceEnglishKeyboardLayout` (removed — feature deleted)

### Keys to keep (or evaluate)

- `groupShortcuts` — Used internally by the shortcut registration system;
  not a user-facing preference. May stay in UserDefaults or move into
  `UserSettings` later.

All consumer code is migrated to read from `UserSettings` directly, so
these keys are deleted outright — no bridge, no intermediate state.

---

## Phase 6 — Update tests

### `ConfigValidatorTests.swift` — No changes needed
Pure validation logic with no dependency on settings, config paths, or themes.

### `URLSchemeTests.swift` — Delete entirely
The URL scheme feature is being removed, so this entire test file goes away.

### `UserConfigTests.swift`
This file is heavily affected:
- **`setUp()`** uses `Defaults[.configDir] = tempBaseDir` to point config at a
  temp directory. Since we're removing the `configDir` default and hard-coding
  `~/.config/leaderkey/`, we need a different injection mechanism. Options:
  - Make `UserConfig` accept a directory path in its initializer (test-friendly).
  - Or have `UserConfig` expose an overridable class-level property for tests.
- **`testCreatesDefaultConfigDirIfNotExists()`** — references
  `UserConfig.defaultDirectory()` and `Defaults[.configDir]`. Update to use
  the new hard-coded `~/.config/leaderkey/` path, or better yet, keep the
  test using the injectable directory so it doesn't touch the real filesystem.
- **`testResetsToDefaultDirWhenCustomDirDoesNotExist()`** — **Delete entirely.**
  This tests the fallback behavior for custom config directories, which we're
  removing. There is no custom config dir anymore.
- **`testShowsAlertWhenConfigFileFailsToParse()`** — uses
  `Defaults[.configDir]`. Update to use the injected temp directory instead.
- **`testValidationIssuesDoNotTriggerAlerts()`** — same, update config dir
  reference.

### `KeyboardLayoutTests.swift` — Delete entirely
The force-English keyboard layout feature is being removed.

### New test file: `UserSettingsTests.swift`
- **Test parsing** — Load a valid `settings.json`, verify all fields are read
  correctly.
- **Test defaults for missing keys** — Load a partial/empty `settings.json`
  (`{}`), verify every setting falls back to its default value.
- **Test invalid values** — Verify graceful handling of bad enum strings,
  negative numbers, etc.
- **Test activation shortcut parsing** — Verify `"control+space"`,
  `"command+shift+k"`, etc. are correctly parsed into modifier flags + key.
- **Test write-back** — When the menu bar changes a setting (e.g.
  `launch_at_login`), verify `settings.json` is updated on disk.

---

## Order of execution

Phases are roughly sequential but 1 and 2 can be worked in parallel since
they touch different files. Phase 3 and 4 depend on Phase 2 (menu needs
`UserSettings` to read/write). Phase 5 is cleanup after everything works.
Phase 6 runs throughout.

```
Phase 1 (config path)  ──┐
                          ├──▸ Phase 3 (menu bar) ──▸ Phase 4 (delete) ──▸ Phase 5 (cleanup)
Phase 2 (settings.json) ─┘
                                                                             Phase 6 (tests)
```
