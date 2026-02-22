import Cocoa
import KeyboardShortcuts

struct CheatsheetData: Encodable {
  var autoOpen: AutoOpenCheatsheetSetting
  var delayMS: Int
  var expandGroups: Bool
  var showAppIcons: Bool
  var showFavicons: Bool
  var showDetails: Bool

  enum CodingKeys: String, CodingKey {
    case autoOpen = "auto_open"
    case delayMS = "delay_ms"
    case expandGroups = "expand_groups"
    case showAppIcons = "show_app_icons"
    case showFavicons = "show_favicons"
    case showDetails = "show_details"
  }

  static let defaults = CheatsheetData(
    autoOpen: .delay,
    delayMS: 2000,
    expandGroups: false,
    showAppIcons: true,
    showFavicons: true,
    showDetails: true
  )
}

extension CheatsheetData: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let d = Self.defaults
    autoOpen =
      (try? container.decode(AutoOpenCheatsheetSetting.self, forKey: .autoOpen)) ?? d.autoOpen
    let rawDelay = (try? container.decode(Int.self, forKey: .delayMS)) ?? d.delayMS
    delayMS = rawDelay > 0 ? rawDelay : d.delayMS
    expandGroups = (try? container.decode(Bool.self, forKey: .expandGroups)) ?? d.expandGroups
    showAppIcons = (try? container.decode(Bool.self, forKey: .showAppIcons)) ?? d.showAppIcons
    showFavicons = (try? container.decode(Bool.self, forKey: .showFavicons)) ?? d.showFavicons
    showDetails = (try? container.decode(Bool.self, forKey: .showDetails)) ?? d.showDetails
  }
}

struct SettingsData: Encodable {
  var activationShortcut: String
  var cheatsheet: CheatsheetData
  var reactivateBehavior: ReactivateBehavior
  var screen: Screen

  enum CodingKeys: String, CodingKey {
    case activationShortcut = "activation_shortcut"
    case cheatsheet
    case reactivateBehavior = "reactivate_behavior"
    case screen
  }

  static let defaults = SettingsData(
    activationShortcut: "control+space",
    cheatsheet: .defaults,
    reactivateBehavior: .hide,
    screen: .primary
  )
}

extension SettingsData: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let d = Self.defaults
    activationShortcut =
      (try? container.decode(String.self, forKey: .activationShortcut)) ?? d.activationShortcut
    cheatsheet =
      (try? container.decode(CheatsheetData.self, forKey: .cheatsheet)) ?? d.cheatsheet
    reactivateBehavior =
      (try? container.decode(ReactivateBehavior.self, forKey: .reactivateBehavior))
      ?? d.reactivateBehavior
    screen = (try? container.decode(Screen.self, forKey: .screen)) ?? d.screen
  }
}

class UserSettings {
  static let shared = UserSettings()

  let fileManager: FileManager
  let directoryPath: String
  var filePath: String {
    (directoryPath as NSString).appendingPathComponent("settings.json")
  }
  var url: URL {
    URL(fileURLWithPath: filePath)
  }

  var activationShortcut: String
  var cheatsheetAutoOpen: AutoOpenCheatsheetSetting
  var cheatsheetDelayMS: Int
  var cheatsheetExpandGroups: Bool
  var cheatsheetShowAppIcons: Bool
  var cheatsheetShowFavicons: Bool
  var cheatsheetShowDetails: Bool
  var reactivateBehavior: ReactivateBehavior
  var screen: Screen

  init(directoryPath: String? = nil, fileManager: FileManager = .default) {
    self.fileManager = fileManager
    self.directoryPath = directoryPath ?? UserConfig.defaultDirectory()

    let d = SettingsData.defaults
    self.activationShortcut = d.activationShortcut
    self.cheatsheetAutoOpen = d.cheatsheet.autoOpen
    self.cheatsheetDelayMS = d.cheatsheet.delayMS
    self.cheatsheetExpandGroups = d.cheatsheet.expandGroups
    self.cheatsheetShowAppIcons = d.cheatsheet.showAppIcons
    self.cheatsheetShowFavicons = d.cheatsheet.showFavicons
    self.cheatsheetShowDetails = d.cheatsheet.showDetails
    self.reactivateBehavior = d.reactivateBehavior
    self.screen = d.screen

    load()
  }

  func load() {
    guard fileManager.fileExists(atPath: filePath) else {
      save()
      return
    }

    do {
      let data = try Data(contentsOf: url)
      let settingsData = try JSONDecoder().decode(SettingsData.self, from: data)
      apply(settingsData)
    } catch {
      print("Failed to load settings.json: \(error)")
    }
  }

  func apply(_ data: SettingsData) {
    activationShortcut = data.activationShortcut
    cheatsheetAutoOpen = data.cheatsheet.autoOpen
    cheatsheetDelayMS = data.cheatsheet.delayMS
    cheatsheetExpandGroups = data.cheatsheet.expandGroups
    cheatsheetShowAppIcons = data.cheatsheet.showAppIcons
    cheatsheetShowFavicons = data.cheatsheet.showFavicons
    cheatsheetShowDetails = data.cheatsheet.showDetails
    reactivateBehavior = data.reactivateBehavior
    screen = data.screen
  }

  func save() {
    let data = SettingsData(
      activationShortcut: activationShortcut,
      cheatsheet: CheatsheetData(
        autoOpen: cheatsheetAutoOpen,
        delayMS: cheatsheetDelayMS,
        expandGroups: cheatsheetExpandGroups,
        showAppIcons: cheatsheetShowAppIcons,
        showFavicons: cheatsheetShowFavicons,
        showDetails: cheatsheetShowDetails
      ),
      reactivateBehavior: reactivateBehavior,
      screen: screen
    )

    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let jsonData = try encoder.encode(data)
      try jsonData.write(to: url, options: .atomic)
    } catch {
      print("Failed to save settings.json: \(error)")
    }
  }

  func applyActivationShortcut() {
    guard let shortcut = ShortcutParser.parse(activationShortcut) else {
      print("Failed to parse activation shortcut: \(activationShortcut)")
      return
    }

    KeyboardShortcuts.setShortcut(shortcut, for: .activate)
  }
}
