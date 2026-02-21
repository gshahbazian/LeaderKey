import Foundation
import SwiftUI

struct CursorBlink: ViewModifier {
  @State var visible: Bool = true

  static let singleDurationS = 0.15

  func body(content: Content) -> some View {
    content.onAppear {
      withAnimation(
        Animation.easeInOut(duration: 0.08).repeatForever(autoreverses: true)
      ) {
        visible.toggle()
      }
    }
    .opacity(visible ? 1 : 0)
  }
}

extension View {
  func cursorBlink() -> some View {
    self.modifier(CursorBlink())
  }
}
