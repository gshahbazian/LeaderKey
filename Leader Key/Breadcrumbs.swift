import SwiftUI

enum Breadcrumbs {
  static let dimension = 36.0
  static let margin = 8.0
  static let padding = 13.0

  class Window: MainWindow {
    required init(controller: Controller) {
      super.init(
        controller: controller,
        contentRect: NSRect(x: 0, y: 0, width: 0, height: 0))

      let view = MainView().environment(self.controller.userState)
      contentView = NSHostingView(rootView: view)
    }

    override func show(on screen: NSScreen, after: (() -> Void)? = nil) {
      if controller.userState.navigationPath.isEmpty == true {
        self.setFrame(
          CGRect(
            x: Breadcrumbs.margin,
            y: Breadcrumbs.margin,
            width: Breadcrumbs.dimension,
            height: Breadcrumbs.dimension),
          display: true)
      } else {
        self.setFrame(
          CGRect(
            x: Breadcrumbs.margin,
            y: Breadcrumbs.margin,
            width: 200,
            height: Breadcrumbs.dimension),
          display: true)

        self.contentAspectRatio = NSSize(width: 0, height: Breadcrumbs.dimension)
        self.contentMinSize = NSSize(width: 80, height: Breadcrumbs.dimension)
        self.contentMaxSize = NSSize(
          width: screen.frame.width - (Breadcrumbs.margin * 2),
          height: Breadcrumbs.dimension
        )
      }
      let newOriginX = screen.visibleFrame.origin.x + Breadcrumbs.margin
      let newOriginY = screen.visibleFrame.origin.y + Breadcrumbs.margin
      self.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))

      makeKeyAndOrderFront(nil)

      fadeIn {
        after?()
      }
    }

    override func hide(after: (() -> Void)? = nil) {
      fadeOut {
        super.hide(after: after)
      }
    }

    override func notFound() {
      shake()
    }

    override func cheatsheetOrigin(cheatsheetSize: NSSize) -> NSPoint {
      return NSPoint(
        x: frame.minX,
        y: frame.maxY + Breadcrumbs.margin)
    }
  }

  struct MainView: View {
    @Environment(UserState.self) var userState

    var breadcrumbPath: [String] {
      return userState.navigationPath.map(\.displayName)
    }

    var body: some View {
      HStack(spacing: 0) {
        if breadcrumbPath.isEmpty {
          let text = Text(TerminalTheme.emptyIndicator)
            .foregroundStyle(TerminalTheme.cursor)
            .padding(.horizontal, Breadcrumbs.padding)

          if userState.isShowingRefreshState {
            text.cursorBlink()
          } else {
            text
          }
        } else {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
              ForEach(Array(breadcrumbPath.enumerated()), id: \.offset) { index, name in
                if index > 0 {
                  Text(TerminalTheme.separator)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(TerminalTheme.dim)
                }

                let text = Text(name)
                  .lineLimit(1)
                  .truncationMode(.middle)

                if userState.isShowingRefreshState {
                  text.cursorBlink()
                } else {
                  text
                }
              }
            }
            .padding(.horizontal, Breadcrumbs.padding)
          }
        }
      }
      .frame(height: Breadcrumbs.dimension)
      .fixedSize(horizontal: true, vertical: true)
      .font(TerminalTheme.font)
      .foregroundStyle(TerminalTheme.foreground)
      .background(TerminalBackground())
    }
  }
}
