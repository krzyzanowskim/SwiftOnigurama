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
            checksum: "2827288f79fa18e1765f7a985bf790e03f89c6f0fd11e47f71c84fcf494e8161"
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
