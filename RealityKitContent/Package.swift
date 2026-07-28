// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RealityKitContent",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "RealityKitContent",
            targets: ["RealityKitContent"]
        )
    ],
    targets: [
        .target(
            name: "RealityKitContent",
            resources: [.process("Resources")]
        )
    ]
)
