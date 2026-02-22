import XCTest

@testable import Leader_Key

final class UserSettingsTests: XCTestCase {
  var tempDir: String!

  override func setUp() {
    super.setUp()
    tempDir = NSTemporaryDirectory().appending("/LeaderKeySettingsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(atPath: tempDir)
    super.tearDown()
  }

  // MARK: - Defaults for missing keys

  func testDefaultsWhenNoFileExists() {
    let settings = UserSettings(directoryPath: tempDir)

    XCTAssertEqual(settings.activationShortcut, "control+space")
    XCTAssertEqual(settings.cheatsheetAutoOpen, .delay)
    XCTAssertEqual(settings.cheatsheetDelayMS, 2000)
    XCTAssertEqual(settings.cheatsheetExpandGroups, false)
    XCTAssertEqual(settings.cheatsheetShowAppIcons, true)
    XCTAssertEqual(settings.cheatsheetShowFavicons, true)
    XCTAssertEqual(settings.cheatsheetShowDetails, true)
    XCTAssertEqual(settings.reactivateBehavior, .hide)
    XCTAssertEqual(settings.screen, .primary)
  }

  func testDefaultsForEmptyJSON() throws {
    let json = "{}"
    let path = (tempDir as NSString).appendingPathComponent("settings.json")
    try json.write(toFile: path, atomically: true, encoding: .utf8)

    let settings = UserSettings(directoryPath: tempDir)

    XCTAssertEqual(settings.activationShortcut, "control+space")
    XCTAssertEqual(settings.cheatsheetAutoOpen, .delay)
    XCTAssertEqual(settings.cheatsheetDelayMS, 2000)
    XCTAssertEqual(settings.cheatsheetExpandGroups, false)
    XCTAssertEqual(settings.cheatsheetShowAppIcons, true)
    XCTAssertEqual(settings.cheatsheetShowFavicons, true)
    XCTAssertEqual(settings.cheatsheetShowDetails, true)
    XCTAssertEqual(settings.reactivateBehavior, .hide)
    XCTAssertEqual(settings.screen, .primary)
  }

  // MARK: - Parsing valid settings

  func testParsesAllFields() throws {
    let json = """
      {
        "activation_shortcut": "command+shift+k",
        "cheatsheet": {
          "auto_open": "always",
          "delay_ms": 500,
          "expand_groups": true,
          "show_app_icons": false,
          "show_favicons": false,
          "show_details": false
        },
        "reactivate_behavior": "reset",
        "screen": "mouse"
      }
      """
    let path = (tempDir as NSString).appendingPathComponent("settings.json")
    try json.write(toFile: path, atomically: true, encoding: .utf8)

    let settings = UserSettings(directoryPath: tempDir)

    XCTAssertEqual(settings.activationShortcut, "command+shift+k")
    XCTAssertEqual(settings.cheatsheetAutoOpen, .always)
    XCTAssertEqual(settings.cheatsheetDelayMS, 500)
    XCTAssertEqual(settings.cheatsheetExpandGroups, true)
    XCTAssertEqual(settings.cheatsheetShowAppIcons, false)
    XCTAssertEqual(settings.cheatsheetShowFavicons, false)
    XCTAssertEqual(settings.cheatsheetShowDetails, false)
    XCTAssertEqual(settings.reactivateBehavior, .reset)
    XCTAssertEqual(settings.screen, .mouse)
  }

  func testParsesPartialCheatsheet() throws {
    let json = """
      {
        "cheatsheet": {
          "auto_open": "never"
        }
      }
      """
    let path = (tempDir as NSString).appendingPathComponent("settings.json")
    try json.write(toFile: path, atomically: true, encoding: .utf8)

    let settings = UserSettings(directoryPath: tempDir)

    XCTAssertEqual(settings.cheatsheetAutoOpen, .never)
    // Other cheatsheet values should stay at defaults
    XCTAssertEqual(settings.cheatsheetDelayMS, 2000)
    XCTAssertEqual(settings.cheatsheetExpandGroups, false)
  }

  // MARK: - Invalid values

  func testInvalidEnumValuesFallbackToDefaults() throws {
    let json = """
      {
        "reactivate_behavior": "bogus",
        "screen": "unknown",
        "cheatsheet": {
          "auto_open": "nope"
        }
      }
      """
    let path = (tempDir as NSString).appendingPathComponent("settings.json")
    try json.write(toFile: path, atomically: true, encoding: .utf8)

    let settings = UserSettings(directoryPath: tempDir)

    XCTAssertEqual(settings.reactivateBehavior, .hide)
    XCTAssertEqual(settings.screen, .primary)
    XCTAssertEqual(settings.cheatsheetAutoOpen, .delay)
  }

  // MARK: - Activation shortcut parsing

  func testParseControlSpace() {
    let shortcut = ShortcutParser.parse("control+space")

    XCTAssertNotNil(shortcut)
    XCTAssertEqual(shortcut?.key, .space)
    XCTAssertTrue(shortcut?.modifiers.contains(.control) ?? false)
    XCTAssertFalse(shortcut?.modifiers.contains(.command) ?? true)
  }

  func testParseCommandShiftK() {
    let shortcut = ShortcutParser.parse("command+shift+k")

    XCTAssertNotNil(shortcut)
    XCTAssertEqual(shortcut?.key, .k)
    XCTAssertTrue(shortcut?.modifiers.contains(.command) ?? false)
    XCTAssertTrue(shortcut?.modifiers.contains(.shift) ?? false)
  }

  func testParseOptionF12() {
    let shortcut = ShortcutParser.parse("option+f12")

    XCTAssertNotNil(shortcut)
    XCTAssertEqual(shortcut?.key, .f12)
    XCTAssertTrue(shortcut?.modifiers.contains(.option) ?? false)
  }

  func testParseInvalidShortcut() {
    let shortcut = ShortcutParser.parse("")
    XCTAssertNil(shortcut)
  }

  // MARK: - Save and reload

  func testSaveWritesFile() {
    let settings = UserSettings(directoryPath: tempDir)
    settings.cheatsheetDelayMS = 3000
    settings.save()

    let path = (tempDir as NSString).appendingPathComponent("settings.json")
    XCTAssertTrue(FileManager.default.fileExists(atPath: path))

    // Reload and verify
    let reloaded = UserSettings(directoryPath: tempDir)
    XCTAssertEqual(reloaded.cheatsheetDelayMS, 3000)
  }

  func testScreenActiveWindow() throws {
    let json = """
      {
        "screen": "active_window"
      }
      """
    let path = (tempDir as NSString).appendingPathComponent("settings.json")
    try json.write(toFile: path, atomically: true, encoding: .utf8)

    let settings = UserSettings(directoryPath: tempDir)
    XCTAssertEqual(settings.screen, .activeWindow)
  }

  func testRoundTripAllSettings() {
    let settings = UserSettings(directoryPath: tempDir)
    settings.activationShortcut = "option+space"
    settings.cheatsheetAutoOpen = .always
    settings.cheatsheetDelayMS = 1500
    settings.cheatsheetExpandGroups = true
    settings.cheatsheetShowAppIcons = false
    settings.cheatsheetShowFavicons = false
    settings.cheatsheetShowDetails = false
    settings.reactivateBehavior = .nothing
    settings.screen = .activeWindow
    settings.save()

    let reloaded = UserSettings(directoryPath: tempDir)
    XCTAssertEqual(reloaded.activationShortcut, "option+space")
    XCTAssertEqual(reloaded.cheatsheetAutoOpen, .always)
    XCTAssertEqual(reloaded.cheatsheetDelayMS, 1500)
    XCTAssertEqual(reloaded.cheatsheetExpandGroups, true)
    XCTAssertEqual(reloaded.cheatsheetShowAppIcons, false)
    XCTAssertEqual(reloaded.cheatsheetShowFavicons, false)
    XCTAssertEqual(reloaded.cheatsheetShowDetails, false)
    XCTAssertEqual(reloaded.reactivateBehavior, .nothing)
    XCTAssertEqual(reloaded.screen, .activeWindow)
  }
}
