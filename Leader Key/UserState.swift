import Combine
import Foundation
import SwiftUI

final class UserState: ObservableObject {
  var userConfig: UserConfig!

  @Published var display: String?
  @Published var isShowingRefreshState: Bool
  @Published var navigationPath: [Group] = []

  private var configCancellable: AnyCancellable?

  var currentGroup: Group? {
    return navigationPath.last
  }

  init(
    userConfig: UserConfig!,
    lastChar: String? = nil,
    isShowingRefreshState: Bool = false
  ) {
    self.userConfig = userConfig
    display = lastChar
    self.isShowingRefreshState = isShowingRefreshState
    self.navigationPath = []

    // Forward config changes so SwiftUI views that observe UserState
    // re-render when the config root updates (e.g. after async load).
    configCancellable = userConfig?.objectWillChange.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
  }

  func clear() {
    display = nil
    navigationPath = []
    isShowingRefreshState = false
  }

  func navigateToGroup(_ group: Group) {
    navigationPath.append(group)
  }
}
