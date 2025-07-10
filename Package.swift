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
            checksum: "658a52566a85ea74afd57d39bec43c52a9e74a1d33948d02e94440dccb24cc3b"
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