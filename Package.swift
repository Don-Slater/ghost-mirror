// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EaseMirror",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "EaseMirrorCore", targets: ["EaseMirrorCore"]),
        .executable(name: "EaseMirror", targets: ["EaseMirror"]),
        .executable(name: "ghost-mirror-cli", targets: ["EaseMirrorCLI"]),
    ],
    targets: [
        .target(
            name: "EaseMirrorCore",
            path: "Sources/EaseMirrorCore"
        ),
        .executableTarget(
            name: "EaseMirror",
            dependencies: ["EaseMirrorCore"],
            path: "Sources/EaseMirror"
        ),
        .executableTarget(
            name: "EaseMirrorCLI",
            dependencies: ["EaseMirrorCore"],
            path: "Sources/EaseMirrorCLI"
        ),
    ]
)
