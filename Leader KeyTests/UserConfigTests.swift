import XCTest

@testable import Leader_Key

class TestAlertManager: AlertHandler {
  var shownAlerts: [(style: NSAlert.Style, message: String)] = []

  func showAlert(style: NSAlert.Style, message: String) {
    shownAlerts.append((style: style, message: message))
  }

  func showAlert(
    style: NSAlert.Style, message: String, informativeText: String, buttons: [String]
  ) -> NSApplication.ModalResponse {
    shownAlerts.append((style: style, message: message))
    return .alertFirstButtonReturn
  }

  func reset() {
    shownAlerts = []
  }
}

final class UserConfigTests: XCTestCase {
  var tempBaseDir: String!
  var testAlertManager: TestAlertManager!
  var subject: UserConfig!

  override func setUp() {
    super.setUp()

    // Create a unique temporary directory for each test
    tempBaseDir = NSTemporaryDirectory().appending("/LeaderKeyTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(atPath: tempBaseDir, withIntermediateDirectories: true)

    testAlertManager = TestAlertManager()
    subject = UserConfig(alertHandler: testAlertManager, configDirectory: tempBaseDir)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(atPath: tempBaseDir)
    testAlertManager.reset()
    subject = nil
    super.tearDown()
  }

  func testInitializesWithDefaults() throws {
    subject.ensureAndLoad()
    waitForConfigLoad()

    XCTAssertNotEqual(subject.root, emptyRoot)
    XCTAssertTrue(subject.exists)
    XCTAssertEqual(testAlertManager.shownAlerts.count, 0)
  }

  func testCreatesConfigDirIfNotExists() throws {
    let newDir = tempBaseDir.appending("/subdir")
    let newSubject = UserConfig(
      alertHandler: testAlertManager, configDirectory: newDir)

    newSubject.ensureAndLoad()
    waitForConfigLoad()

    XCTAssertTrue(FileManager.default.fileExists(atPath: newDir))
    XCTAssertTrue(newSubject.exists)
    XCTAssertEqual(testAlertManager.shownAlerts.count, 0)
    XCTAssertNotEqual(newSubject.root, emptyRoot)
  }

  func testShowsAlertWhenConfigFileFailsToParse() throws {
    let invalidJSON = "{ invalid json }"
    try invalidJSON.write(to: subject.url, atomically: true, encoding: .utf8)

    subject.ensureAndLoad()
    waitForConfigLoad()

    XCTAssertEqual(subject.root, emptyRoot)
    XCTAssertGreaterThan(testAlertManager.shownAlerts.count, 0)
    XCTAssertTrue(
      testAlertManager.shownAlerts.contains { alert in
        alert.style == .warning
      })
  }

  func testValidationIssuesDoNotTriggerAlerts() throws {
    let json = """
      {
        "actions": [
          { "key": "a", "type": "application", "value": "/Applications/Safari.app" },
          { "key": "a", "type": "url", "value": "https://example.com" }
        ]
      }
      """

    try json.write(to: subject.url, atomically: true, encoding: .utf8)

    subject.ensureAndLoad()
    waitForConfigLoad()

    XCTAssertFalse(subject.validationErrors.isEmpty)
    XCTAssertEqual(testAlertManager.shownAlerts.count, 0)

    testAlertManager.reset()
    subject.saveConfig()

    XCTAssertFalse(subject.validationErrors.isEmpty)
    XCTAssertEqual(testAlertManager.shownAlerts.count, 0)
  }

  func testParsesGlobalShortcutOnGroup() throws {
    let json = """
      {
        "actions": [
          {
            "key": "o",
            "type": "group",
            "label": "Open",
            "global_shortcut": "control+o",
            "actions": [
              { "key": "s", "type": "application", "value": "/Applications/Safari.app" }
            ]
          },
          {
            "key": "a",
            "type": "group",
            "actions": [
              { "key": "t", "type": "application", "value": "/Applications/Terminal.app" }
            ]
          }
        ]
      }
      """

    try json.write(to: subject.url, atomically: true, encoding: .utf8)
    subject.ensureAndLoad()
    waitForConfigLoad()

    // First group has globalShortcut
    if case .group(let group) = subject.root.actions[0] {
      XCTAssertEqual(group.globalShortcut, "control+o")
    } else {
      XCTFail("Expected first action to be a group")
    }

    // Second group has no globalShortcut
    if case .group(let group) = subject.root.actions[1] {
      XCTAssertNil(group.globalShortcut)
    } else {
      XCTFail("Expected second action to be a group")
    }
  }

  func testGlobalShortcutRoundTrips() throws {
    let json = """
      {
        "actions": [
          {
            "key": "o",
            "type": "group",
            "global_shortcut": "command+shift+o",
            "actions": [
              { "key": "s", "type": "application", "value": "/Applications/Safari.app" }
            ]
          }
        ]
      }
      """

    try json.write(to: subject.url, atomically: true, encoding: .utf8)
    subject.ensureAndLoad()
    waitForConfigLoad()

    // Save and reload
    subject.saveConfig()
    subject.reloadFromFile()
    waitForConfigLoad()

    if case .group(let group) = subject.root.actions[0] {
      XCTAssertEqual(group.globalShortcut, "command+shift+o")
    } else {
      XCTFail("Expected first action to be a group")
    }
  }

  private func waitForConfigLoad() {
    let expectation = expectation(description: "config load flush")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      expectation.fulfill()
    }
    self.wait(for: [expectation], timeout: 1.0)
  }
}
