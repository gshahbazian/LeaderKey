import Cocoa

enum AutoOpenCheatsheetSetting: String {
  case never
  case always
  case delay
}

enum ModifierKeyConfig: String, Codable, CaseIterable, Identifiable {
  case controlGroupOptionSticky
  case optionGroupControlSticky

  var id: Self { self }

  var description: String {
    switch self {
    case .controlGroupOptionSticky:
      return "⌃ Group sequences, ⌥ Sticky mode"
    case .optionGroupControlSticky:
      return "⌥ Group sequences, ⌃ Sticky mode"
    }
  }
}

enum ReactivateBehavior: String {
  case hide
  case reset
  case nothing
}

enum Screen: String {
  case primary
  case mouse
  case activeWindow
}
