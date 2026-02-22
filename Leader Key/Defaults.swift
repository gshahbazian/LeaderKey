import Cocoa

enum AutoOpenCheatsheetSetting: String, Codable {
  case never
  case always
  case delay

  init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    switch value {
    case "always": self = .always
    case "after_delay": self = .delay
    case "never": self = .never
    default:
      throw DecodingError.dataCorruptedError(
        in: try decoder.singleValueContainer(),
        debugDescription: "Unknown auto_open value: \(value)")
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .always: try container.encode("always")
    case .delay: try container.encode("after_delay")
    case .never: try container.encode("never")
    }
  }
}

enum ReactivateBehavior: String, Codable {
  case hide
  case reset
  case nothing
}

enum Screen: String, Codable {
  case primary
  case mouse
  case activeWindow

  init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    switch value {
    case "primary": self = .primary
    case "mouse": self = .mouse
    case "active_window": self = .activeWindow
    default:
      throw DecodingError.dataCorruptedError(
        in: try decoder.singleValueContainer(),
        debugDescription: "Unknown screen value: \(value)")
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .primary: try container.encode("primary")
    case .mouse: try container.encode("mouse")
    case .activeWindow: try container.encode("active_window")
    }
  }
}
