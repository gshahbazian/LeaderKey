// swift-tools-version:6.1
import PackageDescription

let package = Package(
  name: "LeaderKey",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "leaderkey", targets: ["Leader_Key"])
  ],
  dependencies: [
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "2.4.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", exact: "8.5.0"),
  ],
  targets: [
    .executableTarget(
      name: "Leader_Key",
      dependencies: [
        .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
        .product(name: "Kingfisher", package: "Kingfisher"),
      ],
      path: "Leader Key",
      swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .testTarget(
      name: "LeaderKeyTests",
      dependencies: ["Leader_Key"],
      path: "Leader KeyTests",
      swiftSettings: [.swiftLanguageMode(.v5)]
    ),
  ]
)
