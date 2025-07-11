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
            checksum: "1c7167edb3285e89125c2eb2c974ddf6df8e0fb38d95183b581d67ea9af07fdb"
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
