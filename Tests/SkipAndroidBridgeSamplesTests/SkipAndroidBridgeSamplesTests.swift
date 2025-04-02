// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
import SkipBridge
import SkipAndroidBridge
import SkipAndroidBridgeSamples
import XCTest

final class SkipAndroidBridgeSamplesTests: XCTestCase {
    override func setUp() {
        #if SKIP
        loadPeerLibrary(packageName: "skip-android-bridge", moduleName: "SkipAndroidBridgeSamples")

        //try AndroidBridge.initBridge("SkipAndroidBridgeSamples") // doesn't work on Robolectric

        let context = ProcessInfo.processInfo.androidContext
        try AndroidBridgeBootstrap.initAndroidBridge(filesDir: context.getFilesDir().getAbsolutePath(), cacheDir: context.getCacheDir().getAbsolutePath())

        #endif
    }

    func testAndroidBridge() throws {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        XCTAssertNotNil(context, "ProcessInfo.processInfo.androidContext was nil")

        let filesDir = URL(fileURLWithPath: context.getFilesDir().getAbsolutePath(), isDirectory: true)
        let cacheDir = URL(fileURLWithPath: context.getCacheDir().getAbsolutePath(), isDirectory: true)

        if isRobolectric {
            // Robolectric's files folder is tough to predict (e.g. /var/folders/zl/wkdjv4s1271fbm6w0plzknkh0000gn/T/robolectric-AndroidBridgeTests_testAndroidBridge_SkipAndroidBridge_debugUnitTest10131350412654065418/skip.android.bridge.samples.test-dataDir/files)
            XCTAssertTrue(filesDir.path.hasSuffix("/files"), "unexpected filesDir.path: \(filesDir.path)")
            XCTAssertTrue(cacheDir.path.hasSuffix("/cache"), "unexpected cacheDir.path: \(cacheDir.path)")
        } else {
            // …but Android is predictably the app's "files" and "cache" directories
            XCTAssertEqual("/data/user/0/skip.android.bridge.samples.test/files", filesDir.path)
            XCTAssertEqual("/data/user/0/skip.android.bridge.samples.test/cache", cacheDir.path)
        }

        // make sure we can read and write to the filesDir
        try "ABC".write(to: filesDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        try "XYZ".write(to: cacheDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)

        try AndroidBridgeBootstrap.initAndroidBridge(filesDir: filesDir.path, cacheDir: cacheDir.path)
        #else
        throw XCTSkip("testAndroidBridge only works from SKIP")
        #endif
    }

    func testSimpleConstants() {
        XCTAssertEqual(swiftStringConstant, "s")
    }

    func testFunction() {
        XCTAssertEqual("value", getStringValue("value"))
    }

    func testBundleClassName() throws {
        let className = bundleClassName()
        if isAndroid {
            XCTAssertEqual("AndroidBundle: bundle: class skip.android.bridge.samples._ModuleBundleLocator", className)
        } else {
            XCTAssertTrue(className.hasPrefix("NSBundle"), "unexpected bundle class name: \(className)")
        }
    }

    func testResourceURL() throws {
        if isRobolectric {
            // unwrap fails on Robolectric
            throw XCTSkip("unknown error on Robolectric")
        }

        let url = try XCTUnwrap(getAssetURL(named: "sample.json"))
        if isRobolectric || !isJava {
            XCTAssertEqual("file", url.scheme)
            XCTAssertEqual("sample.json", url.lastPathComponent)
        } else {
            XCTAssertEqual("asset", url.scheme)
            XCTAssertEqual("asset:/skip/android/bridge/samples/Resources/sample.json", url.absoluteString)
        }

        let expectedContents = #"{ "name": "SkipAndroidBridgeSamples" }"# + "\n"

        let bridgedData = try XCTUnwrap(getAssetContents(named: "sample.json"))
        XCTAssertEqual(expectedContents, String(data: bridgedData, encoding: .utf8))

        // also try loading localy with the Java side of the URLProtocol
        let localData = try Data(contentsOf: url)
        XCTAssertEqual(expectedContents, String(data: localData, encoding: .utf8))
    }

    func testUserDefaultsClassName() throws {
        let className = userDefaultsClassName()
        if isAndroid {
            XCTAssertEqual("AndroidUserDefaults: SkipAndroidBridge.UserDefaultsAccess", className)
        }
    }

    func testUserDefaults() throws {
        if isRobolectric {
            // ???
            // SkipBridge/BridgedTypes.swift:189: Fatal error: Unable to bridge Swift instance value of type: NSTaggedPointerString
            throw XCTSkip("unknown error on Robolectric")
        }

        setStringDefault(name: "test", value: "value")
        XCTAssertEqual("value", getStringDefault(name: "test"))

        setStringDefault(name: "test", value: "value2")
        XCTAssertEqual("value2", getStringDefault(name: "test"))

        setStringDefault(name: "test", value: nil)
        XCTAssertEqual(nil, getStringDefault(name: "test"))
    }

    func testAndroidContext() throws {
        if !isAndroid {
            throw XCTSkip("no package name on Robolectric")
        }

        // SkipAndroidBridgeSamplesTests.kt testAndroidContext -> SkipAndroidBridgeSamples.kt nativeAndroidContextPackageName -> SkipAndroidBridgeSamples.swift nativeAndroidContextPackageName -> AndroidContext.swift getPackageName()
        XCTAssertEqual("skip.android.bridge.samples.test", try nativeAndroidContextPackageName())
    }

    // not working yet…
//    func testMainActorAsync() async throws {
//        let value = await mainActorAsyncValue()
//        XCTAssertEqual("MainActor!", value)
//    }
}
