// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PasswordManageriOS",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PasswordManageriOS",
            targets: ["PasswordManageriOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        .package(url: "https://github.com/sqlcipher/sqlcipher.git", from: "4.5.5")
    ],
    targets: [
        .target(
            name: "PasswordManageriOS",
            dependencies: [
                "Alamofire",
                .product(name: "SQLite", package: "SQLite.swift")
            ]),
        .testTarget(
            name: "PasswordManageriOSTests",
            dependencies: ["PasswordManageriOS"]),
    ]
)