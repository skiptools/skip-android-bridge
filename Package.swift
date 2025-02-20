// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-android-bridge",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipAndroidBridge", type: .dynamic, targets: ["SkipAndroidBridge"]),
        .library(name: "SkipAndroidBridgeKt", type: .dynamic, targets: ["SkipAndroidBridgeKt"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.2.1"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.2.0"),
        .package(url: "https://source.skip.tools/skip-bridge.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://source.skip.tools/swift-android-native.git", "0.0.0"..<"2.0.0")
    ],
    targets: [
        // mode=swift
        .target(name: "SkipAndroidBridge", dependencies: [
            .product(name: "SkipBridgeKt", package: "skip-bridge"),
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "AndroidNative", package: "swift-android-native", condition: .when(platforms: [.android])),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        // mode=kotlin
        .target(name: "SkipAndroidBridgeKt",
            dependencies: [
                "SkipAndroidBridge",
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]),

        .testTarget(name: "SkipAndroidBridgeTests", dependencies: [
            "SkipAndroidBridge",
            .product(name: "SkipTest", package: "skip"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipAndroidBridgeKtTests", dependencies: [
            "SkipAndroidBridgeKt",
            .product(name: "SkipTest", package: "skip"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
