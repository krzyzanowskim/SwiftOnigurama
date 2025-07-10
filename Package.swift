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
            checksum: "998cdbe4f0e22a5e86ecd5802a6480976378e455989f7abe215d08b1ed1aa56e"
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