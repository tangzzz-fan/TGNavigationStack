// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TGNavigationStack",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "TGNavigationStack",
            targets: ["TGNavigationStack"]
        ),
    ],
    targets: [
        .target(
            name: "TGNavigationStack"
        ),
        .testTarget(
            name: "TGNavigationStackTests",
            dependencies: ["TGNavigationStack"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
