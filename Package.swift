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
            checksum: "5ac929c580666ae4c92dff6cafbd30f4159af60515a19247d7b738cda9fc4932"
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
