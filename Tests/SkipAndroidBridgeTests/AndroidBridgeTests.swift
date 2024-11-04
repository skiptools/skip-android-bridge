// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
import SkipBridge
@testable import SkipAndroidBridge

let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "Tests")

@available(macOS 13, *)
final class AndroidBridgeTests: XCTestCase {
    override func setUp() {
        #if SKIP
        loadPeerLibrary(packageName: "skip-android-bridge", moduleName: "SkipAndroidBridge")
        #endif
    }

    func testSampleFunction() throws {
        XCTAssertEqual("ABCXYZ", testSupport_appendStrings("ABC", "XYZ"))
    }

    func testAndroidBridge() throws {
        let mode = testSupport_isSkipMode()
        XCTAssertEqual(isJava ? 1 : -2, mode, "@BridgeToSwift should be transpiled: \(mode)")

        #if SKIP
        let tmpdir = testSupport_getJavaSystemProperty("java.io.tmpdir")
        XCTAssertEqual(isRobolectric ? NSTemporaryDirectory() : "/data/user/0/skip.android.bridge.test/cache", tmpdir)

        XCTAssertNotNil(ProcessInfo.processInfo.androidContext, "ProcessInfo.processInfo.androidContext was nil")

        let context = AndroidContext.shared

        XCTAssertNotNil(context, "bridged context was nil")

        let filesDir = URL(fileURLWithPath: context.filesDir, isDirectory: true)
        let cacheDir = URL(fileURLWithPath: context.cacheDir, isDirectory: true)

        // Robolectric's files folder is tough to predict /var/folders/zl/wkdjv4s1271fbm6w0plzknkh0000gn/T/robolectric-AndroidBridgeTests_testAndroidBridge_SkipAndroidBridge_debugUnitTest10131350412654065418/skip.android.bridge.test-dataDir/files
        if !isRobolectric {
            // …but Android is predictable
            XCTAssertEqual("/data/user/0/skip.android.bridge.test/files", filesDir)
            XCTAssertEqual("/data/user/0/skip.android.bridge.test/cache", cacheDir)
        }

        // make sure we can read and write to the filesDir
        try "ABC".write(to: filesDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        try "XYZ".write(to: cacheDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        #endif
    }
}
