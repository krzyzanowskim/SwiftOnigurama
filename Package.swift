// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Oniguruma",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v12),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "Oniguruma",
            targets: ["Oniguruma"]
        ),
        .library(
            name: "SwiftOniguruma",
            targets: ["SwiftOniguruma"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "Oniguruma",
            url: "https://github.com/krzyzanowskim/SwiftOniguruma/releases/download/6.9.10/Oniguruma.xcframework.zip",
            checksum: "84e56c3d6506fc68c8ffe49f56d043e0b8b6ce6905babab8788a986df7198457"
        ),
        .target(
        	name: "SwiftOniguruma",
        	dependencies: [
        		"Oniguruma"
        	]
        ),
        .testTarget(
            name: "SwiftOnigurumaTests",
            dependencies: [
                "SwiftOniguruma"
            ]
        )
    ]
)
