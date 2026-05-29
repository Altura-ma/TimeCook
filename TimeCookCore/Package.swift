// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TimeCookCore",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "TimeCookCore", targets: ["TimeCookCore"])
    ],
    targets: [
        .target(name: "TimeCookCore"),
        .testTarget(name: "TimeCookCoreTests", dependencies: ["TimeCookCore"])
    ]
)
