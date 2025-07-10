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
    ],
    targets: [
        .binaryTarget(
            name: "Oniguruma",
            url: "https://github.com/krzyzanowskim/oniguruma/releases/download/v6.9.10-xcframework/Oniguruma.xcframework.zip",
            checksum: "614c9fe04a7f6513f38a4ea825f32f20833f9a3db19ce440e07522b5d5d04238"
        )
    ]
)