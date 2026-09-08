// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BlankSpaceCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "BlankSpaceCore", targets: ["BlankSpaceCore"]),
    ],
    targets: [
        .target(
            name: "BlankSpaceCore",
            resources: [.process("Resources")]
        ),
        .testTarget(name: "BlankSpaceCoreTests", dependencies: ["BlankSpaceCore"]),
    ]
)
