// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FullStorySwiftUITransformer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from:Version("600.0.1")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "FullStorySwiftUITransformer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(name: "FullStorySwiftUITransformerTests",
                    dependencies: ["FullStorySwiftUITransformer"]),
    ]
)
