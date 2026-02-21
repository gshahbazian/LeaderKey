import SwiftUI

struct TerminalBackground: View {
  var body: some View {
    Rectangle()
      .fill(TerminalTheme.background)
      .overlay(
        Rectangle()
          .strokeBorder(TerminalTheme.dim, lineWidth: 1)
      )
  }
}
