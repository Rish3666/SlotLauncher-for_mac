// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SlotLauncher",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SlotLauncher",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            exclude: ["Info.plist"]
        ),
    ]
)
