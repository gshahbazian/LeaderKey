import Cocoa

enum AutoOpenCheatsheetSetting: String {
  case never
  case always
  case delay
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
