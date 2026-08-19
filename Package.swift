// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "skip-android-bridge",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipAndroidBridge", type: .dynamic, targets: ["SkipAndroidBridge"]),
        .library(name: "SkipAndroidBridgeSamples", type: .dynamic, targets: ["SkipAndroidBridgeSamples"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skiptools/skip.git", from: "1.9.6"),
        .package(url: "https://github.com/skiptools/skip-foundation.git", from: "1.4.3"),
        .package(url: "https://github.com/skiptools/swift-jni.git", "0.5.0"..<"2.0.0"),
        .package(url: "https://github.com/skiptools/skip-bridge.git", "0.17.3"..<"2.0.0"),
        .package(url: "https://github.com/skiptools/swift-android-native.git", from: "1.5.1")
    ],
    targets: [
        .target(name: "SkipAndroidBridge", dependencies: [
            .product(name: "SkipBridge", package: "skip-bridge"),
            .product(name: "SwiftJNI", package: "swift-jni"),
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "AndroidNative", package: "swift-android-native", condition: .when(platforms: [.android])),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),

        .testTarget(name: "SkipAndroidBridgeTests", dependencies: [
            "SkipAndroidBridge",
            .product(name: "SkipTest", package: "skip"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),

        .target(name: "SkipAndroidBridgeSamples", dependencies: [
            "SkipAndroidBridge",
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipAndroidBridgeSamplesTests", dependencies: [
            "SkipAndroidBridgeSamples",
            .product(name: "SkipTest", package: "skip"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
