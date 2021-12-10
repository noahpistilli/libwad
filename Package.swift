// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "libwad",
    // CryptoSwift requires higher than El Capitan
    platforms: [
        .macOS(.v10_12),
    ],
    products: [
        .library(
            name: "libwad",
            targets: ["libwad"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.4.1")),
    ],
    targets: [
        .target(
            name: "libwad",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ]
        ),
    ]
)
