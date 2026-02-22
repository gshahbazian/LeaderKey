import Cocoa
import KeyboardShortcuts
import SwiftUI
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  var controller: Controller!

  let statusItem = StatusItem()
  let config = UserConfig()

  var state: UserState!

  func applicationDidFinishLaunching(_: Notification) {
    guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
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
      self.registerGlobalShortcuts()
      UserSettings.shared.load()
      UserSettings.shared.applyActivationShortcut()
      self.controller.showReloadFeedback()
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

    // Wire up status item appearance to controller lifecycle
    controller.onActivate = { [weak self] in
      self?.statusItem.appearance = .active
    }
    controller.onDeactivate = { [weak self] in
      self?.statusItem.appearance = .normal
    }

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

  func registerGlobalShortcuts() {
    KeyboardShortcuts.removeAllHandlers()

    KeyboardShortcuts.onKeyDown(for: .activate) {
      self.activate()
    }

    let actions = config.root.actions
    for case .group(let group) in actions {
      guard let shortcutString = group.globalShortcut,
        let shortcut = ShortcutParser.parse(shortcutString),
        let groupKey = group.key
      else { continue }

      let name = KeyboardShortcuts.Name("group-\(groupKey)")
      KeyboardShortcuts.setShortcut(shortcut, for: name)
      KeyboardShortcuts.onKeyDown(for: name) {
        if !self.controller.window.isVisible {
          self.activate()
        }
        self.processKeys([groupKey])
      }
    }

    if !KeyboardShortcuts.isEnabled(for: .activate) {
      // No activation shortcut set — write default to settings
      UserSettings.shared.activationShortcut = "control+space"
      UserSettings.shared.applyActivationShortcut()
    }
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

  func processKeys(_ keys: [String], execute: Bool = true) {
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
