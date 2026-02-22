import Cocoa
import KeyboardShortcuts

enum ShortcutParser {
  static func parse(_ string: String) -> KeyboardShortcuts.Shortcut? {
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

    guard let key = key(for: keyPart) else { return nil }

    return KeyboardShortcuts.Shortcut(key, modifiers: modifiers)
  }

  private static func key(for name: String) -> KeyboardShortcuts.Key? {
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
      return characterToKey[name]
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
    ";": .semicolon, "'": .quote, ",": .comma, ".": .period,
    "/": .slash, "\\": .backslash, "-": .minus, "=": .equal,
    "`": .backtick, "[": .leftBracket, "]": .rightBracket,
  ]
}
