// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddybuildSwift",
    products: [
        .library(
            name: "BuddybuildSwift",
            targets: ["BuddybuildSwift"]),
    ],
    dependencies: [
        .package(url: "git@github.com:JohnSundell/Files.git", from: "1.12.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "1.2.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "7.0.2"),

    ],
    targets: [
        .target(
            name: "BuddybuildSwift",
            dependencies: ["Files"]),
        .testTarget(
            name: "BuddybuildSwiftTests",
            dependencies: ["BuddybuildSwift", "Quick", "Nimble", "Files"]),
    ]
)
