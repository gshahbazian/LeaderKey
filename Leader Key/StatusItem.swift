import Cocoa
import ServiceManagement

class StatusItem {
  enum Appearance {
    case normal
    case active
  }

  var appearance: Appearance = .normal {
    didSet {
      updateStatusItemAppearance()
    }
  }

  var statusItem: NSStatusItem?

  var handleAbout: (() -> Void)?
  var handleReloadConfig: (() -> Void)?
  var handleRevealConfig: (() -> Void)?
  var handleEditConfig: (() -> Void)?
  var handleEditSettings: (() -> Void)?

  private var launchAtLoginItem: NSMenuItem?

  func enable() {
    statusItem = NSStatusBar.system.statusItem(
      withLength: NSStatusItem.squareLength)

    guard let item = statusItem else {
      print("No status item")
      return
    }

    if let menubarButton = item.button {
      menubarButton.image = NSImage(named: NSImage.Name("StatusItem"))
    }

    let menu = NSMenu()

    // About
    let aboutItem = NSMenuItem(
      title: "About Leader Key", action: #selector(showAbout),
      keyEquivalent: ""
    )
    aboutItem.target = self
    menu.addItem(aboutItem)

    menu.addItem(NSMenuItem.separator())

    // Launch at Login
    let loginItem = NSMenuItem(
      title: "Launch at Login", action: #selector(toggleLaunchAtLogin),
      keyEquivalent: ""
    )
    loginItem.target = self
    loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    launchAtLoginItem = loginItem
    menu.addItem(loginItem)

    menu.addItem(NSMenuItem.separator())

    // Edit Config
    let editConfigItem = NSMenuItem(
      title: "Edit Config", action: #selector(editConfig),
      keyEquivalent: ""
    )
    editConfigItem.target = self
    menu.addItem(editConfigItem)

    // Edit Settings
    let editSettingsItem = NSMenuItem(
      title: "Edit Settings", action: #selector(editSettings),
      keyEquivalent: ""
    )
    editSettingsItem.target = self
    menu.addItem(editSettingsItem)

    // Reveal Config in Finder
    let revealConfigItem = NSMenuItem(
      title: "Reveal Config in Finder", action: #selector(revealConfigFile),
      keyEquivalent: ""
    )
    revealConfigItem.target = self
    menu.addItem(revealConfigItem)

    // Reload Config
    let reloadConfigItem = NSMenuItem(
      title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: ""
    )
    reloadConfigItem.target = self
    menu.addItem(reloadConfigItem)

    menu.addItem(NSMenuItem.separator())

    // Quit
    menu.addItem(
      NSMenuItem(
        title: "Quit Leader Key",
        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      ))

    item.menu = menu

    updateStatusItemAppearance()
  }

  func disable() {
    guard let item = statusItem else { return }

    NSStatusBar.system.removeStatusItem(item)
    statusItem = nil
  }

  @objc func showAbout() {
    handleAbout?()
  }

  @objc func reloadConfig() {
    handleReloadConfig?()
  }

  @objc func revealConfigFile() {
    handleRevealConfig?()
  }

  @objc func editConfig() {
    handleEditConfig?()
  }

  @objc func editSettings() {
    handleEditSettings?()
  }

  @objc func toggleLaunchAtLogin() {
    let service = SMAppService.mainApp
    do {
      if service.status == .enabled {
        try service.unregister()
      } else {
        try service.register()
      }
    } catch {
      print("Failed to toggle launch at login: \(error)")
    }
    launchAtLoginItem?.state = service.status == .enabled ? .on : .off
  }

  private func updateStatusItemAppearance() {
    guard let button = statusItem?.button else { return }

    switch appearance {
    case .normal:
      button.image = NSImage(named: NSImage.Name("StatusItem"))
    case .active:
      button.image = NSImage(named: NSImage.Name("StatusItem-filled"))
    }
  }
}
