// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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

    func resourceURLTest(name: String, bundle: Bundle?) throws {
        if isRobolectric {
            // unwrap fails on Robolectric
            throw XCTSkip("unknown error on Robolectric")
        }

        let url = try XCTUnwrap(getAssetURL(named: "\(name).json", in: bundle))
        if isRobolectric || !isJava {
            XCTAssertEqual("file", url.scheme)
            XCTAssertEqual("\(name).json", url.lastPathComponent)
        } else {
            XCTAssertEqual("asset", url.scheme)
            XCTAssertEqual("asset:/skip/android/bridge/samples/Resources/\(name).json", url.absoluteString)
        }

        let expectedContents = "{ \"name\": \"\(name)\" }\n"

        let bridgedData = try XCTUnwrap(getAssetContents(named: "\(name).json", in: bundle))
        XCTAssertEqual(expectedContents, String(data: bridgedData, encoding: .utf8))

        // also try loading localy with the Java side of the URLProtocol
        let localData = try Data(contentsOf: url)
        XCTAssertEqual(expectedContents, String(data: localData, encoding: .utf8))
    }

    func testResourceURL() throws {
        try resourceURLTest(name: "SkipAndroidBridgeSamples", bundle: nil)
    }

    func testResourceURLWithBundleParameter() throws {
        try resourceURLTest(name: "SkipAndroidBridgeSamplesTests", bundle: .module)
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

    func testLocalizedStringResource() throws {
        XCTAssertEqual(localizedStringResourceLiteralKey(), "literal")
        XCTAssertEqual(localizedStringResourceInterpolatedKey(), "interpolated %lld!")
    }

    // not working yet…
//    func testMainActorAsync() async throws {
//        let value = await mainActorAsyncValue()
//        XCTAssertEqual("MainActor!", value)
//    }
}
