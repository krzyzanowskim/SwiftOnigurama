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
            url: "https://github.com/krzyzanowskim/oniguruma/releases/download/6.9.10/Oniguruma.xcframework.zip",
            checksum: "d49ca9245b4915a8d5a9d76f3aa67379d0cad35267c9f7b7aadadcdb5581f96c"
        )
    ]
)