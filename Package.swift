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
            name: "SwiftOnigurama",
            targets: ["SwiftOnigurama"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "Oniguruma",
            url: "https://github.com/krzyzanowskim/oniguruma/releases/download/6.9.10/Oniguruma.xcframework.zip",
            checksum: "f06fb4086a17d0e805a1e1564932f1ad12db7537df9ec3bcb4328232c16f14aa"
        ),
        .target(
        	name: "SwiftOnigurama",
        	dependencies: [
        		"Oniguruma"
        	]
        ),
        .testTarget(
            name: "SwiftOniguramaTests",
            dependencies: [
                "SwiftOnigurama"
            ]
        )
    ]
)