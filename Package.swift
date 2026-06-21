// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CursorDVD",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CursorDVD", targets: ["CursorDVD"])
    ],
    targets: [
        .executableTarget(
            name: "CursorDVD",
            dependencies: [],
            path: "Sources/CursorDVD"
        )
    ]
)
