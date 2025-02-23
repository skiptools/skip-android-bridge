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

        try AndroidBridgeBootstrap.initAndroidBridge(filesDir: filesDir.path, cacheDir: cacheDir.path)
        #else
        throw XCTSkip("testAndroidBridge only works from SKIP")
        #endif
    }
}
