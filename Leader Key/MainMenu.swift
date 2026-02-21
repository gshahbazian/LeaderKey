import Cocoa

class MainMenu: NSMenu {
  init() {
    super.init(title: "MainMenu")

    let appMenu = NSMenuItem()
    appMenu.submenu = NSMenu(title: "Leader Key")
    appMenu.submenu?.items = [
      NSMenuItem(
        title: "About Leader Key",
        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
      .separator(),
      NSMenuItem(
        title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"),
      .separator(),
      NSMenuItem(
        title: "Quit Leader Key", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      ),
    ]

    items = [appMenu]
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
