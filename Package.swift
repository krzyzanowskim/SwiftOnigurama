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
            url: "https://github.com/krzyzanowskim/SwiftOnigurama/releases/download/6.9.10/Oniguruma.xcframework.zip",
            checksum: "75fee5175b46f8656485fc6085f18e241429d538e4c19637ac5b84817ca5c0b1"
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