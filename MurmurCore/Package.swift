// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MurmurCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "MurmurCore", targets: ["MurmurCore"])
    ],
    targets: [
        .target(name: "MurmurCore"),
        .testTarget(
            name: "MurmurCoreTests",
            dependencies: ["MurmurCore"]
        )
    ]
)
