// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PasswordManagerTest",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "TestDatabase",
            targets: ["TestDatabase"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TestDatabase",
            dependencies: [],
            path: ".",
            sources: [
                "TestCore/DatabaseService.swift"
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
    ]
)