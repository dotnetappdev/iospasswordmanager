// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iOSPasswordManager",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "iOSPasswordManager",
            targets: ["iOSPasswordManager"]),
    ],
    dependencies: [
        // No external dependencies - using only native iOS frameworks
    ],
    targets: [
        .target(
            name: "iOSPasswordManager",
            dependencies: [],
            path: "iOSPasswordManager",
            sources: [
                "App.swift",
                "Models/PasswordManager.swift",
                "Services/KeychainService.swift",
                "Services/BiometricAuth.swift",
                "Services/DatabaseService.swift",
                "Views/ContentView.swift",
                "Views/LoginView.swift",
                "Views/QRScannerView.swift"
            ]
        ),
        .testTarget(
            name: "iOSPasswordManagerTests",
            dependencies: ["iOSPasswordManager"],
            path: "Tests"
        ),
    ]
)