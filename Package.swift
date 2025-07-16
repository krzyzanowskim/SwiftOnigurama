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
            checksum: "4b952a92835b2f40e584471dfd696410a8baeeeb4220a588eb7f932383401805"
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
