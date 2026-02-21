import Cocoa
import Defaults
import KeyboardShortcuts
import SwiftUI
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,
  UNUserNotificationCenterDelegate
{
  var controller: Controller!

  let statusItem = StatusItem()
  let config = UserConfig()

  var state: UserState!

  func applicationDidFinishLaunching(_: Notification) {

    guard
      ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
    else { return }
    guard !isRunningTests() else { return }

    NSApp.mainMenu = MainMenu()

    config.ensureAndLoad()
    state = UserState(userConfig: config)
    controller = Controller(userState: state, userConfig: config)

    statusItem.handleAbout = {
      NSApp.orderFrontStandardAboutPanel(nil)
    }
    statusItem.handleReloadConfig = {
      self.config.reloadFromFile()
    }
    statusItem.handleRevealConfig = {
      let dirURL = URL(fileURLWithPath: UserConfig.defaultDirectory(), isDirectory: true)
      NSWorkspace.shared.activateFileViewerSelecting([dirURL])
    }
    statusItem.handleEditConfig = {
      NSWorkspace.shared.open(self.config.url)
    }
    statusItem.handleEditSettings = {
      NSWorkspace.shared.open(UserSettings.shared.url)
    }

    statusItem.enable()

    // Set activation policy to accessory (background app)
    NSApp.setActivationPolicy(.accessory)

    // Apply activation shortcut from settings and register global shortcuts
    UserSettings.shared.applyActivationShortcut()
    registerGlobalShortcuts()
  }

  func activate() {
    if self.controller.window.isKeyWindow {
      switch UserSettings.shared.reactivateBehavior {
      case .hide:
        self.hide()
      case .reset:
        self.controller.userState.clear()
      case .nothing:
        return
      }
    } else if self.controller.window.isVisible {
      self.controller.window.makeKeyAndOrderFront(nil)
    } else {
      self.show()
    }
  }

  public func registerGlobalShortcuts() {
    KeyboardShortcuts.removeAllHandlers()

    KeyboardShortcuts.onKeyDown(for: .activate) {
      self.activate()
    }

    for groupKey in Defaults[.groupShortcuts] {
      print("Registering shortcut for \(groupKey)")
      KeyboardShortcuts.onKeyDown(for: KeyboardShortcuts.Name("group-\(groupKey)")) {
        if !self.controller.window.isVisible {
          self.activate()
        }
        self.processKeys([groupKey])
      }
    }
    if Defaults[.groupShortcuts].isEmpty && !KeyboardShortcuts.isEnabled(for: .activate) {
      // No activation shortcut set — write default to settings
      UserSettings.shared.activationShortcut = "control+space"
      UserSettings.shared.applyActivationShortcut()
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    // Config saves automatically on changes
  }

  func show() {
    controller.show()
  }

  func hide() {
    controller.hide()
  }

  func isRunningTests() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard environment["XCTestSessionIdentifier"] != nil else { return false }
    return true
  }

  private func processKeys(_ keys: [String], execute: Bool = true) {
    guard !keys.isEmpty else { return }

    controller.handleKey(keys[0], execute: execute)

    if keys.count > 1 {
      let remainingKeys = Array(keys.dropFirst())

      var delayMs = 100
      for key in remainingKeys {
        delay(delayMs) { [weak self] in
          self?.controller.handleKey(key, execute: execute)
        }
        delayMs += 100
      }
    }
  }
}
