// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-android-bridge",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipAndroidBridge", type: .dynamic, targets: ["SkipAndroidBridge"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.1.16"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-bridge.git", branch: "main"),
        .package(url: "https://source.skip.tools/swift-android-native.git", branch: "main")
    ],
    targets: [
        .target(name: "SkipAndroidBridge", dependencies: [
            .product(name: "SkipBridge", package: "skip-bridge"),
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "AndroidNative", package: "swift-android-native"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipAndroidBridgeTests", dependencies: [
            "SkipAndroidBridge",
            .product(name: "SkipTest", package: "skip"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
