// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UIComponents",
    platforms: [
        .iOS("15.0"),
        .macOS("11.4")
    ],
    products: [
        .library(
            name: "UIComponents",
            targets: ["UIComponents"]),
    ],
    dependencies: [
        .package(url: "https://github.com/duckduckgo/DesignResourcesKit", from: "4.1.0"),
    ],
    targets: [
        .target(
            name: "UIComponents",
            dependencies: [
                .product(name: "DesignResourcesKit", package: "DesignResourcesKit")
            ]),
        .testTarget(
            name: "UIComponentsTests",
            dependencies: ["UIComponents"]
        ),
    ]
)
