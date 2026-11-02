// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FLOWYourBrainUncomplicated",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .visionOS(.v1)],
    targets: [
        .executableTarget(name: "FLOWYourBrainUncomplicated", path: "Sources"),
        .executableTarget(name: "FLOWYourBrainUncomplicatedShare", path: "Share",
                          swiftSettings: [.unsafeFlags(["-application-extension"])],
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])]),
    ]
)
