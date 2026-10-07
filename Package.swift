// swift-tools-version: 6.0
// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

// Only upcoming features that Swift 6 language mode does not already enable.
// Consumers that build this package in Swift 5 mode (for example Tuist's
// SWIFT_VERSION 5.0 override) still compile it with the same import rules.
let swiftSettings: [SwiftSetting] = [
  SwiftSetting.enableUpcomingFeature("ExistentialAny"),
  SwiftSetting.enableUpcomingFeature("InternalImportsByDefault")
]

let package = Package(
  name: "FelinePine",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .visionOS(.v1),
    .watchOS(.v10)
  ],
  products: [
    .library(
      name: "FelinePine",
      targets: ["FelinePine"]
    )
  ],
  targets: [
    .target(
      name: "FelinePine",
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "FelinePineTests",
      dependencies: ["FelinePine"]
    )
  ]
)
// swiftlint:enable explicit_acl explicit_top_level_acl
