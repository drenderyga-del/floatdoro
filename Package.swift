// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Floatdoro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Floatdoro", targets: ["Floatdoro"])
    ],
    targets: [
        .executableTarget(
            name: "Floatdoro",
            path: "Sources/Pomo"
        ),
        .testTarget(
            name: "FloatdoroTests",
            dependencies: ["Floatdoro"],
            path: "Tests/PomoTests"
        )
    ]
)
