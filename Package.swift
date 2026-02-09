// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DynamicNotch",
    platforms: [
        .macOS(.v14) // Target modern macOS
    ],
    products: [
        .executable(name: "DynamicNotch", targets: ["DynamicNotch"])
    ],
    targets: [
        .executableTarget(
            name: "DynamicNotch",
            path: "Sources"
        )
    ]
)
