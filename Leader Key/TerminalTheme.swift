import SwiftUI

enum TerminalTheme {
  // MARK: - Colors

  static let background = Color(hex: 0x101010)
  static let foreground = Color(hex: 0xFFFFFF)
  static let cursor = Color(hex: 0xFFC799)
  static let dim = Color(hex: 0x505050)
  static let secondary = Color(hex: 0xA0A0A0)
  static let selectionBg = Color(hex: 0x2A2A2A)
  static let red = Color(hex: 0xFF8080)
  static let green = Color(hex: 0x99FFE4)

  // MARK: - Fonts

  static let font: Font = .system(size: 14, weight: .medium, design: .monospaced)
  static let badgeFont: Font = .system(size: 13, weight: .bold, design: .monospaced)

  // MARK: - Text tokens

  static let separator = "/"
  static let emptyIndicator = "█"
  static let groupIndicator = ">"
}

extension Color {
  init(hex: UInt32) {
    let r = Double((hex >> 16) & 0xFF) / 255.0
    let g = Double((hex >> 8) & 0xFF) / 255.0
    let b = Double(hex & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}
