// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
#if canImport(OSLog)
import OSLog
#endif
import Foundation
import SkipBridge
@testable import SkipAndroidBridge

#if canImport(OSLog)
let logger: Logger = Logger(subsystem: "skip.android.bridge", category: "AndroidBridgeTests")
#endif

@available(macOS 13, *)
final class AndroidBridgeTests: XCTestCase {
    override func setUp() {
        #if SKIP
        loadPeerLibrary(packageName: "skip-android-bridge", moduleName: "SkipAndroidBridge")
        #endif
    }

    func testAndroidBridge() throws {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        XCTAssertNotNil(context, "ProcessInfo.processInfo.androidContext was nil")

        let filesDir = URL(fileURLWithPath: context.getFilesDir().getAbsolutePath(), isDirectory: true)
        let cacheDir = URL(fileURLWithPath: context.getCacheDir().getAbsolutePath(), isDirectory: true)

        if isRobolectric {
            // Robolectric's files folder is tough to predict (e.g. /var/folders/zl/wkdjv4s1271fbm6w0plzknkh0000gn/T/robolectric-AndroidBridgeTests_testAndroidBridge_SkipAndroidBridge_debugUnitTest10131350412654065418/skip.android.bridge.test-dataDir/files)
            XCTAssertTrue(filesDir.path.hasSuffix("/files"), "unexpected filesDir.path: \(filesDir.path)")
            XCTAssertTrue(cacheDir.path.hasSuffix("/cache"), "unexpected cacheDir.path: \(cacheDir.path)")
        } else {
            // …but Android is predictably the app's "files" and "cache" directories
            XCTAssertEqual("/data/user/0/skip.android.bridge.test/files", filesDir.path)
            XCTAssertEqual("/data/user/0/skip.android.bridge.test/cache", cacheDir.path)
        }

        // make sure we can read and write to the filesDir
        try "ABC".write(to: filesDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        try "XYZ".write(to: cacheDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)

        /*
         02-28 01:26:38.353  2089  2107 E TestRunner: skip.lib.ErrorException: Error Domain=NSCocoaErrorDomain Code=4 "The file doesn’t exist."
         02-28 01:26:38.353  2089  2107 E TestRunner:     at skip.android.bridge.AndroidBridgeBootstrap$Companion.Swift_Companion_initAndroidBridge_0(Native Method)
         02-28 01:26:38.353  2089  2107 E TestRunner:     at skip.android.bridge.AndroidBridgeBootstrap$Companion.initAndroidBridge(AndroidBridgeBootstrap.kt:79)
         02-28 01:26:38.353  2089  2107 E TestRunner:     at skip.android.bridge.AndroidBridgeTests.testAndroidBridge$SkipAndroidBridge_debugAndroidTest(AndroidBridgeTests.kt:40)
         02-28 01:26:38.353  2089  2107 E TestRunner:     at java.lang.reflect.Method.invoke(Native Method)
         02-28 01:26:38.353  2089  2107 E TestRunner:     at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:59)
         */
        try AndroidBridgeBootstrap.initAndroidBridge(filesDir: filesDir.path, cacheDir: cacheDir.path)
        #else
        throw XCTSkip("testAndroidBridge only works from SKIP")
        #endif
    }
}
