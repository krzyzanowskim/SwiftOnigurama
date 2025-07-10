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
            checksum: "26ab6965710c21f0eb370717e98e4edbc5ce95e2f9bf4f40e53587a5d5c79ec4"
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