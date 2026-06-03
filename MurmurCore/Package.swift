// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MurmurCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "MurmurCore", targets: ["MurmurCore"])
    ],
    targets: [
        .target(
            name: "MurmurCore",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "MurmurCoreTests",
            dependencies: ["MurmurCore"]
        )
    ]
)
