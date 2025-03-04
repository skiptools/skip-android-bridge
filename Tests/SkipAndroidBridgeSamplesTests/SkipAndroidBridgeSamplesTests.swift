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

    func testDynamicAndroidContext() throws {
        #if os(Android) || ROBOLECTRIC
        // Unresolved reference 'dynamicAndroidContext'.
        //let context = ProcessInfo.processInfo.dynamicAndroidContext()
        //let cachesDir: String = try context.getCachesDir()
        //XCTAssertEqual("", cachesDir)
        #endif
    }

    // not working yet…
//    func testMainActorAsync() async throws {
//        let value = await mainActorAsyncValue()
//        XCTAssertEqual("MainActor!", value)
//    }
}
