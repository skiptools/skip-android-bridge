// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
import SkipBridge
import SkipAndroidBridge
import SkipAndroidBridgeSamples
import XCTest
#if SKIP
import androidx.test.platform.app.InstrumentationRegistry
#endif

let logger: Logger = Logger(subsystem: "SkipAndroidBridgeSamplesTests", category: "Tests")

final class SkipAndroidBridgeSamplesTests: XCTestCase {
    static var wasSetupOnce = false
    static var wasSetupOnMainThread: Bool? = nil

    override func setUp() {
        super.setUp()

        #if SKIP
        if Self.wasSetupOnce {
            return // already set up once
        }
        Self.wasSetupOnce = true

        loadPeerLibrary(packageName: "skip-android-bridge", moduleName: "SkipAndroidBridgeSamples")

        //try AndroidBridge.initBridge("SkipAndroidBridgeSamples") // doesn't work on Robolectric

        // we need to run this synchronously on the main thread in order for initAndroidBridge to setup the main looper properly
        // androidx.test.runner.AndroidJUnitRunner,5,main]
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            logger.info("setting up tests on thread=\(java.lang.Thread.currentThread()) vs. mainLooper thread=\(android.os.Looper.getMainLooper().getThread())")
            Self.wasSetupOnMainThread = java.lang.Thread.currentThread() == android.os.Looper.getMainLooper().getThread()

            let context = ProcessInfo.processInfo.androidContext
            try AndroidBridgeBootstrap.initAndroidBridge(filesDir: context.getFilesDir().getAbsolutePath(), cacheDir: context.getCacheDir().getAbsolutePath())
        }
        #endif

        logger.info("setup complete")
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
            throw XCTSkip("bridged assets not working on Robolectric")
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
            throw XCTSkip("test only runs on Android")
        }

        if isRobolectric {
            throw XCTSkip("no package name on Robolectric")
        }

        // SkipAndroidBridgeSamplesTests.kt testAndroidContext -> SkipAndroidBridgeSamples.kt nativeAndroidContextPackageName -> SkipAndroidBridgeSamples.swift nativeAndroidContextPackageName -> AndroidContext.swift getPackageName()
        XCTAssertEqual("skip.android.bridge.samples.test", try nativeAndroidContextPackageName())
    }

    func testLocalizedStringResource() throws {
        XCTAssertEqual(localizedStringResourceLiteralKey(), "literal")
        XCTAssertEqual(localizedStringResourceInterpolatedKey(), "interpolated %lld!")
    }

    func testLocalizedStringNS() throws {
        if isRobolectric {
            throw XCTSkip("bridged localized strings not working on Robolectric")
        }

        if !isJava && ProcessInfo.processInfo.environment["XCODE_SCHEME_NAME"] == nil {
            // we guard for !isJava because on CI we are running using the OSS Swift toolchain, which doesn't process .xcstrings files
            // this _will_ pass when running using Xcode's swift version, but AFAIK there isn't any way to check for that at runtime other than checking for an environment variable that is usually set by Xcode
            throw XCTSkip("xcstrings not working on Swift OSS toolchain")
        }

        XCTAssertEqual(localizedStringValueNS(), "Localized into English")
    }

    func testMainActorAsync() async throws {
        #if SKIP
        XCTAssertEqual(true, Self.wasSetupOnMainThread, "test case was not initialized on the main thread")

        if isAndroid {
            throw XCTSkip("test hangs on Android")
        }
        #endif

        // test hangs on Android emulator for some reason
        let value = await mainActorAsyncValue()
        XCTAssertEqual("MainActor!", value)
    }
}
