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
        .package(url: "https://source.skip.tools/skip.git", from: "1.2.34"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.3.1"),
        //.package(url: "https://source.skip.tools/swift-jni.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://source.skip.tools/swift-jni.git", branch: "swift-java-jni-cutover"), // ### REMOVEME
        //.package(url: "https://source.skip.tools/skip-bridge.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://source.skip.tools/skip-bridge.git", branch: "swift-java-jni-cutover"),
        .package(url: "https://github.com/swift-android-sdk/swift-android-native.git", from: "2.0.1")
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
            // swift-android-native fork v2 no longer re-exports AndroidContext through AndroidNative,
            // so depend on the AndroidContext product directly for the sample that reads the package name.
            .product(name: "AndroidContext", package: "swift-android-native", condition: .when(platforms: [.android])),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipAndroidBridgeSamplesTests", dependencies: [
            "SkipAndroidBridgeSamples",
            .product(name: "SkipTest", package: "skip"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)

// SKIP_DEPENDENCY_ROOT overrides skiptools dependencies with local `.package(path:)` checkouts so this
// package can be built/tested against unreleased local changes (e.g. the swift-java-jni-core cutover).
// In CI/normal builds the variable is unset and remote versions resolve as usual. swift-android-native
// intentionally stays on its declared (fork) URL — only skip* deps and swift-jni are overridden.
if let dependencyRoot = Context.environment["SKIP_DEPENDENCY_ROOT"] {
    package.dependencies = package.dependencies.map { dep in
        switch dep.kind {
        case .sourceControl(_, let location, _):
            guard let baseName = location.split(separator: "/").last?.split(separator: ".").first else {
                return dep
            }
            // Remap skip* and swift-jni (the SWIFT_JAVA_JNI_CORE substrate; a direct dep here) to local;
            // leave swift-android-native on its declared fork URL.
            guard baseName.hasPrefix("skip") || baseName == "swift-jni" else {
                return dep
            }
            return Package.Dependency.package(path: dependencyRoot + "/" + baseName)
        default:
            return dep
        }
    }
}
