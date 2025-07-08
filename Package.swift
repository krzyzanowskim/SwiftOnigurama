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
            checksum: "bbd921f37744246abdbaaa4298d5256f15e5842874dfea2e3ab6ab68597e4a20"
        )
    ]
)