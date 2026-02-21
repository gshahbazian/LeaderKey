import Cocoa
import KeyboardShortcuts

class UserSettings {
  static let shared = UserSettings()

  private let fileManager: FileManager
  private let directoryPath: String
  private var filePath: String {
    (directoryPath as NSString).appendingPathComponent("settings.json")
  }
  var url: URL {
    URL(fileURLWithPath: filePath)
  }

  // MARK: - Settings properties

  var activationShortcut: String {
    didSet {
      if activationShortcut != oldValue {
        save()
        applyActivationShortcut()
      }
    }
  }

  var modifierKeys: ModifierKeyConfig {
    didSet { if modifierKeys != oldValue { save() } }
  }

  var cheatsheetAutoOpen: AutoOpenCheatsheetSetting {
    didSet { if cheatsheetAutoOpen != oldValue { save() } }
  }

  var cheatsheetDelayMS: Int {
    didSet { if cheatsheetDelayMS != oldValue { save() } }
  }

  var cheatsheetExpandGroups: Bool {
    didSet { if cheatsheetExpandGroups != oldValue { save() } }
  }

  var cheatsheetShowAppIcons: Bool {
    didSet { if cheatsheetShowAppIcons != oldValue { save() } }
  }

  var cheatsheetShowFavicons: Bool {
    didSet { if cheatsheetShowFavicons != oldValue { save() } }
  }

  var cheatsheetShowDetails: Bool {
    didSet { if cheatsheetShowDetails != oldValue { save() } }
  }

  var reactivateBehavior: ReactivateBehavior {
    didSet { if reactivateBehavior != oldValue { save() } }
  }

  var screen: Screen {
    didSet { if screen != oldValue { save() } }
  }

  // MARK: - Init

  init(directoryPath: String? = nil, fileManager: FileManager = .default) {
    self.fileManager = fileManager
    self.directoryPath = directoryPath ?? UserConfig.defaultDirectory()

    // Set defaults before loading
    self.activationShortcut = "control+space"
    self.modifierKeys = .controlGroupOptionSticky
    self.cheatsheetAutoOpen = .delay
    self.cheatsheetDelayMS = 2000
    self.cheatsheetExpandGroups = false
    self.cheatsheetShowAppIcons = true
    self.cheatsheetShowFavicons = true
    self.cheatsheetShowDetails = true
    self.reactivateBehavior = .hide
    self.screen = .primary

    load()
  }

  // MARK: - Load

  func load() {
    guard fileManager.fileExists(atPath: filePath) else {
      save()
      return
    }

    do {
      let data = try Data(contentsOf: url)
      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return
      }
      apply(json)
    } catch {
      print("Failed to load settings.json: \(error)")
    }
  }

  private func apply(_ json: [String: Any]) {
    if let v = json["activation_shortcut"] as? String {
      activationShortcut = v
    }
    if let v = json["modifier_keys"] as? String,
      let parsed = ModifierKeyConfig.fromSettingsString(v)
    {
      modifierKeys = parsed
    }
    if let cheatsheet = json["cheatsheet"] as? [String: Any] {
      if let v = cheatsheet["auto_open"] as? String,
        let parsed = AutoOpenCheatsheetSetting.fromSettingsString(v)
      {
        cheatsheetAutoOpen = parsed
      }
      if let v = cheatsheet["delay_ms"] as? Int, v > 0 {
        cheatsheetDelayMS = v
      }
      if let v = cheatsheet["expand_groups"] as? Bool {
        cheatsheetExpandGroups = v
      }
      if let v = cheatsheet["show_app_icons"] as? Bool {
        cheatsheetShowAppIcons = v
      }
      if let v = cheatsheet["show_favicons"] as? Bool {
        cheatsheetShowFavicons = v
      }
      if let v = cheatsheet["show_details"] as? Bool {
        cheatsheetShowDetails = v
      }
    }
    if let v = json["reactivate_behavior"] as? String,
      let parsed = ReactivateBehavior.fromSettingsString(v)
    {
      reactivateBehavior = parsed
    }
    if let v = json["screen"] as? String,
      let parsed = Screen.fromSettingsString(v)
    {
      screen = parsed
    }
  }

  // MARK: - Save

  func save() {
    let json: [String: Any] = [
      "activation_shortcut": activationShortcut,
      "modifier_keys": modifierKeys.settingsString,
      "cheatsheet": [
        "auto_open": cheatsheetAutoOpen.settingsString,
        "delay_ms": cheatsheetDelayMS,
        "expand_groups": cheatsheetExpandGroups,
        "show_app_icons": cheatsheetShowAppIcons,
        "show_favicons": cheatsheetShowFavicons,
        "show_details": cheatsheetShowDetails,
      ] as [String: Any],
      "reactivate_behavior": reactivateBehavior.settingsString,
      "screen": screen.settingsString,
    ]

    do {
      let data = try JSONSerialization.data(
        withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
      try data.write(to: url, options: .atomic)
    } catch {
      print("Failed to save settings.json: \(error)")
    }
  }

  // MARK: - Activation Shortcut

  func applyActivationShortcut() {
    guard let shortcut = parseShortcutString(activationShortcut) else {
      print("Failed to parse activation shortcut: \(activationShortcut)")
      return
    }
    KeyboardShortcuts.setShortcut(shortcut, for: .activate)
  }

  func parseShortcutString(_ string: String) -> KeyboardShortcuts.Shortcut? {
    let parts = string.lowercased().split(separator: "+").map(String.init)
    guard parts.count >= 1 else { return nil }

    var modifiers: NSEvent.ModifierFlags = []
    let keyPart = parts.last!

    for modifier in parts.dropLast() {
      switch modifier {
      case "command", "cmd": modifiers.insert(.command)
      case "shift": modifiers.insert(.shift)
      case "control", "ctrl": modifiers.insert(.control)
      case "option", "opt", "alt": modifiers.insert(.option)
      default: break
      }
    }

    guard let key = keyboardShortcutsKey(for: keyPart) else { return nil }

    return KeyboardShortcuts.Shortcut(key, modifiers: modifiers)
  }

  private func keyboardShortcutsKey(for name: String) -> KeyboardShortcuts.Key? {
    switch name {
    case "space": return .space
    case "enter", "return": return .return
    case "tab": return .tab
    case "escape", "esc": return .escape
    case "delete", "backspace": return .delete
    case "up": return .upArrow
    case "down": return .downArrow
    case "left": return .leftArrow
    case "right": return .rightArrow
    case "f1": return .f1
    case "f2": return .f2
    case "f3": return .f3
    case "f4": return .f4
    case "f5": return .f5
    case "f6": return .f6
    case "f7": return .f7
    case "f8": return .f8
    case "f9": return .f9
    case "f10": return .f10
    case "f11": return .f11
    case "f12": return .f12
    default:
      // Single character key — map via the letter/number lookup
      return Self.characterToKey[name]
    }
  }

  private static let characterToKey: [String: KeyboardShortcuts.Key] = [
    "a": .a, "b": .b, "c": .c, "d": .d, "e": .e, "f": .f,
    "g": .g, "h": .h, "i": .i, "j": .j, "k": .k, "l": .l,
    "m": .m, "n": .n, "o": .o, "p": .p, "q": .q, "r": .r,
    "s": .s, "t": .t, "u": .u, "v": .v, "w": .w, "x": .x,
    "y": .y, "z": .z,
    "0": .zero, "1": .one, "2": .two, "3": .three, "4": .four,
    "5": .five, "6": .six, "7": .seven, "8": .eight, "9": .nine,
  ]
}

// MARK: - Settings string conversions

extension ModifierKeyConfig {
  var settingsString: String {
    switch self {
    case .controlGroupOptionSticky: return "control_group_option_sticky"
    case .optionGroupControlSticky: return "option_group_control_sticky"
    }
  }

  static func fromSettingsString(_ s: String) -> ModifierKeyConfig? {
    switch s {
    case "control_group_option_sticky": return .controlGroupOptionSticky
    case "option_group_control_sticky": return .optionGroupControlSticky
    default: return nil
    }
  }
}

extension AutoOpenCheatsheetSetting {
  var settingsString: String {
    switch self {
    case .always: return "always"
    case .delay: return "after_delay"
    case .never: return "never"
    }
  }

  static func fromSettingsString(_ s: String) -> AutoOpenCheatsheetSetting? {
    switch s {
    case "always": return .always
    case "after_delay": return .delay
    case "never": return .never
    default: return nil
    }
  }
}

extension ReactivateBehavior {
  var settingsString: String {
    rawValue
  }

  static func fromSettingsString(_ s: String) -> ReactivateBehavior? {
    ReactivateBehavior(rawValue: s)
  }
}

extension Screen {
  var settingsString: String {
    switch self {
    case .primary: return "primary"
    case .mouse: return "mouse"
    case .activeWindow: return "active_window"
    }
  }

  static func fromSettingsString(_ s: String) -> Screen? {
    switch s {
    case "primary": return .primary
    case "mouse": return .mouse
    case "active_window": return .activeWindow
    default: return nil
    }
  }
}
