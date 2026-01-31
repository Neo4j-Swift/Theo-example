// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "theo-example",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/Neo4j-Swift/Neo4j-Swift.git", from: "6.0.0")
    ],
    targets: [
        .executableTarget(
            name: "theo-example",
            dependencies: [
                .product(name: "Theo", package: "Neo4j-Swift")
            ],
            path: "Sources"
        )
    ]
)
